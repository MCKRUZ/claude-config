<#
.SYNOPSIS
  Zero-dependency secret vault backed by Windows Credential Manager (DPAPI, per-user).
.DESCRIPTION
  Stores secrets as GENERIC credentials named "DevSecret:<NAME>", persisted LOCAL_MACHINE
  (encrypted at rest by Windows under your user account; NOT roamed, NOT OneDrive-synced).
  The same credential entries are readable by the sibling helpers devsecrets.py (Python)
  and devsecrets.js (Node), which use the identical target-name convention and UTF-16LE blob.

  Usage:
    Import-Module C:\Users\kruz7\.devsecrets\DevSecrets.psm1
    Set-DevSecret -Name OPENROUTER_API_KEY        # prompts securely (no echo, no history)
    Get-DevSecret -Name OPENROUTER_API_KEY
    Get-DevSecretNames
    Remove-DevSecret -Name OPENROUTER_API_KEY
#>

if (-not ('DevSecretsCredMan' -as [type])) {
  Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class DevSecretsCredMan {
  const int CRED_TYPE_GENERIC = 1;
  const int CRED_PERSIST_LOCAL_MACHINE = 2;
  const int ERROR_NOT_FOUND = 1168;

  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  struct CREDENTIAL {
    public int Flags;
    public int Type;
    public string TargetName;
    public string Comment;
    public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
    public int CredentialBlobSize;
    public IntPtr CredentialBlob;
    public int Persist;
    public int AttributeCount;
    public IntPtr Attributes;
    public string TargetAlias;
    public string UserName;
  }

  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
  static extern bool CredWriteW(ref CREDENTIAL cred, int flags);
  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "CredReadW")]
  static extern bool CredReadW(string target, int type, int flags, out IntPtr credPtr);
  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "CredDeleteW")]
  static extern bool CredDeleteW(string target, int type, int flags);
  [DllImport("advapi32.dll", SetLastError = true)]
  static extern void CredFree(IntPtr buffer);
  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "CredEnumerateW")]
  static extern bool CredEnumerateW(string filter, int flags, out int count, out IntPtr pCredentials);

  public static void Write(string name, string secret) {
    byte[] blob = Encoding.Unicode.GetBytes(secret);
    CREDENTIAL cred = new CREDENTIAL();
    cred.Type = CRED_TYPE_GENERIC;
    cred.TargetName = name;
    cred.UserName = "DevSecret";
    cred.Persist = CRED_PERSIST_LOCAL_MACHINE;
    cred.CredentialBlobSize = blob.Length;
    cred.CredentialBlob = Marshal.AllocHGlobal(blob.Length);
    Marshal.Copy(blob, 0, cred.CredentialBlob, blob.Length);
    try {
      if (!CredWriteW(ref cred, 0))
        throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    } finally {
      Marshal.FreeHGlobal(cred.CredentialBlob);
    }
  }

  public static string Read(string name) {
    IntPtr credPtr;
    if (!CredReadW(name, CRED_TYPE_GENERIC, 0, out credPtr)) {
      int err = Marshal.GetLastWin32Error();
      if (err == ERROR_NOT_FOUND) return null;
      throw new System.ComponentModel.Win32Exception(err);
    }
    try {
      CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
      if (cred.CredentialBlobSize == 0) return "";
      byte[] blob = new byte[cred.CredentialBlobSize];
      Marshal.Copy(cred.CredentialBlob, blob, 0, cred.CredentialBlobSize);
      return Encoding.Unicode.GetString(blob);
    } finally {
      CredFree(credPtr);
    }
  }

  public static bool Delete(string name) {
    if (!CredDeleteW(name, CRED_TYPE_GENERIC, 0)) {
      int err = Marshal.GetLastWin32Error();
      if (err == ERROR_NOT_FOUND) return false;
      throw new System.ComponentModel.Win32Exception(err);
    }
    return true;
  }

  public static string[] Enumerate(string filter) {
    int count; IntPtr pcreds;
    if (!CredEnumerateW(filter, 0, out count, out pcreds)) {
      int err = Marshal.GetLastWin32Error();
      if (err == ERROR_NOT_FOUND) return new string[0];
      throw new System.ComponentModel.Win32Exception(err);
    }
    try {
      string[] names = new string[count];
      for (int i = 0; i < count; i++) {
        IntPtr p = Marshal.ReadIntPtr(pcreds, i * IntPtr.Size);
        CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(p, typeof(CREDENTIAL));
        names[i] = cred.TargetName;
      }
      return names;
    } finally {
      CredFree(pcreds);
    }
  }
}
'@
}

function Set-DevSecret {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [string]$Secret
  )
  if (-not $Secret) {
    $ss = Read-Host "Enter secret for DevSecret:$Name" -AsSecureString
    $Secret = [System.Net.NetworkCredential]::new('', $ss).Password
  }
  if ([string]::IsNullOrEmpty($Secret)) { throw "Empty secret; nothing stored." }
  [DevSecretsCredMan]::Write("DevSecret:$Name", $Secret)
  Write-Host "Stored DevSecret:$Name ($($Secret.Length) chars)"
}

function Get-DevSecret {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Name)
  [DevSecretsCredMan]::Read("DevSecret:$Name")
}

function Remove-DevSecret {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Name)
  $ok = [DevSecretsCredMan]::Delete("DevSecret:$Name")
  Write-Host $(if ($ok) { "Removed DevSecret:$Name" } else { "DevSecret:$Name not found" })
}

function Get-DevSecretNames {
  [DevSecretsCredMan]::Enumerate("DevSecret:*") | ForEach-Object { $_ -replace '^DevSecret:', '' } | Sort-Object
}

Export-ModuleMember -Function Set-DevSecret, Get-DevSecret, Remove-DevSecret, Get-DevSecretNames
