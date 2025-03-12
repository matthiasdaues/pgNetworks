-- this procedure creates the selector grid for the edge processing step.
-- it calculates a grid of cells of different size but with a roughly
-- evenly balanced population of elements within their extent.

-- name: create_procedure_calculate_selector_grid#
create or replace procedure pgnetworks_staging.calculate_selector_grid(max_points integer)
language plpgsql
as $procedure$
declare   
    -- a record type to hold the parcel we're splitting
    current_parcel record;
    
    -- the bounding box geometry
    minx float8;
    miny float8;
    maxx float8;
    maxy float8;
    
    -- median coordinate
    median_value float8;
    
    -- child bounding boxes
    child_envelope_1 geometry(polygon, 4326);
    child_envelope_2 geometry(polygon, 4326);
    
    -- number of points in each child
    child_count_1 integer;
    child_count_2 integer;
    
begin
    /*
     * 1. create/clean the parcels table if needed
     *    (you could truncate or delete if you want to start fresh each time).
     */
    truncate table pgnetworks_staging.selector_grid restart identity;
    
    /*
     * 2. insert initial parcel: bounding box of all points, plus point count.
     */
    insert into pgnetworks_staging.selector_grid (parent_id, population, geom, processed)
    select 0
         , count(*) as population
         , st_envelope(st_extent(geom))::geometry(polygon, 4326) as geom
         , case when count(*) <= max_points then true else false end as processed
    from pgnetworks_staging.road_network
   where segmentized is FALSE
    ;
    /*
     * 3. iteratively process parcels that exceed max_points.
     */
    loop        
        -- retrieve one parcel that is not final and has more points than allowed.
        select id, parent_id, population, geom, processed
          into current_parcel
          from pgnetworks_staging.selector_grid 
         where processed = false
           and population > max_points
         limit 1;

        -- if no such parcel found, we are done.
        if not found then
            exit;
        end if;
        
        -- extract minx, miny, maxx, maxy of the current envelope
        select st_xmin(current_parcel.geom),
               st_ymin(current_parcel.geom),
               st_xmax(current_parcel.geom),
               st_ymax(current_parcel.geom)
          into minx, miny, maxx, maxy;
        
        -- decide whether to split vertically or horizontally
        if (maxx - minx) >= (maxy - miny) then
            /*
             * split vertically along the x dimension.
             * we'll find the median x of points that lie within the current envelope.
             */
            select percentile_cont(0.5) within group (order by st_x(st_pointn(rn.geom,1)))
              into median_value
              from pgnetworks_staging.road_network rn
             where st_within(rn.geom, current_parcel.geom)
               and rn.segmentized is FALSE;
             
            -- safety check (in case all points have the same x, etc.)
            if median_value is null or median_value <= minx or median_value >= maxx then
                -- if we can't properly split, mark current parcel final to avoid infinite loop
                update pgnetworks_staging.selector_grid
                   set processed = true
                 where id = current_parcel.id;
                continue;
            end if;
            
            -- child 1 bounding box: from minx..median_value
            child_envelope_1 := st_makeenvelope(minx, miny, median_value, maxy, 4326);
            -- child 2 bounding box: from median_value..maxx
            child_envelope_2 := st_makeenvelope(median_value, miny, maxx, maxy, 4326);
            
        else
            /*
             * split horizontally along the y dimension.
             * we'll find the median y of points that lie within the current envelope.
             */
            select percentile_cont(0.5) within group (order by st_y(st_pointn(rn.geom,1)))
              into median_value
              from pgnetworks_staging.road_network rn
             where st_within(rn.geom, current_parcel.geom)
               and rn.segmentized is FALSE;
             
            -- safety check
            if median_value is null or median_value <= miny or median_value >= maxy then
                update pgnetworks_staging.selector_grid
                   set processed = true
                 where id = current_parcel.id;
                continue;
            end if;
            
            -- child 1 bounding box: from miny..median_value
            child_envelope_1 := st_makeenvelope(minx, miny, maxx, median_value, 4326);
            -- child 2 bounding box: from median_value..maxy
            child_envelope_2 := st_makeenvelope(minx, median_value, maxx, maxy, 4326);
        end if;
        
        -- count how many points fall into each new child envelope
        select count(*)
          into child_count_1
          from pgnetworks_staging.road_network rn
         where st_within(rn.geom, child_envelope_1)
           and rn.segmentized is FALSE;
        
        select count(*)
          into child_count_2
          from pgnetworks_staging.road_network rn
         where st_within(rn.geom, child_envelope_2)
           and rn.segmentized is FALSE;
        
        -- insert child 1
        insert into pgnetworks_staging.selector_grid (parent_id, population, geom)
        values (
            current_parcel.id,
            child_count_1,
            child_envelope_1
        );
        
        -- insert child 2
        insert into pgnetworks_staging.selector_grid (parent_id, population, geom)
        values (
            current_parcel.id,
            child_count_2,
            child_envelope_2
        );
        
        -- mark the current parcel as final (we have now “replaced” it with two children)
        update pgnetworks_staging.selector_grid
           set processed = true
         where id = current_parcel.id;
        
    end loop;
    
    /*
     * 4. Delete all rows that have been processed during the looping procedure
     */
    
    execute format('delete from pgnetworks_staging.selector_grid where processed is TRUE');
    
end;
$procedure$;

-- name: drop_procedure_calculate_selector_grid#
drop procedure pgnetworks_staging.calculate_selector_grid(int);
