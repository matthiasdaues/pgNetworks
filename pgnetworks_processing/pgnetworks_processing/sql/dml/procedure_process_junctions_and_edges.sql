-- this procedure processes the input edges / linestrings:
-- snaps closest points to linestrings, segmentizes linestrings

-- name: create_procedure_process_junctions_and_edges#
create or replace procedure pgnetworks_staging.process_junctions_and_edges(in lower_bound bigint, upper_bound bigint, out item_count int)
language plpgsql
as $procedure$
--do $$
declare
    -- extraction variables
    edge_data_array pgnetworks_staging.edge_processing[];
    edge_data pgnetworks_staging.edge_processing;
    -- transformation variables
    snap_tolerance float;
    junctioned_edge geometry;
    -- validation variables
    round_count int;
    -- loading variables
    segment pgnetworks_staging.segment_processing;
    segments_array pgnetworks_staging.segment_processing[];
begin
    -- begin batch processing
    -- collect the edge data into an array specified by lower and upper bound
    with edge_ids as (
        -- create an ordered array that corresponds 
        -- to the btree index on the edge_id field
        select array_agg(distinct edge_id order by edge_id asc) as edge_id_array
          from pgnetworks_staging.vertex_2_edge
         where edge_id >= lower_bound 
           and edge_id < upper_bound
    )
    ,   edge_geom as (
        select rn.id as edge_id
             , rn.geom
          from pgnetworks_staging.road_network rn
         where id = any (array(select edge_id_array from edge_ids))
    )
    ,   junctions as (
        select edge_id
             , st_union(closest_point_geom) as junction_geometries
             , count(*) filter (where new_point) as new_points_count
          from pgnetworks_staging.vertex_2_edge 
         where edge_id = any (array(select edge_id_array from edge_ids))
         group by edge_id
    )
    select into edge_data_array
    array(
        select row(
                   -- this row is defined as the custom data type "edge_processing"
                   -- which allows aggregating multiple datatypes into a heterogenous array
                   eg.edge_id, 
                   eg.geom,
                   j.new_points_count,
                   j.junction_geometries
               )::pgnetworks_staging.edge_processing
          from edge_geom eg
          left join junctions j on eg.edge_id = j.edge_id
    );
    item_count := array_length(edge_data_array, 1);
    -- loop through the edge data array
    foreach edge_data in array edge_data_array
    loop
        --raise notice '%', edge_data.edge_id;
        snap_tolerance := 0.1;
        round_count := 0;
        -- loop through varying tolerance values
        -- when snapping the junctions to the edge line.
        -- equality of the count of the points in the new line
        -- with the sum of the point count of the old line and thenew points
        -- exits the loop.
        -- else an error is thrown.
        while round_count <= 20 
            loop
                begin
                junctioned_edge := st_snap(edge_data.edge_geom, edge_data.junction_geometries,snap_tolerance);
                    if st_numpoints(junctioned_edge) = st_numpoints(edge_data.edge_geom) + edge_data.new_points_count
                    then             
                    --raise notice '%', round_count;
                    exit;
                    elsif round_count = 20
                    then raise notice 'no value found';
                    end if;
                end;
            snap_tolerance := snap_tolerance / 10;
            round_count := round_count + 1;
            end loop; 
        execute format(
        $split_and_insert$
        with split_result as (
            select (st_dump(
                st_split($1, $2)  -- $1 = junctioned_edge, $2 = junction geometries
            )).geom as parted_geom
        )
        insert into pgnetworks_staging.segments (
            edge_id, 
            edge_type, 
            node_1, 
            node_2, 
            geom
        )
        select
            $3 as edge_id,         -- $3 = edge_data.edge_id
            'near_net',
            ghh_encode_xy_to_id(
                st_x(st_pointn(parted_geom, 1))::numeric(10,7),
                st_y(st_pointn(parted_geom, 1))::numeric(10,7)
            ) as node_1,
            ghh_encode_xy_to_id(
                st_x(st_pointn(parted_geom, -1))::numeric(10,7),
                st_y(st_pointn(parted_geom, -1))::numeric(10,7)
            ) as node_2,
            parted_geom
        from split_result
        where parted_geom is not null
        and geometrytype(parted_geom) = 'linestring'
        $split_and_insert$
        )
        using
            junctioned_edge,
            edge_data.junction_geometries,
            edge_data.edge_id;

        execute format('update pgnetworks_staging.road_network set segmentized = TRUE where id = $1')
        using edge_data.edge_id;
        
    end loop;
    -- close batch processing
end 
$procedure$;

create or replace function pgnetworks_staging.call_process_junctions_and_edges(lower_bound bigint, upper_bound bigint)
returns int
language plpgsql
as $function$
declare
    item_count int;
begin
    call pgnetworks_staging.process_junctions_and_edges(lower_bound, upper_bound, item_count);
    return item_count;
end;
$function$;


-- name: drop_procedure_process_junctions_and_edges#
drop function pgnetworks_staging.call_process_junctions_and_edges(bigint, bigint);
drop procedure pgnetworks_staging.process_junctions_and_edges(in bigint, bigint, out int);