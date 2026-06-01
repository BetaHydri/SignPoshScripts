# SignPoshScripts

**Language / Sprache:** [English](README.md) | **Deutsch**

[![PowerShell](https://img.shields.io/badge/Language-PowerShell-blue?logo=powershell&logoColor=white)](https://github.com/BetaHydri/SignPoshScripts)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white)](https://github.com/BetaHydri/SignPoshScripts)
[![GitHub stars](https://img.shields.io/github/stars/BetaHydri/SignPoshScripts?style=flat&logo=github)](https://github.com/BetaHydri/SignPoshScripts/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/BetaHydri/SignPoshScripts?logo=github)](https://github.com/BetaHydri/SignPoshScripts/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/BetaHydri/SignPoshScripts/SIGNPOWERSHELL?logo=github)](https://github.com/BetaHydri/SignPoshScripts/commits/SIGNPOWERSHELL)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Hinweis:** Dieses Repository hieß früher `SignPowershell`.
> Alte URLs werden automatisch hierher weitergeleitet.

WPF-Oberfläche in PowerShell zum Signieren von Skripten mit
Codesignaturzertifikaten aus dem Windows-Zertifikatspeicher **oder**
von einer Smartcard.

## Funktionen

- Mehrere PowerShell-Dateien auswählen (`.ps1`, `.psm1`, `.psd1`, `.ps1xml`)
- Findet Codesignaturzertifikate aus **beiden** Quellen:
  - `Cert:\CurrentUser\My` (softwarebasierte Zertifikate)
  - Smartcard-Leser (Microsoft Smart Card Key Storage Provider)
- Dedupliziert Zertifikate und filtert abgelaufene aus
- Signiert mit SHA-256 und Zeitstempel über DigiCert
- Konfigurierbarer Zeitstempelserver (Standard: DigiCert, änderbar über ⚙-Schaltfläche)
- Bindet die vollständige Zertifikatskette in die Signatur ein

## Zeitstempelserver

Jede mit diesem Tool erstellte Authenticode-Signatur enthält einen
**RFC-3161-Zeitstempel** einer vertrauenswürdigen Zeitstempelstelle.
Der Standardserver ist `http://timestamp.digicert.com`.
Über die **⚙**-Schaltfläche neben dem Feld „Timestamp Server"
in der Oberfläche lässt er sich ändern.

### Warum Zeitstempel wichtig sind

Ein Zeitstempel weist kryptografisch nach, **wann** die Signatur
erstellt wurde. Ohne Zeitstempel wird die Signatur ungültig, sobald
das Codesignaturzertifikat abläuft. Mit Zeitstempel vertraut Windows
der Signatur dauerhaft — auch nach Ablauf des Zertifikats — da der
Zeitstempel belegt, dass das Skript während der Gültigkeitsdauer
signiert wurde.

**Kurz gesagt:** Immer einen Zeitstempelserver verwenden. Er kostet
nichts und sorgt dafür, dass signierte Skripte nach einer
Zertifikatserneuerung weiterhin funktionieren.

### Gängige Zeitstempelserver

| Anbieter | URL |
|---|---|
| DigiCert (Standard) | `http://timestamp.digicert.com` |
| Sectigo | `http://timestamp.sectigo.com` |
| GlobalSign | `http://timestamp.globalsign.com/tsa/r6advanced1` |
| SSL.com | `http://ts.ssl.com` |

> **Hinweis:** Zeitstempelserver sind öffentlich und kostenlos.
> Sie funktionieren mit jedem Codesignaturzertifikat — egal ob von
> einer öffentlichen CA, einer internen Unternehmens-CA oder
> selbstsigniert.

## Voraussetzungen

Es wird mindestens ein gültiges Codesignaturzertifikat im
Benutzerzertifikatspeicher (`Cert:\CurrentUser\My`) **oder** auf
einer angeschlossenen Smartcard benötigt.

Die erweiterte Schlüsselverwendung (EKU) des Zertifikats muss
enthalten:
$\color{red}{\text{Code Signing (1.3.6.1.5.5.7.3.3)}}$

## Dateien

| Datei / Ordner | Beschreibung |
|---|---|
| `SignPS.ps1` | WPF-/PowerShell-Quellcode |
| `CodeSigningTool.exe` | Eigenständige ausführbare Datei (aus `SignPS.ps1` mit [ps2exe](https://github.com/MScholtes/ps2exe) kompiliert) |
| `images/` | Screenshots für diese README |
| `.vscode/launch.json` | VS-Code-Debug-Konfiguration |
| `LICENSE` | MIT-Lizenz |

## Executable neu erstellen

Um die `.exe` nach Änderungen am Skript neu zu kompilieren:

```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Invoke-PS2EXE -InputFile .\SignPS.ps1 -OutputFile .\CodeSigningTool.exe -NoConsole
```

---

## Codesignaturzertifikat als vertrauenswürdig einstufen

Nach dem Signieren der PowerShell-Skripte müssen die Zielsysteme dem
Codesignaturzertifikat vertrauen, bevor signierte Skripte ausgeführt
werden. Auf jedem Zielsystem sind drei Dinge erforderlich:

1. Das **Codesignaturzertifikat** muss im Speicher
   **Vertrauenswürdige Herausgeber** (Trusted Publishers) liegen.
2. Das **Stammzertifikat der CA** (und ggf. Zwischenzertifikate)
   muss im Speicher **Vertrauenswürdige Stammzertifizierungsstellen**
   liegen.
3. Die PowerShell-**Ausführungsrichtlinie** muss auf `AllSigned`
   oder `RemoteSigned` gesetzt sein.

### Eigenständiger Server (manuell)

#### 1 — Codesignaturzertifikat exportieren

Auf dem System, auf dem die Skripte signiert wurden, das Zertifikat
in eine `.cer`-Datei exportieren:

```powershell
# Codesignaturzertifikate auflisten
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert

# Zertifikat exportieren (Thumbprint ersetzen)
$cert = Get-ChildItem Cert:\CurrentUser\My\<thumbprint>
Export-Certificate -Cert $cert -FilePath C:\Temp\CodeSigning.cer
```

Wurde das Zertifikat von einer internen (Enterprise-)CA ausgestellt,
zusätzlich das Stammzertifikat aus `Cert:\LocalMachine\Root` oder
`Cert:\CurrentUser\Root` exportieren.

#### 2 — Zertifikate auf dem Zielsystem importieren

Die `.cer`-Dateien auf den Zielserver kopieren und in einer
**erhöhten** PowerShell-Sitzung ausführen:

```powershell
# Codesignaturzertifikat in Vertrauenswürdige Herausgeber importieren
Import-Certificate -FilePath C:\Temp\CodeSigning.cer `
    -CertStoreLocation Cert:\LocalMachine\TrustedPublisher

# Stammzertifikat in Vertrauenswürdige Stammzertifizierungsstellen importieren
# (überspringen bei öffentlich vertrauenswürdiger CA wie DigiCert)
Import-Certificate -FilePath C:\Temp\RootCA.cer `
    -CertStoreLocation Cert:\LocalMachine\Root
```

#### 3 — Ausführungsrichtlinie setzen

```powershell
# Nur signierte Skripte zulassen
Set-ExecutionPolicy AllSigned -Scope LocalMachine -Force

# --- ODER ---
# Signierte Remote-Skripte zulassen, lokale Skripte ohne Signatur
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

#### 4 — Überprüfen

```powershell
# Sollte 'Valid' zurückgeben
Get-AuthenticodeSignature -FilePath C:\Scripts\YourScript.ps1 |
    Select-Object -ExpandProperty Status
```

### Active-Directory-Umgebung (Gruppenrichtlinie)

In einer AD-Domäne lassen sich Zertifikate und Ausführungsrichtlinie
zentral per Gruppenrichtlinie verteilen.

#### 1 — Zertifikate per GPO verteilen

1. **Gruppenrichtlinienverwaltung** öffnen (`gpmc.msc`).
2. Ein GPO erstellen oder bearbeiten, das mit der OU der Zielsysteme
   verknüpft ist.
3. Navigieren zu:<br>
   `Computerkonfiguration → Richtlinien → Windows-Einstellungen →`
   `Sicherheitseinstellungen → Richtlinien für öffentliche Schlüssel`
4. **Vertrauenswürdige Herausgeber** — Rechtsklick → **Importieren…** →
   Codesignaturzertifikat (`.cer`) auswählen.
5. **Vertrauenswürdige Stammzertifizierungsstellen** — Rechtsklick →
   **Importieren…** → Stammzertifikat (`.cer`) auswählen.<br>
   *(Bei öffentlich vertrauenswürdiger CA überspringen.)*

Nach dem nächsten GPO-Refresh (`gpupdate /force` oder Neustart)
vertraut jedes betroffene System dem Zertifikat.

#### 2 — Ausführungsrichtlinie per GPO erzwingen

1. Im selben (oder einem separaten) GPO navigieren zu:<br>
   `Computerkonfiguration → Richtlinien → Administrative Vorlagen →`
   `Windows-Komponenten → Windows PowerShell`
2. **Skriptausführung aktivieren** einschalten.
3. Auf **Nur signierte Skripte zulassen** (`AllSigned`) oder
   **Lokale Skripte und remote signierte Skripte zulassen**
   (`RemoteSigned`) setzen.

> **Hinweis:** Die per GPO gesetzte Ausführungsrichtlinie hat
> Vorrang vor lokal konfigurierten Richtlinien. Die effektive
> Richtlinie und ihre Quelle prüfen mit:
>
> ```powershell
> Get-ExecutionPolicy -List
> ```

#### 3 — Auf einem Domänen-Mitglied prüfen

```powershell
# Gruppenrichtlinien aktualisieren
gpupdate /force

# Vertrauenswürdiges Zertifikat prüfen
Get-ChildItem Cert:\LocalMachine\TrustedPublisher

# Ausführungsrichtlinie prüfen
Get-ExecutionPolicy -List

# Signiertes Skript validieren
Get-AuthenticodeSignature -FilePath \\Server\Share\YourScript.ps1 |
    Select-Object -ExpandProperty Status
```

### Kurzreferenz — Zertifikatspeicher

| Speicherort | Zweck |
|---|---|
| `Cert:\LocalMachine\TrustedPublisher` | Vertrauenswürdige Codesignaturzertifikate |
| `Cert:\LocalMachine\Root` | Vertrauenswürdige Stammzertifikate |
| `Cert:\LocalMachine\CA` | Zwischenzertifikate |
| `Cert:\CurrentUser\My` | Persönliche Zertifikate (Signiermaschine) |

---

## Was passiert, wenn ein signiertes Skript geändert wird?

Authenticode-Signaturen sind ein kryptografischer Hash über den
gesamten Dateiinhalt. Wird das Skript nach der Signatur in **irgend-
einer** Weise geändert — selbst nur ein einzelnes Zeichen — wird
die Signatur ungültig.

### Verhalten je Ausführungsrichtlinie

| Ausführungsrichtlinie | Verhalten bei geändertem signiertem Skript |
|---|---|
| `AllSigned` | **Blockiert** — Fehler: „Datei wurde seit der Signatur geändert" |
| `RemoteSigned` | Lokale Dateien laufen weiter (keine Signatur nötig). Remote-/UNC-Dateien werden blockiert |
| `Unrestricted` | Läuft, kann bei Remote-Dateien eine Warnung anzeigen |

### Signaturstatus prüfen

```powershell
Get-AuthenticodeSignature .\YourScript.ps1 | Select-Object Status, StatusMessage
```

| Status | Bedeutung |
|---|---|
| `Valid` | Datei wurde seit der Signatur nicht verändert |
| `HashMismatch` | Datei wurde nach der Signatur verändert — neu signieren |
| `NotSigned` | Kein Signaturblock vorhanden |
| `UnknownError` | Signaturzertifikat ist auf diesem System nicht vertrauenswürdig |

> **Wichtig:** Nach jeder Codeänderung muss das Skript erneut signiert
> werden. Der alte Signaturblock bleibt in der Datei, ist nach einer
> Inhaltsänderung aber kryptografisch ungültig.

---

## Bedienung

### Schritt 1 — Dateien auswählen

Auf **Browse...** klicken, um den Dateiauswahldialog zu öffnen. Eine
oder mehrere PowerShell-Dateien (`.ps1`, `.psm1`, `.psd1`, `.ps1xml`)
auswählen. Die gewählten Dateien erscheinen in der Liste links.
Das Tool ermittelt automatisch alle gültigen Codesignaturzertifikate
aus dem Zertifikatspeicher und von angeschlossenen Smartcards und
befüllt damit die Auswahl **Choose Code Signing Certificate**.

### Schritt 2 — Zertifikat auswählen

Das gewünschte Zertifikat aus der Liste wählen. Der Bereich
**Certificate Info** auf der rechten Seite zeigt die vollständigen
Details (Aussteller, Antragsteller, Thumbprint, Gültigkeit) des
ausgewählten Zertifikats.

Sind mehrere Codesignaturzertifikate vorhanden — etwa eines software-
basiert und eines auf einer Smartcard — erscheinen sie jeweils als
eigene Einträge. Beim Signieren mit einem Smartcard-Zertifikat fordert
Windows zur Eingabe der Smartcard-PIN auf.

### Schritt 3 — Signieren

Eine oder mehrere Dateien in der Liste markieren und auf **Sign**
klicken. Jede Datei wird mit SHA-256 signiert, über den konfigurierten
Zeitstempelserver (Standard: DigiCert) mit einem Zeitstempel versehen
und enthält die vollständige Zertifikatskette. Um einen anderen
Zeitstempelserver zu nutzen, vor dem Signieren auf die **⚙**-Schalt-
fläche neben dem Feld „Timestamp Server" klicken.
Im Bereich **Notifications** wird bestätigt, welche Dateien
erfolgreich signiert wurden bzw. welche Fehler aufgetreten sind.

### Schritt 4 — Schließen

Auf **Close** klicken (oder `Esc` drücken), um das Tool zu beenden.

## Screenshots

### WPF-Oberfläche — nach Dateiauswahl und Zertifikatauswahl

![WPF GUI](images/WPF-GUI.png)

### Signiertes Skript — der angehängte Authenticode-Signaturblock

![Signed script](images/Sign.png)

### Dateieigenschaften — Reiter „Digitale Signaturen" / „Zertifikat" bestätigt die Signatur

![Certificate properties](images/CodeSigningCert.png)

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).
