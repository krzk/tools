# Copyright (c) 2021 Canonical Ltd.
# Author: Krzysztof Kozlowski <krzysztof.kozlowski@canonical.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0

TARGET = port100_send_frame_async

CC = $(CROSS_COMPILE)gcc
CFLAGS = -g -Wall -Wextra
LDFLAGS = -lpthread

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $(TARGET) $(TARGET).c $(LDFLAGS)

clean:
	$(RM) $(TARGET)
