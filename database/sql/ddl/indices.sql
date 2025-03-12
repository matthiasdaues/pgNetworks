-- name: create_base_data_indices#
create index terminals_location_id_idx on pgnetworks_staging.terminals using btree (location_id);
create index terminals_geom_idx on pgnetworks_staging.terminals using gist (geom);
create index road_network_id_idx on pgnetworks_staging.road_network using btree (id);
create index road_network_properties_idx on pgnetworks_staging.road_network using gin (properties jsonb_path_ops);
