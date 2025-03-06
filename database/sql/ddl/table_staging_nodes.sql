-- create or drop the staging table
-- containing all node_ids.

-- name: create_table_nodes#
create table pgnetworks_staging.nodes (
    node_id bigint
);

-- name: create_index_nodes_node_id_idx#
create index nodes_node_id_idx on pgnetworks_staging.nodes using btree (node_id);

-- name: drop_table_nodes#
drop table pgnetworks_staging.nodes;