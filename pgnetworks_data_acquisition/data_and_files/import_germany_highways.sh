#!/bin/bash

set -e

# Import von OSM-Daten über Osmium und osm2pgsql

cd ~/Documents/geodata

mkdir data

# the first filter expression filters on ways with the
# tag "highway" where this has not the values given in
# the comma separated list of terms
osmium tags-filter -O -o ./data/germany_filtered_01.osm.pbf ./germany-latest.osm.pbf w/highway
osmium tags-filter -O -o ./data/germany_filtered_02.osm.pbf ./data/germany_filtered_01.osm.pbf highway!=area,rest_area,footway,cycleway,parking,parking_aisle,bridleway,motorway,atmotorway,motorway_link,steps,track,trunk,trunk_link,path,abandoned,bus_guideway,construction,corridor,elevator,escalator,private,proposed,planned,platform,raceway,traffic_signals,crossing

## the inverse of the sets having tunnel, foot, area, etc as tags is all
## elements where neither is the case. They can be concatenated.
osmium tags-filter -O -i -o ./data/germany_filtered_03.osm.pbf ./data/germany_filtered_02.osm.pbf n/crossing w/tunnel=yes n/barrier nw/area nw/bridge w/service=parking_aisle

# test the file for missing objects
osmium getid ./data/germany_filtered_03.osm.pbf w43636167 -o ./data/germany_filtered_04.osm.pbf

# Import "generic"
# osm2pgsql -H datenschoenheit.de -P 25433 -U gis -W -d gis -O flex -S /home/matthiasdaues/Documents/projects/howFar_howMuch_howMany/01_scripts/02_lua_and_sh/highway.lua /home/matthiasdaues/Documents/geodata/data/germany_filtered_03.osm.pbf
osm2pgsql -H localhost -P 25432 -U administrator -W -d pgnetworks -O flex -S /home/matthiasdaues/Documents/datenschoenheit/pgNetworks/etl/data_and_files/lua_scripts_for_osm2pgsql/highway.lua /home/matthiasdaues/Documents/geodata/data/germany_filtered_03.osm.pbf

