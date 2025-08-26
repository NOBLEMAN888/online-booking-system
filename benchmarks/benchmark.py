import os, time, hashlib, psycopg2, sqlparse
from prometheus_client import Summary, Gauge, start_http_server
import re, hashlib

name_re = re.compile(r"^\s*(?:--|/\*)\s*name\s*:\s*([^\r\n*]+)", re.I)

SQL_FILE  = os.getenv("SQL_FILE", "/app/test_queries.sql")
INTERVAL  = int(os.getenv("INTERVAL", "60"))
PROM_PORT = int(os.getenv("PROM_PORT", "8000"))

SCRIPT_TIME = Summary(
    "postgres_query_duration_seconds",
    "Execution time of the full SQL script")

STMT_TIME = Summary(
    "postgres_query_statement_duration_seconds",
    "Execution time of individual SQL statements",
    ["query_name"],
)

LAST_SUCCESS_TS = Gauge(
    "postgres_query_last_success_timestamp_seconds",
    "Unix timestamp of the last successful script run",
)

def read_sql(path: str) -> list[str]:
    """Чтение файла и разделение на отдельные выражения."""
    with open(path, encoding="utf-8") as f:
        sql_raw = f.read()
    return [s.strip() for s in sqlparse.split(sql_raw) if s.strip()]

def stmt_meta(stmt: str, idx: int) -> tuple[str, str]:
    m = name_re.match(stmt)
    qname = m.group(1).strip() if m else f"stmt_{idx}"
    qid   = hashlib.sha1(stmt.encode()).hexdigest()[:8]
    return qname, f"{idx}_{qid}"

def connect():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "haproxy"),
        port=os.getenv("DB_PORT", "5000"),
        dbname=os.getenv("DB_NAME", "booking_db"),
        user=os.getenv("DB_ADMIN_USER", "adminuser"),
        password=os.getenv("DB_ADMIN_PASSWORD", "adminpassword"),
    )

def main() -> None:
    statements = read_sql(SQL_FILE)
    conn = connect()
    start_http_server(PROM_PORT)
    print(f"Prometheus metrics exposed on :{PROM_PORT}/metrics")
    print(f"⚡ Found {len(statements)} statements in {SQL_FILE}")

    while True:
        with SCRIPT_TIME.time():
            with conn.cursor() as cur:
                for idx, stmt in enumerate(statements, start=1):
                    qname, _ = stmt_meta(stmt, idx)
                    with STMT_TIME.labels(query_name=qname).time():
                        cur.execute(stmt)
                        try:
                            cur.fetchall()
                        except psycopg2.ProgrammingError:
                            pass
                conn.commit()

        LAST_SUCCESS_TS.set_to_current_time()
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
