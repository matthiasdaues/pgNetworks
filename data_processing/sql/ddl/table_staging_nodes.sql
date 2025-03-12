-- create or drop the staging table containing
-- all node_ids and their frequency.

-- name: create_table_nodes#
create table pgnetworks_staging.nodes (
    node_id bigint,
    degree int,
    selector_grid_hash_id bigint
);

-- name: create_index_nodes_node_id_idx#
create index nodes_node_id_idx on pgnetworks_staging.nodes using btree (node_id);
-- name: create_index_nodes_selector_grid_hash_id_idx#
create index nodes_selector_grid_hash_id_idx on pgnetworks_staging.nodes using btree (selector_grid_hash_id);

-- name: drop_table_nodes#
drop table pgnetworks_staging.nodes;