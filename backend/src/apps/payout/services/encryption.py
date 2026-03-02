"""AES-256 encryption/decryption for owner payment gateway credentials."""
import json
import os
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from src.apps.core.config import settings


def _get_key() -> bytes:
    """Derive a 32-byte AES key from the app's secret key."""
    import hashlib
    return hashlib.sha256(settings.SECRET_KEY.encode()).digest()


def encrypt_credentials(data: dict) -> str:
    """Encrypt a dict to a base64-encoded AES-GCM ciphertext."""
    key = _get_key()
    aesgcm = AESGCM(key)
    nonce = os.urandom(12)
    plaintext = json.dumps(data).encode()
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)
    return base64.b64encode(nonce + ciphertext).decode()


def decrypt_credentials(token: str) -> dict:
    """Decrypt a base64-encoded AES-GCM token back to a dict."""
    key = _get_key()
    aesgcm = AESGCM(key)
    raw = base64.b64decode(token.encode())
    nonce, ciphertext = raw[:12], raw[12:]
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return json.loads(plaintext.decode())
