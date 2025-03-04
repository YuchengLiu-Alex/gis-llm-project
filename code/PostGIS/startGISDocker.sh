docker run -d \               
  --name chatgis-db \
  -e POSTGRES_USER=chatgis \
  -e POSTGRES_PASSWORD=chatgis123 \
  -e POSTGRES_DB=chatgis \
  -p 5432:5432 \
  postgres:latest