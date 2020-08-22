#!/usr/bin/env python3

import ccecc
import getpass
import hashlib
from cryptography.fernet import Fernet
import base64
import os
import sys

def hash_pw(pw, salt):
    return hashlib.scrypt(pw.encode("utf-8"), salt=salt, n=2**14, r=8, p=1)[:32]

def encrypt(data, pw):
    salt = os.urandom(16)
    key = hash_pw(pw, salt)
    f = Fernet(base64.urlsafe_b64encode(key))
    return base64.b64encode(salt) + b"\n" + f.encrypt(data)

def decrypt(data, pw):
    rsalt, encdata = data.split(b"\n", 1)
    salt = base64.b64decode(rsalt)
    key = hash_pw(pw, salt)
    f = Fernet(base64.urlsafe_b64encode(key))
    return f.decrypt(encdata)

if __name__ == "__main__":
    pw = getpass.getpass()
    pwconfirm = getpass.getpass()
    if pw != pwconfirm:
        print("passwords do not match")
        sys.exit(1)
    priv, pub = ccecc.keypair()
    open("update-key", "wb").write(encrypt(priv, pw))

# for use in generate_manifest.py
def get_key():
    return decrypt(open("update-key", "rb").read(), getpass.getpass())