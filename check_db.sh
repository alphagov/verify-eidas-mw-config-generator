#!/usr/bin/env bash

DATABASE_PATH=${DATABASE_PATH:-/tmp/database.tar}
DATABASE_USER=$(docker exec -it eidas-middleware cat /opt/eidas-middleware/configuration/application.properties | grep spring.datasource.user | cut -d '=' -f2 | tr -d $'\r')
DATABASE_PASSWORD=$(docker exec -it eidas-middleware cat /opt/eidas-middleware/configuration/application.properties | grep spring.datasource.password | cut -d '=' -f2 | tr -d $'\r')

CVC_EXPIRY = $(java -cp "$H2_JAR_PATH" org.h2.tools.RunScript -url jdbc:h2:"$DATABASE_PATH" -user "$DATABASE_USER" -password "$DATABASE_PASSWORD" -script <(echo "SELECT NOTONORAFTER FROM TERMINALPERMISSION LIMIT 1 DESC;") -showResults)
