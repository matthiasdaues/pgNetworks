-- create or drop the staging table containing 
-- the segments from the segments
-- name: create_table_segments#
create table pgnetworks_staging.segments (
    edge_id bigint,
    edge_type pgnetworks_staging.edge_type,
    node_1 bigint not null,
    node_2 bigint not null,
    geom geometry(linestring,4326)
);

-- name: create_index_segments_geom_idx#
create index segments_geom_idx on pgnetworks_staging.segments using gist (geom);
-- name: create_index_segments_node_1_idx#
create index segments_node_1_idx on pgnetworks_staging.segments using btree (node_1);
-- name: create_index_segments_node_2_idx#
create index segments_node_2_idx on pgnetworks_staging.segments using btree (node_2);
-- name: create_index_segments_edge_id_idx#
create index segments_edge_id_idx on pgnetworks_staging.segments using btree (edge_id);
-- name: create_index_segments_edge_type_idx#
create index segments_edge_type_idx on pgnetworks_staging.segments using btree (edge_type);

-- name: drop_table_segments#
drop table pgnetworks_staging.segments;

-------------------------------------------------

-- create or drop a style mirroring the 
-- the segments table used in pre-processing
-- name: create_type_segment_processing#
create type pgnetworks_staging.edge_type as enum ('junction','near_net','far_net');
create type pgnetworks_staging.segment_processing as (
    edge_id bigint,
    edge_type pgnetworks_staging.edge_type,
    node_1 bigint,
    node_2 bigint,
    geom geometry(linestring,4326)
);


-- name: drop_type_segment_processing#
drop type pgnetworks_staging.segment_processing cascade;
drop type pgnetworks_staging.edge_type cascade;