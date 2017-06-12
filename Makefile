################################################################################
# Description:
#  Executes testing and validation for python code and configuration files
#  within a StackStorm pack.
#
# =============================================

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PYMODULE_DIR := $(ROOT_DIR)/../
CI_DIR ?= $(ROOT_DIR)
YAML_FILES := $(shell git ls-files '*.yaml' '*.yml')
JSON_FILES := $(shell git ls-files '*.json')
PY_FILES   := $(shell git ls-files '*.py')
VIRTUALENV_DIR ?= $(ROOT_DIR)/virtualenv

.PHONY: all
all: requirements lint test

.PHONY: clean
clean: .clean-virtualenv

.PHONY: lint
lint: requirements flake8 pylint configs-check metadata-check

.PHONY: flake8
flake8: requirements .flake8

.PHONY: pylint
pylint: requirements .pylint

.PHONY: test
test: requirements .test

.PHONY: .flake8
.flake8:
	@echo
	@echo "==================== flake8 ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	for py in $(PY_FILES); do \
		flake8 --config $(CI_DIR)/lint-configs/python/.flake8 $$py || exit 1; \
	done


.PHONY: .pylint
.pylint:
	@echo
	@echo "==================== pylint ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	find ${PYMODULE_DIR} -name 'ci' -prune -or -name '.git' -prune -or -name "*.py" -print0 | xargs -0 -n 1 python -m pylint -E --rcfile=$(CI_DIR)/lint-configs/python/.pylintrc && echo	 "--> No pylint issues found in actions." || exit 1;


.PHONY: .configs-check
.configs-check:
	@echo
	@echo "==================== configs-check ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	for yaml in $(YAML_FILES); do \
		st2-check-validate-yaml-file $$yaml || exit 1; \
	done
	. $(VIRTUALENV_DIR)/bin/activate; \
	for json in $(JSON_FILES); do \
		st2-check-validate-json-file $$json || exit 1; \
	done
	@echo
	@echo "==================== example config check ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	st2-check-validate-pack-example-config /tmp/packs/$(PACK_NAME) || exit 1;


.PHONY: .test
.test:
	@echo
	@echo "==================== test ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	$(ST2_REPO_PATH)/st2common/bin/st2-run-pack-tests -x -p $(PACK_DIR) || exit 1;


.PHONY: requirements
requirements: virtualenv
	@echo
	@echo "==================== requirements ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	$(VIRTUALENV_DIR)/bin/pip install --upgrade pip; \
	$(VIRTUALENV_DIR)/bin/pip install --cache-dir $(HOME)/.pip-cache -q -r $(CI_DIR)/requirements-dev.txt -r $(CI_DIR)/requirements-test.txt;


.PHONY: virtualenv
virtualenv: $(VIRTUALENV_DIR)/bin/activate
$(VIRTUALENV_DIR)/bin/activate:
	@echo
	@echo "==================== virtualenv ===================="
	@echo
	test -d $(VIRTUALENV_DIR) || virtualenv --no-site-packages $(VIRTUALENV_DIR)


.PHONY: .clean-virtualenv
.clean-virtualenv:
	@echo "==================== cleaning virtualenv ===================="
	rm -rf $(VIRTUALENV_DIR)


# @todo print test converage
# @todo print code metrics
