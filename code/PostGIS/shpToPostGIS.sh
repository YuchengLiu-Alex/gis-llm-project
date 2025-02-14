#!/bin/bash

# 设置 `data` 目录路径
DATA_DIR="$(dirname "$0")/../../data"

# 切换到 `data` 目录
cd "$DATA_DIR" || { echo "❌ Failed to change directory to $DATA_DIR"; exit 1; }
echo "📂 Current working directory: $(pwd)"

# PostgreSQL 连接信息
DB_NAME="chatgis"
DB_USER="chatgis"
DB_HOST="localhost"
DB_PORT="5432"
DATA_DIRS=("socal-latest-free.shp" "norcal-latest-free.shp")

# 获取 SRID 的函数
get_srid() {
    PRJ_FILE="$1"
    if [ -f "$PRJ_FILE" ]; then
        if grep -q "WGS_1984" "$PRJ_FILE"; then
            echo "4326"
        elif grep -q "NAD_1983" "$PRJ_FILE"; then
            echo "4269"
        else
            echo "3857"
        fi
    else
        echo "4326"
    fi
}

# 遍历数据目录
for DIR in "${DATA_DIRS[@]}"; do
    SCHEMA=$(basename "$DIR" | sed 's/-latest-free\.shp//')
    echo "📂 Processing directory: $DIR (Schema: $SCHEMA)"

    # 创建 Schema（如果不存在）
    PGPASSWORD="chatgis123" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -c "CREATE SCHEMA IF NOT EXISTS $SCHEMA;"

    # 遍历所有 .shp 文件
    for SHP_FILE in "$DIR"/*.shp; do
        if [ -f "$SHP_FILE" ]; then
            TABLE_NAME=$(basename "$SHP_FILE" .shp)
            PRJ_FILE="${SHP_FILE%.shp}.prj"
            SRID=$(get_srid "$PRJ_FILE")

            echo "🚀 Importing $SHP_FILE into $SCHEMA.$TABLE_NAME (SRID=$SRID)..."

            # 清空表但不删除结构
            PGPASSWORD="chatgis123" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -c "TRUNCATE TABLE $SCHEMA.$TABLE_NAME RESTART IDENTITY;"

            # 导入数据
            shp2pgsql -a -D -I -s $SRID $SHP_FILE $SCHEMA.$TABLE_NAME | \
            PGPASSWORD="chatgis123" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT"

            echo "✅ Imported $SHP_FILE into $SCHEMA.$TABLE_NAME (SRID=$SRID)"
        fi
    done
done

echo "🎉 All shapefiles have been imported successfully!"