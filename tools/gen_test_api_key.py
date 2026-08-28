#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import hashlib
import secrets
import sys


def generar(ambiente):
    key = "gdi-test-{}-{}".format(ambiente, secrets.token_hex(16))
    return key, hashlib.sha256(key.encode()).hexdigest(), key[:12]


def main():
    if len(sys.argv) != 2:
        print("Uso: python tools/gen_test_api_key.py <ambiente>")
        print("Ejemplo: python tools/gen_test_api_key.py dev")
        return 1

    key, key_hash, prefix = generar(sys.argv[1])
    print("v_api_key_plain  := '{}';   <- a 1Password, no al repo".format(key))
    print("v_api_key_hash   := '{}';".format(key_hash))
    print("v_api_key_prefix := '{}';".format(prefix))
    return 0


if __name__ == "__main__":
    sys.exit(main())
