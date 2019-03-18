APP_SERVICE_NAME = beat
APP_DOCKER_COMPOSE_BUILD = ${DC_PREFIX}-build-$(APP_SERVICE_NAME).yml
APP_DOCKER_COMPOSE_RUN = ${DC_PREFIX}-run-$(APP_SERVICE_NAME).yml
APP_PULL_IMAGES = metricbeat heartbeat

APP_BUILD_IMAGES = metricbeat heartbeat

# Image name:version
export metricbeat_image_full = docker.elastic.co/beats/metricbeat:6.6.2
export heartbeat_image_full = docker.elastic.co/beats/heartbeat:6.6.2

# Env build (ARG)
export MIRROR_DEBIAN = $(shell echo $$MIRROR_DEBIAN )
export RUBY_URL = $(shell echo $$RUBY_URL )
export PYPI_URL = $(shell echo $$PYPI_URL )
export PYPI_HOST = $(shell echo $$PYPI_HOST )

# Env run (ENV)
export app_stack_conf_dir = ${APP_PATH}/$(APP_SERVICE_NAME)-conf
export app_stack_data_dir = ${APP_DATA}

$(APP_SERVICE_NAME)-build: $(APP_SERVICE_NAME)-build-image build-dir $(APP_SERVICE_NAME)-save-image

$(APP_SERVICE_NAME)-clean: $(APP_SERVICE_NAME)-clean-image

$(APP_SERVICE_NAME)-build-image: $(APP_SERVICE_NAME)-check-config-image $(APP_SERVICE_NAME)-pull-image
	@echo building ${APP} $(APP_SERVICE_NAME)
	( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_BUILD) build )

$(APP_SERVICE_NAME)-list-services:
	@( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_BUILD) config --services )

$(APP_SERVICE_NAME)-check-config-image:
	@( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_BUILD) config )

$(APP_SERVICE_NAME)-pull-image:
	@echo pull ${APP} $(APP_SERVICE_NAME)
	if [ ! -z "$(APP_PULL_IMAGES)" ] ; then ( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_BUILD) pull $(APP_PULL_IMAGES) ) ; fi

$(APP_SERVICE_NAME)-save-image:
	for service in $(APP_BUILD_IMAGES) ; do \
	image_name=$$(cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_BUILD) config | \
	python -c 'import sys, yaml, json; cfg = json.loads(json.dumps(yaml.load(sys.stdin), sys.stdout, indent=4)); print cfg["services"]["'$$service'"]["image"]') ; \
	  docker image save $$image_name | gzip -9c > $(BUILD_DIR)/$(APP)-$(APP_SERVICE_NAME)-$$service-latest-image.tar.gz ; \
	  cp $(BUILD_DIR)/$(APP)-$(APP_SERVICE_NAME)-$$service-latest-image.tar.gz $(BUILD_DIR)/$(APP)-$(APP_SERVICE_NAME)-$$service-$(APP_VERSION)-image.tar.gz ; \
	done

$(APP_SERVICE_NAME)-clean-image:
	@(cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_BUILD) config | \
           python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' | \
           jq -r '.services[] | . as $(dollar)a | select($(dollar)a.build) | .image' ) | while read image_name ; do \
           docker rmi $$image_name || true ; \
        done

$(APP_SERVICE_NAME)-publish:
	@echo "Publish $(APP) $(APP_VERSION) $(APP_SERVICE_NAME) artifacts"
	if [ -z "$(dml_url)" -o -z "$(openstack_token)" ] ; then exit 1 ; fi
	( cd $(BUILD_DIR) ;\
	    for service in \
                $(APP_BUILD_IMAGES) \
           ; do \
            file=$(APP)-$(APP_SERVICE_NAME)-$$service-$(APP_VERSION)-image.tar.gz ; \
            latest=$(APP)-$(APP_SERVICE_NAME)-$$service-latest-image.tar.gz ; \
            curl $(curl_args) -k -X PUT -T $$file -H 'X-Auth-Token: $(openstack_token)' $(dml_url)/$(publish_dir)/$(APP_VERSION)/$$file ; \
            curl $(curl_args) -k -X PUT -T $$latest -H 'X-Auth-Token: $(openstack_token)' $(dml_url)/$(publish_dir)/latest/$$latest ; \
           done ; \
	)

$(APP_SERVICE_NAME)-load-image:
	( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_RUN) config --services | while read service; do \
	  docker load -i $(BUILD_DIR)/$(APP)-$(APP_SERVICE_NAME)-$$service-$(APP_VERSION)-image.tar.gz ; \
	 done )

$(APP_SERVICE_NAME)-get-build-image: build-dir
	( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_RUN) config --services | while read service; do \
            file=$(APP)-$(APP_SERVICE_NAME)-$$service-$(APP_VERSION)-image.tar.gz ; \
            curl $(curl_args) -k -X GET -L $(dml_url)/$(publish_dir)/$(APP_VERSION)/$$file -o $(BUILD_DIR)/$$file ; \
	 done )

$(APP_SERVICE_NAME)-up:
	@( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_RUN) up -d 2>&1 | grep -v orphan )
$(APP_SERVICE_NAME)-stop:
	@( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_RUN) stop )
$(APP_SERVICE_NAME)-rm:
	@( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_RUN) rm )
$(APP_SERVICE_NAME)-down:
	@( cd ${APP_PATH} && ${DC} -f $(APP_DOCKER_COMPOSE_RUN) down )
