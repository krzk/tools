# Copyright (c) 2017-2018 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

# Dump entire buildbot DB:
# mysqldump --add-drop-table --add-locks  --extended-insert --lock-tables -u buildbot -p -h localhost -P 3306 --protocol tcp buildbot > bck-db-buildbot-$(date +%Y-%m-%d).sql


# Count older commits in next:
SELECT COUNT(*) FROM buildbot.changes where project = 'next' and when_timestamp < unix_timestamp(DATE_SUB(now(), INTERVAL 7 DAY));
# Get rid of them:
DELETE FROM buildbot.changes where project = 'next' and when_timestamp < unix_timestamp(DATE_SUB(now(), INTERVAL 7 DAY));
