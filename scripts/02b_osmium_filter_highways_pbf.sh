# the first filter expression filters on ways with the
# tag "highway" where this has not the values given in
# the comma separated list of terms
osmium tags-filter -O -o ./data/germany_filtered_01.osm.pbf ./data/germany-latest.osm.pbf w/highway
osmium tags-filter -O -o ./data/germany_filtered_02.osm.pbf ./data/germany_filtered_01.osm.pbf highway!=area,rest_area,footway,cycleway,parking,parking_aisle,bridleway,motorway,motorway_link,steps,track,trunk,trunk_link,path,abandoned,bus_guideway,construction,corridor,elevator,escalator,private,proposed,planned,platform,raceway,traffic_signals,crossing

## the inverse of the sets having tunnel, foot, area, etc as tags is all
## elements where neither is the case. They can be concatenated.
osmium tags-filter -O -i -o ./data/germany_filtered_03.osm.pbf ./data/germany_filtered_02.osm.pbf n/crossing w/tunnel=yes n/barrier nw/area nw/bridge w/service=parking_aisle