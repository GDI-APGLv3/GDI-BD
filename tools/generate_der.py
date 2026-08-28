#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SQL_FILE = os.path.normpath(os.path.join(HERE, "..", "sql", "03-create-municipio.sql"))
OUT_FILE = os.path.normpath(os.path.join(HERE, "..", "sql", "DER.md"))

TENANT = "{SCHEMA_NAME}"


class Table:
    def __init__(self, name, group):
        self.name = name
        self.group = group
        self.comment = ""
        self.columns = []
        self.fks = []

    def col(self, name):
        for c in self.columns:
            if c["name"] == name:
                return c
        return None


def clean_type(raw):
    raw = raw.strip().rstrip(",")
    m = re.match(r'^"[^"]+"\."([^"]+)"', raw)
    if m:
        return m.group(1)
    token = raw.split()[0] if raw.split() else "unknown"
    token = re.sub(r"\(.*?\)", "", token)
    is_array = "[]" in token
    token = token.replace("[]", "").replace('"', "")
    token = re.sub(r"[^A-Za-z0-9_]", "", token)
    if not token:
        token = "unknown"
    if is_array:
        token += "_arr"
    return token


def parse_sql(text):
    lines = text.splitlines()
    tables = {}
    order = []
    current_group = "?"
    i = 0
    n = len(lines)

    group_re = re.compile(r"^--\s*GRUPO\s+([A-Z])\s*:\s*(.+?)\s*$")
    create_re = re.compile(r'^\s*CREATE TABLE\s+"' + re.escape(TENANT) + r'"\."([^"]+)"\s*\(')
    col_re = re.compile(r'^\s*"([^"]+)"\s+(.+?)\s*$')
    pk_re = re.compile(r"PRIMARY KEY\s*\(([^)]+)\)")
    uk_re = re.compile(r"\bUNIQUE\s*\(([^)]+)\)")
    fk_inline_re = re.compile(
        r'FOREIGN KEY\s*\(\s*"([^"]+)"\s*\)\s+REFERENCES\s+"([^"]+)"\."([^"]+)"\s*\(\s*"([^"]+)"\s*\)'
        r'(?:\s+ON DELETE\s+(\w+))?'
    )

    while i < n:
        line = lines[i]

        g = group_re.match(line.strip())
        if g:
            current_group = "%s: %s" % (g.group(1), g.group(2))
            i += 1
            continue

        c = create_re.match(line)
        if c:
            tname = c.group(1)
            tbl = Table(tname, current_group)
            tables[tname] = tbl
            order.append(tname)
            i += 1
            while i < n and lines[i].strip() != ");":
                body = lines[i]
                stripped = body.strip()

                if stripped.startswith("CONSTRAINT") or stripped.startswith("FOREIGN KEY") \
                        or stripped.startswith("PRIMARY KEY") or stripped.startswith("UNIQUE") \
                        or stripped.startswith("CHECK"):
                    pass
                elif stripped.startswith('"'):
                    m = col_re.match(body)
                    if m:
                        cname = m.group(1)
                        rest = m.group(2)
                        nullable = "NOT NULL" not in rest.upper()
                        tbl.columns.append({
                            "name": cname,
                            "type": clean_type(rest),
                            "nullable": nullable,
                            "pk": False, "fk": False, "uk": False,
                        })
                i += 1
            i += 1
            continue

        i += 1

    blocks = re.split(r'(?=^\s*CREATE TABLE\s+"' + re.escape(TENANT) + r'")', text, flags=re.M)
    for blk in blocks:
        cm = create_re.match(blk.splitlines()[0]) if blk.splitlines() else None
        if not cm:
            continue
        tname = cm.group(1)
        tbl = tables.get(tname)
        if not tbl:
            continue
        blk = blk.split("\n);", 1)[0]
        for pm in pk_re.finditer(blk):
            for raw in pm.group(1).split(","):
                col = raw.strip().strip('"')
                cc = tbl.col(col)
                if cc:
                    cc["pk"] = True
        for um in uk_re.finditer(blk):
            cols = [x.strip().strip('"') for x in um.group(1).split(",")]
            if len(cols) == 1:
                cc = tbl.col(cols[0])
                if cc:
                    cc["uk"] = True
        for fm in fk_inline_re.finditer(blk):
            col, rschema, rtable, rcol, ondel = fm.groups()
            tbl.fks.append({
                "col": col, "ref_schema": rschema, "ref_table": rtable,
                "ref_col": rcol, "on_delete": ondel,
            })
            cc = tbl.col(col)
            if cc:
                cc["fk"] = True

    alter_re = re.compile(
        r'ALTER TABLE\s+"' + re.escape(TENANT) + r'"\."([^"]+)"\s+'
        r'ADD CONSTRAINT\s+"[^"]+"\s+FOREIGN KEY\s*\(\s*"([^"]+)"\s*\)\s+'
        r'REFERENCES\s+"([^"]+)"\."([^"]+)"\s*\(\s*"([^"]+)"\s*\)',
        re.S,
    )
    for am in alter_re.finditer(text):
        tname, col, rschema, rtable, rcol = am.groups()
        tbl = tables.get(tname)
        if not tbl:
            continue
        tbl.fks.append({
            "col": col, "ref_schema": rschema, "ref_table": rtable,
            "ref_col": rcol, "on_delete": None,
        })
        cc = tbl.col(col)
        if cc:
            cc["fk"] = True

    comment_re = re.compile(
        r'COMMENT ON TABLE\s+"' + re.escape(TENANT) + r'"\."([^"]+)"\s+IS\s+\'((?:[^\']|\'\')*)\''
    )
    for cm in comment_re.finditer(text):
        tname, comment = cm.groups()
        if tname in tables:
            tables[tname].comment = comment.replace("''", "'").strip()

    return [tables[t] for t in order]


def mermaid_entity(tbl):
    out = ["    %s {" % tbl.name]
    for c in tbl.columns:
        keys = []
        if c["pk"]:
            keys.append("PK")
        if c["fk"]:
            keys.append("FK")
        if c["uk"] and not c["pk"]:
            keys.append("UK")
        keytag = (" " + ",".join(keys)) if keys else ""
        out.append("        %s %s%s" % (c["type"], c["name"], keytag))
    out.append("    }")
    return "\n".join(out)


def mermaid_relations(tables):
    rels = []
    seen = set()
    tenant_tables = {t.name for t in tables}
    for tbl in tables:
        for fk in tbl.fks:
            if fk["ref_schema"] == TENANT:
                parent = fk["ref_table"]
            else:
                parent = "public_%s" % fk["ref_table"]
            child = tbl.name
            col = tbl.col(fk["col"])
            left = "||" if (col and not col["nullable"]) else "|o"
            key = (parent, child, fk["col"])
            if key in seen:
                continue
            seen.add(key)
            rels.append("    %s %s--o{ %s : \"%s\"" % (parent, left, child, fk["col"]))
    return rels, tenant_tables


def external_entities(tables):
    ext = {}
    for tbl in tables:
        for fk in tbl.fks:
            if fk["ref_schema"] != TENANT:
                name = "public_%s" % fk["ref_table"]
                ext.setdefault(name, fk["ref_col"])
    blocks = []
    for name in sorted(ext):
        blocks.append("    %s {\n        _ %s PK\n    }" % (name, ext[name]))
    return blocks


def render(tables):
    n_fk = sum(len(t.fks) for t in tables)
    n_ext = len({"public_%s" % fk["ref_table"]
                 for t in tables for fk in t.fks if fk["ref_schema"] != TENANT})

    lines = []
    lines.append("<!-- ========================================================= -->")
    lines.append("<!-- ARCHIVO GENERADO AUTOMATICAMENTE - NO EDITAR A MANO        -->")
    lines.append("<!-- Fuente de verdad: sql/03-create-municipio.sql             -->")
    lines.append("<!-- Regenerar:        python tools/generate_der.py            -->")
    lines.append("<!-- ========================================================= -->")
    lines.append("")
    lines.append("# DER - Schema de Municipio (GDI Latam)")
    lines.append("")
    lines.append("Diagrama Entidad-Relacion del schema que se crea al desplegar un municipio "
                 "(`sql/03-create-municipio.sql`). Cada municipio es un schema PostgreSQL "
                 "independiente (multi-tenant). Las entidades `public_*` son tablas globales "
                 "compartidas por todos los municipios.")
    lines.append("")
    lines.append("| Metrica | Valor |")
    lines.append("|---------|-------|")
    lines.append("| Tablas del tenant | %d |" % len(tables))
    lines.append("| Foreign keys | %d |" % n_fk)
    lines.append("| Tablas globales referenciadas (`public.*`) | %d |" % n_ext)
    lines.append("")
    lines.append("> Cardinalidad: `||--o{` = FK obligatoria (NOT NULL) · "
                 "`|o--o{` = FK opcional (nullable). El lado `o{` es la tabla que tiene la FK.")
    lines.append("")

    lines.append("## Diagrama completo")
    lines.append("")
    lines.append("```mermaid")
    lines.append("erDiagram")
    for tbl in tables:
        lines.append(mermaid_entity(tbl))
    for ext in external_entities(tables):
        lines.append(ext)
    rels, _ = mermaid_relations(tables)
    lines.append("")
    lines.extend(rels)
    lines.append("```")
    lines.append("")

    lines.append("## Entidades por grupo")
    lines.append("")
    groups = {}
    for tbl in tables:
        groups.setdefault(tbl.group, []).append(tbl)
    for grp in sorted(groups):
        lines.append("### Grupo %s" % grp)
        lines.append("")
        lines.append("| Tabla | Cols | FKs | Descripcion |")
        lines.append("|-------|------|-----|-------------|")
        for tbl in groups[grp]:
            desc = tbl.comment or ""
            desc = desc.replace("|", "\\|")
            lines.append("| `%s` | %d | %d | %s |"
                         % (tbl.name, len(tbl.columns), len(tbl.fks), desc))
        lines.append("")

    return "\n".join(lines) + "\n"


def main():
    if not os.path.exists(SQL_FILE):
        sys.stderr.write("ERROR: no existe %s\n" % SQL_FILE)
        return 2
    with open(SQL_FILE, "r", encoding="utf-8") as f:
        text = f.read()

    tables = parse_sql(text)
    if not tables:
        sys.stderr.write("ERROR: no se parseo ninguna tabla. Reviso el regex/formato.\n")
        return 2

    output = render(tables)

    if "--stdout" in sys.argv:
        sys.stdout.write(output)
        return 0

    if "--check" in sys.argv:
        existing = ""
        if os.path.exists(OUT_FILE):
            with open(OUT_FILE, "r", encoding="utf-8") as f:
                existing = f.read()
        if existing != output:
            sys.stderr.write("DRIFT: sql/DER.md esta desactualizado. "
                             "Corre: python tools/generate_der.py\n")
            return 1
        print("OK: sql/DER.md sincronizado (%d tablas)." % len(tables))
        return 0

    with open(OUT_FILE, "w", encoding="utf-8") as f:
        f.write(output)
    n_fk = sum(len(t.fks) for t in tables)
    print("OK: %s generado (%d tablas, %d FKs)." % (OUT_FILE, len(tables), n_fk))
    return 0


if __name__ == "__main__":
    sys.exit(main())
