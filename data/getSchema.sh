# #!/bin/bash

# # 数据库连接信息
# DB_NAME="chatgis"
# DB_USER="chatgis"
# DB_HOST="localhost"
# DB_PORT="5432"
# OUTPUT_DIR="schema_exports"

# # 确保输出目录存在
# mkdir -p "$OUTPUT_DIR"

# # 获取数据库中的所有 schema
# SCHEMAS=$(PGPASSWORD="chatgis123" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT LIKE 'pg_%' AND schema_name NOT IN ('information_schema');")

# # 遍历每个 Schema 并导出
# for SCHEMA in $SCHEMAS; do
#     OUTPUT_FILE="$OUTPUT_DIR/${SCHEMA}.sql"
#     echo "📝 Exporting schema: $SCHEMA -> $OUTPUT_FILE"
    
#     # 使用 pg_dump 导出该 schema
#     PGPASSWORD="chatgis123" pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" --schema="$SCHEMA" --schema-only > "$OUTPUT_FILE"

#     echo "✅ Schema $SCHEMA 导出完成！"
# done

# echo "🎉 所有 schema 已导出，文件存放于 $OUTPUT_DIR 目录下！"

#!/bin/bash

DB_NAME="chatgis"
DB_USER="chatgis"
DB_HOST="localhost"
SCHEMAS=( "norcal" "socal")

for SCHEMA in "${SCHEMAS[@]}"; do
    echo "🚀 Exporting schema metadata for ${SCHEMA}..."
    PGPASSWORD="chatgis123" psql -U "$DB_USER" -d "$DB_NAME" -h "$DB_HOST" -c "
    SELECT table_schema, table_name, column_name, data_type 
    FROM information_schema.columns 
    WHERE table_schema = '${SCHEMA}'
    ORDER BY table_name, ordinal_position;" > "${SCHEMA}_schema.csv"
    echo "✅ Exported ${SCHEMA}_schema.csv successfully!"
done

psql -U chatgis -d chatgis -h localhost -c "
SELECT c.table_schema, c.table_name, c.column_name, c.data_type 
FROM information_schema.columns c
JOIN pg_matviews m 
ON c.table_schema = m.schemaname AND c.table_name = m.matviewname
WHERE c.table_schema = 'california'
ORDER BY c.table_name, c.ordinal_position;" > california_matviews_schema.csv

psql -U chatgis -d chatgis -h localhost -c "
COPY (
    SELECT n.nspname AS schema_name,
           c.relname AS table_name,
           a.attname AS column_name,
           pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE n.nspname = 'california' 
      AND c.relkind IN ('m', 'v', 'r')  -- 'm' 物化视图, 'v' 视图, 'r' 普通表
      AND a.attnum > 0
    ORDER BY c.relname, a.attnum
) TO STDOUT WITH CSV HEADER;" > california_schema.csv

echo "🎉 All schema metadata exported successfully!"