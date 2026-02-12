Copyright (c) 2019-2026 Krzysztof Kozlowski
Author: Krzysztof Kozlowski <krzk@kernel.org>

SPDX-License-Identifier: GPL-2.0

# Playbooks

 - buildbot.yml - Buildbot master and build servers (Buildbot workers)
 - pi.yml - DUT boot controller (Buildbot worker)
 - server.yml - Various servers setup
 - var.yml - Uncategorized junk

# Roles

 - buildbot-boot - DUT boot controller Buildbot worker (incomplete)
 - buildbot-build-storage - Intranet machine service build artifacts to DUT boot controllers over lighttpd
 - buildbot-builder - build server Buildbot worker (pretty complete)
 - buildbot-git-mirror - grok mirror client on Buildbot master and workers
 - buildbot-upload-dest - unpirivileged user on Buildbot master for uploading
   binaries from the build servers
 - gate - SSH server for reverse proxy tunnels
 - hardened - Generic configuration and hardening of servers
 - mail-forward - Postfix mail server forwarding mail as relay
 - safe-env - Softening of build machines, e.g. for trusted environment
 - sshd - SSH server
 - tunnel - SSH reverse-proxy tunnel to the gate
