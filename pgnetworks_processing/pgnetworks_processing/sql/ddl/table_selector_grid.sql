-- this table will contain the selector grid
-- for parallel processing partitioned into 
-- spatially disjoint workload parcels.

-- name: create_table_selector_grid#
create table pgnetworks_staging.selector_grid (
    id serial primary key,
    parent_id int default 0,
    population int,
    geom geometry(polygon, 4326),
    processed boolean default false
)
;

-- name: create_index_selector_grid_geom_idx#
create index selector_grid_geom_idx on pgnetworks_staging.selector_grid using gist (geom);
-- name: create_index_selector_grid_population_idx#
create index selector_grid_population on pgnetworks_staging.selector_grid using btree (population);

-- name: drop_table_selector_grid#
drop table pgnetworks_staging.selector_grid cascade;