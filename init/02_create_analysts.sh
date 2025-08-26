#!/bin/bash

postgres_db="$DB_NAME"
postgres_user="$POSTGRES_USER"
analytic_role="analytic"
analyst_users="$ANALYST_NAMES"
db_host="${POSTGRES_HOST:-haproxy}"
db_port="${POSTGRES_PORT:-5000}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

if [[ -z "$postgres_db" || -z "$postgres_user" || -z "$analyst_users" ]]; then
  exit 1
fi

role_exists=$(psql -h "$db_host" -p "$db_port" -U "$postgres_user" -d "$postgres_db" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$analytic_role'")
if [[ -z "$role_exists" ]]; then
  psql -h "$db_host" -p "$db_port" -U "$postgres_user" -d "$postgres_db" -c "CREATE ROLE \"$analytic_role\" NOINHERIT NOLOGIN;" || { exit 1; }
fi

psql -h "$db_host" -p "$db_port" -U "$postgres_user" -d "$postgres_db" <<-EOSQL
    GRANT USAGE ON SCHEMA public TO "$analytic_role";
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$analytic_role";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$analytic_role";
EOSQL
if [[ $? -ne 0 ]]; then
  exit 1
fi

IFS=',' read -ra analyst_array <<< "$analyst_users"

for analyst in "${analyst_array[@]}"; do
  user_exists=$(psql -h "$db_host" -p "$db_port" -U "$postgres_user" -d "$postgres_db" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$analyst'")
  if [[ ! -z "$user_exists" ]]; then
    continue
  fi

  password="${analyst}_123"
  psql -h "$db_host" -p "$db_port" -U "$postgres_user" -d "$postgres_db" -c \
    "CREATE USER \"$analyst\" WITH PASSWORD '$password' IN ROLE \"$analytic_role\";" \
  || { exit 1; }
done