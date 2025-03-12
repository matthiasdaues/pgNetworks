-- this procedure creates the selector grid for the edge processing step.
-- it calculates a grid of cells of different size but with a roughly
-- evenly balanced population of elements within their extent.

-- name: create_procedure_count_node_degree#
create or replace procedure pgnetworks_staging.count_node_degree(in selector_grid_cell text, out item_count int)
language plpgsql 
as $procedure$

begin

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
    insert into pgnetworks_staging.nodes (id, degree)
    select id
        , count(*) as degree
    from (
        select node_1 as id from refined_selection
        union all 
        select node_2 as id from refined_selection
        ) as all_ids
    group by id
    order by id
    ;

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
drop function call_count_node_degree;
drop procedure count_node_degree;

