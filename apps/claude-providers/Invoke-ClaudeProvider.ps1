param(
    [Parameter(Mandatory)]
    [ValidateSet('anthropic', 'minimax', 'kimi', 'kimi-1m')]
    [string]$Provider,
    [string[]]$ClaudeArgs = @()
)

$ErrorActionPreference = 'Stop'

$providerVars = @(
    'ANTHROPIC_BASE_URL',
    'ANTHROPIC_AUTH_TOKEN',
    'ANTHROPIC_API_KEY',
    'ANTHROPIC_MODEL',
    'ANTHROPIC_DEFAULT_OPUS_MODEL',
    'ANTHROPIC_DEFAULT_SONNET_MODEL',
    'ANTHROPIC_DEFAULT_HAIKU_MODEL',
    'ANTHROPIC_DEFAULT_FABLE_MODEL',
    'CLAUDE_CODE_SUBAGENT_MODEL',
    'CLAUDE_CODE_EFFORT_LEVEL',
    'CLAUDE_CODE_AUTO_COMPACT_WINDOW',
    'CLAUDE_CODE_MAX_CONTEXT_TOKENS',
    'ENABLE_TOOL_SEARCH'
)

foreach ($name in $providerVars) {
    Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
}

if ($Provider -ne 'anthropic') {
    $configPath = Join-Path $env:USERPROFILE '.claude\providers.json'
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "Provider config not found: $configPath (see providers.example.json)"
    }
    $config = (Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json).$Provider
    if (-not $config) {
        throw "Provider '$Provider' is not defined in $configPath"
    }
    foreach ($property in $config.PSObject.Properties) {
        Set-Item -LiteralPath "Env:$($property.Name)" -Value ([string]$property.Value)
    }
}

$claude = Get-Command claude.exe -ErrorAction SilentlyContinue
$claudePath = if ($claude) { $claude.Source } else { Join-Path $env:USERPROFILE '.local\bin\claude.exe' }
if (-not (Test-Path -LiteralPath $claudePath)) {
    throw "claude.exe not found (looked in PATH and $claudePath)"
}

& $claudePath @ClaudeArgs
exit $LASTEXITCODE
