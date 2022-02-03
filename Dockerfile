##FROM mathworks/matlab-deps as prebuilder
#LABEL  MAINTAINER=EISCAT
####USER root
####WORKDIR /root
ARG MATLAB_RELEASE=r2021b
FROM mathworks/matlab-deps:latest
ARG MATLAB_RELEASE
# install docker and eiscat tools
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && \
    apt-get install --no-install-recommends --yes \
        vim wget unzip \
 bzip2 lbzip2 octave ffmpeg \
 gzip ghostscript libimage-exiftool-perl curl \
 gcc libc6-dev libfftw3-3 libgfortran5 \
 python3 python3-pip python3-matplotlib \
        ca-certificates && \
    apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

#ADD matlab_installer_input.txt /matlab_installer_input.txt

# Now install MATLAB (make sure that the install script is executable)
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \ 
    chmod +x mpm && \
    ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=/opt/matlab \
        --products MATLAB && \
    rm -f mpm /tmp/mathworks_root.log

# Add a script to start MATLAB and soft link into /usr/local/bin
ADD startmatlab.sh /opt/startscript/
RUN chmod +x /opt/startscript/startmatlab.sh && \
    ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab

RUN cd /opt/matlab/bin/glnxa64 && rm -f libtiff.so.5 libcurl.so.4

ADD pkgs/*.deb /tmp/
RUN for i in /tmp/*deb; do dpkg -i $i && rm $i; done
COPY pkgs/*.tar.gz /tmp/
RUN for i in /tmp/*.tar.gz; do pip install $i && rm $i; done

# Add a user other than root to run MATLAB
RUN useradd -ms /bin/bash medusa
# Add bless that user with sudo powers
RUN echo "medusa ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/medusa \
    && chmod 0440 /etc/sudoers.d/medusa

# One of the following 2 ways of configuring the FlexLM server to use must be
# uncommented.

ARG LICENSE_SERVER
# Specify the host and port of the machine that serves the network licenses 
# if you want to bind in the license info as an environment variable. This 
# is the preferred option for licensing. It is either possible to build with 
# something like --build-arg LICENSE_SERVER=27000@MyServerName, alternatively
# you could specify the license server directly using
ENV MLM_LICENSE_FILE=27000@hqserv
#ENV MLM_LICENSE_FILE=$LICENSE_SERVER

# Alternatively you can put a license file (or license information) into the 
# container. You should fill this file out with the details of the license 
# server you want to use and uncomment the following line.
# ADD network.lic /usr/local/MATLAB/licenses/
   
USER medusa
WORKDIR /home/medusa
RUN mkdir /home/medusa/gup
RUN mkdir /home/medusa/gup/mygup /home/medusa/gup/results
ENV DISPLAY :0

#ENTRYPOINT ["/opt/startscript/startmatlab.sh"]
ENTRYPOINT ["/usr/bin/bash"]
#ENTRYPOINT ["/usr/bin/guisdap"]
#ENTRYPOINT ["/usr/bin/rtg -o"]
#ENTRYPOINT ["/usr/bin/python3"]
