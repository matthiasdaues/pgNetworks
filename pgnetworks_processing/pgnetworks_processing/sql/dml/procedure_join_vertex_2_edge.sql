-- this procedure processes vertices and
-- creates the closest points on the closest edge

-- name: create_procedure_join_vertex_2_edge#
create or replace procedure pgnetworks_staging.join_vertex_2_edge(
    in lower_bound bigint,
    in upper_bound bigint,
    out item_count int
)
language plpgsql
as $procedure$
begin

    /*
      1. gather all vertex_ids in range
      2. convert each id to geometry once (vt cte)
      3. for each vertex, find all edges within 5000m (edge_candidates)
      4. pick the single closest edge per vertex (closest_edge)
      5. compute the closest point on that edge (closest_point)
      6. see if that closest point is new or already in the edge geometry (edge_dump_array + all_data)
      7. insert set into vertex_2_edge, then insert set into segments
    */

    with vt as (
        select location_id as vertex_id
             , st_setsrid(public.ghh_decode_id_to_wkt(location_id)::geometry, 4326) as vertex_geom
          from pgnetworks_staging.terminals
          where location_id >= lower_bound
            and location_id <  upper_bound
        )
    ,   buffer as (
        select vertex_id
             , vertex_geom
             , st_buffer(vertex_geom::geography, 150)::geometry as buffer 
          from vt
        )
    ,   closest_edge as (
        select distinct on (vertex_id)
               b.vertex_id
             , r.id as edge_id
             , r.geom as edge_geom
             , row_number() over (partition by vertex_id order by vertex_geom <-> r.geom)
          from pgnetworks_staging.road_network r
             , buffer b
         where r.geom && b.buffer
        )
    ,   closest_point as (
        select ce.vertex_id
             , ce.edge_id
             , st_reduceprecision(
                st_closestpoint(ce.edge_geom, vt.vertex_geom), 0.0000001
               )::geometry(point,4326) as closest_point_geom
          from closest_edge ce
          join vt on ce.vertex_id = vt.vertex_id
        )
    ,   edge_dump_array as (
        select edge_id
             , array_agg(dump) as edge_dump_array
          from (
            select edge_id
                 , st_reduceprecision((st_dumppoints(edge_geom)).geom, 0.0000001) as dump 
              from closest_edge 
             where row_number = 1) as subquery
         group by edge_id
        )
    ,   all_data as (
        select cp.vertex_id
             , cp.edge_id
             , public.ghh_encode_xy_to_id(
                st_x(cp.closest_point_geom)::numeric(10,7),
                st_y(cp.closest_point_geom)::numeric(10,7)
               ) as closest_point_id
             , cp.closest_point_geom
             , case 
                when cp.closest_point_geom = any(eda.edge_dump_array) then false
                else true
               end as new_point
          from closest_point cp
          join edge_dump_array eda
            on cp.edge_id = eda.edge_id
        )
    insert into pgnetworks_staging.vertex_2_edge
    (vertex_id, closest_point_id, closest_point_geom, edge_id, new_point)
    select vertex_id
         , closest_point_id
         , closest_point_geom
         , edge_id
         , new_point
      from all_data;

    -- Record how many rows were inserted
    get diagnostics item_count = row_count;

    -- 2) insert into segments in one go
    insert into pgnetworks_staging.segments
    (edge_id, edge_type, node_1, node_2, geom)
    select -1
         , 'junction'::pgnetworks_staging.edge_type
         , a.vertex_id
         , a.closest_point_id
         , st_reduceprecision(st_makeline(vt.vertex_geom, a.closest_point_geom),0000001)
      from all_data a
      join vt 
        on a.vertex_id = vt.vertex_id;

END;
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