#!/bin/bash

# Set export directory
mkdir -p ${PAPERLESS_EXPORT_DIR}

# set Web server password from secret
if [ ! -z ${PAPERLESS_WEBSERVER_PWD_FILE} -a -f ${PAPERLESS_WEBSERVER_PWD_FILE} ]; then
    PAPERLESS_WEBSERVER_PWD=`cat $PAPERLESS_WEBSERVER_PWD_FILE`;
fi

# set Passphrase from secret
if [ ! -z ${PAPERLESS_PASSPHRASE_FILE} -a -f ${PAPERLESS_PASSPHRASE_FILE} ]; then
    export PAPERLESS_PASSPHRASE=`cat $PAPERLESS_PASSPHRASE_FILE`;
fi


# Migrate database
echo Migrate database
/usr/src/paperless/src/manage.py migrate

# Create webserver user
echo Create webserver user
# https://stackoverflow.com/a/42491469/1937418
/usr/src/paperless/src/manage.py createsuperuser2 --username ${PAPERLESS_WEBSERVER_USER} --email paperless@test.com --password ${PAPERLESS_WEBSERVER_PWD} --noinput

# start web server
echo start web server
/usr/src/paperless/scripts/docker-entrypoint.sh runserver --insecure 0.0.0.0:8000 &

echo "exec command $@"
exec sudo -HEu paperless "/usr/src/paperless/src/manage.py" "$@"
//exec "$@"
