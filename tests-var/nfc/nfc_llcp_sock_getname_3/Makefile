# Copyright (c) 2021 Canonical Ltd.
# Author: Krzysztof Kozlowski <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0

TARGET = llcp_sock_getname

CC = $(CROSS_COMPILE)gcc
CFLAGS = -g -Wall -Wextra
LDFLAGS =

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $(TARGET) $(TARGET).c $(LDFLAGS)

clean:
	$(RM) $(TARGET)
