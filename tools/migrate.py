
import os
import re
import sys
import hashlib
import psycopg2

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run_migrations import NO_TRANSACTION_MARKER, _partes  # noqa: E402


def extract_version(filename):
    basename = os.path.basename(filename)
    match = re.match(r"^(\d+[a-z]?)_", basename)
    if match:
        return match.group(1)
    return None


def extract_name(filename):
    basename = os.path.basename(filename).replace(".sql", "")
    match = re.match(r"^\d+[a-z]?_(.*)", basename)
    if match:
        return match.group(1)
    return basename


def main():
    if len(sys.argv) != 2:
        print("Uso: python tools/migrate.py sql/migrations/NNN_nombre.sql")
        sys.exit(1)

    sql_path = sys.argv[1]

    if not os.path.isabs(sql_path):
        repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sql_path = os.path.join(repo_root, sql_path)

    if not os.path.isfile(sql_path):
        print(f"ERROR: No existe el archivo: {sql_path}")
        sys.exit(1)

    version = extract_version(sql_path)
    if not version:
        print(f"ERROR: No se pudo extraer version del nombre: {os.path.basename(sql_path)}")
        print("El archivo debe tener formato: NNN_nombre.sql o NNNa_nombre.sql")
        sys.exit(1)

    name = extract_name(sql_path)

    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL no esta definida en el entorno.")
        sys.exit(1)

    with open(sql_path, "r", encoding="utf-8") as f:
        sql_content = f.read()

    checksum = hashlib.sha256(sql_content.encode()).hexdigest()[:16]

    sin_transaccion = NO_TRANSACTION_MARKER in sql_content

    try:
        conn = psycopg2.connect(database_url)
        conn.autocommit = sin_transaccion
    except Exception as e:
        print(f"ERROR conectando a la BD: {e}")
        sys.exit(1)

    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT applied_at FROM public.schema_migrations WHERE version = %s",
                (version,)
            )
            row = cur.fetchone()
            if row:
                print(f"SKIP: version '{version}' ya aplicada el {row[0]}")
                conn.close()
                sys.exit(0)

            print(f"Aplicando migracion {version} ({name})...")
            if sin_transaccion:
                print("  (sin transaccion: la migracion lo pide con @no-transaction)")
            for parte in _partes(sql_content):
                cur.execute(parte)

            cur.execute(
                """INSERT INTO public.schema_migrations (version, name, checksum)
                   VALUES (%s, %s, %s)
                   ON CONFLICT (version) DO UPDATE SET checksum = EXCLUDED.checksum""",
                (version, name, checksum)
            )

        if not sin_transaccion:
            conn.commit()
        print(f"OK: Migracion {version} aplicada y registrada.")

    except Exception as e:
        if not sin_transaccion:
            conn.rollback()
        else:
            print("AVISO: la migracion corrio SIN transaccion; lo ya aplicado NO se revierte.")
        print(f"ERROR aplicando migracion: {e}")
        conn.close()
        sys.exit(1)

    conn.close()


if __name__ == "__main__":
    main()
