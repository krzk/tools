# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>
#
# please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

FROM docker.io/library/debian:13
LABEL org.opencontainers.image.authors="Krzysztof Kozlowski <krzk@kernel.org>"

USER		root
WORKDIR		/root

ARG		DEBIAN_FRONTEND=noninteractive

RUN echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/99norecommends
RUN echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/99norecommends

# Install security updates and required packages
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install -q \
        build-essential \
        git \
        python3-dev \
        python3-pip \
        libffi-dev \
        libssl-dev \
        curl \
        mc \
        unattended-upgrades \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y locales \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && localedef -i en_GB -c -f UTF-8 -A /usr/share/locale/locale.alias en_GB.UTF-8

ENV LANG=en_US.UTF-8

COPY 51unattended-upgrades-custom /etc/apt/apt.conf.d/51unattended-upgrades-custom

# Kernel
RUN apt-get update \
    && apt-get install -y \
        bc \
        bison \
        ccache \
        clang \
        diffutils \
        dwarves \
        flex \
        gcc-arm-linux-gnueabi \
        gcc-aarch64-linux-gnu \
        gcc-powerpc64-linux-gnu \
        gcc-riscv64-linux-gnu \
        gcc-s390x-linux-gnu \
        gcc-sparc64-linux-gnu \
        # For depmod / `make modules_install` \
        kmod \
        libelf-dev \
        libkeyutils-dev \
        libssl-dev \
        lld \
        llvm

RUN apt-get update \
    && apt-get install -y \
        chrpath \
        cpio \
        diffstat \
        file \
        gawk \
        lz4 \
        patch \
        psmisc \
        texinfo \
	tig \
        wget \
        zstd

# neard
RUN apt-get update \
    && apt-get install -y \
	autoconf \
	autoconf-archive \
	automake \
	libdbus-1-dev \
	libglib2.0-dev \
	libnl-3-dev \
	libnl-genl-3-dev \
	libtool

RUN cp /etc/skel/.bashrc /etc/skel/.profile .

COPY .bash_aliases .
ADD https://raw.githubusercontent.com/krzk/tools/refs/heads/master/linux/.bash_aliases_linux .
