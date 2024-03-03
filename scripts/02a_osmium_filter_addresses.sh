# the first filter expression filters on ways with the
# tag "highway" where this has not the values given in
# the comma separated list of terms
osmium tags-filter -O -o ../data/osm_data/bremen_a_filtered_01.osm.pbf ../data/osm_data/bremen-latest.osm.pbf nrw/addr:housenumber
