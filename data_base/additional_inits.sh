#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER gis WITH PASSWORD 'HeWhoBuildsTheLand';
	CREATE DATABASE gis TEMPLATE postgres;
	GRANT ALL PRIVILEGES ON DATABASE gis TO gis;
EOSQL