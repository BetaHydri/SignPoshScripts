# SignPoshScripts
WPF GUI written im PowerShell to sign your scripts.

<b>Prerequisites</b>

You need to import at least one CodeSigning Certificate into your users certificate store at: <b>Cert:\CurrentUser\My\\</b>

The enhanced key usage (EKU) must be <b>Code Signing (1.3.6.1.5.5.7.3.3)</b>

<b>Files</b>
<ul>
<li>CodeSigningTool.exe - precompiled executable of the PoSh Sign.ps1 script</li>
<li>SignPS.ps1 - WFP / PowerShell source code</li>
</ul>
