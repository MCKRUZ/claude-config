"""
Zero-dependency secret vault access for Python, backed by Windows Credential Manager.

Reads/writes the SAME entries as the PowerShell module (DevSecrets.psm1) and the
Node helper (devsecrets.js): GENERIC credential named "DevSecret:<NAME>", UTF-16LE blob,
persisted LOCAL_MACHINE (DPAPI-encrypted per-user, not roamed, not OneDrive-synced).

Library use:
    from devsecrets import get_secret, set_secret, delete_secret, list_secrets
    key = get_secret("OPENROUTER_API_KEY")   # None if missing

CLI use:
    py devsecrets.py get  OPENROUTER_API_KEY
    py devsecrets.py set  OPENROUTER_API_KEY      # prompts (no echo)
    py devsecrets.py del  OPENROUTER_API_KEY
    py devsecrets.py list
"""
import ctypes
from ctypes import wintypes

CRED_TYPE_GENERIC = 1
CRED_PERSIST_LOCAL_MACHINE = 2
ERROR_NOT_FOUND = 1168
_PREFIX = "DevSecret:"

advapi32 = ctypes.WinDLL("advapi32", use_last_error=True)


class FILETIME(ctypes.Structure):
    _fields_ = [("dwLowDateTime", wintypes.DWORD), ("dwHighDateTime", wintypes.DWORD)]


class CREDENTIAL(ctypes.Structure):
    _fields_ = [
        ("Flags", wintypes.DWORD),
        ("Type", wintypes.DWORD),
        ("TargetName", wintypes.LPWSTR),
        ("Comment", wintypes.LPWSTR),
        ("LastWritten", FILETIME),
        ("CredentialBlobSize", wintypes.DWORD),
        ("CredentialBlob", ctypes.POINTER(ctypes.c_byte)),
        ("Persist", wintypes.DWORD),
        ("AttributeCount", wintypes.DWORD),
        ("Attributes", ctypes.c_void_p),
        ("TargetAlias", wintypes.LPWSTR),
        ("UserName", wintypes.LPWSTR),
    ]


PCREDENTIAL = ctypes.POINTER(CREDENTIAL)

advapi32.CredReadW.argtypes = [
    wintypes.LPCWSTR,
    wintypes.DWORD,
    wintypes.DWORD,
    ctypes.POINTER(PCREDENTIAL),
]
advapi32.CredReadW.restype = wintypes.BOOL
advapi32.CredWriteW.argtypes = [PCREDENTIAL, wintypes.DWORD]
advapi32.CredWriteW.restype = wintypes.BOOL
advapi32.CredDeleteW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD]
advapi32.CredDeleteW.restype = wintypes.BOOL
advapi32.CredFree.argtypes = [ctypes.c_void_p]
advapi32.CredEnumerateW.argtypes = [
    wintypes.LPCWSTR,
    wintypes.DWORD,
    ctypes.POINTER(wintypes.DWORD),
    ctypes.POINTER(ctypes.POINTER(PCREDENTIAL)),
]
advapi32.CredEnumerateW.restype = wintypes.BOOL


def get_secret(name):
    """Return the secret string for NAME, or None if it does not exist."""
    target = _PREFIX + name
    cred_ptr = PCREDENTIAL()
    if not advapi32.CredReadW(target, CRED_TYPE_GENERIC, 0, ctypes.byref(cred_ptr)):
        err = ctypes.get_last_error()
        if err == ERROR_NOT_FOUND:
            return None
        raise ctypes.WinError(err)
    try:
        cred = cred_ptr.contents
        size = cred.CredentialBlobSize
        if size == 0:
            return ""
        raw = ctypes.string_at(cred.CredentialBlob, size)
        return raw.decode("utf-16-le")
    finally:
        advapi32.CredFree(cred_ptr)


def set_secret(name, value):
    """Create or overwrite the secret for NAME."""
    target = _PREFIX + name
    blob = value.encode("utf-16-le")
    buf = (ctypes.c_byte * len(blob)).from_buffer_copy(blob)
    cred = CREDENTIAL()
    cred.Type = CRED_TYPE_GENERIC
    cred.TargetName = target
    cred.UserName = "DevSecret"
    cred.Persist = CRED_PERSIST_LOCAL_MACHINE
    cred.CredentialBlobSize = len(blob)
    cred.CredentialBlob = ctypes.cast(buf, ctypes.POINTER(ctypes.c_byte))
    if not advapi32.CredWriteW(ctypes.byref(cred), 0):
        raise ctypes.WinError(ctypes.get_last_error())


def delete_secret(name):
    """Delete the secret for NAME. Returns True if removed, False if it did not exist."""
    target = _PREFIX + name
    if not advapi32.CredDeleteW(target, CRED_TYPE_GENERIC, 0):
        err = ctypes.get_last_error()
        if err == ERROR_NOT_FOUND:
            return False
        raise ctypes.WinError(err)
    return True


def list_secrets():
    """Return the list of DevSecret names."""
    count = wintypes.DWORD()
    creds = ctypes.POINTER(PCREDENTIAL)()
    if not advapi32.CredEnumerateW(
        _PREFIX + "*", 0, ctypes.byref(count), ctypes.byref(creds)
    ):
        err = ctypes.get_last_error()
        if err == ERROR_NOT_FOUND:
            return []
        raise ctypes.WinError(err)
    try:
        names = []
        for i in range(count.value):
            names.append(creds[i].contents.TargetName[len(_PREFIX) :])
        return sorted(names)
    finally:
        advapi32.CredFree(creds)


def _main(argv):
    import getpass

    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd = argv[1].lower()
    if cmd == "get":
        v = get_secret(argv[2])
        if v is None:
            print(f"(not found: {argv[2]})")
            return 1
        print(v)
    elif cmd == "set":
        v = getpass.getpass(f"Enter secret for DevSecret:{argv[2]}: ")
        if not v:
            print("Empty secret; nothing stored.")
            return 1
        set_secret(argv[2], v)
        print(f"Stored DevSecret:{argv[2]} ({len(v)} chars)")
    elif cmd in ("del", "delete", "rm"):
        print("Removed" if delete_secret(argv[2]) else "Not found")
    elif cmd in ("list", "ls"):
        for n in list_secrets():
            print(n)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    import sys

    sys.exit(_main(sys.argv))
