-- this procedure processes vertices and
-- creates the closest points on the closest edge

-- name: create_procedure_join_vertex_2_edge#
create or replace procedure pgnetworks_staging.join_vertex_2_edge(in lower_bound bigint, upper_bound bigint, out item_count int)
language plpgsql
as $procedure$
--do $$
declare
    -- log variables
    log_level text;
    work_step text;
    start_time timestamptz;
    end_time timestamptz;
--    item_count int;
    message text;
    -- process variables
    vertex_id_array bigint[];
    vertex_id bigint;  
    vertex_geom geometry(point,4326);
    buffer_distance int;
    buffer_geom geometry(polygon,4326);
    closest record;
    nodes_array bigint[];
    -- result variables
    access record;
begin
    -- set start time
    start_time := clock_timestamp();
    work_step := 'join_vertex_2_edge';
    -- begin batch processing
    -- collect the id-array specified by lower and upper bound
    with id_list as (
        select location_id
          from pgnetworks_staging.terminals
         where location_id >= lower_bound
           and location_id < upper_bound 
         order by location_id asc
    )
    select into vertex_id_array
           array_agg(location_id)
      from id_list
     ;
    item_count := array_length(vertex_id_array, 1);
    -- loop through the id array
    foreach vertex_id in array vertex_id_array
    loop
        -- create vertex_geom
        vertex_geom := st_setsrid(public.ghh_decode_id_to_wkt(vertex_id)::geometry, 4326);
        -- find the closest edge by looping through increasing buffer distances
        -- to accomodate for vertices further away from the nearest edge
        buffer_distance := 100;
        loop 
            begin       
            buffer_geom := st_buffer(vertex_geom::geography, buffer_distance)::geometry;
            select into closest
                   r.id as edge_id
                 , r.geom as edge_geom
              from pgnetworks_staging.road_network r
             where buffer_geom && r.geom
             order by vertex_geom <-> r.geom
             limit 1;
            -- assign edge_id und edge_geom to variable
            if 
                closest.edge_id is not null then exit;
            end if;
            -- maybe limit the buffer distance
            buffer_distance := buffer_distance * 5;
            end;
        end loop;
        -- calculate the closest point id
        with closest_point as (
            select st_closestpoint(closest.edge_geom,vertex_geom) as closest_point_geom
        )
        , edge_dump_array as (
            select array_agg(ed.edge_dump) as edge_dump_array 
              from (
                select (st_dumppoints(closest.edge_geom)).geom as edge_dump
                ) ed
        )
        select into access
               vertex_id
             , closest.edge_id 
             , public.ghh_encode_xy_to_id(st_x(cp.closest_point_geom)::numeric(10,7),st_y(cp.closest_point_geom)::numeric(10,7)) as closest_point_id
             , cp.closest_point_geom
             , case when cp.closest_point_geom = ANY(eda.edge_dump_array) then false else true end as new_point
          from closest_point cp, edge_dump_array eda;
--    nodes_array := nodes_array || ARRAY[access.vertex_id, access.closest_point_id];
    execute format('insert into pgnetworks_staging.vertex_2_edge (vertex_id, closest_point_id, closest_point_geom, edge_id, new_point) values ($1, $2, $3, $4, $5)')
    using access.vertex_id, access.closest_point_id, access.closest_point_geom, access.edge_id, access.new_point; 
    execute format('insert into pgnetworks_staging.segments (edge_id, node_1, node_2, geom) values ($1, $2, $3, $4)')
    using -1, access.vertex_id, access.closest_point_id, st_makeline(vertex_geom, access.closest_point_geom); 
    end loop;
    -- close batch processing
--    execute format('insert into pgnetworks_staging.nodes (node_id) select * from unnest($1)') 
--    using nodes_array; 
    execute format('insert into pgnetworks_staging.nodes (node_id) values ($1), ($2)') 
    using access.vertex_id, access.closest_point_id; 
    end_time := clock_timestamp();
--    execute format('insert into pgnetworks_staging.log (log_level, run_id, start_date, end_date, work_step, lower_bound, upper_bound, chunk_size, item_count, message) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)')
--    using 'INFO', run_id, start_time, end_time, work_step, lower_bound, upper_bound, chunk_size, item_count, ('{"idx":2}')::jsonb;  
end 
$procedure$;

create or replace function pgnetworks_staging.call_join_vertex_2_edge(lower_bound bigint, upper_bound bigint)
returns int
language plpgsql
as $function$
declare
    item_count int;
begin
    call pgnetworks_staging.join_vertex_2_edge(lower_bound, upper_bound, item_count);
    return item_count;
end;
$function$;


-- name: drop_procedure_join_vertex_2_edge#
drop function pgnetworks_staging.call_join_vertex_2_edge(bigint, bigint);
drop procedure pgnetworks_staging.join_vertex_2_edge(in bigint, bigint, out int);