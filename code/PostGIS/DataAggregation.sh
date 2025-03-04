#!/bin/bash

DB_NAME="chatgis"
DB_USER="chatgis"
DB_PASSWORD="chatgis123"
DB_HOST="localhost"
DB_PORT="5432"

SCHEMA_CALIFORNIA="california"
SCHEMA_SOUTH="socal"
SCHEMA_NORTH="norcal"

# 表的名字，注意这个是你改名字后的，比如 buildings_a、roads 之类
TABLES=("buildings_a" "roads" "traffic" "natural" "pois_a" "landuse_a" "waterways" "pois" "traffic_a" "transport" "water_a" "railways" "pofw" "pofw_a" "places" "transport_a" "natural_a" "places_a")

# 创建california schema
echo "CREATE SCHEMA IF NOT EXISTS $SCHEMA_CALIFORNIA;" | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT

for table in "${TABLES[@]}"
do
  echo "Creating Materialized View for $table..."

  SQL="
  DROP MATERIALIZED VIEW IF EXISTS $SCHEMA_CALIFORNIA.$table;

  CREATE MATERIALIZED VIEW $SCHEMA_CALIFORNIA.$table AS
  SELECT * FROM $SCHEMA_SOUTH.$table
  UNION ALL
  SELECT * FROM $SCHEMA_NORTH.$table;
  "

  echo "$SQL" | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT

done

echo "✅ All materialized views created successfully in schema: $SCHEMA_CALIFORNIA"