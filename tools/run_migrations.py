#!/usr/bin/env python3

import glob
import hashlib
import os
import sys

import psycopg2

MIGRATIONS_DIR = os.environ.get(
    "MIGRATIONS_DIR",
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "sql", "migrations"),
)

_ENSURE_TABLE = """
CREATE TABLE IF NOT EXISTS public.schema_migrations (
    version      TEXT PRIMARY KEY,
    name         TEXT NOT NULL,
    applied_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    applied_by   TEXT,
    checksum     TEXT
)
"""


def _version_and_name(path: str):
    base = os.path.basename(path)
    if base.endswith(".sql"):
        base = base[:-4]
    parts = base.split("_", 1)
    version = parts[0]
    name = parts[1] if len(parts) > 1 else base
    return version, name


def _migration_files():
    files = glob.glob(os.path.join(MIGRATIONS_DIR, "*.sql"))
    return sorted(files, key=lambda p: os.path.basename(p))


def _checksum(sql: str) -> str:
    return hashlib.sha256(sql.encode("utf-8")).hexdigest()


NO_TRANSACTION_MARKER = "-- @no-transaction"
SEPARADOR_STATEMENTS = "-- @@"
SALTO = chr(10)


def _partes(sql: str) -> list[str]:
    if NO_TRANSACTION_MARKER not in sql:
        return [sql]

    pedazos, actual = [], []
    for linea in sql.splitlines():
        if linea.strip() == SEPARADOR_STATEMENTS:
            pedazos.append(SALTO.join(actual))
            actual = []
        else:
            actual.append(linea)
    pedazos.append(SALTO.join(actual))

    return [p for p in pedazos if _tiene_sql(p)]


def _tiene_sql(pedazo: str) -> bool:
    for linea in pedazo.splitlines():
        limpia = linea.strip()
        if limpia and not limpia.startswith("--"):
            return True
    return False


def main() -> int:
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL no está definida en el entorno.", file=sys.stderr)
        return 1

    if not os.path.isdir(MIGRATIONS_DIR):
        print(f"ERROR: no encuentro el directorio de migraciones: {MIGRATIONS_DIR}", file=sys.stderr)
        return 1

    try:
        conn = psycopg2.connect(database_url)
    except Exception as e:
        print(f"ERROR: no se pudo conectar a la BD: {e}", file=sys.stderr)
        return 1
    conn.autocommit = True

    try:
        with conn.cursor() as cur:
            cur.execute(_ENSURE_TABLE)
            cur.execute("SELECT version FROM public.schema_migrations")
            applied = {row[0] for row in cur.fetchall()}

        files = _migration_files()
        pending = [(f, *_version_and_name(f)) for f in files]
        pending = [(f, v, n) for (f, v, n) in pending if v not in applied]

        if not pending:
            print("Migraciones: nada pendiente, la BD está al día.", flush=True)
            return 0

        print(f"Migraciones pendientes: {len(pending)} -> {[v for _, v, _ in pending]}", flush=True)

        for path, version, name in pending:
            print(f"  Aplicando {version} ({name})...", flush=True)
            with open(path, "r", encoding="utf-8") as fh:
                sql = fh.read()
            try:
                with conn.cursor() as cur:
                    for parte in _partes(sql):
                        cur.execute(parte)
                    cur.execute(
                        "INSERT INTO public.schema_migrations (version, name, applied_by, checksum) "
                        "VALUES (%s, %s, 'run_migrations', %s) "
                        "ON CONFLICT (version) DO UPDATE SET checksum = EXCLUDED.checksum",
                        (version, name, _checksum(sql)),
                    )
            except Exception as e:
                print(f"ERROR aplicando migración {version} ({name}): {e}", file=sys.stderr)
                print("Se detiene el runner. Arreglá la migración y volvé a correrlo.", file=sys.stderr)
                return 1
            print(f"  OK {version}", flush=True)

        print(f"Migraciones: {len(pending)} aplicada(s). BD al día.", flush=True)
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
