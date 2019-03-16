#!/bin/bash
set -e

script_name=$(basename $0 .sh)
echo "# $script_name start"

ret=0
# detect TTY
if test -t 1 ; then
  DOCKER_USE_TTY="-t"
else
  DC_USE_TTY="-T"
fi

set +e
# test metricbeat config syntax
test_status=OK
service_name="metricbeat"
test_name="${APP_DOCKER_COMPOSE_RUN} ${service_name}: "'metricbeat version'
echo "# $script_name: $test_name"
test_output=$( ( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} run --rm --no-deps ${DC_USE_TTY} ${service_name} /bin/bash -c "metricbeat version" ) )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	echo "ERROR: $test_output"
	ret=$test_result
	test_status=FAILED
fi
echo "# $script_name: $test_name $test_status $test_output"

# start all service
test_status=OK
test_name="${APP_DOCKER_COMPOSE_RUN} ${service_name}: "'metricbeat test config'
echo "# $script_name: $test_name"
#( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} up --no-recreate --no-deps --no-build 2>&1 )
test_output=$( ( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} run --rm --no-deps ${DC_USE_TTY} ${service_name} /bin/bash -c "metricbeat --strict.perms=false --path.config /metricbeat -v test config" ) )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result $test_output"
	ret=$test_result
	test_status=FAILED
	exit $ret
fi
echo "# $script_name: $test_name $test_status $test_output"

# start all service
test_status=OK
test_name="${APP_DOCKER_COMPOSE_RUN} ${service_name}: "'metricbeat test modules'
echo "# $script_name: $test_name"
#( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} up --no-recreate --no-deps --no-build 2>&1 )
test_output=$( ( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} run --rm --no-deps ${DC_USE_TTY} ${service_name} /bin/bash -c "metricbeat --strict.perms=false --path.config /metricbeat -v test modules" ) )
test_result=$?
if [ "$test_result" -gt 0 ] ;then
	echo "ERROR: $test_name $test_result"
	ret=$test_result
	test_status=FAILED
	exit $ret
fi
echo "# $script_name: $test_name $test_status"

set -e
exit $ret
