#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import hashlib
import os
import sys


def derivar(schema_name, secret):
    sufijo = hashlib.md5((schema_name + secret).encode()).hexdigest()
    key = "gdi-agent-{}-{}".format(schema_name, sufijo)
    return key, hashlib.sha256(key.encode()).hexdigest()


def main():
    if len(sys.argv) != 2:
        print("Uso: python tools/gen_agent_api_key.py <schema_name>")
        print("Ejemplo: python tools/gen_agent_api_key.py 100_test")
        return 1

    schema_name = sys.argv[1]
    secret = os.environ.get("GDI_AGENT_KEY_SECRET")
    if not secret:
        print("[ERROR] Variable de entorno GDI_AGENT_KEY_SECRET no configurada")
        print("Ejemplo: export GDI_AGENT_KEY_SECRET='<secret-de-esta-instalacion>'")
        return 1

    key, key_hash = derivar(schema_name, secret)
    print("schema      : {}".format(schema_name))
    print("api_key     : {}   <- entregar al AgenteLANG, no guardar".format(key))
    print("api_key_hash: {}".format(key_hash))
    print("prefix      : {}".format(key[:12]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
