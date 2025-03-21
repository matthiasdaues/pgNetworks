-- this file contains the methods
-- which create the graph assets
-- from the imported data

-- name: find_bounds_in_road_network_table
with ordered_rows as (
    select id
         , row_number() over (order by id asc) as rn
      from pgnetworks_staging.road_network 
    )
,   ordered_bounds as (
    select id
    from ordered_rows 
    where mod((rn-1),:chunk_size) = 0
    union 
    select id
    from pgnetworks_staging.road_network
    where id = (select max(id) from pgnetworks_staging.road_network)
    )
select * from ordered_bounds order by id asc 
;


-- name: find_bounds_in_poi_table
with ordered_rows as (
    select location_id as id
         , row_number() over (order by location_id asc) as rn
      from pgnetworks_staging.terminals 
    )
,   ordered_bounds as (
    select id
    from ordered_rows 
    where mod((rn-1),:chunk_size) = 0
    union 
    select location_id as id
    from pgnetworks_staging.terminals
    where location_id = (select max(location_id) from pgnetworks_staging.terminals)
    )
select * from ordered_bounds order by id asc 
;


 -- name: test
 select :lower_bound as lower_bound
      , :upper_bound as upper_bound 
      , count(*) as count
   from pgnetworks_staging.terminals
  where location_id >= :lower_bound
    and location_id < :upper_bound
;


-- name: join_vertex_2_edge$
with item_count as (
    select call_join_vertex_2_edge as item_count 
      from pgnetworks_staging.call_join_vertex_2_edge(%s, %s)
    )
select item_count 
  from item_count 
;


-- name: find_bounds_in_segment_junctions
with edge_ids as (
    select distinct(source_edge_id)
      from pgnetworks_staging.segments
     order by source_edge_id
    )
,   ordered_rows as (
    select source_edge_id as id
         , row_number() over (order by source_edge_id asc) as rn
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


-- name: process_junctions_and_edges$
with item_count as (
    select call_process_junctions_and_edges as item_count 
      from pgnetworks_staging.call_process_junctions_and_edges(%s, %s)
    )
select item_count 
  from item_count 
;


-- name: calculate_selector_grid#
truncate table pgnetworks_staging.selector_grid;
call pgnetworks_staging.calculate_selector_grid(%s)
;


-- name: select_selector_grid
select st_astext(geom) as geom from pgnetworks_staging.selector_grid order by geom
;


-- name: segmentize_road_network$
with item_count as (
    select call_segmentize_road_network as item_count 
      from pgnetworks_staging.call_segmentize_road_network(%s)
    )
select item_count 
  from item_count 
;


-- name: find_bounds_in_segments
with node_1_id as (
    select distinct(node_1)
      from pgnetworks_staging.segments
     order by node_1
    )
,   ordered_rows as (
    select node_1 as id
         , row_number() over (order by node_1 asc) as rn
      from node_1_id
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


-- name: copy_segments_to_edges
with item_count as (
    select call_copy_segments_to_edges as item_count 
      from pgnetworks_staging.call_copy_segments_to_edges(%s, %s)
    )
select item_count 
  from item_count 
;