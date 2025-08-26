#!/bin/bash

postgres_db="${POSTGRES_DB:-postgres}"
postgres_user="${POSTGRES_USER:-postgres}"
db="${DB_NAME:-booking_db}"
admin_user="${DB_ADMIN_USER:-adminuser}"
admin_password="${DB_ADMIN_PASSWORD:-adminpassword}"
db_host="${POSTGRES_HOST:-haproxy}"
db_port="${POSTGRES_PORT:-5000}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

MAX_RETRIES=30
for i in $(seq 1 $MAX_RETRIES); do
  pg_isready -h "$db_host" -p "$db_port" -U "$postgres_user" && break || sleep 2
  if [ "$i" -eq "$MAX_RETRIES" ]; then
    exit 1
  fi
done

if ! psql -h "$db_host" -p "$db_port" -U "$postgres_user" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$admin_user'" | grep -q 1; then
  psql -h "$db_host" -p "$db_port" -U "$postgres_user" -c "CREATE USER \"$admin_user\" WITH CREATEDB PASSWORD '$admin_password';" || { echo "Ошибка создания пользователя"; exit 1; }
fi
if ! psql -h "$db_host" -p "$db_port" -U "$postgres_user" -tAc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1; then
  psql -h "$db_host" -p "$db_port" -U "$postgres_user" -c "CREATE DATABASE \"$db\" WITH OWNER \"$admin_user\";" || { echo "Ошибка создания БД"; exit 1; }
fi

psql -h "$db_host" -p "$db_port" -U "$postgres_user" -d "$db" <<-EOSQL
    GRANT ALL ON SCHEMA public TO "$admin_user";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "$admin_user";
EOSQL