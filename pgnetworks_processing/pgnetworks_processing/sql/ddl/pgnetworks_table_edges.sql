-- create or drop the table containing
-- the graph data.

-- name: create_table_edges# 
create table pgnetworks.edges (
    edge_id bigint primary key not NULL,                -- created as the hilbert hash of the centroid of the segment  
    source_edge_id bigint,
    edge_type text not NULL,
    node_1 bigint not NULL,
    node_2 bigint not NULL,
--    properties jsonb default '{}',
    length numeric(10,2) generated always as (st_length(geom::geography, TRUE)) stored,
--    weight numeric(10,2) default 1.0,
    geom geometry(linestring,4326) not NULL    
);
-- COMMENTS ON TABLE AND COLUMNS --------------------------
comment on table pgnetworks.edges
    is 'The table edges contains edges that constitute a graph of the OpenStreetMap road network.'
    ;
comment on column pgnetworks.edges.edge_id
    is 'The unique edge id is implemented as the hilbert hash of the midpoint on the linestring.'
    ;
comment on column pgnetworks.edges.source_edge_id
    is 'The source edge id is the id of the parent geometry in the input data set.'
    ;
comment on column pgnetworks.edges.edge_type
    is 'The type of edge. Values are: junction, near_net, far_net.'
    ;
comment on column pgnetworks.edges.node_1
    is 'The source_vertex_id is calculated from the lon-lat coordinates of the first point in the edges line string geometry, rounded to 7 decimals. The coordinates are converted into a hilbert curve hash, precision 31, base 4, and transformed into a big integer. The process is reversible and thus the id can be decoded into a coordinate pair with 1cm2 positional fidelity.'
    ;
comment on column pgnetworks.edges.node_2
    is 'The target_vertex_id is calculated from the lon-lat coordinates of the last point in the edges line string geometry, rounded to 7 decimals. The coordinates are converted into a hilbert curve hash, precision 31, base 4, and transformed into a big integer. The process is reversible and thus the id can be decoded into a coordinate pair with 1cm2 positional fidelity.'
    ;
-- comment on column pgnetworks.edges.properties
--     is 'The attributes of the source edge / road entity in the source system collected into a JSON object.'
--     ;
comment on column pgnetworks.edges.length
    is 'The geodesic length of the edge calculated from the geography type.'
    ;
-- comment on column pgnetworks.edges.weight
--     is 'The weight is the product of length and cost per unit, depending from attributes of edge.'
--     ;
comment on column pgnetworks.edges.geom
    is 'The geometry of the edge as geometry(linestring, 4326).'
    ;

-- name: create_index_edges_node_1_id_idx#
create index edges_node_1_id_idx on pgnetworks_staging.edges using btree (node_id);
-- name: create_index_edges_node_2_id_idx#
create index edges_node_2_id_idx on pgnetworks_staging.edges using btree (node_id);
-- name: create_index_source_edge_id_idx#
create index edges_source_edge_id_idx on pgnetworks_staging.edges using btree (node_id);
-- name: create_index_geom_idx#
create index edges_geom_idx on pgnetworks_staging.edges using gist (geometry);

-- name: drop_table_edges#
drop table pgnetworks_staging.edges;