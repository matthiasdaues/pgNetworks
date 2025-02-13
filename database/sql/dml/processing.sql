-- this file contains the methods
-- which create the graph assets
-- from the imported data

-- name: find_bounds_in_road_network_table
with ordered_rows as (
    select id
         , row_number() over (order by id asc) as rn
      from osm.road_network 
    )
,   ordered_bounds as (
    select id
    from ordered_rows 
    where mod((rn-1),:chunk_size) = 0
    union 
    select id
    from osm.road_network
    where id = (select max(id) from osm.road_network)
    )
select * from ordered_bounds order by id asc 
;


-- name: find_bounds_in_poi_table
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
call pgnetworks_staging.join_vertex_2_edge(%s, %s, %s, %s);


-- name: find_bounds_in_vertex_2_edge
-- DONE: Muss die Bounds über die distinkten edge_id's erzeugen, um Dopplungen beim Prozessieren zu vermeiden.
with edge_ids as (
    select distinct(edge_id)
      from pgnetworks_staging.vertex_2_edge
     order by edge_id
    )
,   ordered_rows as (
    select edge_id as id
         , row_number() over (order by edge_id asc) as rn
      from edge_ids
     order by id
    )
,   ordered_bounds as (
    select id
    from ordered_rows 
    where mod((rn-1),:chunk_size) = 0
    order by id asc
    )
select * from ordered_bounds
 union
select max(id) from ordered_rows
 order by id asc
;


-- name: process_junctions_and_edges
call pgnetworks_staging.process_junctions_and_edges(%s, %s, %s, %s);