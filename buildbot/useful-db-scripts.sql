# Copyright (c) 2017-2020 Krzysztof Kozlowski
# Author: Krzysztof Kozlowski <k.kozlowski.k@gmail.com>
#                             <krzk@kernel.org>
#
# SPDX-License-Identifier: GPL-2.0
#

# Dump entire buildbot DB:
# mysqldump --add-drop-table --add-locks  --extended-insert --lock-tables -u buildbot -p -h localhost -P 3306 --protocol tcp buildbot > bck-db-buildbot-$(date +%Y-%m-%d).sql

SELECT COUNT(*),project FROM buildbot.changes GROUP BY project;

# next:
SELECT COUNT(*) FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY))
  AND buildbot.changes.project = 'next';

DELETE buildbot.changes, buildbot.sourcestamps, buildbot.change_files FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY))
  AND buildbot.changes.project = 'next';

# stable and stable-rc
SELECT COUNT(*) FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 90 DAY))
  AND (buildbot.changes.project = 'stable-rc' OR buildbot.changes.project = 'stable');

DELETE buildbot.changes, buildbot.sourcestamps, buildbot.change_files FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 90 DAY))
  AND (buildbot.changes.project = 'stable-rc' OR buildbot.changes.project = 'stable');

# krzk-github
SELECT COUNT(*) FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 180 DAY))
  AND buildbot.changes.project = 'krzk-github';

DELETE buildbot.changes, buildbot.sourcestamps, buildbot.change_files FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 180 DAY))
  AND buildbot.changes.project = 'krzk-github';

# All (so also krzk and mainline):
SELECT COUNT(*) FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 360 DAY));

DELETE buildbot.changes, buildbot.sourcestamps, buildbot.change_files FROM buildbot.changes
LEFT JOIN buildbot.sourcestamps ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
LEFT JOIN buildbot.change_files ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE
  buildbot.changes.when_timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 360 DAY));

# Cleanup after previous deletes:
DELETE buildbot.change_files FROM buildbot.change_files
LEFT JOIN buildbot.changes ON buildbot.changes.changeid = buildbot.change_files.changeid
WHERE buildbot.changes.changeid IS NULL;

DELETE buildbot.sourcestamps FROM buildbot.sourcestamps
LEFT JOIN buildbot.changes ON buildbot.changes.sourcestampid = buildbot.sourcestamps.id
WHERE buildbot.changes.changeid IS NULL;

OPTIMIZE TABLE buildbot.changes, buildbot.sourcestamps, buildbot.change_files;

SELECT COUNT(*),project FROM buildbot.changes GROUP BY project;

# Select pending build requests for specific project:
SELECT buildbot.buildrequests.*, buildbot.buildset_sourcestamps.buildsetid, buildbot.sourcestamps.id, buildbot.sourcestamps.project FROM buildbot.buildrequests
INNER JOIN buildbot.buildset_sourcestamps ON buildbot.buildrequests.buildsetid = buildbot.buildset_sourcestamps.buildsetid
INNER JOIN buildbot.sourcestamps ON buildbot.buildset_sourcestamps.sourcestampid = buildbot.sourcestamps.id
WHERE buildbot.buildrequests.complete = 0
	AND buildbot.sourcestamps.project = "krzk-github";
# And remove them:
DELETE buildbot.buildrequests FROM buildbot.buildrequests
INNER JOIN buildbot.buildset_sourcestamps ON buildbot.buildrequests.buildsetid = buildbot.buildset_sourcestamps.buildsetid
INNER JOIN buildbot.sourcestamps ON buildbot.buildset_sourcestamps.sourcestampid = buildbot.sourcestamps.id
WHERE buildbot.buildrequests.complete = 0
	AND buildbot.sourcestamps.project = "krzk-github";
