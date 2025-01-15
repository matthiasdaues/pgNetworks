-- create or drop the staging table containing 
-- the joint data for vertex and closest edge

-- name: create_table_vertex_2_edge$
create table pgnetworks_staging.vertex_2_edge (
    vertex_id bigint,
    closest_point_id bigint,
    edge_id bigint
);

-- name: drop_table_vertex_2_edge$
drop table pgnetworks_staging.vertex_2_edge;