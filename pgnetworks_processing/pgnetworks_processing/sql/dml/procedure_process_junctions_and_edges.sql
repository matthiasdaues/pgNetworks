-- this procedure processes the input edges / linestrings:
-- snaps closest points to linestrings, segmentizes linestrings

-- name: create_procedure_process_junctions_and_edges#
create or replace procedure pgnetworks_staging.process_junctions_and_edges(
    in  lower_bound bigint,
    in  upper_bound bigint,
    out item_count  int
)
language plpgsql
as $procedure$
declare

begin
    /* 
     * 1) Select statement to get the relevant data for splitting the road network
     */
    -- get the source edge ids that will be processed
    with source_edge_ids as (
        select distinct(s.source_edge_id)
          from pgnetworks_staging.segments s
         where source_edge_id >= lower_bound
           and source_edge_id <  upper_bound  
    )     
        ,   edges as (
        select s.source_edge_id
             , rn.geom as orig_geom
             , coalesce(rn.properties->>'layer', 'n') as orig_layer
          from source_edge_ids s
          left join pgnetworks_staging.road_network rn on rn.id = s.source_edge_id
        )
    -- get the junctions for the edges
    ,   junctions as (
        select s.source_edge_id
             , st_makeline(
                    st_pointn(seg.geom, 1),
                    st_translate(
                        st_pointn(seg.geom, -1),
                        sin(
                            st_azimuth(
                                st_pointn(seg.geom, 1),
                                st_pointn(seg.geom, -1)
                            )
                        ) * (st_length(seg.geom)*0.01), 
                        cos(
                            st_azimuth(
                                st_pointn(seg.geom, 1),
                                st_pointn(seg.geom, -1)
                            )
                        ) * (st_length(seg.geom)*0.01)
                    )
                ) as blade
          from source_edge_ids s
          left join pgnetworks_staging.segments seg 
            on s.source_edge_id = seg.source_edge_id
           and seg.edge_type = 'network_to_vertex'
        )
    -- get all neighbours for the edges
    ,   neighbours as (
        select e.source_edge_id
             , rn.geom as blade
          from edges e
          left join pgnetworks_staging.road_network rn 
            on e.orig_geom && rn.geom
           and e.source_edge_id != rn.id
           and e.orig_layer = coalesce(rn.properties->>'layer', 'n')           
           and st_dimension(ST_Intersection(e.orig_geom, rn.geom)) = 0 
        )
    -- union select the junctions and neighbours 
    ,   combined as (
        select j.source_edge_id
             , j.blade
          from junctions j
        union all
        select n.source_edge_id
             , n.blade
          from neighbours n
        )
    -- st_union the junctions and neighbours to blade geometries for each edge
    ,   grouped as (
        select e.source_edge_id
             , e.orig_geom
             , st_union(c.blade) as blade
          from edges e
          left join combined c
            on e.source_edge_id = c.source_edge_id
         group by e.source_edge_id, e.orig_geom
        )
    -- split the edges by the blade geometry
    ,   split as (
        select source_edge_id
             , (st_dump(st_split(orig_geom, blade))).geom as geom
          from grouped
        )
    ,   segment_center as (
        select s.source_edge_id
             , coalesce(st_reducePrecision(st_lineInterpolatePoint(s.geom, 0.5), 0.0000001),st_pointn(s.geom, 1)) as segment_center
             , st_reduceprecision(s.geom, 0.0000001) as geom
             , case 
                when s.geom = g.orig_geom 
                then 'unsegmented' 
                else 'network_near'
               end as edge_type
          from split s
          left join grouped g on s.source_edge_id = g.source_edge_id
         where geometryType(s.geom) = 'LINESTRING'
        )
    insert into pgnetworks_staging.segments (
        edge_id,
        source_edge_id,
        edge_type,
        node_1,
        node_2,
        geom
    )
    select ghh_encode_xy_to_id(
                st_x(segment_center)::numeric(10,7), 
                st_y(segment_center)::numeric(10,7)
              ) as edge_id
         , source_edge_id
         , 'network_near' 
         , ghh_encode_xy_to_id(
            st_x(st_pointn(geom, 1))::numeric(10,7),
            st_y(st_pointn(geom, 1))::numeric(10,7)
           ) as node_1
         , ghh_encode_xy_to_id(
            st_x(st_pointn(geom, -1))::numeric(10,7),
            st_y(st_pointn(geom, -1))::numeric(10,7)
           ) as node_2
         , geom
      from segment_center
     where not st_isEmpty(geom);

    get diagnostics item_count = row_count;

end
$procedure$;

create or replace function pgnetworks_staging.call_process_junctions_and_edges(lower_bound bigint, upper_bound bigint)
returns int
language plpgsql
as $function$
declare
    item_count int;
begin
    call pgnetworks_staging.process_junctions_and_edges(lower_bound, upper_bound, item_count);
    return item_count;
end;
$function$;


-- name: drop_procedure_process_junctions_and_edges#
drop function pgnetworks_staging.call_process_junctions_and_edges(bigint, bigint);
drop procedure pgnetworks_staging.process_junctions_and_edges(in bigint, bigint, out int);