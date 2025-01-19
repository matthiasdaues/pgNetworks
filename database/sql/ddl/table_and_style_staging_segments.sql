-- create or drop the staging table containing 
-- the segments from the segments
-- name: create_table_segments$
create table pgnetworks_staging.segments (
    edge_id bigint,
    node_1 bigint not null,
    node_2 bigint not null,
    geom geometry(linestring,4326)
);

-- name: drop_table_segments$
drop table pgnetworks_staging.segments;

-------------------------------------------------

-- create or drop a style mirroring the 
-- the segments table used in pre-processing
-- name: create_style_segments_processing$
create style segment_processing as (
    edge_id bigint,
    node_1 bigint,
    node_2 bigint,
    geom geometry(linestring,4326)
);

-- name: drop_style_segments_processing$
drop style segment_processing cascade;