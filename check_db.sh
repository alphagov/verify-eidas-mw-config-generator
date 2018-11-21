#!/usr/bin/env bash

DATABASE_PATH=${DATABASE_PATH:-/tmp/database.tar}
DATABASE_USER=$(docker exec -it eidas-middleware cat /opt/eidas-middleware/configuration/application.properties | grep spring.datasource.user | cut -d '=' -f2 | tr -d $'\r')
DATABASE_PASSWORD=$(docker exec -it eidas-middleware cat /opt/eidas-middleware/configuration/application.properties | grep spring.datasource.password | cut -d '=' -f2 | tr -d $'\r')

function runSQL() {
    echo $(java -cp "$H2_JAR_PATH" org.h2.tools.RunScript -url jdbc:h2:"$DATABASE_PATH" -user "$DATABASE_USER" -password "$DATABASE_PASSWORD" -script <(echo $1) -showResults | grep '\-->' | sed 's/--> \(.*\)/\1/')
}

LAST_UPDATED_REF_ID=$(runSQL "SELECT REFID FROM TERMINALPERMISSION ORDER BY BLACKLISTSTOREDATE DESC LIMIT 1;")
CVC_EXPIRY=$(runSQL "SELECT NOTONORAFTER FROM TERMINALPERMISSION WHERE REFID = '$LAST_UPDATED_REF_ID';")
BLACKLIST_UPDATE=$(runSQL "SELECT BLACKLISTSTOREDATE FROM TERMINALPERMISSION WHERE REFID = '$LAST_UPDATED_REF_ID';")

echo $LAST_UPDATED_REF_ID
echo $CVC_EXPIRY
echo $BLACKLIST_UPDATE

read -r -d '' CHECK_OUTPUT_TEMPLATE << EOM
{
    "refId": "%s",
    "dateValue": "%s",
    "timestamp": "%s"
}
EOM

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

printf "$CHECK_OUTPUT_TEMPLATE" "$LAST_UPDATED_REF_ID" "$CVC_EXPIRY" "$TIMESTAMP" > cvc_expiry_check.json
printf "$CHECK_OUTPUT_TEMPLATE" "$LAST_UPDATED_REF_ID" "$BLACKLIST_UPDATE" "$TIMESTAMP" > blacklist_update_check.json
