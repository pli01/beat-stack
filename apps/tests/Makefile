#
#  definition variables de environnement de test
#
export COMPOSE_PROJECT_NAME = test_${APP}_${APP_SERVICE_NAME}
# repertoire racine de test
export TEST_APP_PATH=${APP_PATH}/tests
# repertoire data de test
export TEST_APP_DATA=${APP_PATH}/tests
# docker-compose de test du service
export APP_DOCKER_COMPOSE_RUN = ${TEST_APP_PATH}/docker-compose-run-${APP_SERVICE_NAME}.yml

export dollar = $(shell echo \$$)

# config de test du service
# export app_stack_conf_dir = ${APP_PATH}/${APP_SERVICE_NAME}-conf
export app_stack_conf_dir = ${TEST_APP_PATH}/${APP_SERVICE_NAME}-conf
# repertoire data de test du service
export app_stack_data_dir = ${TEST_APP_DATA}
# parametre de test du service
#export DC_UP_ARGS = testrunner
# config du runner de test
export APP_TEST_RUNNER_SERVICE_NAME = ${APP_SERVICE_NAME}-testrunner
export APP_TEST_RUNNER_DOCKER_COMPOSE_BUILD =  ${TEST_APP_PATH}/docker-compose-build-${APP_TEST_RUNNER_SERVICE_NAME}.yml
# testrunner image name
export testrunner_image_full = ${APP}-${APP_TEST_RUNNER_SERVICE_NAME}:latest

#
# target:
#    prepare-test: testrunner-build-image
#    run-test
#    clean-test
#

prepare-test: ${APP_TEST_RUNNER_SERVICE_NAME}-build-image
	@echo "# $@ "
	bash build-env-test.sh

run-test: up-test
	@echo "# $@ "

up-test: ${APP_DOCKER_COMPOSE_RUN}
	bash run-env-test.sh

clean-test: down-test ${APP_TEST_RUNNER_SERVICE_NAME}-clean-image
	@echo "# $@ "

down-test:
	( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} down -v )

stop-test:
	( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} stop )

rm-test:
	( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} rm -f -v )

log-test:
	( cd ${APP_PATH} && ${DC} -f ${APP_DOCKER_COMPOSE_RUN} logs  )

${APP_TEST_RUNNER_SERVICE_NAME}-build-image: ${APP_TEST_RUNNER_DOCKER_COMPOSE_BUILD} ${APP_TEST_RUNNER_SERVICE_NAME}-check-config-image
	@echo building ${APP} ${APP_TEST_RUNNER_SERVICE_NAME}
	( cd ${TEST_APP_PATH} && ${DC} -f ${APP_TEST_RUNNER_DOCKER_COMPOSE_BUILD} build --pull )

${APP_TEST_RUNNER_SERVICE_NAME}-check-config-image:
	@( cd ${TEST_APP_PATH} && ${DC} -f ${APP_TEST_RUNNER_DOCKER_COMPOSE_BUILD} config -q )

${APP_TEST_RUNNER_SERVICE_NAME}-clean-image:
	@(cd ${TEST_APP_PATH} && ${DC} -f ${APP_TEST_RUNNER_DOCKER_COMPOSE_BUILD} config | \
           python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' | \
           jq -r '.services[] | . as $(dollar)a | select($(dollar)a.build) | .image' ) | while read image_name ; do \
           docker rmi $$image_name || true ; \
        done
