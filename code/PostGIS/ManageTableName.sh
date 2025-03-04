#!/bin/bash

DB_NAME="chatgis"
DB_USER="chatgis"
DB_HOST="localhost"
DB_PORT="5432"
PASSWORD="chatgis123"
SCHEMAS=("norcal" "socal")

for SCHEMA in "${SCHEMAS[@]}"; do
  echo "📂 正在处理 schema: $SCHEMA"

  TABLES=$(PGPASSWORD=$PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -At -c "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = '$SCHEMA';")

  for TABLE in $TABLES; do
    # 提取中间的关键部分，比如 buildings、roads、waterways
    CORE_NAME=$(echo "$TABLE" | sed -E 's/gis_osm_(.*)(_a_free_1|_free_1)$/\1/')
    
    # 防止已经是简化名字的表重复处理
    if [ "$CORE_NAME" != "$TABLE" ]; then
      echo "🔄 重命名 $SCHEMA.$TABLE → $CORE_NAME"
      PGPASSWORD=$PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "ALTER TABLE $SCHEMA.\"$TABLE\" RENAME TO \"$CORE_NAME\";"
    else
      echo "✅ 表名 $SCHEMA.$TABLE 无需修改"
    fi
  done
done

echo "🎉 所有表名已修改完成！"