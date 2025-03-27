-- this procedure processes vertices and
-- creates the closest points on the closest edge

-- name: create_procedure_join_vertex_2_edge#
create or replace procedure pgnetworks_staging.join_vertex_2_edge(in lower_bound bigint, upper_bound bigint, out item_count int)
language plpgsql
as $procedure$
--do $$
begin

    -- simple statement to find the nearest neighbour edge for each vertex
    with vt as (
        select location_id as vertex_id
            , geom as vertex_geom
        from pgnetworks_staging.terminals
        where location_id >= 2595910006465660600
        and location_id <  2595977728678422864
        )
    ,   buffer as (
        select vertex_id
            , vertex_geom
            , st_buffer(vertex_geom::geography, 150)::geometry as buffer 
        from vt
        )
    ,   closest_edge_candidates as (
        select distinct on (vertex_id)
            b.vertex_id
            , r.id as edge_id
            , r.geom as edge_geom
            , vertex_geom
            , row_number() over (partition by vertex_id order by vertex_geom <-> r.geom) as row_num
        from pgnetworks_staging.road_network r
            , buffer b
        where r.geom && b.buffer
        )
    ,   closest_edge as (
        select vertex_id
            , edge_id
            , st_linelocatepoint(edge_geom, vertex_geom) as fraction
        from closest_edge_candidates
        where row_num = 1
        )
    insert into pgnetworks_staging.vertex_2_edge
    (vertex_id, edge_id, fraction)
    select vertex_id
        , edge_id
        , fraction
    from closest_edge
    ;

    -- get the  number of processed points
    get diagnostics item_count = row_count;
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