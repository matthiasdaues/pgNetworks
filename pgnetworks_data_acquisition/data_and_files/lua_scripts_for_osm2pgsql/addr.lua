local tables = {}

tables.addr_points = osm2pgsql.define_node_table('addr_points', {
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'point', projection = 4326 },
    },{ schema = 'osm' }
)

tables.addr_polys = osm2pgsql.define_area_table('addr_polys', {
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'geometry', projection = 4326 },
    },{ schema = 'osm' }
)

function osm2pgsql.process_node(object)
    if object.tags['addr:city'] then
        tables.addr_points:add_row({
            tags = object.tags
        })
    end
end

function osm2pgsql.process_way(object)
    if object.tags['addr:city'] then
        tables.addr_polys:add_row({
            tags = object.tags,
            geom = { create = 'area' }
        })
    end
end

function osm2pgsql.process_relation(object)
    if object.tags.type == 'multipolygon' and object.tags['addr:city'] then
        tables.addr_polys:add_row({
            -- The 'split_at' setting tells osm2pgsql to split up MultiPolygons
            -- into several Polygon geometries.
            tags = object.tags,
            geom = { create = 'area', split_at = 'multi' }
        })
    end
end

