local tables = {}

tables.highways = osm2pgsql.define_way_table('highways', {
    { column = 'type', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'surface', type = 'text'},
    { column = 'tags', type = 'jsonb'},
    { column = 'geom', type = 'linestring', projection = 4326 },
    },{ schema = 'osm' }
)

tables.boundaries = osm2pgsql.define_area_table('boundaries', {
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'geometry', projection = 4326 },
    },{ schema = 'osm' }
)

function osm2pgsql.process_way(object)
    if object.tags.highway then
        tables.highways:add_row{ 
            type = object.tags.highway,
            name = object.tags.name,
            surface = object.tags.surface,
            tags=object.tags
        }
    end
end

function osm2pgsql.process_relation(object)
    if object.tags.boundary == 'administrative' then
        tables.boundaries:add_row{
            tags = object.tags,
            geom = { create = 'area' }
        }
    end
end