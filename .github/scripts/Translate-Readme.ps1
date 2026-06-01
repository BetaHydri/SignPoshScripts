#requires -Version 7.0
<#
.SYNOPSIS
    Translates README.md to README.de.md using the OpenAI Chat Completions API,
    preserving markdown structure, code blocks, badges, and the language-switcher
    header.

.DESCRIPTION
    - Reads README.md from the repo root.
    - Replaces the English language-switcher header with the German one.
    - Splits the document into translatable text and pass-through spans
      (fenced code blocks, inline code, image refs, badge shields, LaTeX,
      bare URLs). Pass-through spans are wrapped in [[KEEP:N]] placeholder
      tokens that the model is instructed to reproduce verbatim.
    - Calls OpenAI with a strict "translate-only, preserve markdown and
      placeholders" system prompt.
    - Restores placeholders and writes README.de.md.

.PARAMETER ApiKey
    OpenAI API key (sk-...).

.PARAMETER Model
    OpenAI model. Default: gpt-4o-mini (good quality, cheap). Use gpt-4o or
    gpt-4.1 for highest quality.

.PARAMETER SourcePath
    Path to the English README. Default: README.md

.PARAMETER TargetPath
    Path to write the German README. Default: README.de.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ApiKey,
    [string]$Model = 'gpt-4o-mini',
    [string]$SourcePath = 'README.md',
    [string]$TargetPath = 'README.de.md'
)

$ErrorActionPreference = 'Stop'

$endpoint = 'https://api.openai.com/v1/chat/completions'

$source = Get-Content -Path $SourcePath -Raw

# 1) Swap language-switcher header (line right under H1).
$source = $source -replace `
    '(?m)^\*\*Language / Sprache:\*\*\s*\*\*English\*\*\s*\|\s*\[Deutsch\]\(README\.de\.md\)', `
    '**Language / Sprache:** [English](README.md) | **Deutsch**'

# 2) Protect non-translatable spans with [[KEEP:N]] placeholders.
$script:placeholders = [System.Collections.Generic.List[string]]::new()
function Save-Placeholder {
    param([string]$Value)
    $idx = $script:placeholders.Count
    $script:placeholders.Add($Value) | Out-Null
    return "[[KEEP:$idx]]"
}

# Order matters: most specific first.
$patterns = @(
    '(?s)```.*?```',                       # fenced code blocks
    '\[!\[[^\]]*\]\([^)]+\)\]\([^)]+\)',   # badge images wrapped in links
    '!\[[^\]]*\]\([^)]+\)',                # image links
    '`[^`\n]+`',                            # inline code
    '\$\\color\{[^}]+\}\{[^}]+\}\$',        # LaTeX color
    'https?://[^\s)]+'                      # bare URLs
)

$working = $source
foreach ($pattern in $patterns) {
    $working = [regex]::Replace($working, $pattern, {
        param($m) Save-Placeholder $m.Value
    })
}

# 3) Call OpenAI.
$systemPrompt = @'
You are a professional technical translator. Translate the user's Markdown
document from English to German.

STRICT RULES:
1. Output ONLY the translated Markdown. No commentary, no code fences around
   the whole output, no extra blank lines at the start or end.
2. Preserve every Markdown construct exactly: headings (# levels), tables
   (pipes and separators), lists, bold/italic, links, blockquotes, line
   breaks, and trailing punctuation.
3. Tokens of the form [[KEEP:N]] (where N is a number) MUST be reproduced
   verbatim and in the same order. Do not translate, modify, reorder, or
   remove them. Do not add or remove whitespace around them beyond what is
   present in the source.
4. Do not translate: code, file paths, command-line flags, cmdlet names,
   registry paths, certificate-store paths, URLs, environment variable names.
5. Translate UI element labels appearing in plain prose (e.g. "click Browse")
   into natural German; labels inside backticks/code are already protected
   by rule 3.
6. Use formal but accessible German technical writing. Prefer established
   German IT terminology (e.g. "Codesignaturzertifikat", "Zertifikatspeicher",
   "Ausfuehrungsrichtlinie", "Gruppenrichtlinie"). Keep English terms only
   where they are de-facto standard (e.g. "Thumbprint", "Smartcard", "WPF").
7. Keep all badge tables, image tables, and reference tables structurally
   identical (same number of columns and rows).
'@

$body = @{
    model       = $Model
    temperature = 0.2
    messages    = @(
        @{ role = 'system'; content = $systemPrompt }
        @{ role = 'user';   content = $working }
    )
} | ConvertTo-Json -Depth 5 -Compress

$headers = @{
    Authorization  = "Bearer $ApiKey"
    'Content-Type' = 'application/json; charset=utf-8'
}

Write-Host "POST $endpoint  (model: $Model, chars in: $($working.Length))"
$response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body

$translated = $response.choices[0].message.content

# Defensive: strip any outer ```markdown ... ``` fence the model might wrap.
if ($translated -match '(?s)^\s*```(?:markdown|md)?\s*\r?\n(?<inner>.*)\r?\n```\s*$') {
    $translated = $Matches['inner']
}

# 4) Restore placeholders (descending so [[KEEP:10]] isn't shadowed by [[KEEP:1]]).
for ($i = $script:placeholders.Count - 1; $i -ge 0; $i--) {
    $translated = $translated.Replace("[[KEEP:$i]]", $script:placeholders[$i])
}

# 5) Sanity check: no orphan placeholders left behind.
if ($translated -match '\[\[KEEP:\d+\]\]') {
    throw "Orphan placeholder(s) remain in output. Model likely altered token format."
}

Set-Content -Path $TargetPath -Value $translated -Encoding utf8NoBOM
Write-Host "Wrote $TargetPath ($($translated.Length) chars)"
