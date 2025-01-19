drop table osm.road_network_segmentized;
create table osm.road_network_segmentized (
    id bigint,
    path int,
    geom geometry(linestring,4326)
)
;
truncate table osm.road_network_segmentized;
with edge_dump as (
    select id, (dump).path[1] as path_idx, st_astext(st_makeline(lag((dump).geom, 1, null) over (partition by d.id order by d.id, (dump).path), (dump).geom)) as geom
      from (select id, st_dumppoints(geom) as dump from osm.road_network /*limit 10*/) d
    )
    insert into osm.road_network_segmentized 
    select id 
         , path_idx -1 as path_idx
         , geom
      from edge_dump
     where geom is not NULL
;
create index road_network_segmentized_geom_idx on osm.road_network_segmentized using gist (geom);