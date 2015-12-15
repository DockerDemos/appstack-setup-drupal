#!/bin/bash

## Uses $CMS_PKG ENV var set in Dockerfile for install

if [[ -z "$DB_PORT_3306_TCP_ADDR" ]] ; then
  echo '$DB_PORT_3306_TCP_ADDR environmental variable not set'
  echo 'Is this container linked with the database container as "db"?'
  exit 1
fi

DBYAML='/conf/.creds/dbdata.yaml'

DB_NAME="$(grep name dbdata.yaml |awk '{print $2}')"
DB_USER='root'
DB_PASS="$(grep mysql dbdata.yaml |awk '{print $2}')"
DB_HOST=$DB_PORT_3306_TCP_ADDR
DB_URL="mysql://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME"

if [[ "$(/bin/ls -A /var/www/html)" ]] ; then
  /bin/echo "SOMETHING ALREADY INSTALLED IN '/var/www/html'"
  exit 1
else
  if [ ! -f "/var/www/html/sites/default/settings.php" ] ; then
    /bin/tar -xz -C /var/www/html --strip-components=1 -f /$CMS_PKG

    yes | /drush/drush site-install --db-url="$DB_URL" -r /var/www/html

    # UID 48 is Apache on RHEL-based servers
    # We can set UID 48 even if the user doesn't exist
    /bin/chown -R 48 /var/www/html
  fi
fi
