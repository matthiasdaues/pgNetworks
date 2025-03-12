-- this procedure creates the selector grid for the edge processing step.
-- it calculates a grid of cells of different size but with a roughly
-- evenly balanced population of elements within their extent.

-- name: create_procedure_count_node_degree#
create or replace procedure pgnetworks_staging.count_node_degree(in selector_grid_cell text, out item_count int)
language plpgsql 
as $procedure$
declare 

    selector_grid_hash_id bigint;

begin

    selector_grid_hash_id := ghh_encode_xy_to_id(
                                st_x(st_centroid(selector_grid_cell::geometry(polygon,4326)))::numeric,
                                st_y(st_centroid(selector_grid_cell::geometry(polygon,4326)))::numeric
                             );

    with rough_selection as (
        select node_1
             , node_2
             , geom
          from pgnetworks_staging.segments
         where geom && selector_grid_cell::geometry(polygon,4326)
        )
    ,   refined_selection as (
        select node_1
             , node_2
             , geom
          from rough_selection
         where st_intersects(st_pointn(geom,1),selector_grid_cell::geometry(polygon,4326))
         order by geom
        )
    ,   all_nodes_counted as (
            select node_id
                 , count(*) as degree
              from (
                    select node_1 as node_id from refined_selection
                    union all 
                    select node_2 as node_id from refined_selection
                   ) as all_ids
             group by node_id
             order by node_id
        )
    insert into pgnetworks_staging.nodes (node_id, degree, selector_grid_hash_id)
    select node_id
         , degree
         , selector_grid_hash_id 
      from all_nodes_counted
     where degree = 2
    ;

    with rough_selection as (
        select node_1
             , node_2
             , geom
          from pgnetworks_staging.segments
         where geom && selector_grid_cell::geometry(polygon,4326)
        )
    ,   refined_selection as (
        select node_1
             , node_2
             , geom
          from rough_selection
         where st_intersects(st_pointn(geom,1),selector_grid_cell::geometry(polygon,4326))
         order by geom
        )
    select into item_count count(*) from refined_selection;

end
$procedure$;


create or replace function pgnetworks_staging.call_count_node_degree(selector_grid_cell text)
returns int
language plpgsql
as $function$
declare
    item_count int;
begin
    call pgnetworks_staging.count_node_degree(selector_grid_cell, item_count);
    return item_count;
end;
$function$;

-- name: drop_procedure_count_node_degree#
drop function pgnetworks_staging.call_count_node_degree(text);
drop procedure pgnetworks_staging.count_node_degree(in text, out int);

