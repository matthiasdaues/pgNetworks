-- create or drop a composite datatype that 
-- makes arraying multiple datatypes possible

-- name: create_type_edge_processing#
create type pgnetworks_staging.edge_processing as (
    edge_id integer,
    edge_geom geometry,
    new_points_count int,
    junction_geometries geometry
);

-- name: drop_type_edge_processing#
drop type pgnetworks_staging.edge_processing cascade;