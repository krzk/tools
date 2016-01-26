#!/bin/sh
# Non-clean shutdown of Buildbot will leave stale PID
# triggering error on next buildbot startup:
# buildslave[1521]: Can't check status of PID 720 from pidfile /home/buildbot/slaves/slave/twistd.pid: Operation not permitted

test -f /home/buildbot/slaves/slave/twistd.pid && rm /home/buildbot/slaves/slave/twistd.pid
