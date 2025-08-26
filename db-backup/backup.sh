#!/usr/bin/env bash
set -eu

TIMESTAMP=$(date +'%Y-%m-%dT%H%M%S')
FILE="${BACKUP_DIR}/${POSTGRES_DB}_${TIMESTAMP}.sql.gz"

echo "[$(date)] → dumping into $FILE"
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
    -h "$POSTGRES_HOST" -U "$POSTGRES_USER" "$POSTGRES_DB" \
    | gzip > "$FILE"

# ------- ретеншн --------
ALL_FILES=($(ls -1t "${BACKUP_DIR}"/*.sql.gz 2>/dev/null || true))
EXTRA=$(( ${#ALL_FILES[@]} - BACKUP_RETENTION_COUNT ))

if [ "$EXTRA" -gt 0 ]; then
  echo "[$(date)] cleaning $EXTRA old backup(s)…"
  for f in "${ALL_FILES[@]: -$EXTRA}"; do
    rm -f "$f"
    echo "  • removed $f"
  done
fi

echo "[$(date)] backup done"
