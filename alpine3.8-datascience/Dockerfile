FROM alpine:3.8.4 AS openrc
RUN mkdir -p /lib/apk/db /run
RUN apk add --no-cache --initdb openrc

FROM alpine:3.8.4 AS kernel
RUN mkdir -p /lib/apk/db /run
RUN apk add --no-cache --initdb linux-virt

FROM alpine:3.8.4 AS install
USER root
# the public key that is authorized to connect to this instance.
ARG SSHPUBKEY
# optional packages
ARG PKGS

# don't want all the /etc stuff from openrc -- only tools
# https://pkgs.alpinelinux.org/contents?repo=main&page=2&arch=x86_64&branch=v3.8&name=openrc
COPY --from=openrc /lib/ /lib/
COPY --from=openrc /bin /bin
COPY --from=openrc /sbin /sbin
COPY --from=openrc /etc/ /etc/

# Need virtio modules for networking
COPY --from=kernel /lib/modules /lib/modules

# Copy kernel for later use
COPY --from=kernel /boot/vmlinuz-virt /vmlinuz

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/community" >> /etc/apk/repositories
RUN mkdir -p /lib/apk/db /run
RUN apk add --update --no-cache --initdb alpine-baselayout apk-tools busybox ca-certificates util-linux \
    openssh openssh-client rng-tools dhcpcd

RUN [ ! -z "$PKGS" ] && apk add --no-cache $PKGS || echo "No optional pkgs provided."

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# R runtime dependencies
RUN apk --no-cache add --virtual make-deps \
        gcc \
        gfortran \
        g++ \
        make \
        readline-dev \
        icu-dev \
        bzip2-dev \
        xz-dev \
        pcre-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        tiff-dev  \
        curl-dev \
        zip \
        file \
        coreutils \
        bash && \
# R build dependencies
    apk --no-cache add --virtual build-deps \
        curl \
        perl \
        openjdk8-jre-base \
        pango-dev \
        cairo-dev \
        tcl-dev \
        tk-dev && \
    cd /tmp && \
# Download source code
    curl -O https://stat.ethz.ch/R/daily/R-devel.tar.gz && \
# Extract source code
    tar -xf R-devel.tar.gz && \
    cd R-devel && \
# Sect compiler flags
    CFLAGS="-g -O2 -fstack-protector-strong -D_DEFAULT_SOURCE -D__USE_MISC" \
    CXXFLAGS="-g -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -D__MUSL__" \
# configure script options
    ./configure --prefix=/usr \
                --sysconfdir=/etc/R \
                --localstatedir=/var \
                rdocdir=/usr/share/doc/R \
                rincludedir=/usr/include/R \
                rsharedir=/usr/share/R \
                --disable-nls \
                --without-x \
                --without-recommended-packages \
                --enable-memory-profiling \
                --enable-R-shlib && \
# Build and install R
    make && \
    make install && \
    cd src/nmath/standalone && \
    make && \
    make install && \
# Fis library path
    echo "R_LIBS_SITE=\${R_LIBS_SITE-'/usr/local/lib/R/site-library:/usr/lib/R/library'}" >> /usr/lib/R/etc/Renviron && \
# Add default CRAN mirror
    echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"))' >> /usr/lib/R/etc/Rprofile.site && \
# Add symlinks for the config ifile in /etc/R
    mkdir -p /etc/R && \
    ln -s /usr/lib/R/etc/* /etc/R/ && \
# Add library directory
    mkdir -p /usr/local/lib/R/site-library && \
    chgrp users /usr/local/lib/R/site-library

ENV APKGS libxml2-dev
ENV RPKGS tidyverse data.table

RUN apk --no-cache add ${APKGS} && \
    Rscript -e 'install.packages(commandArgs(TRUE))' ${RPKGS}

# Remove build dependencies
RUN apk del --purge --rdepends build-deps make-deps && \
    rm -f /usr/lib/R/bin/R && \
    ln -s /usr/bin/R /usr/lib/R/bin/R && \
# Clean up
    rm -rf /usr/lib/R/library/translations && \
    rm -rf /tmp/*


# Deleted cached packages
RUN rm -rf /var/cache/apk/*

# Our local files
COPY files/init /init

RUN echo "RNGD_OPTS=\"-f -r /dev/urandom\"" > /etc/conf.d/rngd
RUN echo "Welcome to slim!" > /etc/motd
RUN echo "ttyS0" >> /etc/securetty
RUN echo "ttyS0::respawn:/sbin/agetty -a root -L ttyS0 115200 vt100" > /etc/inittab

# Set an ssh key
RUN mkdir -p /etc/ssh /root/.ssh && chmod 0700 /root/.ssh
RUN echo $SSHPUBKEY > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

# Fix ssh
RUN sed -i 's/root:!/root:*/' /etc/shadow