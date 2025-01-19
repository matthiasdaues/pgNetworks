do $$
declare
    -- process variables
    lower_bound bigint := 1;
    upper_bound bigint := 100001;
    start_time timestamptz;
    end_time timestamptz;
    duration interval;
    -- extraction variables
    edge_data_array edge_processing[];
    edge_data edge_processing;
    -- transformation variables
    snap_tolerance float;
    junctioned_edge geometry;
    -- validation variables
    round_count int;
    -- loading variables
    segments_array segments_processing[];
    segment segments_processing;
begin
    -- set start time
    start_time := clock_timestamp();
    raise notice 'starting process at %', start_time;
    -- begin batch processing
    -- collect the edge data into an array specified by lower and upper bound
    with edge_ids as (
        -- create an ordered array that corresponds 
        -- to the btree index on the edge_id field
        select array_agg(distinct edge_id order by edge_id asc) as edge_id_array
          from pgnetworks_staging.vertex_2_edge
         where id between lower_bound and upper_bound
    )
    select into edge_data_array
           array(
                select row(
                           -- this row is defined as the custom data type "edge_processing"
                           -- which allows aggregating multiple datatypes into a heterogenous array
                           v2e.edge_id, 
                           rn.geom, 
                           array_agg(distinct v2e.closest_point_id),
                           count(*) filter (where new_point),
                           st_union(v2e.closest_point_geom)
                       )::edge_processing
                  from pgnetworks_staging.vertex_2_edge v2e
                  left join osm.road_network rn on v2e.edge_id = rn.id
                 where v2e.edge_id = any(array(select edge_id_array from edge_ids))
                 group by v2e.edge_id, rn.geom
            );
    -- loop through the edge data array
    foreach edge_data in array edge_data_array
    loop
        --raise notice '%', edge_data.edge_id;
        snap_tolerance := 0.1;
        round_count := 0;
        -- loop through varying tolerance values
        -- when snapping the junctions to the edge line.
        -- equality of the count of the points in the new line
        -- with the sum of the point count of the old line and thenew points
        -- exits the loop.
        -- else an error is thrown.
        while round_count <= 20 loop
            begin
            junctioned_edge := st_snap(edge_data.edge_geom, edge_data.junction_geometries,snap_tolerance);
                if st_numpoints(junctioned_edge) = st_numpoints(edge_data.edge_geom) + edge_data.new_points_count
                then             
                --raise notice '%', round_count;
                exit;
                elsif round_count = 20
                then raise notice 'no value found';
                end if;
            end;
        snap_tolerance := snap_tolerance / 10;
        round_count := round_count + 1;
        end loop; 
--    execute format('insert into pgnetworks_staging.junctioned_edges (edge_id, edge_geom) values ($1, $2)')
--    using edge_data.edge_id, junctioned_edge; 
    -- Here comes Paul Ramsey's simple code:
    -- https://blog.cleverelephant.ca/2015/02/breaking-linestring-into-segments.html
    with line_segment_dump as (
    select edge_data.edge_id, st_astext(st_makeline(lag((pt).geom, 1, null) over (partition by edge_data.edge_id order by edge_data.edge_id, (pt).path), (pt).geom)) as geom
      from (select edge_data.edge_id, st_dumppoints(junctioned_edge) as pt) as dumps
    )
    select into segments_array (
           array(
                select row(
                       -- this row is defined as the custom data type "segments"
                       -- which allows aggregating multiple datatypes into a heterogenous array
                       edge_id
                     , ghh_encode(st_x(st_pointn(geom,1))::numeric(10,7),st_y(st_pointn(geom,1))::numeric(10,7)) 
                     , ghh_encode(st_x(st_pointn(geom,-1))::numeric(10,7),st_y(st_pointn(geom,-1))::numeric(10,7))
                     , geom
                       )::segments_processing
                  from line_segment_dump where geom is not null
            )
    );
    foreach segment in array segments_array 
        loop
            execute format('insert into pgnetworks_staging.segments (edge_id, node_1, node_2, geom) values ($1, $2, $3, $4)')
            using segment.edge_id, segment.node_1, segment.node_2, segment.geom;
        end loop;
--    raise notice '%', segments_array;        
    end loop;
    -- close batch processing    
    end_time := clock_timestamp();
    raise notice 'ending process at %', end_time;
    duration := end_time - start_time;
    raise notice 'duration: %', duration;
end
$$;


--------------------------------------------------------------------------------------------------
-- stupid example
 
 with edge_matter as (
    select array_agg(distinct v2e.closest_point_id) as id_array
         , st_union(st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326)) as closest_point_geom
         , rn.geom
         , v2e.edge_id
      from pgnetworks_staging.vertex_2_edge v2e
      left join osm.road_network rn on v2e.edge_id = rn.id
     where v2e.edge_id = 14980120
       and rn.id = 14980120
     group by v2e.edge_id, rn.geom
 )
 ,  dumped_edge as (
    select 
         , (st_dumppoints(rn.geom)).geom as dumped_edge
      from osm.road_network rn 
     where rn.id = 14980120
 )
 --,  snapped as (
    select st_union(de.dumped_edge,st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326))
      from pgnetworks_staging.vertex_2_edge v2e
      left join osm.road_network rn on v2e.edge_id = rn.id
     where v2e.edge_id = 14980120
       and rn.id = 14980120
     group by v2e.edge_id, rn.geom
 )
 ;
 
 
 
 ---------------------------------------------------------------------------------------------------------------
 -- demo example
 with dumped_edge as (
    select rn.id
         , (st_dumppoints(rn.geom)).geom as dumped_edge
      from osm.road_network rn 
     where rn.id = 508330818
)
,   unioned_edge as (
    select id
         , st_union(dumped_edge) as unioned_edge
      from dumped_edge
     group by id
)
,   snap as (
    select v2e.edge_id
         , (st_dumppoints(st_snap(rn.geom,st_union(st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326)),0.0000001))).geom as dumped_snap
      from pgnetworks_staging.vertex_2_edge v2e
      left join osm.road_network rn on v2e.edge_id = rn.id
     where v2e.edge_id = 508330818
       and rn.id = 508330818
     group by v2e.edge_id, rn.geom
)
,   unioned_snap as (
    select edge_id
         , st_union(dumped_snap) as unioned_snap
      from snap
     group by edge_id
)
select v2e.edge_id
     , array_agg(distinct v2e.closest_point_id) 
     , st_union(st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326)) as closest_point_geom
     , ue.unioned_edge
     , us.unioned_snap
     , rn.geom
     , st_snap(rn.geom,st_union(st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326)),0.0000000000) as snapped 
     , count(distinct v2e.closest_point_id)
  from pgnetworks_staging.vertex_2_edge v2e
  left join osm.road_network rn on v2e.edge_id = rn.id
  left join unioned_edge ue on v2e.edge_id = ue.id
  left join unioned_snap us on v2e.edge_id = us.edge_id
 where v2e.edge_id = 508330818
   and rn.id = 508330818
 group by v2e.edge_id, rn.geom, ue.unioned_edge, us.unioned_snap
;


select v2e.edge_id
     , array_agg(distinct v2e.closest_point_id) 
     , st_union(st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326)) as closest_point_geom
     , rn.geom
     , st_numpoints(rn.geom) 
     , st_snap(rn.geom,st_union(st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326)),0.0000000000) as snapped 
     , st_numpoints(st_snap(rn.geom,st_union(st_setsrid(ghh_decode_to_wkt(v2e.closest_point_id)::geometry,4326)),0.1))
     , count(distinct v2e.closest_point_id)
  from pgnetworks_staging.vertex_2_edge v2e
  left join osm.road_network rn on v2e.edge_id = rn.id
 where v2e.edge_id = 14980120
   and rn.id = 14980120
 group by v2e.edge_id, rn.geom
;


select *
  from pgnetworks_staging.vertex_2_edge 
 where edge_id = 303002173;

 
 
