################################################################################
# Description:
#  Executes testing and validation for python code and configuration files
#  within a StackStorm pack.
#
# =============================================

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PYMODULE_DIR := $(ROOT_DIR)/../
PYMODULE_TESTS_DIR ?= $(PYMODULE_DIR)/tests
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
lint: requirements flake8 pylint json-lint yaml-lint

.PHONY: flake8
flake8: requirements .flake8

.PHONY: pylint
pylint: requirements .pylint

.PHONY: json-lint
pylint: requirements .json-lint

.PHONY: yaml-lint
pylint: requirements .yaml-lint

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
	for py in $(PY_FILES); do \
		python -m pylint -E --rcfile=$(CI_DIR)/lint-configs/python/.pylintrc $py && echo "--> No pylint issues found in file: $$py." || exit 1; \
	done


.PHONY: .json-lint
.json-lint:
	@echo
	@echo "==================== json-lint ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	for json in $(JSON_FILES); do \
		python -mjson.tool $$json > /dev/null || exit 1; \
	done


.PHONY: .yaml-lint
.yaml-lint:
	@echo
	@echo "==================== yaml-lint ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	for yaml in $(YAML_FILES); do \
		python -c "import yaml; yaml.safe_load(open('$$yaml', 'r'))" || exit 1; \
	done


.PHONY: .test
.test:
	@echo
	@echo "==================== test ===================="
	@echo
	. $(VIRTUALENV_DIR)/bin/activate; \
	nosetests -s -v --exe $(PYMODULE_TESTS_DIR) -x -p $(PYMODULE_DIR) || exit 1;


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
