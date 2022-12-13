SHELL=/bin/bash -eu -o pipefail


DOCKER_RUN_CMD = docker run python-package-manager-shootout-main
DOCKER_EXEC_CMD = docker exec python-package-manager-shootout-main bash -c

.github/workflows/benchmark.yml: Makefile bin/build_workflow.sh templates/workflow_start.yml templates/workflow_tool.yml templates/workflow_end.yml
	./bin/build_workflow.sh > $@

.PHONY: github-workflow
github-workflow: .github/workflows/benchmark.yml

# random package to benchmark adding a new dependency
PACKAGE := goodconf

.PHONY: pip-clean
pip-clean:
	rm -rf ~/.cache/pip

.PHONY: docker-pre-benchmark
docker-pre-benchmark:
    docker build -t python-package-manager-shootout-main .
    docker run python-package-manager-shootout-main
    $(DOCKER_EXEC_CMD) "bin/actions_prereqs.sh"

TOOLS := poetry
.PHONY: poetry-tooling poetry-import poetry-clean-cache poetry-clean-venv poetry-clean-lock poetry-lock poetry-install poetry-add-package poetry-version poetry-benchmark poetry-stats
poetry-tooling:
	$(DOCKER_EXEC_CMD) "curl -sSL https://install.python-poetry.org | python3 -"
poetry-import:
	$(DOCKER_EXEC_CMD) "cd poetry; poetry add $$(sed -e 's/#.*//' -e '/^$$/ d' < ../requirements.txt)"
poetry-clean-cache: pip-clean
	rm -rf ~/.cache/pypoetry
poetry-clean-venv:
	cd poetry; poetry env remove python || true
poetry-clean-lock:
	rm -f poetry/poetry.lock
poetry-lock:
	cd poetry; poetry lock
poetry-install:
	cd poetry; poetry install
poetry-update:
	cd poetry; poetry update
poetry-add-package:
	cd poetry; poetry add $(PACKAGE)
poetry-version:
	@poetry --version | awk '{print $$3}' | tr -d ')'

poetry-stats:
	VERSION=$($(MAKE) poetry-version)
	CSV=timings/poetry/stats.csv
	MD=timings/poetry/stats.md
	TIMESTAMP=$(date +%s)
	echo "tool,version,timestamp,stat,elapsed time,system,user,cpu percent,max rss,inputs,outputs" > "$CSV"
	for stat in "tooling" "import" "lock" "install-cold" "install-warm" "update" "add-package"; do
	  echo "poetry,$VERSION,$TIMESTAMP,$stat,$(cat timings/poetry/$stat.txt | tr -d '%')" >> "$CSV"
	done
	mdtable "$CSV" >> $MD
poetry-benchmark:
    . ./bin/actions_prereqs.sh
    @time --output=timings/poetry/tooling.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) poetry-tooling
    @time --output=timings/poetry/import.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) poetry-import
    $(MAKE) poetry-clean-cache
    $(MAKE) poetry-clean-venv
    $(MAKE) poetry-clean-lock
    @time --output=timings/poetry/lock.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) poetry-lock
    $(MAKE) poetry-clean-cache
    $(MAKE) poetry-clean-venv
    @time --output=timings/poetry/install-cold.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) poetry-install
    $(MAKE) poetry-clean-venv
    @time --output=timings/poetry/install-warm.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) poetry-install

TOOLS := "$(TOOLS) pdm-582"
.PHONY: pdm-582-tooling pdm-582-import pdm-582-clean-cache pdm-582-clean-venv pdm-582-clean-lock pdm-582-lock pdm-582-install pdm-582-add-package pdm-582-version pdm-582-benchmark pdm-582-stats
pdm-582-tooling:
	curl -sSL https://raw.githubusercontent.com/pdm-project/pdm/main/install-pdm.py | python3 -
pdm-582-import:
	cd pdm; pdm import -f requirements ../requirements.txt
pdm-582-clean-cache: pip-clean
	rm -rf ~/.cache/pdm
pdm-582-clean-venv:
	rm -rf pdm/__pypackages__
	mkdir -p pdm/__pypackages__
pdm-582-clean-lock:
	rm -f pdm/pdm.lock
pdm-582-lock:
	cd pdm; pdm lock
pdm-582-install:
	cd pdm; pdm install
pdm-582-update:
	cd pdm; pdm update
pdm-582-add-package:
	cd pdm; pdm add $(PACKAGE)
pdm-582-version:
	@pdm --version | awk '{print $$3}'

pdm-582-stats:
    VERSION=$($(MAKE) pdm-582-version)
    CSV=timings/pdm-582/stats.csv
    MD=timings/pdm-582/stats.md
    TIMESTAMP=$(date +%s)
    echo "tool,version,timestamp,stat,elapsed time,system,user,cpu percent,max rss,inputs,outputs" > "$CSV"
    for stat in "tooling" "import" "lock" "install-cold" "install-warm" "update" "add-package"; do
      echo "pdm-582,$VERSION,$TIMESTAMP,$stat,$(cat timings/pdm-582/$stat.txt | tr -d '%')" >> "$CSV"
    done
    mdtable "$CSV" >> $MD
pdm-582-benchmark:
    . ./bin/actions_prereqs.sh
    @time --output=timings/pdm-582/tooling.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-582-tooling
    @time --output=timings/pdm-582/import.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-582-import
    $(MAKE) pdm-582-clean-cache
    $(MAKE) pdm-582-clean-venv
    $(MAKE) pdm-582-clean-lock
    @time --output=timings/pdm-582/lock.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-582-lock
    $(MAKE) pdm-582-clean-cache
    $(MAKE) pdm-582-clean-venv
    @time --output=timings/pdm-582/install-cold.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-582-install
    $(MAKE) pdm-582-clean-venv
    @time --output=timings/pdm-582/install-warm.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-582-install
    $(MAKE) pdm-582-stats

TOOLS := "$(TOOLS) pdm-venv"
.PHONY: pdm-venv-tooling pdm-venv-import pdm-venv-clean-cache pdm-venv-clean-venv pdm-venv-clean-lock pdm-venv-lock pdm-venv-install pdm-venv-add-package pdm-venv-version pdm-venv-benchmark pdm-venv-stats
pdm-venv-tooling:
	curl -sSL https://raw.githubusercontent.com/pdm-project/pdm/main/install-pdm.py | python3 -
pdm-venv-import:
	cd pdm; pdm import -f requirements ../requirements.txt
pdm-venv-clean-cache: pip-clean
	rm -rf ~/.cache/pdm
pdm-venv-clean-venv:
	rm -rf pdm/__pypackages__
	cd pdm; pdm venv purge
pdm-venv-clean-lock:
	rm -f pdm/pdm.lock
pdm-venv-lock:
	cd pdm; pdm lock
pdm-venv-install:
	cd pdm; pdm install
pdm-venv-update:
	cd pdm; pdm update
pdm-venv-add-package:
	cd pdm; pdm add $(PACKAGE)
pdm-venv-version:
	@pdm --version | awk '{print $$3}'

pdm-venv-stats:
    VERSION=$($(MAKE) pdm-venv-version)
    CSV=timings/pdm-venv/stats.csv
    MD=timings/pdm-venv/stats.md
    TIMESTAMP=$(date +%s)
    echo "tool,version,timestamp,stat,elapsed time,system,user,cpu percent,max rss,inputs,outputs" > "$CSV"
    for stat in "tooling" "import" "lock" "install-cold" "install-warm" "update" "add-package"; do
      echo "pdm-venv,$VERSION,$TIMESTAMP,$stat,$(cat timings/pdm-venv/$stat.txt | tr -d '%')" >> "$CSV"
    done
    mdtable "$CSV" >> $MD
pdm-venv-benchmark:
    . ./bin/actions_prereqs.sh
    @time --output=timings/pdm-venv/tooling.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-venv-tooling
    @time --output=timings/pdm-venv/import.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-venv-import
    $(MAKE) pdm-venv-clean-cache
    $(MAKE) pdm-venv-clean-venv
    $(MAKE) pdm-venv-clean-lock
    @time --output=timings/pdm-venv/lock.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-venv-lock
    $(MAKE) pdm-venv-clean-cache
    $(MAKE) pdm-venv-clean-venv
    @time --output=timings/pdm-venv/install-cold.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-venv-install
    $(MAKE) pdm-venv-clean-venv
    @time --output=timings/pdm-venv/install-warm.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pdm-venv-install
    $(MAKE) pdm-venv-stats

TOOLS := "$(TOOLS) pipenv"
.PHONY: pipenv-tooling pipenv-import pipenv-clean-cache pipenv-clean-venv pipenv-clean-lock pipenv-lock pipenv-install pipenv-add-package pipenv-version pipenv-benchmark pipenv-stats
pipenv-tooling:
	pip install --user pipenv
pipenv-import:
	cd pipenv; pipenv install -r ../requirements.txt
pipenv-clean-cache: pip-clean
	rm -rf ~/.cache/pipenv
pipenv-clean-venv:
	cd pipenv; rm -rf $$(pipenv --venv || echo "./does-not-exist")
pipenv-clean-lock:
	rm -f pipenv/Pipfile.lock
pipenv-lock:
	cd pipenv; pipenv lock
pipenv-install:
	cd pipenv; pipenv sync
pipenv-update:
	cd pipenv; pipenv update
pipenv-add-package:
	cd pipenv; pipenv install $(PACKAGE)
pipenv-version:
	@pipenv --version | awk '{print $$3}'

pipenv-stats:
    VERSION=$($(MAKE) pipenv-version)
    CSV=timings/pipenv/stats.csv
    MD=timings/pipenv/stats.md
    TIMESTAMP=$(date +%s)
    echo "tool,version,timestamp,stat,elapsed time,system,user,cpu percent,max rss,inputs,outputs" > "$CSV"
    for stat in "tooling" "import" "lock" "install-cold" "install-warm" "update" "add-package"; do
      echo "pipenv,$VERSION,$TIMESTAMP,$stat,$(cat timings/pipenv/$stat.txt | tr -d '%')" >> "$CSV"
    done
    mdtable "$CSV" >> $MD
pipenv-benchmark:
    . ./bin/actions_prereqs.sh
    @time --output=timings/pipenv/tooling.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pipenv-tooling
    @time --output=timings/pipenv/import.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pipenv-import
    $(MAKE) pipenv-clean-cache
    $(MAKE) pipenv-clean-venv
    $(MAKE) pipenv-clean-lock
    @time --output=timings/pipenv/lock.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pipenv-lock
    $(MAKE) pipenv-clean-cache
    $(MAKE) pipenv-clean-venv
    @time --output=timings/pipenv/install-cold.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pipenv-install
    $(MAKE) pipenv-clean-venv
    @time --output=timings/pipenv/install-warm.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pipenv-install
    $(MAKE) pipenv-stats

TOOLS := "$(TOOLS) pip-tools"
.PHONY: pip-tools-tooling pip-tools-import pip-tools-clean-cache pip-tools-clean-venv pip-tools-clean-lock pip-tools-lock pip-tools-install pip-tools-add-package pip-tools-version pip-tools-benchmark pip-tools-stats
pip-tools-tooling:
	pip install --user pip-tools
pip-tools-import:
	cat requirements.txt
pip-tools-clean-cache: pip-clean
	rm -rf ~/.cache/pip-tools
pip-tools-clean-venv:
	rm -rf pip-tools/.venv
pip-tools-clean-lock:
	rm -f pip-tools/requirements.txt
pip-tools-lock:
	pip-compile --generate-hashes --output-file=pip-tools/requirements.txt requirements.txt
pip-tools-install:
	test -f pip-tools/.venv/bin/python || python -m venv --upgrade-deps pip-tools/.venv
	test -f pip-tools/.venv/bin/wheel || ./pip-tools/.venv/bin/python -m pip install -U wheel
	pip-sync --python-executable=./pip-tools/.venv/bin/python pip-tools/requirements.txt
pip-tools-update:
	pip-compile --generate-hashes --output-file=pip-tools/requirements.txt requirements.txt
	pip-sync --python-executable=./pip-tools/.venv/bin/python pip-tools/requirements.txt
pip-tools-add-package:
	echo $(PACKAGE) >> requirements.txt
	$(MAKE) pip-tools-lock pip-tools-install
pip-tools-version:
	@pip-compile --version | awk '{print $$3}'

pip-tools-stats:
    VERSION=$($(MAKE) pip-tools-version)
    CSV=timings/pip-tools/stats.csv
    MD=timings/pip-tools/stats.md
    TIMESTAMP=$(date +%s)
    echo "tool,version,timestamp,stat,elapsed time,system,user,cpu percent,max rss,inputs,outputs" > "$CSV"
    for stat in "tooling" "import" "lock" "install-cold" "install-warm" "update" "add-package"; do
      echo "pip-tools,$VERSION,$TIMESTAMP,$stat,$(cat timings/pip-tools/$stat.txt | tr -d '%')" >> "$CSV"
    done
    mdtable "$CSV" >> $MD
pip-tools-benchmark:
    . ./bin/actions_prereqs.sh
    @time --output=timings/pip-tools/tooling.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pip-tools-tooling
    @time --output=timings/pip-tools/import.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pip-tools-import
    $(MAKE) pip-tools-clean-cache
    $(MAKE) pip-tools-clean-venv
    $(MAKE) pip-tools-clean-lock
    @time --output=timings/pip-tools/lock.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pip-tools-lock
    $(MAKE) pip-tools-clean-cache
    $(MAKE) pip-tools-clean-venv
    @time --output=timings/pip-tools/install-cold.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pip-tools-install
    $(MAKE) pip-tools-clean-venv
    @time --output=timings/pip-tools/install-warm.txt --format="%e,%S,%U,%P,%M,%I,%O" $(MAKE) pip-tools-install
    $(MAKE) pip-tools-stats

.PHONY: tools
tools:
	@echo $(TOOLS)
