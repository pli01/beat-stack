#!/bin/bash
#
# quick docker deploy
#
set -e -o pipefail
set -x

# optional dockerhub login
export DOCKERHUB_LOGIN="${DOCKERHUB_LOGIN:-}"
export DOCKERHUB_TOKEN="${DOCKERHUB_TOKEN:-}"

export DOCKER_REGISTRY_USERNAME="${DOCKER_REGISTRY_USERNAME:-}"
export DOCKER_REGISTRY_TOKEN="${DOCKER_REGISTRY_TOKEN:-}"

export METRIC_NAME="${METRIC_NAME:-beat-stack}"
export METRIC_BRANCH="${METRIC_BRANCH:-master}"
export METRIC_URL="https://github.com/pli01/${METRIC_NAME}/archive/refs/heads/${METRIC_BRANCH}.tar.gz"

# if authenticated repo
if [ -n "${GITHUB_TOKEN}" ] ; then
  curl_args=" -H \"Authorization: token ${GITHUB_TOKEN}\" "
fi

# if METRIC_ROLE defined use make up-${METRIC_ROLE}
if [ -n "$METRIC_ROLE" ] ;then
 app_role="-${METRIC_ROLE}"
fi

# download install repo
mkdir -p ${METRIC_NAME}
curl -kL -s $curl_args ${METRIC_URL} | \
   tar -zxvf - --strip-components=1 -C ${METRIC_NAME}
# install app (role)
( cd ${METRIC_NAME}
  [ -n "$DOCKERHUB_TOKEN" -a -n "$DOCKERHUB_LOGIN" ] &&  echo $DOCKERHUB_TOKEN | \
      docker login --username $DOCKERHUB_LOGIN --password-stdin

  make beat-pull
  make beat-down$app_role
  make beat-up$app_role

  [ -n "$DOCKERHUB_TOKEN" -a -n "$DOCKERHUB_LOGIN" ] && docker logout
  exit 0
)

