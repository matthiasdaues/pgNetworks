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
    snap_tolerance float8 := 1.0000000000000001e-15;  -- initial tolerance
    round_count    int    := 0;
    edges_remaining int;
begin
    /* 
     * 0) we create a temp table holding the new edges data as well as some
     *    control data to govern the procedure.
     */
    create temporary table junctioned_edges (
        edge_id int,
        orig_geom geometry,
        orig_points_count int,
        union_junctions geometry,
        split_junctions geometry,
        required_points int,
        new_geom geometry,
        new_points_count int,
        snapped boolean generated always as (case when orig_points_count + required_points = new_points_count then TRUE else FALSE END) stored
        )
    ;
    /* 
     *    and fill the table with the data for this instance of the procedure.
     */
    with junction_data as (
        select v2e.edge_id
            , rn.geom as orig_geom
            , st_numpoints(rn.geom) as orig_points_count
            , st_collect(distinct(closest_point_geom)) filter (where v2e.new_point) as union_junctions
            , st_collect(distinct(closest_point_geom)) as split_junctions
            , count(distinct closest_point_geom) filter (where v2e.new_point) as required_points
        from pgnetworks_staging.vertex_2_edge v2e
        left join pgnetworks_staging.road_network rn on rn.id = v2e.edge_id
        where edge_id >= lower_bound
        and edge_id <  upper_bound
        group by v2e.edge_id, rn.geom
        )
    ,   neighbour_data as (
        select jd.edge_id
             , st_collect(jd.split_junctions, rn.geom) as split_junctions
          from junction_data jd
          left join pgnetworks_staging.road_network rn 
            on jd.orig_geom && rn.geom
        )
    insert into junctioned_edges 
    (edge_id, orig_geom, orig_points_count, union_junctions, split_junctions, required_points)
    select jd.edge_id
         , jd.orig_geom
         , jd.orig_points_count
         , jd.union_junctions
         , nd.split_junctions
         , jd.required_points
      from junction_data jd
      join neighbour_data nd on jd.edge_id = nd.edge_id
    ;
    select into item_count count(*) from junctioned_edges;
    /*
     * 1) we repeat up to 20 times:
     *    for all edges in [lower_bound, upper_bound) that are not fully snapped,
     *    gather their “junction points,” do a bulk st_snap, update road_network,
     *    and mark edges that are now fully snapped as snapped=true in vertex_2_edge.
     */
    while round_count <= 10
    loop
        /* 
         * a. bulk snap all unsnapped edges in a single shot:
         *    - we gather (for each edge) the union of its new_point "closest_point_geom".
         *    - we compare numpoints before/after snapping.
         *    - if it matches old_points + new_points_count => mark edge as snapped.
        */

        with edge_data as (
            select je.edge_id
                 , je.orig_geom
                 , je.union_junctions
              from junctioned_edges je
             where snapped = false
            )
        ,   snapped as (
            -- snap the geometry in bulk, generating the new geometry in one pass
            select edge_id
                 , orig_geom
                 , case
                    when union_junctions is NULL
                    then orig_geom
                    else st_snap(orig_geom, union_junctions, snap_tolerance) 
                   end as new_geom
              from edge_data
             )
        ,   count as (
            select edge_id
                 , st_numpoints(new_geom) as new_points_count
              from snapped
            )
        -- (1) update the "road_network" table with the newly snapped geometry
        update junctioned_edges je
           set new_geom = s.new_geom
             , new_points_count = c.new_points_count
          from snapped s
             , count c
         where je.edge_id = s.edge_id
           and je.edge_id = c.edge_id;

        /* 
         * b. count how many edges remain unsnapped in the requested range.
         *    if zero, we're done snapping.
         */
        select count(distinct edge_id)
          into edges_remaining
          from junctioned_edges
         where snapped = false;

        raise notice '% % %', round_count, edges_remaining, snap_tolerance;

        if edges_remaining = 0 then
            -- all edges have integrated their new points, so break out of the loop
            exit;
        end if;

        /*
         * c. if not done, reduce snap tolerance by factor 10 and repeat.
         */
        round_count := round_count + 1;
        snap_tolerance := snap_tolerance * 10.0;

        
    end loop;

    /*
     * 2) at this point, either all edges are snapped or we reached 20 iterations.
     *    if some remain unsnapped, we might log/throw a notice.
     */
    select count(distinct edge_id)
      into edges_remaining
      from junctioned_edges
     where snapped = false;

    if edges_remaining > 0 then
        with edge_id_array as (select array_agg(distinct(edge_id)) from junctioned_edges where snapped = FALSE)
        insert into pgnetworks_staging.log (log_level, start_date, work_step, message)
        select 'WARNING' as log_level
             , now() as start_date
             , 'process_junctions_and_edges' as work_step
             , jsonb_build_object(
                'message', 'some edges could not be snapped',
                'edges_remaining', edges_remaining,
                'edge_id', (select array_agg from edge_id_array))
    ;
        raise notice 'some edges could not be snapped after % rounds.', round_count;
    end if;
        
        raise notice 'edges snapped after % rounds with snap tolerance %.', round_count, snap_tolerance;

    /*
      3) now do a final st_split pass (in bulk) for all edges in [lower_bound, upper_bound).
         insert the resulting segments in a single shot. 
         we only need to split each edge by the union of all relevant “closest_point_geom” 
         (since they should now lie on the line).
    */
    with final_edges as (
        select edge_id
             , new_geom
               -- union of *all* junction points relevant to that edge 
             , split_junctions
          from junctioned_edges
        )
    ,   splitted as (
        select fe.edge_id
             , st_split(fe.new_geom, fe.split_junctions) as geom_collection
          from final_edges fe
        )
    ,   parted as (
        select edge_id
             , (st_dump(geom_collection)).geom as parted_geom
          from splitted
    )
    insert into pgnetworks_staging.segments (
        edge_id,
        edge_type,
        node_1,
        node_2,
        geom
    )
    select edge_id
         , 'near_net'  -- or your desired edge_type
         , ghh_encode_xy_to_id(
            st_x(st_pointn(parted_geom, 1))::numeric(10,7),
            st_y(st_pointn(parted_geom, 1))::numeric(10,7)
           ) as node_1
         , ghh_encode_xy_to_id(
            st_x(st_pointn(parted_geom, -1))::numeric(10,7),
            st_y(st_pointn(parted_geom, -1))::numeric(10,7)
           ) as node_2
         , parted_geom
      from parted
     where parted_geom is not null;

    /*
     * 4) (optional) mark the edges as fully segmentized or do further updates
     */
--   update pgnetworks_staging.road_network
--      set segmentized = TRUE
--     from junctioned_edges je
--    where id = je.edge_id 
--      and je.snapped is TRUE;

    /*
     * 5) remove temporary table
     */
    drop table junctioned_edges;
    
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