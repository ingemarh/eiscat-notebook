FROM ubuntu:21.10
LABEL  MAINTAINER=EISCAT

# To avoid inadvertently polluting the / directory, use root's home directory 
USER root
WORKDIR /root

# install eiscat tools
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install --no-install-recommends -y \
 sudo vim wget \
 bzip2 lbzip2 octave ffmpeg \
 gcc libc6-dev libfftw3-3 libgfortran5 \
 python3 python3-pip python3-matplotlib \
 && apt-get clean \
 && apt-get -y autoremove \
 && rm -rf /var/lib/apt/lists/*

ADD pkgs/*.deb /tmp/
RUN for i in /tmp/*deb; do dpkg -i $i && rm $i; done
COPY pkgs/*.tar.gz /tmp/
RUN for i in /tmp/*.tar.gz; do pip install $i && rm $i; done

# Add a user other than root
RUN useradd -ms /bin/bash medusa
# Add bless that user with sudo powers
RUN echo "medusa ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/medusa \
    && chmod 0440 /etc/sudoers.d/medusa

USER medusa
WORKDIR /home/medusa
RUN mkdir /home/medusa/gup
RUN mkdir /home/medusa/gup/mygup /home/medusa/gup/results
ENV DISPLAY :0

ENTRYPOINT ["/usr/bin/bash"]
#ENTRYPOINT ["/usr/bin/rtg -o"]
#ENTRYPOINT ["/usr/bin/python3"]
