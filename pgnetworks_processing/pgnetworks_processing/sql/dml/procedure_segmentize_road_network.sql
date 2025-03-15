-- this procedure processes the linestrings still
-- unsegmentized after snapping the vertices to the network

-- name: create_procedure_segmentize_road_network#
create or replace procedure pgnetworks_staging.segmentize_road_network(in selector_grid_cell text, out item_count int)
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
    with rough_selection as (
        select id
             , properties
             , geom
          from pgnetworks_staging.road_network 
         where geom && selector_grid_cell::geometry(polygon,4326)
           and segmentized is FALSE 
        )
    ,   refined_selection as (
        select id::int
             , coalesce(cast((properties ->> 'layer') as text),'n') as edge_layer
             , geom
          from rough_selection
         where st_intersects(geom, selector_grid_cell::geometry(polygon,4326))
         order by geom
        )
    /*
     * 2) for each edge, collect the geometry of all neighbors
     *    that share the same layer and intersect it.
     *    - if an edge has no neighbors, 'st_collect(n.geom)' ends
     *      up null (or geometry collection empty).
     *    - we then split the edge geometry by the neighbor geometry.
    */
    ,   splitted as (
        select e.id as edge_id
               -- st_dump() is used because st_split may return multiple pieces
             , (st_dump(
               case 
                when st_collect(n.geom) is null 
                 then e.geom 
                else st_split(e.geom, st_collect(n.geom)) 
               end
               )).geom as splitted_geom
          from selected_edges e
          left join pgnetworks_staging.road_network n 
            on st_intersects(e.geom, n.geom)
           and e.id    != n.id
           and e.layer = coalesce(n.properties->>'layer', 'n')           
           and st_dimension(ST_Intersection(e.geom, n.geom)) = 0 
         group by e.id, e.geom
        )
    /*
     *  3) insert all split results into the 'segments' table.
     *     - if the edge had neighbors, the geometry is the set of
     *       split pieces.
     *     - if no neighbors, the geometry is unchanged.
    */
    insert into pgnetworks_staging.segments
    (edge_id, edge_type, node_1, node_2, geom)
    select s.edge_id
         , 'far_net'::pgnetworks_staging.edge_type
         , ghh_encode_xy_to_id(
           st_x(st_pointn(s.splitted_geom, 1))::numeric, 
           st_y(st_pointn(s.splitted_geom, 1))::numeric
           )
         , ghh_encode_xy_to_id(
           st_x(st_pointn(s.splitted_geom, -1))::numeric, 
           st_y(st_pointn(s.splitted_geom, -1))::numeric
           )
         , s.splitted_geom
      from splitted s;
    /*
     *  4) mark the original edges as segmentized in a single batch.
    */
    --update pgnetworks_staging.road_network
    --   set segmentized = true
    -- where id in (select id from selected_edges);
    /*
     *  5) return the number of edges processed in this batch.
     *     (if you prefer total segments created, you'd do get diagnostics
     *     after the insert. here we show edges.)
    */
    get diagnostics item_count = row_count;

end;
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