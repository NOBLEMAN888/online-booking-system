#!/usr/bin/env sh
set -eu

# Записываем cron-файл. Логи уходят в stdout → можно смотреть docker logs
echo "${BACKUP_INTERVAL_CRON} /backup/backup.sh >> /proc/1/fd/1 2>&1" \
  > /etc/crontabs/root

echo "⏰ Cron job installed: ${BACKUP_INTERVAL_CRON}"
echo "📦 Retention: ${BACKUP_RETENTION_COUNT} files"

exec crond -f -l 8   # -f = foreground, чтобы контейнер не выходил
