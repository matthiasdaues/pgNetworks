-- create or drop the staging table containing 
-- the edges with the snapped junction points
-- name: create_table_junctioned_edges$
create table pgnetworks_staging.junctioned_edges (
    id bigserial primary key,
    edge_id bigint not null,
    edge_geom geometry(linestring, 4326);
);

-- name: drop_table_junctioned_edges$
drop table pgnetworks_staging.junctioned_edges;