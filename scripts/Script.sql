select id from "_02_kubus".vertices_addresses order by id limit 100;


with id as (
    select 2595912532712795106 as id
         , st_setsrid(ghh_decode_to_wkt(2595912532712795106)::geometry, 4326) as geom
)
,   buffer as (
    select st_buffer(geom::geography, 100)::geometry as geom
      from id
)
select id.id as vertex_id
     , r.geom
     , id.geom
     , r.id as closest_edge_id
     , st_transform(st_closestpoint(st_transform(r.geom, 3034), st_transform(id.geom,3034)),4326) as touchpoint_1
     , st_closestpoint(r.geom, id.geom) as touchpoint_2
from 
    osm.road_network r
,   buffer b
,   id id
where 
    b.geom && r.geom
order by 
    id.geom <-> r.geom
limit 1
;

create table pgnetworks_staging.vertex_2_edge (
    vertex_id bigint,
    closest_point_id bigint,
    edge_id bigint
);

