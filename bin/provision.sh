#! /usr/bin/env bash

# This file is a simple starter for provisioning
# a new docker container and then using fetcher to
# provision a drupal site inside that container.

if [ $# -lt 3 ]
  then
    echo "Invalid selection\n"
    echo "You must specify fetcher site name, ubuntu version, and git ref\n\n"
    echo "Example: provision zivtech 12.04 HEAD"
    exit 1
fi
INSTANCE_NAME=$4
if [ -z $4 ]
  then
    INSTANCE_NAME=$1
fi

NAME=$1
UBUNTU_VERSION=$2
REF=$3
HOSTNAME_SUFFIX="local"
REMOTE_ENVIRONMENT='dev'
WORKING_DIR="/var/www/${1}"
DRUPAL_ROOT="${WORKING_DIR}/webroot"

docker run \
  --name ${INSTANCE_NAME} \
  -d \
  -p 22 \
  -p 80 \
  -p 443 \
  -p 3306 \
  -p 6379 \
  -v /vagrant/ssh_credentials/id_rsa.pub:/root/.ssh/id_rsa.pub:ro \
  -v /vagrant/ssh_credentials/id_rsa:/root/.ssh/id_rsa:ro ubuntu-${UBUNTU_VERSION}-lamp:latest \
  penelope \
    -n ssh \
    -c '/usr/sbin/sshd -d -D' \
    -n apache \
    -c '/usr/sbin/apache2ctl -D FOREGROUND' \
    -n mysql \
    -c 'mysqld_safe' \
    -n redis \
    -c 'redis-server'
sleep 2
docker-enter ${INSTANCE_NAME} hostname ${1}.${HOSTNAME_SUFFIX}
docker-enter ${INSTANCE_NAME} drush fetch \
  -v \
  --sql-sync \
  --remote-environment=$REMOTE_ENVIRONMENT \
  --hostname="${INSTANCE_NAME}.${HOSTNAME_SUFFIX}" \
  --local-environment=docker \
  ${NAME}
docker-enter ${INSTANCE_NAME} chown www-data -R ${WORKING_DIR}/public_files
docker-enter ${INSTANCE_NAME} chown www-data -R ${WORKING_DIR}/private_files
docker-enter ${INSTANCE_NAME} chown www-data -R ${WORKING_DIR}/private_files
docker-enter ${INSTANCE_NAME} git  --work-tree="${WORKING_DIR}/code" --git-dir="${WORKING_DIR}/code/.git" checkout $REF
docker-enter ${INSTANCE_NAME}  drush --root=$DRUPAL_ROOT updb -y
docker-enter ${INSTANCE_NAME} drush --root=$DRUPAL_ROOT fra -y
