-- create or drop a composite datatype that 
-- makes arraying multiple datatypes possible

-- name: create_type_edge_processing_2#
create type pgnetworks_staging.edge_processing_2 as (
    edge_id integer,
    edge_layer text,
    edge_geom geometry
);

-- name: drop_type_edge_processing_2#
drop type pgnetworks_staging.edge_processing_2 cascade;