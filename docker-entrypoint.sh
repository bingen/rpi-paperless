#!/bin/bash

# Set consumption directory
mkdir -p ${PAPERLESS_CONSUMPTION_DIR}

# Set export directory
mkdir -p $PAPERLESS_EXPORT_DIR

# set ftp user home to Consume folder
usermod -d ${PAPERLESS_CONSUMPTION_DIR} ftp

# allow to upload thru FTP
sed -i 's/#write_enable=/write_enable=/g' /etc/vsftpd.conf
# Chroot to home folder
sed -i '0,/#chroot_local_user=/{s/#chroot_local_user=/chroot_local_user=/}' /etc/vsftpd.conf
echo "pasv_min_port=21100" >> /etc/vsftpd.conf
echo "pasv_max_port=21110" >> /etc/vsftpd.conf

# set Web server password from secret
if [ ! -z ${PAPERLESS_WEBSERVER_PWD_FILE} -a -f ${PAPERLESS_WEBSERVER_PWD_FILE} ]; then
    PAPERLESS_WEBSERVER_PWD=`cat $PAPERLESS_WEBSERVER_PWD_FILE`;
fi

# set Passphrase from secret
if [ ! -z ${PAPERLESS_PASSPHRASE_FILE} -a -f ${PAPERLESS_PASSPHRASE_FILE} ]; then
    export PAPERLESS_PASSPHRASE=`cat $PAPERLESS_PASSPHRASE_FILE`;
fi

# set FTP user password from secret
if [ ! -z ${PAPERLESS_FTP_PWD_FILE} -a -f ${PAPERLESS_FTP_PWD_FILE} ]; then
    PAPERLESS_FTP_PWD=`cat $PAPERLESS_FTP_PWD_FILE`;
fi


# Migrate database
echo Migrate database
/usr/src/paperless/src/manage.py migrate

# Create webserver user
echo Create webserver user
# https://stackoverflow.com/a/42491469/1937418
/usr/src/paperless/src/manage.py createsuperuser2 --username ${PAPERLESS_WEBSERVER_USER} --email paperless@test.com --password ${PAPERLESS_WEBSERVER_PWD} --noinput

# create FTP user
useradd -d ${PAPERLESS_CONSUMPTION_DIR} -p `openssl passwd -1 ${PAPERLESS_FTP_PWD}` ${PAPERLESS_FTP_USER}

# start FTP server
echo start FTP server
service vsftpd start

# start web server
echo start web server
/usr/src/paperless/scripts/docker-entrypoint.sh runserver --insecure 0.0.0.0:8000 &

echo "exec command $@"
exec sudo -HEu paperless "/usr/src/paperless/src/manage.py" "$@"
//exec "$@"
