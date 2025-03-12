-- terminal_id
-- road_id
-- closest_point_geom
-- closest_point_id
-- closest_point_type
-- point_2_road_id
-- point_2_road_geom
-- point_2_road_type
-- point_2_road_cost
with vertices as (
    select 
        id 
    ,   geom
    from
        pgnetworks_staging.terminals
    where
        properties @> '[{"ags":{"ags11":"05962024002"}}]'
    --limit 100
)
insert into pgnetworks_staging.terminal_connection(terminal_id, road_id, closest_point_geom, closest_point_id, closest_point_type, point_2_road_id, point_2_road_geom, point_2_road_type, point_2_road_cost)
select 
	a.id as terminal_id
,   b.road_id as road_id
,   st_closestpoint(b.road_geom, a.geom) as closest_point_geom
,   ghh_encode(st_x(st_closestpoint(b.road_geom, a.geom))::numeric(10,7),st_y(st_closestpoint(b.road_geom, a.geom))::numeric(10,7)) as closest_point_id
,   'address_road' as closest_point_type
,   ghh_encode(st_x(st_lineinterpolatepoint(st_makeline(st_closestpoint(b.road_geom, a.geom), a.geom),0.5))::numeric(10,7), st_y(st_lineinterpolatepoint(st_makeline(st_closestpoint(b.road_geom, a.geom), a.geom),0.5))::numeric(10,7)) as point_2_road_id
,   st_makeline(st_closestpoint(b.road_geom, a.geom), a.geom) as point_2_road_geom
,   'address_road' as point_2_road_type
,   st_length(st_makeline(st_closestpoint(b.road_geom, a.geom), a.geom)::geography)::numeric(10,2) as point_2_road_cost
from
    vertices a
join lateral (
    select
        id as road_id
    ,   geom as road_geom
    from
        pgnetworks_staging.road_network b
    order by
        a.geom <-> b.geom 
    limit
        1
    ) as b on true
order by
    road_id, terminal_id
;

