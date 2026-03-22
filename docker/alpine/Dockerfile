# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>
#
# please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

FROM alpine:latest
USER		root
WORKDIR		/root	

RUN apk update

RUN apk add \
	bash \
	git \
	mc \
	tig

# neard:
RUN apk add \
	autoconf \
	autoconf-archive \
	automake \
	binutils \
	gzip \
	tar \
	dbus-dev \
	glib-dev \
	libnl3-dev \
	libtool \
	make \
	musl-dev \
	pkgconfig \
	clang gcc
