-- this file contains the methods
-- which create the graph assets
-- from the imported data

-- name: find_lower_and_upper_bounds
with ordered_rows as (
    select id
         , row_number() over (order by id asc) as rn
      from _02_kubus.vertices_addresses 
    )
,   ordered_bounds as (
    select id
    from ordered_rows 
    where mod((rn-1),:chunk_size) = 0
    union 
    select id
    from _02_kubus.vertices_addresses
    where id = (select max(id) from _02_kubus.vertices_addresses)
    )
select * from ordered_bounds order by id asc 
;

 -- name: test
 select :lower_bound as lower_bound
      , :upper_bound as upper_bound 
      , count(*) as count
   from _02_kubus.vertices_addresses
  where id >= :lower_bound
    and id < :upper_bound
;

-- name: join_vertex_2_edge
call pgnetworks_staging.join_vertex_2_edge(%s, %s);

