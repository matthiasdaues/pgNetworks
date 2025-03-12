-- New script in postgres@datenschoenheit.
-- Date: 4 Mar 2024
-- Time: 18:14:04


-- create schema pgnetworks;
-- create schema pgnetworks_staging;

drop table pgnetworks_staging.terminal_connection;
create table pgnetworks_staging.terminal_connection (
    id                  bigserial
,   terminal_id         bigint
,   road_id             bigint
,   closest_point_geom  geometry(point,4326)
,   closest_point_id    bigint
,   closest_point_type  text
,   point_2_road_id     bigint
,   point_2_road_geom   geometry(linestring,4326)
,   point_2_road_type   text
,   point_2_road_cost   numeric(10,2)
    )