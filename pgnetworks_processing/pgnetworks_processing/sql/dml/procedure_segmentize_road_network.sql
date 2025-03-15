-- this procedure processes the linestrings still
-- unsegmentized after snapping the vertices to the network

-- name: create_procedure_segmentize_road_network#
create or replace procedure pgnetworks_staging.segmentize_road_network(in selector_grid_cell text, out item_count int)
language plpgsql
as $procedure$
-- do $$
declare
    -- extraction variables
    this_edge_id bigint;  
    -- processing variables
    edges_count int;
    neighbours_count int;

begin
    create temporary table edge_data_table (
        id int,
        layer text,
        geom geometry
    );
    create index temp_table_id_idx on edge_data_table using btree (id);    

    create temporary table neighbour_data_table (
        id int,
        edge_id int,
        edge_layer text,
        layer text,
        geom geometry
    );

    -- begin batch processing
    -- select the edges within the selector grid cell
    with rough_selection as (
        select id
             , properties
             , geom
          from pgnetworks_staging.road_network 
         where geom && 'POLYGON((5.8630797 47.2842039,5.8630797 47.9593379,7.7708982 47.9593379,7.7708982 47.2842039,5.8630797 47.2842039))'::geometry(polygon,4326)
           and segmentized is FALSE 
        )
    ,   refined_selection as (
        select id::int
             , coalesce(cast((properties ->> 'layer') as text),'n') as edge_layer
             , geom
          from rough_selection
         where st_intersects(geom, 'POLYGON((5.8630797 47.2842039,5.8630797 47.9593379,7.7708982 47.9593379,7.7708982 47.2842039,5.8630797 47.2842039))'::geometry(polygon,4326))
         order by geom
        )
    insert into edge_data_table (id, layer, geom)
    select id
         , edge_layer::text
         , geom
      from refined_selection;

    -- set "item_count"
    select into item_count count(*) from edge_data_table;
    raise notice '%', item_count;

    -- loop through the edge data array and select the neighbours
    edges_count := item_count;
    raise notice '%', edges_count;
    while edges_count > 0
    loop

        -- set the current edge_id    
        select into this_edge_id 
               id
          from edge_data_table
         order by id asc
         limit 1;
        
        raise notice '%', this_edge_id;

        -- select the neighbouring edges into the neighbours table 
        with edge_data as (
            select *
              from edge_data_table
             where id = this_edge_id
        )
        insert into neighbour_data_table 
        select rn.id
             , ed.id as edge_id
             , ed.layer as edge_layer
             , coalesce(cast((rn.properties ->> 'layer') as text),'n') as layer
             , rn.geom
          from pgnetworks_staging.road_network rn
             , edge_data ed
         where st_intersects(ed.geom, rn.geom)
           and ed.id != rn.id
           and ed.layer = coalesce(cast((rn.properties ->> 'layer') as text),'n');

        -- set the neighbours count
        select into neighbours_count count(*) from neighbour_data_table;
        raise notice '%', neighbours_count;
        
        -- check whether the table is populated
        if neighbours_count < 1             
        
        -- if no neighbours exist, insert into segments and remove from edge_data_array
        then
            insert into pgnetworks_staging.segments (edge_id, edge_type, node_1, node_2, geom)
            select id
                 , 'far_net'::pgnetworks_staging.edge_type
                 , ghh_encode_xy_to_id(st_x(st_pointn(geom,1))::numeric, st_y(st_pointn(geom,1))::numeric)
                 , ghh_encode_xy_to_id(st_x(st_pointn(geom,-1))::numeric, st_y(st_pointn(geom,-1))::numeric)
                 , geom
              from edge_data_table
             where id = this_edge_id;
            delete from edge_data_table where id = this_edge_id;
            edges_count := edges_count -1;
 
        -- if neighbours exist
        -- create the topological jigsaw through "st_split()"
        else
            with neighbours as (
                select *
                  from neighbour_data_table
                )
            ,   line_2 as (
                select max(edge_id) as edge_id      -- reduce result set to 1
                     , st_collect(n.geom) as geom
                  from neighbours n
                 where n.layer = n.edge_layer       -- this excludes over- or underpasses
                )
            ,   splits as (
                select edge_id
                     , (st_dump(st_split((select geom from edge_data_table where id = edge_id),(select geom from line_2)))).geom
                  from line_2
                )
            insert into pgnetworks_staging.segments (edge_id, edge_type, node_1, node_2, geom)
            select edge_id
                 , 'far_net'::pgnetworks_staging.edge_type
                 , ghh_encode_xy_to_id(st_x(st_pointn(geom,1))::numeric, st_y(st_pointn(geom,1))::numeric)
                 , ghh_encode_xy_to_id(st_x(st_pointn(geom,-1))::numeric, st_y(st_pointn(geom,-1))::numeric)
                 , geom
              from splits
            ;
            -- remove the processed edge from the current data set
            delete from edge_data_table where id = this_edge_id;
            -- rinse the neighbour table
            truncate table neighbour_data_table;
            -- reduce the edges count
            edges_count := edges_count -1;

        end if;
    end loop;
    -- close batch processing
    drop table edge_data_table;  
    drop table neighbour_data_table;  
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