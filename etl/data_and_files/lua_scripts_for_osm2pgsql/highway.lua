local tables = {}

tables.road_network = osm2pgsql.define_table({
    name = 'road_network',
    ids = { type = 'way', id_column = 'id' },
    columns = {
        { column = 'properties', type = 'jsonb' },
        { column = 'geom', type = 'linestring', projection = 4326 },
    },
    schema = 'osm'
})

function osm2pgsql.process_way(object)
    tables.road_network:add_row({
        properties = object.tags,
        geom = { create = 'line' }
    })
end