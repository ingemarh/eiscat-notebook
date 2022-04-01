# Copyright 2021-2022 The MathWorks, Inc.
# Builds Docker image with 
# 1. MATLAB - Using MPM
# 2. MATLAB Integration for Jupyter
# on a base image of jupyter/base-notebook.

## Sample Build Command:
# docker build --build-arg MATLAB_RELEASE=r2021b \
#              --build-arg MATLAB_PRODUCT_LIST="MATLAB Deep_Learning_Toolbox Symbolic_Math_Toolbox"\
#              --build-arg LICENSE_SERVER=12345@hostname.com \
#              -t my_matlab_image_name .

# Specify release of MATLAB to build. (use lowercase, default is r2021b)
ARG MATLAB_RELEASE=r2022a

# Specify the list of products to install into MATLAB, 
ARG MATLAB_PRODUCT_LIST="MATLAB"

# Optional Network License Server information
ARG LICENSE_SERVER

# If LICENSE_SERVER is provided then SHOULD_USE_LICENSE_SERVER will be set to "_use_lm"
#ARG SHOULD_USE_LICENSE_SERVER=${LICENSE_SERVER:+"_with_lm"}
ARG SHOULD_USE_LICENSE_SERVER=${LICENSE_SERVER:+"_use_lm"}

# Default DDUX information
ARG MW_CONTEXT_TAGS=MATLAB_PROXY:JUPYTER:MPM:V1

# Base Jupyter image without LICENSE_SERVER
FROM jupyter/base-notebook AS base_jupyter_image

# Base Jupyter image with LICENSE_SERVER
#FROM jupyter/base-notebook AS base_jupyter_image_with_lm
ARG LICENSE_SERVER
# If license server information is available, then use it to set environment variable
#ENV MLM_LICENSE_FILE=${LICENSE_SERVER}
ENV MLM_LICENSE_FILE=27000@hqserv

# Select base Jupyter image based on whether LICENSE_SERVER is provided
FROM base_jupyter_image${SHOULD_USE_LICENSE_SERVER}
ARG MW_CONTEXT_TAGS
ARG MATLAB_RELEASE
ARG MATLAB_PRODUCT_LIST

# Switch to root user
USER root
ENV DEBIAN_FRONTEND="noninteractive" TZ="Etc/UTC"

## Installing Dependencies for Ubuntu 20.04
# For MATLAB : Get base-dependencies.txt from matlab-deps repository on GitHub
# For mpm : wget, unzip, ca-certificates
# For MATLAB Integration for Jupyter : xvfb

# List of MATLAB Dependencies for Ubuntu 20.04 and specified MATLAB_RELEASE
ARG MATLAB_DEPS_REQUIREMENTS_FILE="https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE}/ubuntu20.04/base-dependencies.txt"

# Install dependencies
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y `wget -qO- ${MATLAB_DEPS_REQUIREMENTS_FILE}`\
    wget \
    unzip \
    ca-certificates \
    xvfb \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Run mpm to install MATLAB in the target location and delete the mpm installation afterwards
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \ 
    chmod +x mpm && \
    ./mpm install \
    --release=${MATLAB_RELEASE} \
    --destination=/opt/matlab \
    --products ${MATLAB_PRODUCT_LIST} && \
    rm -f mpm /tmp/mathworks_root.log && \
    ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab

# Install patched glibc - See https://github.com/mathworks/build-glibc-bz-19329-patch
WORKDIR /packages
RUN export DEBIAN_FRONTEND=noninteractive &&\
    wget -q https://github.com/mathworks/build-glibc-bz-19329-patch/releases/download/ubuntu-focal/all-packages.tar.gz &&\
    tar -x -f all-packages.tar.gz \
    --exclude glibc-*.deb \
    --exclude libc6-dbg*.deb &&\
    apt-get install --yes --no-install-recommends ./*.deb &&\
    rm -fr /packages
WORKDIR /

# Installing MATLAB Engine for Python
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y  python3-distutils \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && cd /opt/matlab/extern/engines/python \
    && python setup.py install



RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install --no-install-recommends -y \
 nano scite vim wget unzip openssh-client git telnet curl unzip \
 bzip2 lbzip2 octave ffmpeg gnuplot-qt fonts-freefont-otf \
 gzip ghostscript libimage-exiftool-perl curl qpdfview \
 gcc libc6-dev libfftw3-3 libgfortran5 \
 dbus-x11 xfce4 xfce4-panel xfce4-session xfce4-settings xorg xubuntu-icon-theme \
 tigervnc-scraping-server tigervnc-xorg-extension \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN cd /opt/matlab/bin/glnxa64 && rm -f libtiff.so.5 libcurl.so.4

# Install pithia tools
RUN cd /tmp && curl -qOJ https://cloud.eiscat.se/s/XGm8jnePJWCwP3A/download && \
    unzip pkg.zip && \
    for i in /tmp/pkg/*deb; do dpkg -i $i && rm $i; done && \
    rm -rf /tmp/pkg*
COPY pkgs/*.m /opt/matlab/toolbox/local/
COPY pkgs/RTG*.m /usr/share/octave/site/m/

#RUN echo "$NB_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$NB_USER \
#    && chmod 0440 /etc/sudoers.d/$NB_USER

ARG TURBOVNC_VERSION=2.2.7
RUN wget -q "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" -O turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get install -y -q ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get remove -y -q light-locker && \
   rm ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   ln -s /opt/TurboVNC/bin/* /usr/local/bin/
RUN chown -R $NB_UID:$NB_GID $HOME
ADD desktop /opt/install
RUN fix-permissions /opt/install



# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Install integration
RUN python -m pip install jupyter-matlab-proxy
RUN python -m pip install octave_kernel
RUN python -m pip install matplotlib numpy
COPY pkgs/*.tar.gz /tmp/
#RUN for i in /tmp/*.tar.gz; do python -m pip install $i && rm $i; done
RUN for i in /tmp/*.tar.gz; do python -m pip install $i; done
ARG OCTAVE_EXECUTABLE=/usr/bin/octave
RUN cd /opt/install && \
   conda env update -n base --file environment.yml

# Ensure jupyter-server-proxy JupyterLab extension is installed
RUN jupyter labextension install @jupyterlab/server-proxy

# Make JupyterLab the default environment
ENV JUPYTER_ENABLE_LAB="yes"

ENV MW_CONTEXT_TAGS=${MW_CONTEXT_TAGS}

