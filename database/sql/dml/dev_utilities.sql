-- name: cleanup_processing_tables#
truncate table pgnetworks_staging.segments;
truncate table pgnetworks_staging.junctioned_edges;
alter sequence pgnetworks_staging.junctioned_edges_id_seq restart with 1;
truncate table pgnetworks_staging.vertex_2_edge;
alter sequence pgnetworks_staging.vertex_2_edge_id_seq restart with 1;
drop index pgnetworks_staging.vertex_2_edge_edge_id_idx;