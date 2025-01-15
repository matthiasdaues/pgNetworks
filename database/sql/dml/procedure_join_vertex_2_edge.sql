-- this procedure processes vertices and
-- creates the closest points on the closest edge

-- name: create_procedure_join_vertex_2_edge$
create or replace procedure pgnetworks_staging.join_vertex_2_edge(lower_bound bigint, upper_bound bigint)
language plpgsql
as $procedure$
--do $$
declare
    -- process variables
    start_time timestamptz;
    end_time timestamptz;
    duration interval;
    vertex_id_array bigint[];
    vertex_id bigint;  
--    lower_bound bigint := 2595910006465660600;
--    upper_bound bigint := 2595913045157100801;--2595912533134594922 --(100);--2595913045157100801 --(1000);--2595940121573209691 --(10000);-- 2595959187942176414 --(100000);    
    vertex_geom geometry(point,4326);
    buffer_distance int;
    buffer_geom geometry(polygon,4326);
    closest record;
    -- result variables
    access record;
begin
    truncate table pgnetworks_staging.vertex_2_edge;
    -- set start time
    start_time := clock_timestamp();
    raise notice 'starting process at %', start_time;
    -- begin batch processing
    -- collect the id-array specified by lower and upper bound
    select into vertex_id_array
           array_agg(id)
      from _02_kubus.vertices_addresses
     where id between lower_bound and upper_bound;
    -- loop through the id array
    foreach vertex_id in array vertex_id_array
    loop
        -- create vertex_geom
        vertex_geom := st_setsrid(ghh_decode_to_wkt(vertex_id)::geometry, 4326);
        -- find the closest edge by looping through increasing buffer distances
        -- to accomodate for vertices further away from the nearest edge
        buffer_distance := 100;
        loop 
            begin       
            buffer_geom := st_buffer(vertex_geom::geography, buffer_distance)::geometry;
            select into closest
                   r.id as edge_id
                 , r.geom as edge_geom
              from osm.road_network r
             where buffer_geom && r.geom
             order by vertex_geom <-> r.geom
             limit 1;
            -- assign edge_id und edge_geom to variable
            if 
                closest.edge_id is not null then exit;
            end if;
            buffer_distance := buffer_distance * 5;
            end;
        end loop;
        -- calculate the closest point id
        with closest_point as (
            select st_closestpoint(closest.edge_geom,vertex_geom) as closest_point_geom
        )
        select into access
               vertex_id
             , closest.edge_id 
             , ghh_encode(st_x(cp.closest_point_geom)::numeric(10,7),st_y(cp.closest_point_geom)::numeric(10,7)) as closest_point_id
          from closest_point cp;           
    execute format('insert into pgnetworks_staging.vertex_2_edge (vertex_id, closest_point_id, edge_id) values ($1, $2, $3)')
    using access.vertex_id, access.closest_point_id, access.edge_id; 
    end loop;
    -- close batch processing    
    end_time := clock_timestamp();
    raise notice 'ending process at %', end_time;
    duration := end_time - start_time;
    raise notice 'duration: %', duration;
end 
--$$;
$procedure$;


-- name: drop_procedure_join_vertex_2_edge$
drop procedure pgnetworks_staging.join_vertex_2_edge(bigint, bigint);