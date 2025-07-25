FROM ubuntu:24.04
ARG SWAN_VER
ENV VERSION=$SWAN_VER

RUN \
  # install packages
  DEV_PACKAGES="wget bzip2 make gcc libssl-dev libgmp-dev" && \
  apt-get -y update && \
  apt-get -y install gettext-base iproute2 iputils-ping nano tcpdump curl yq $DEV_PACKAGES && \
  \
  # download and build strongSwan IKEv2 daemon
  mkdir /strongswan-build && \
  cd /strongswan-build && \
  wget https://download.strongswan.org/strongswan-$VERSION.tar.bz2 && \
  tar xfj strongswan-$VERSION.tar.bz2 && \
  cd strongswan-$VERSION && \
  ./configure --prefix=/usr/local && \
   make all && make install && \
   cd / && rm -R strongswan-build && \
   ln -s /usr/local/libexec/ipsec/charon charon && \
   \
   # clean up
   mkdir -p /etc/swanctl && \
   apt-get -y remove $DEV_PACKAGES && \
   apt-get -y autoremove && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/*

# Copy local files to the image
COPY ./files/ ./

# Expose IKE and NAT-T ports
EXPOSE 500 4500

ENTRYPOINT ["/docker-entrypoint.sh"]
