# SignPoshScript
WPF GUI written im PowerShell to sign your scripts.

<b>Prerequisites</b>

You need to import at least one CodeSigning Certificate into your users certificate store at: <b>Cert:\CurrentUser\My\\</b>

The  EnhancedKeyUsageList (EKU) must be ${\color{red}Code Signing (1.3.6.1.5.5.7.3.3)}$

<b>Files</b>
<ul>
<li>CodeSigningTool.exe - precompiled executable of the PoSh Sign.ps1 script</li>
<li>SignPS.ps1 - WFP / PowerShell source code</li>
</ul>

---

## Trusting the Code-Signing Certificate

After signing your PowerShell scripts, target machines must trust the
code-signing certificate before they will execute signed scripts.
Two things are required on every target machine:

1. The **code-signing certificate** must be in the
   **Trusted Publishers** certificate store.
2. The **root CA certificate** (and any intermediate CA certificates)
   must be in the **Trusted Root Certification Authorities** store.
3. The PowerShell **execution policy** must be set to `AllSigned`
   or `RemoteSigned`.

### Standalone Server (Manual)

#### 1 — Export the Code-Signing Certificate

On the machine where you signed the scripts, export the certificate
to a `.cer` file:

```powershell
# List code-signing certificates
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert

# Export the certificate (replace the thumbprint)
$cert = Get-ChildItem Cert:\CurrentUser\My\<thumbprint>
Export-Certificate -Cert $cert -FilePath C:\Temp\CodeSigning.cer
```

If your certificate was issued by an internal (enterprise) CA, also
export the root CA certificate from
`Cert:\LocalMachine\Root` or `Cert:\CurrentUser\Root`.

#### 2 — Import Certificates on the Target Machine

Copy the `.cer` files to the target server and run the following
in an **elevated** PowerShell session:

```powershell
# Import the code-signing certificate into Trusted Publishers
Import-Certificate -FilePath C:\Temp\CodeSigning.cer `
    -CertStoreLocation Cert:\LocalMachine\TrustedPublisher

# Import the root CA certificate into Trusted Root CAs
# (skip if using a publicly trusted CA like DigiCert, etc.)
Import-Certificate -FilePath C:\Temp\RootCA.cer `
    -CertStoreLocation Cert:\LocalMachine\Root
```

#### 3 — Set the Execution Policy

```powershell
# Allow only signed scripts
Set-ExecutionPolicy AllSigned -Scope LocalMachine -Force

# --- OR ---
# Allow signed remote scripts, unsigned local scripts
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

#### 4 — Verify

```powershell
# Should return 'Valid'
Get-AuthenticodeSignature -FilePath C:\Scripts\YourScript.ps1 |
    Select-Object -ExpandProperty Status
```

### Active Directory Environment (Group Policy)

In an AD domain you can distribute the certificates and enforce
the execution policy centrally via Group Policy.

#### 1 — Distribute Certificates via GPO

1. Open **Group Policy Management** (`gpmc.msc`).
2. Create or edit a GPO linked to the OU that contains the
   target servers/workstations.
3. Navigate to:<br>
   `Computer Configuration → Policies → Windows Settings →`
   `Security Settings → Public Key Policies`
4. **Trusted Publishers** — right-click → **Import…** →
   select the code-signing certificate (`.cer`).
5. **Trusted Root Certification Authorities** — right-click →
   **Import…** → select the root CA certificate (`.cer`).<br>
   *(Skip if using a publicly trusted CA.)*

After the next Group Policy refresh (`gpupdate /force` or at
next reboot) every computer in scope will trust the certificate.

#### 2 — Enforce Execution Policy via GPO

1. In the same (or a separate) GPO navigate to:<br>
   `Computer Configuration → Policies → Administrative Templates →`
   `Windows Components → Windows PowerShell`
2. Enable **Turn on Script Execution**.
3. Set the policy to **Allow only signed scripts** (`AllSigned`)
   or **Allow local scripts and remote signed scripts**
   (`RemoteSigned`).

> **Note:** The GPO-based execution policy takes precedence over
> locally configured policies. You can verify the effective policy
> and its source with:
>
> ```powershell
> Get-ExecutionPolicy -List
> ```

#### 3 — Verify on a Domain-Joined Machine

```powershell
# Force a Group Policy update
gpupdate /force

# Confirm the certificate is trusted
Get-ChildItem Cert:\LocalMachine\TrustedPublisher

# Confirm the execution policy
Get-ExecutionPolicy -List

# Validate a signed script
Get-AuthenticodeSignature -FilePath \\Server\Share\YourScript.ps1 |
    Select-Object -ExpandProperty Status
```

### Quick Reference — Certificate Stores

| Store Location | Purpose |
|---|---|
| `Cert:\LocalMachine\TrustedPublisher` | Trusted code-signing certificates |
| `Cert:\LocalMachine\Root` | Trusted root CA certificates |
| `Cert:\LocalMachine\CA` | Intermediate CA certificates |
| `Cert:\CurrentUser\My` | Personal certificates (signing machine) |

---

### WPF GUI
![alt text](https://github.com/BetaHydri/SignPoshScripts/blob/SIGNPOWERSHELL/WPF-GUI.png)

### Code signed .ps1
![alt text](https://github.com/BetaHydri/SignPoshScripts/blob/SIGNPOWERSHELL/Sign.png)

### Properties of .ps1 Certificate Tab
![alt text](https://github.com/BetaHydri/SignPoshScripts/blob/SIGNPOWERSHELL/CodeSigningCert.png)
