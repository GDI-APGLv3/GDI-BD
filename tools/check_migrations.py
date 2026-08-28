
import hashlib
import os
import re
import sys
import psycopg2

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRATIONS_DIR = os.path.join(REPO_ROOT, "sql", "migrations")


def get_pending_files():
    files = []
    for entry in os.listdir(MIGRATIONS_DIR):
        if entry.endswith(".sql") and os.path.isfile(os.path.join(MIGRATIONS_DIR, entry)):
            files.append(entry)
    return sorted(files)


def extract_version(filename):
    match = re.match(r"^(\d+[a-z]?)_", filename)
    if match:
        return match.group(1)
    return None


def get_applied_versions(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT version, checksum FROM public.schema_migrations ORDER BY version;")
        return {row[0]: row[1] for row in cur.fetchall()}


def _checksum(path):
    with open(path, "r", encoding="utf-8") as fh:
        return hashlib.sha256(fh.read().encode("utf-8")).hexdigest()


def main():
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL no esta definida en el entorno.")
        sys.exit(1)

    pending_files = get_pending_files()

    if not pending_files:
        print("No hay archivos de migracion pendientes en sql/migrations/")
        print("(La carpeta solo contiene el directorio archive/)")
        return

    try:
        conn = psycopg2.connect(database_url)
    except Exception as e:
        print(f"ERROR conectando a la BD: {e}")
        sys.exit(1)

    try:
        applied = get_applied_versions(conn)
    except Exception as e:
        print(f"ERROR leyendo schema_migrations: {e}")
        print("Tip: Correr primero sql/migrations/000_create_schema_migrations.sql")
        conn.close()
        sys.exit(1)

    conn.close()

    print(f"\n{'VERSION':<10} {'ARCHIVO':<50} {'ESTADO'}")
    print("-" * 75)

    falta_aplicar = []
    con_drift = []
    for filename in pending_files:
        version = extract_version(filename)
        if version is None:
            estado = "SKIP (sin version)"
        elif version not in applied:
            estado = "PENDIENTE"
            falta_aplicar.append(filename)
        else:
            checksum_guardado = applied[version]
            if checksum_guardado is None:
                estado = "OK (aplicada, sin checksum)"
            else:
                path = os.path.join(MIGRATIONS_DIR, filename)
                if _checksum(path) == checksum_guardado:
                    estado = "OK (aplicada)"
                else:
                    estado = "DRIFT (archivo cambio despues de aplicarse)"
                    con_drift.append(filename)
        print(f"{version or '?':<10} {filename:<50} {estado}")

    print()
    if falta_aplicar:
        print(f"PENDIENTES ({len(falta_aplicar)}): {', '.join(falta_aplicar)}")
        print("  Aplicar con el runner oficial (idempotente, aplica todas en orden):")
        print("    python tools/run_migrations.py")
    if con_drift:
        print(f"DRIFT ({len(con_drift)}): el archivo difiere del checksum guardado en este ambiente:")
        for f in con_drift:
            print(f"  {f}")
        print("  Revisar que el cambio sea intencional (y por que no se registro con otra version)")
        print("  antes de continuar — puede ser una edicion post-aplicacion no propagada.")

    if falta_aplicar or con_drift:
        sys.exit(1)
    else:
        print("Todas las migraciones estan aplicadas, sin drift.")


if __name__ == "__main__":
    main()
