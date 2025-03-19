-- create or drop the staging table containing 
-- the segments from the segments
-- name: create_table_segments#
create table pgnetworks_staging.segments (
    edge_id bigint,                            -- the hilbert hash of the centerpoint on the linestring
    source_edge_id bigint,                     -- the ID of the original linestring / junction target
    edge_type pgnetworks_staging.edge_type,    -- vertex_to_network, network, root_to_vertex
    node_1 bigint not null,                    -- filled with the "source" ID
    node_2 bigint not null,                    -- filled with the "target" ID
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
-- name: create_index_segments_source_edge_id_idx#
create index segments_source_edge_id_idx on pgnetworks_staging.segments using btree (source_edge_id);

-- name: drop_table_segments#
drop table pgnetworks_staging.segments;

-------------------------------------------------

-- create the enum data type to describe
-- the different kinds of segments / edges
-- name: create_type_edge_type#
create type pgnetworks_staging.edge_type as enum ('network_to_vertex', 'network_near', 'network_far', 'root_to_vertex', 'unsegmentized');

-- name: drop_type_edge_type#
drop type pgnetworks_staging.edge_type cascade;

-------------------------------------------------

-- create or drop a style mirroring the 
-- segments table used in pre-processing
-- name: create_type_segment_processing#
create type pgnetworks_staging.segment_processing as (
    edge_id bigint,
    source_edge_id bigint,
    edge_type pgnetworks_staging.edge_type,
    node_1 bigint,
    node_2 bigint,
    geom geometry(linestring,4326)
);

-- name: drop_type_segment_processing#
drop type pgnetworks_staging.segment_processing cascade;
