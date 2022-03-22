# Jupyter with EISCAT tools
# Argument shared across multi-stage build to hold location of installed MATLAB 
ARG BASE_ML_INSTALL_LOC=/tmp/matlab-install-location

# MATLAB should be available on the path in the Docker image
#FROM mathworks/matlab:r2021b AS matlab-install-stage
FROM mathworks/matlab AS matlab-install-stage
ARG BASE_ML_INSTALL_LOC

# Run code to locate a MATLAB install in the base image and softlink
# to BASE_ML_INSTALL_LOC for a latter stage to copy 
RUN export ML_INSTALL_LOC=$(which matlab) \
    && if [ ! -z "$ML_INSTALL_LOC" ]; then \
        ML_INSTALL_LOC=$(dirname $(dirname $(readlink -f ${ML_INSTALL_LOC}))); \
        echo "soft linking: " $ML_INSTALL_LOC " to" ${BASE_ML_INSTALL_LOC}; \
        ln -s ${ML_INSTALL_LOC} ${BASE_ML_INSTALL_LOC}; \
    elif [ $BASE_ML_INSTALL_LOC = '/tmp/matlab-install-location' ]; then \
        echo "MATLAB was not found in your image."; exit 1; \
    else \
        echo "Proceeding with user provided path to MATLAB installation: ${BASE_ML_INSTALL_LOC}"; \
    fi

# name your environment and choose the python version
FROM jupyter/base-notebook

ARG BASE_ML_INSTALL_LOC

# Switch to root user
USER root

# Copy MATLAB install from supplied Docker image
COPY --from=matlab-install-stage ${BASE_ML_INSTALL_LOC} /usr/local/MATLAB

# Put MATLAB on the PATH
RUN ln -s /usr/local/MATLAB/bin/matlab /usr/local/bin/matlab

## Install MATLAB dependencies
# Please update this list for the version of MATLAB you are using.
# Listed below are the dependencies of R2021b for Ubuntu 20.04
# Reference: https://github.com/mathworks-ref-arch/container-images/tree/master/matlab-deps/r2021b
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libc6 \
    libcairo-gobject2 \
    libcairo2 \
    libcap2 \
    libcrypt1 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libfontconfig1 \
    libgbm1 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libgomp1 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer1.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libodbc1 \
    libpam0g \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpangoft2-1.0-0 \
    libpython3.9 \
    libsm6 \
    libsndfile1 \
    libssl1.1 \
    libuuid1 \
    libx11-6 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxft2 \
    libxi6 \
    libxinerama1 \
    libxrandr2 \
    libxrender1 \
    libxt6 \
    libxtst6 \
    libxxf86vm1 \
    locales \
    locales-all \
    make \
    net-tools \
    procps \
    sudo \
    unzip \
    zlib1g \
 vim wget unzip openssh-client git telnet curl unzip \ 
 bzip2 lbzip2 octave ffmpeg gnuplot-qt fonts-freefont-otf \
 gzip ghostscript libimage-exiftool-perl curl \
 gcc libc6-dev libfftw3-3 libgfortran5 \
 python3 python3-pip python3-matplotlib python3-numpy \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

#RUN apt-get install update-manager-core && do-release-upgrade -d

RUN cd /usr/local/MATLAB/bin/glnxa64 && rm -f libtiff.so.5 libcurl.so.4

# Install pithia tools
#ADD pkgs/*.deb /tmp/
RUN cd /tmp && curl -qOJ https://cloud.eiscat.se/s/XGm8jnePJWCwP3A/download && \
    unzip pkg.zip && \
    for i in /tmp/pkg/*deb; do dpkg -i $i && rm $i; done && \
    rm -rf /tmp/pkg*
COPY pkgs/*.tar.gz /tmp/
RUN for i in /tmp/*.tar.gz; do pip install $i && rm $i; done
COPY pkgs/*.tar.gz /tmp/
RUN for i in /tmp/*.tar.gz; do pip install $i && rm $i; done

# Install jupyter-matlab-proxy dependencies
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install --yes \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "$NB_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$NB_USER \
    && chmod 0440 /etc/sudoers.d/$NB_USER

# Switch back to notebook user
USER $NB_USER

# Install integrations
RUN python -m pip install jupyter-matlab-proxy
RUN pip install octave_kernel
RUN pip install matplotlib numpy
ARG OCTAVE_EXECUTABLE=/usr/bin/octave
WORKDIR /home/$NB_USER

# Ensure jupyter-server-proxy JupyterLab extension is installed
RUN jupyter labextension install @jupyterlab/server-proxy

ENV MLM_LICENSE_FILE=27000@hqserv

# Alternatively you can put a license file (or license information) into the 
# container. You should fill this file out with the details of the license 
# server you want to use and uncomment the following line.
# ADD network.lic /usr/local/MATLAB/licenses/
   
RUN git clone https://github.com/ingemarh/lpgen.git
RUN mkdir /home/$NB_USER/tmp /home/$NB_USER/gup
RUN mkdir /home/$NB_USER/gup/mygup /home/$NB_USER/gup/results
COPY pkgs/*.m /usr/local/MATLAB/toolbox/local
COPY pkgs/RTG.m /home/$NB_USER/work/

#ENTRYPOINT ["/usr/bin/bash"]
#ENTRYPOINT ["/usr/bin/guisdap"]
#ENTRYPOINT ["/usr/bin/rtg -o"]
#ENTRYPOINT ["/usr/bin/python3"]
