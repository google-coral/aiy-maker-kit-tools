# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SHELL := /bin/bash
MAKEFILE_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
OUT_DIR ?= $(MAKEFILE_DIR)/out
DOCKER_IMAGE ?= rpios-builder
RELEASE_BRANCH ?= master

.PHONY: \
	release \
	docker-release \
	docker-image \
	docker-shell \
	clean

url_effective = $(shell curl -LIs -o /dev/null -w %{url_effective} $(1))

help:
	@echo "make release"
	@echo "make docker-release"
	@echo "make docker-image"
	@echo "make docker-shell"
	@echo "make clean"

# Docker helpers
docker-image:
	docker build -t $(DOCKER_IMAGE) scripts

docker-shell: docker-image
	docker run --rm --privileged --interactive --tty --workdir /aiy \
		--volume $(MAKEFILE_DIR):/aiy $(DOCKER_IMAGE) /bin/bash

# Image builds
release:
	BUILD_ENGINE=native scripts/build.sh $(OUT_DIR) "aiy-maker-kit"

docker-release: docker-image
	BUILD_ENGINE=docker scripts/build.sh $(OUT_DIR) "aiy-maker-kit"

# Clean
clean:
	rm -rf $(OUT_DIR)
