# Copyright (c) 2017-2019 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

# Dump entire buildbot DB:
# mysqldump --add-drop-table --add-locks  --extended-insert --lock-tables -u buildbot -p -h localhost -P 3306 --protocol tcp buildbot > bck-db-buildbot-$(date +%Y-%m-%d).sql


# Count older commits in next:
SELECT * FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY))
  AND buildbot.changes.project = 'next';

# Get rid of them:
DELETE buildbot.changes, buildbot.sourcestamps, buildbot.change_files FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY))
  AND buildbot.changes.project = 'next';

DELETE buildbot.change_files FROM buildbot.change_files
LEFT JOIN buildbot.changes ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE buildbot.changes.changeid IS NULL

DELETE buildbot.sourcestamps FROM buildbot.sourcestamps
LEFT JOIN buildbot.changes ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
WHERE buildbot.changes.changeid IS NULL

OPTIMIZE TABLE buildbot.changes, buildbot.sourcestamps, buildbot.change_files
