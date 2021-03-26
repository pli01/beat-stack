#!/bin/bash
set -e
test -f $(dirname $0)/lib-common.sh && source $(dirname $0)/lib-common.sh
trap clean EXIT QUIT KILL

scriptname=$(basename $0 .sh)
slack_notification "0" "$scriptname Started"

source_dir=$(pwd)

echo "# Check build folder (${source_dir})"
( ls -lah ${source_dir}/*-build/ )

echo "# Publish in progress (${source_dir})"
( cd ${source_dir} &&
  echo "# generate token"
  export no_proxy="$no_proxy"
  eval $(openstack --insecure token issue -f shell -c id)
  OS_AUTH_TOKEN=${id:-}
  [ -z "$OS_STORAGE_URL" -o -z "$OS_AUTH_TOKEN" -o -z "$PROJECT_NAME" ] && exit 1

  make publish clean \
       dml_url=$OS_STORAGE_URL \
       openstack_token=$OS_AUTH_TOKEN \
       publish_dir=$PROJECT_NAME
)
