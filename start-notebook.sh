#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -ex

: "${JUPYTER_BASE_URL:=/}"

echo ">> PWD: $(pwd)"
if [[ "X${JUPYTER_API_TOKEN}" != X ]]; then
  # launched by JupyterHub, use single-user entrypoint
  jupyter lab --debug --allow-root \
          --config=/etc/jupyter/jupyter_notebook_config.py \
          --NotebookApp.base_url=${JUPYTER_BASE_URL} \
          --NotebookApp.token=${JUPYTER_API_TOKEN} \
          --NotebookApp.allow_origin="*" \
          --ip=0.0.0.0 $*
else
  if [[ "X${JUPYTER_ENABLE_LAB}" != "X" ]]; then
    . /usr/local/bin/start.sh jupyter lab $*
  else
    . /usr/local/bin/start.sh jupyter lab --allow-root \
          --config=/etc/jupyter/jupyter_notebook_config.py \
          --NotebookApp.base_url=${JUPYTER_BASE_URL} $*
  fi
fi
