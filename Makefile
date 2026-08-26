SHELL := /bin/bash

PYTHON := .venv/bin/python
RUFF := .venv/bin/ruff
PYRIGHT := .venv/bin/pyright
QMLFORMAT := .venv/bin/pyside6-qmlformat
QMLLINT := .venv/bin/pyside6-qmllint
QML_FILES := $(shell find src/settimer/ui -name '*.qml' -type f | sort)

.PHONY: install run format format-check lint type-check qml-check test coverage check package clean

install:
	$(PYTHON) -m pip install -e '.[dev]'

run:
	$(PYTHON) -m settimer

format:
	$(RUFF) format src tests packaging
	$(RUFF) check --fix src tests packaging
	$(QMLFORMAT) --inplace $(QML_FILES)

format-check:
	$(RUFF) format --check src tests packaging
	@for file in $(QML_FILES); do diff -u "$$file" <($(QMLFORMAT) "$$file"); done

lint:
	$(RUFF) check src tests packaging

type-check:
	$(PYRIGHT)

qml-check:
	$(QMLLINT) -W 0 -I src/settimer/ui $(QML_FILES)

test:
	$(PYTHON) -m unittest discover -s tests -v

coverage:
	$(PYTHON) -m coverage run -m unittest discover -s tests
	$(PYTHON) -m coverage report

check: format-check lint type-check qml-check test

package: check
	$(PYTHON) -m PyInstaller --clean --noconfirm SetTimer.spec

clean:
	$(PYTHON) -c "from pathlib import Path; import shutil; [shutil.rmtree(path, ignore_errors=True) for path in (Path('build'), Path('dist'))]"
