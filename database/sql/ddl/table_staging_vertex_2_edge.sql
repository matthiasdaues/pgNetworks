-- create or drop the staging table containing 
-- the joint data for vertex and closest edge

-- name: create_table_vertex_2_edge$
create table pgnetworks_staging.vertex_2_edge (
    id bigserial primary key,
    vertex_id bigint not null,
    closest_point_id bigint not null,
    closest_point_geom geometry(point,4326),
    edge_id bigint not null,
    new_point boolean
);

-- name: drop_table_vertex_2_edge$
drop table pgnetworks_staging.vertex_2_edge;