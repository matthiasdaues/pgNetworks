-- this procedure processes the linestrings still
-- unsegmentized after snapping the vertices to the network

-- name: create_procedure_copy_segments_to_edges#
create or replace procedure pgnetworks_staging.copy_segments_to_edges(in lower_bound bigint, upper_bound bigint, out item_count int)
language plpgsql
as $procedure$
-- do $$
begin
    /*
     * 1) get the features contained within the selector cell.
     *    collect an initial result with index overlap and re-
     *    fine the selection with an intersects query of the 
     *    first point in the linestring and the selector cell.
    */
    with all_edges as (
            select ghh_encode_xy_to_id(
                st_x(st_lineInterpolatePoint(geom, 0.5))::numeric, 
                st_y(st_lineInterpolatePoint(geom, 0.5))::numeric
              ) as edge_id
            , edge_id as source_edge_id
            , edge_type
            , node_1
            , node_2
            , geom
            , row_number() over (partition by geom)
          from pgnetworks_staging.segments
        where node_1 >= lower_bound 
          and node_1 <  upper_bound
        )  
    insert into pgnetworks.edges 
    (edge_id, source_edge_id, edge_type, node_1, node_2, geom)
    select distinct on (edge_id) 
          edge_id, source_edge_id, edge_type, node_1, node_2, geom
      from all_edges
    where row_number = 1
    order by edge_id
    ;
    /*
     *  2) return the number of edges processed in this batch.
     *     (if you prefer total segments created, you'd do get diagnostics
     *     after the insert. here we show edges.)
    */
    get diagnostics item_count = row_count;

end;
$procedure$;
-- $$

create or replace function pgnetworks_staging.call_copy_segments_to_edges(lower_bound bigint, upper_bound bigint)
returns int
language plpgsql
as $function$
declare
    item_count int;
begin
    call pgnetworks_staging.copy_segments_to_edges(lower_bound, upper_bound, item_count);
    return item_count;
end;
$function$;


-- name: drop_procedure_copy_segments_to_edges#
drop function pgnetworks_staging.call_copy_segments_to_edges(bigint, bigint);
drop procedure pgnetworks_staging.copy_segments_to_edges(in bigint, bigint, out int);