# syntax=docker/dockerfile:1.3
ARG PYTHON_VERSION=3.9
FROM python:${PYTHON_VERSION}-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install base dependencies
RUN apt-get update -y -q && \
    apt-get install -y --no-install-recommends \
    git \
    build-essential \
    time \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

FROM base as poetry

CMD ["make" "poetry-benchmark"]

FROM base as pdm-582

CMD ["make" "pdm-582-benchmark"]

FROM base as pdm-venv

CMD ["make" "pdm-venv-benchmark"]

FROM base as pipenv

CMD ["make" "pipenv-benchmark"]

FROM base as pip-tools

CMD ["make" "pip-tools-benchmark"]
