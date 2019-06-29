ARG FROM_IMG_REGISTRY=docker.io
ARG FROM_IMG_REPO=qnib
ARG FROM_IMG_NAME=uplain-init
ARG FROM_IMG_TAG=xenial-20180726_2018-08-10_18-27
ARG FROM_IMG_HASH=''
FROM ${FROM_IMG_REGISTRY}/${FROM_IMG_REPO}/${FROM_IMG_NAME}:${FROM_IMG_TAG}${DOCKER_IMG_HASH}

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH

COPY fix-permissions /usr/local/bin/fix-permissions
# Create jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN mkdir -p $CONDA_DIR

# Install conda as jovyan and check the md5 sum provided on the download site
ARG MINICONDA_VERSION=4.6.14
ARG MINICONDA_MD5=718259965f234088d785cad1fbd7de03
RUN cd /tmp \
 && wget -q https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
 && echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - \
 && /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR \
 && rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
 && $CONDA_DIR/bin/conda config --system --prepend channels conda-forge \
 && $CONDA_DIR/bin/conda config --system --set auto_update_conda false \
 && $CONDA_DIR/bin/conda config --system --set show_channel_urls true \
 && $CONDA_DIR/bin/conda install --quiet --yes conda="${MINICONDA_VERSION%.*}.*" \
 && $CONDA_DIR/bin/conda update --all --quiet --yes \
 && conda clean -tipsy
# Install Tini
RUN conda install --quiet --yes 'tini=0.18.0' \
 && conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned \
 && conda clean -tipsy

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN mkdir -p /opt/jupyter /notebooks \
 && chmod 777 -R /opt/jupyter/ /notebooks
WORKDIR /opt/jupyter
RUN conda install --yes \
    'notebook=5.7.*' \
    'jupyterlab=0.35.*' \
 && conda clean -tipsy \
 && jupyter lab --generate-config \
 && rm -rf $CONDA_DIR/share/jupyter/lab/staging

USER root

EXPOSE 8888
#WORKDIR $HOME

# Configure container startup
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
RUN fix-permissions /etc/jupyter/
VOLUME /opt/jupyter
RUN mkdir -p /etc/jupyter/lab /.local \
 && chmod 777 -R /etc/jupyter/lab /.local
ENV JUPYTER_CONFIG_DIR=/etc/jupyter/
ENV JUPYTER_RUNTIME_DIR=/opt/jupyter/
ENV JUPYTER_PATH=/opt/jupyter/
#ENV JUPYTERLAB_DIR=/opt/jupyter/
