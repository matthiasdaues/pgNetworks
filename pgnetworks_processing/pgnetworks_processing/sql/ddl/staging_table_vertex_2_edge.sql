-- create or drop the staging table containing 
-- the joint data for vertex and closest edge

-- name: create_table_vertex_2_edge#
create table pgnetworks_staging.vertex_2_edge (
    vertex_id bigint,
    edge_id bigint,
    fraction float
);

-- name: create_index_vertex_2_edge_edge_id_idx#
create index vertex_2_edge_edge_id_idx on pgnetworks_staging.vertex_2_edge using btree (edge_id);

-- name: drop_table_vertex_2_edge#
drop table pgnetworks_staging.vertex_2_edge;