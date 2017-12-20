# Dump entire buildbot DB:
# mysqldump --add-drop-table --add-locks  --extended-insert --lock-tables -u buildbot -p -h localhost -P 3306 --protocol tcp buildbot > bck-db-buildbot-$(date +%Y-%m-%d).sql


# Count older commits in next:
SELECT COUNT(*) FROM buildbot.changes where project = 'next' and when_timestamp < unix_timestamp(DATE_SUB(now(), INTERVAL 7 DAY));
# Get rid of them:
DELETE FROM buildbot.changes where project = 'next' and when_timestamp < unix_timestamp(DATE_SUB(now(), INTERVAL 7 DAY));
