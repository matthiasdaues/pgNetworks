local tables = {}

tables.buildings = osm2pgsql.define_area_table('buildings', {
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'geometry', projection = 4326 },
    },{ schema = 'osm' }
)

function osm2pgsql.process_way(object)
    if object.tags.building then
        tables.buildings:add_row({
            tags = object.tags,
            geom = { create = 'area' }
        })
    end
end

function osm2pgsql.process_relation(object)
    if object.tags.type == 'multipolygon' and object.tags.building then
        tables.buildings:add_row({
            -- The 'split_at' setting tells osm2pgsql to split up MultiPolygons
            -- into several Polygon geometries.
            tags = object.tags,
            geom = { create = 'area', split_at = 'multi' }
        })
    end
end

