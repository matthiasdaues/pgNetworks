#!/bin/bash

# This script downloads the required data
# It was created with the invaluable assistance of ChatGPT4

# OPEN GOV GEODATA

# Define the list of open data URLs
declare -A gov_data
gov_data["NRW"]="https://www.opengeodata.nrw.de/produkte/geobasis/lk/akt/gebref_txt/gebref_EPSG25832_ASCII.zip"
#gov_data["Hessen"]="https://gds.hessen.de/INTERSHOP/web/WFS/HLBG-Geodaten-Site/de_DE/-/EUR/ViewDownloadcenter-Start?path=Liegenschaftskataster/Hauskoordinaten%20ohne%20Postalische%20Angaben%20(txt)" -> derzeit nicht verfügbar wegen GeoInfoDok Umstellung
gov_data["Thüringen"]="https://geoportal.geoportal-th.de/hausko_umr/HK-TH.zip"
gov_data["Sachsen"]="https://geocloud.landesvermessung.sachsen.de/index.php/s/R8Fm0cbDW2jw5LR/download?path=%2F&files=hk_sn_ascii.zip"
gov_data["Sachsen-Anhalt"]="https://www.lvermgeo.sachsen-anhalt.de/datei/anzeigen/id/258997,501/gebaeudereferenzen.zip"
#gov_data["Brandenburg"]="https://geobroker.geobasis-bb.de/gbss.php?MODE=GetProductInformation&PRODUCTID=51600a1d-c7a3-4211-aff8-e94fb7dc166d" -> muss bestellt werden und kann dann erst heruntergeladen werden
gov_data["Berlin"]="https://fbinter.stadt-berlin.de/fb/atom/Hauskoordinaten/HKO_EPSG25833.zip"
#gov_data["Schleswig-Holstein"]="https://geodaten.schleswig-holstein.de/gaialight-sh/_apps/dladownload/dl-hk_alkis.html" -> Download wird auf Anforderung bereit gestellt.
gov_data["Hamburg"]="https://daten-hamburg.de/inspire/hh_inspire_adressen_hauskoordinaten/HH_INSPIRE_Adressen_Hauskoordinaten_2020-07-17.zip" # -> veralteter Datenstand

# Define the target directory
target_directory="../data/gov_data"
mkdir -p "$target_directory"
log_file="../data/downloads.log"

# Create logfile
> "$log_file"

# Start logfile
current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$current_time] Attempting download of open geodata."  | tee -a "$log_file"

# Loop through the list of URLs and use wget to download each one
for name in "${!gov_data[@]}"
do
  url=${gov_data[$name]}
  filename=$(basename "$url") # Extracts the filename from the URL
 
  wget -P "$target_directory" "$url" -O "$target_directory/$filename"
  
  # Check the exit status of wget
  if [ $? -ne 0 ]; then
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$current_time] Download failed for $name" | tee -a "$log_file"
  else
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$current_time] $name downloaded successfully: $filename" | tee -a "$log_file"
  fi
done

# OPEN STREET MAP

# Define thea list of OSM data URLs
declare -A osm_data
osm_data["Bayern"]="https://download.geofabrik.de/europe/germany/bayern-latest.osm.pbf"
osm_data["Baden-W"]="https://download.geofabrik.de/europe/germany/baden-wuerttemberg-latest.osm.pbf"
osm_data["Rheinland-P"]="https://download.geofabrik.de/europe/germany/rheinland-pfalz-latest.osm.pbf"
osm_data["Saarland"]="https://download.geofabrik.de/europe/germany/saarland-latest.osm.pbf"
osm_data["Niedersachsen"]="https://download.geofabrik.de/europe/germany/niedersachsen-latest.osm.pbf"
osm_data["Meck-Vor"]="https://download.geofabrik.de/europe/germany/mecklenburg-vorpommern-latest.osm.pbf"
osm_data["Bremen"]="https://download.geofabrik.de/europe/germany/bremen-latest.osm.pbf"
# temporary fix
osm_data["Hessen"]="https://download.geofabrik.de/europe/germany/hessen-latest.osm.pbf"
osm_data["Brandenburg"]="https://download.geofabrik.de/europe/germany/brandenburg-latest.osm.pbf"
osm_data["Schleswig-Holstein"]="https://download.geofabrik.de/europe/germany/schleswig-holsteing-latest.osm.pbf"

# Define the target directory
target_directory="../data/osm_data"
mkdir -p "$target_directory"

current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$current_time] Attempting download of open street map data."  | tee -a "$log_file"

# Loop through the list of osm_data and use wget to download each one
for name in "${!osm_data[@]}"
do
  url=${osm_data[$name]}
  filename=$(basename "$url") # Extracts the filename from the URL
 
  wget -P "$target_directory" "$url" -O "$target_directory/$filename"
  
  # Check the exit status of wget
  if [ $? -ne 0 ]; then
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$current_time] Download failed for $name" | tee -a "$log_file"
  else
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$current_time] $name downloaded successfully: $filename" | tee -a "$log_file"
  fi
done

# finish logfile
current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$current_time] All attempted downloads are complete." | tee -a "$log_file"
