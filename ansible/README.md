Copyright (c) 2019-2023 Krzysztof Kozlowski  
Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>  
                            <krzk@kernel.org>

SPDX-License-Identifier: GPL-2.0

# Playbooks

 - buildbot.yml - Buildbot master and build servers (Buildbot workers)
 - pi.yml - DUT boot controller (Buildbot worker)
 - server.yml - Various servers setup
 - var.yml - Uncategorized junk

# Roles

 - buildbot-boot - DUT boot controller Buildbot worker (incomplete)
 - buildbot-builder - build server Buildbot worker (pretty complete)
 - buildbot-git-mirror - grok mirror client on Buildbot master
 - buildbot-upload-dest - unpirivileged user on Buildbot master for uploading
   binaries from the build servers
 - buildbot-worker-docker - Docker-based build server Buildbot worker
   (incomplete, not used)
 - gate - SSH server for reverse proxy tunnels
 - hardened - Generic configuration and hardening of servers
 - mail-forward - Postfix mail server forwarding mail as relay
 - safe-env - Softening of servers, e.g. for trusted environment
 - sshd - SSH server
 - tunnel - SSH reverse-proxy tunnel to the gate
