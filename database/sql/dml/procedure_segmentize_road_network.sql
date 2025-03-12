-- this procedure processes the linestrings still
-- unsegmentized after snapping the vertices to the network

-- name: create_procedure_segmentize_road_network#
create or replace procedure pgnetworks_staging.segmentize_road_network(in selector_grid_cell text, out item_count int)
language plpgsql
as $procedure$
-- do $$
declare
--    -- DEV only variables
--    selector_grid_cell geometry;
--    item_count int;
    -- extraction variables
    edge_data_array pgnetworks_staging.edge_processing_2[];
    edge_data pgnetworks_staging.edge_processing_2;
    edge_id bigint;  
    -- processing variables
    edges_count int;
    start_end geometry(point,4326)[];
    start_end_neighbour geometry(point,4326)[];
    cp_neighbour geometry(point,4326);
    ok_neighbours int;
    neighbours pgnetworks_staging.edge_processing_2[];
    neighbour pgnetworks_staging.edge_processing_2;
    edge_split_collection geometry;
    edge_split_array pgnetworks_staging.edge_processing_2[];
    edge_split pgnetworks_staging.edge_processing_2;

begin
--    -- DEV only: select the selector grid cell
--    select into selector_grid_cell geom from pgnetworks_staging.selector_grid limit 1;

    -- begin batch processing

    -- collect the edge ids into an array specified by the selector grid cell
    selector_grid_cell := selector_grid_cell::geometry;
    with rough_selection as (
        select id
             , properties
             , geom
          from pgnetworks_staging.road_network 
         where segmentized is FALSE 
           and geom && selector_grid_cell::geometry(polygon,4326)
    )
    ,   refined_selection as (
        select id
             , jsonb_path_query_first(properties, '$.layer') as edge_layer
             , geom
          from rough_selection 
         where st_intersects(st_pointn(geom,1),selector_grid_cell::geometry(polygon,4326))
         order by geom
--         limit 10000
    )
    select into edge_data_array
           array(
                select row(id, edge_layer, geom)::pgnetworks_staging.edge_processing_2
                  from refined_selection
           )::pgnetworks_staging.edge_processing_2[]
      from refined_selection;        
    item_count := array_length(edge_data_array, 1);
    edges_count := item_count;

    -- loop through the edge data array and select the neighbours
    while edges_count > 0
    loop
        edge_data := edge_data_array[1];
--        raise notice 'start count:%, start id: %', edges_count, edge_data.edge_id;
        start_end := array[st_pointn(edge_data.edge_geom,1), st_pointn(edge_data.edge_geom,-1)];

        -- select the neighbouring edges into the neighbours array 
        select into neighbours array(
               select row (
                      rn.id
                    , jsonb_path_query_first(rn.properties, '$.layer')
                    , rn.geom
                      )::pgnetworks_staging.edge_processing_2  
                 from pgnetworks_staging.road_network rn
                where st_intersects(edge_data.edge_geom, rn.geom)
                  and edge_data.edge_id != rn.id
        )::pgnetworks_staging.edge_processing_2[];

        -- check whether the array is populated
        if 
            array_length(neighbours,1) is NULL 
        
        -- if no neighbours exist, remove from edge_data_array
        then
            edge_data_array := array_remove(edge_data_array,edge_data);
            edges_count := array_length(edge_data_array,1);
 
        -- if neighbours exist
        else

            -- check the relationship
            ok_neighbours := 0;
            foreach neighbour in array neighbours 
            loop
                start_end_neighbour := array[st_pointn(neighbour.edge_geom,1), st_pointn(neighbour.edge_geom,-1)];
                cp_neighbour := st_closestpoint(neighbour.edge_geom,edge_data.edge_geom);
    
                -- start or end coincide
                if
                    start_end && start_end_neighbour
                then
                    ok_neighbours := ok_neighbours + 1;
--                    raise notice '% % % % %',edge_data.edge_id, neighbour.edge_id, 'start or end coincide', ok_neighbours, array_length(neighbours,1);

                    NULL;
    
                -- closest point coincides with neighbour's start or end
                elsif  
                    cp_neighbour = any(start_end_neighbour)
                then
--                    raise notice '% % %',edge_data.edge_id, neighbour.edge_id, 'closest point coincides with neighbour edge start or end';
                    edge_split_collection := st_split(edge_data.edge_geom, cp_neighbour);
                    select into edge_split_array array(
                           select row (
                                  edge_data.edge_id,
                                  edge_data.edge_layer,                               
                                  st_geometryn(edge_split_collection,1)
                           )::pgnetworks_staging.edge_processing_2
                           union all
                           select row (
                                  edge_data.edge_id,
                                  edge_data.edge_layer,                                
                                  st_geometryn(edge_split_collection,2)
                           )::pgnetworks_staging.edge_processing_2
                    );
                    -- remove the original geometry from edge_data_array
                    edge_data_array := array_remove(edge_data_array,edge_data_array[1]);
                    -- insert the split geometries into the edge_data_array
                    edge_data_array := edge_data_array || edge_split_array;
                    edges_count := array_length(edge_data_array,1);
--                    raise notice '% % %',edge_data.edge_id, 'intersection: edge is split', edges_count;
                    exit;

                -- closest point coincides with current edge's start or end
                elsif   
                    cp_neighbour = any(start_end)
                then
                    ok_neighbours := ok_neighbours + 1;
--                    raise notice '% % %',edge_data.edge_id, neighbour.edge_id, 'closest point coincides with current edge start or end';
                    NULL;
                
                -- layer entry exists and is identical
                elsif  (
                            neighbour.edge_layer is not NULL
                        and edge_data.edge_layer is not NULL 
                        and neighbour.edge_layer = edge_data.edge_layer 
                       ) or not (
                            neighbour.edge_layer is NULL
                        and edge_data.edge_layer is NULL 
                       )                       
                then
--                    raise notice '% % %',edge_data.edge_id, neighbour.edge_id, 'crossing permitted';
                    edge_split_collection := st_split(edge_data.edge_geom, cp_neighbour);
                    select into edge_split_array array(
                           select row (
                                  edge_data.edge_id,
                                  edge_data.edge_layer,                               
                                  st_geometryn(edge_split_collection,1)
                           )::pgnetworks_staging.edge_processing_2
                           union all
                           select row (
                                  edge_data.edge_id,
                                  edge_data.edge_layer,                                
                                  st_geometryn(edge_split_collection,2)
                           )::pgnetworks_staging.edge_processing_2
                    );
                    -- remove the original geometry from edge_data_array
                    edge_data_array := array_remove(edge_data_array,edge_data_array[1]);
                    -- insert the split geometries into the edge_data_array
                    edge_data_array := edge_data_array || edge_split_array;
                    edges_count := array_length(edge_data_array,1);
--                    raise notice '% % %',edge_data.edge_id, 'crossing: edge is split', edges_count;
                    exit;
    
                else
                    ok_neighbours := ok_neighbours + 1;
--                    raise notice '% % %',edge_data.edge_id, neighbour.edge_id, 'crossing prohibited';
                    NULL;
                end if;
            end loop;
            edge_data_array := array_remove(edge_data_array,edge_data);
            edges_count := array_length(edge_data_array,1);
--            raise notice 'stop count:%, stop id: %', edges_count, edge_data.edge_id;
--            raise notice '%', '----------------------';
        end if;
        if
            ok_neighbours = array_length(neighbours,1)
        then
            execute format('insert into pgnetworks_staging.segments (edge_id, edge_type, node_1, node_2, geom) values ($1, $2, $3, $4, $5)')
            using edge_data.edge_id, 'far_net'::pgnetworks_staging.edge_type, ghh_encode_xy_to_id(st_x(start_end[1])::numeric, st_y(start_end[1])::numeric),ghh_encode_xy_to_id(st_x(start_end[2])::numeric, st_y(start_end[2])::numeric), edge_data.edge_geom;
        elsif
            array_length(neighbours,1) is NULL
        then
--            raise notice '%',edge_data.edge_id;
        end if;
    end loop;
    -- close batch processing    
end
$procedure$;
-- $$

create or replace function pgnetworks_staging.call_segmentize_road_network(selector_grid_cell text)
returns int
language plpgsql
as $function$
declare
    item_count int;
begin
    call pgnetworks_staging.segmentize_road_network(selector_grid_cell, item_count);
    return item_count;
end;
$function$;


-- name: drop_procedure_segmentize_road_network#
drop function pgnetworks_staging.call_segmentize_road_network(text);
drop procedure pgnetworks_staging.segmentize_road_network(in text, out int);