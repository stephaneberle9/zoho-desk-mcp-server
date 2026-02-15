# Zoho Desk Token Setup Script
# Reads the self_client JSON downloaded from Zoho API Console,
# exchanges the authorization code for access + refresh tokens,
# and updates config.json.
#
# Works on Windows (PowerShell 5.1+), macOS, and Linux (PowerShell Core / pwsh).

param(
    [string]$JsonFile,
    [ValidateSet("US", "EU", "IN", "AU", "JP", "CA")]
    [string]$Region
)

# Zoho accounts URLs per datacenter region
$regionUrls = @{
    US = "https://accounts.zoho.com"
    EU = "https://accounts.zoho.eu"
    IN = "https://accounts.zoho.in"
    AU = "https://accounts.zoho.com.au"
    JP = "https://accounts.zoho.jp"
    CA = "https://accounts.zohocloud.ca"
}

$configPath = Join-Path $PSScriptRoot "config.json"

# Find the self_client JSON file
if (-not $JsonFile) {
    # Auto-detect: pick the most recent self_client*.json from Downloads
    $userHome = [Environment]::GetFolderPath("UserProfile")
    $downloads = Join-Path $userHome "Downloads"

    if (-not (Test-Path $downloads)) {
        # XDG fallback for Linux
        $xdgDir = $env:XDG_DOWNLOAD_DIR
        if ($xdgDir -and (Test-Path $xdgDir)) {
            $downloads = $xdgDir
        } else {
            Write-Host "ERROR: Downloads folder not found at $downloads" -ForegroundColor Red
            Write-Host "Usage: ./setup-token.ps1 [-Region EU] [-JsonFile <path-to-self_client.json>]"
            exit 1
        }
    }

    $found = Get-ChildItem -Path $downloads -Filter "self_client*.json" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($found) {
        $JsonFile = $found.FullName
        Write-Host "Found: $JsonFile" -ForegroundColor Cyan
    } else {
        Write-Host "ERROR: No self_client*.json found in $downloads" -ForegroundColor Red
        Write-Host "Usage: ./setup-token.ps1 [-Region EU] [-JsonFile <path-to-self_client.json>]"
        exit 1
    }
}

if (-not (Test-Path $JsonFile)) {
    Write-Host "ERROR: File not found: $JsonFile" -ForegroundColor Red
    exit 1
}

# Read the downloaded JSON
$grant = Get-Content $JsonFile -Raw | ConvertFrom-Json

if (-not $grant.code -or -not $grant.client_id -or -not $grant.client_secret) {
    Write-Host "ERROR: JSON file is missing required fields (code, client_id, client_secret)" -ForegroundColor Red
    exit 1
}

# Load existing config if present
$orgId = $null
$existingConfig = $null
if (Test-Path $configPath) {
    $existingConfig = Get-Content $configPath -Raw | ConvertFrom-Json
    $orgId = $existingConfig.orgId
}

# Determine region: parameter > existing config > prompt user
if (-not $Region) {
    if ($existingConfig -and $existingConfig.region) {
        $Region = $existingConfig.region
        Write-Host "Region: $Region (from config.json)" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "Select your Zoho datacenter region:" -ForegroundColor Cyan
        Write-Host "  1) US  - accounts.zoho.com"
        Write-Host "  2) EU  - accounts.zoho.eu"
        Write-Host "  3) IN  - accounts.zoho.in"
        Write-Host "  4) AU  - accounts.zoho.com.au"
        Write-Host "  5) JP  - accounts.zoho.jp"
        Write-Host "  6) CA  - accounts.zohocloud.ca"
        Write-Host ""
        $choice = Read-Host "Enter choice (1-6)"
        $Region = switch ($choice) {
            "1" { "US" } "2" { "EU" } "3" { "IN" }
            "4" { "AU" } "5" { "JP" } "6" { "CA" }
            default {
                Write-Host "Invalid choice. Defaulting to US." -ForegroundColor Yellow
                "US"
            }
        }
    }
}

$accountsUrl = $regionUrls[$Region]
Write-Host "Exchanging authorization code for tokens..." -ForegroundColor Cyan
Write-Host "  Region:    $Region ($accountsUrl)"
Write-Host "  Client ID: $($grant.client_id.Substring(0, 15))..."

# Exchange the authorization code for access + refresh tokens
$body = @{
    grant_type    = "authorization_code"
    client_id     = $grant.client_id
    client_secret = $grant.client_secret
    code          = $grant.code
}

try {
    $response = Invoke-RestMethod -Uri "$accountsUrl/oauth/v2/token" -Method Post -Body $body
} catch {
    Write-Host "FAILED: Token exchange request failed" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow
    }
    exit 1
}

if (-not $response.access_token) {
    Write-Host "FAILED: No access_token in response" -ForegroundColor Red
    Write-Host ($response | ConvertTo-Json -Depth 5)
    if ($response.error -eq "invalid_client") {
        Write-Host ""
        Write-Host "This usually means:" -ForegroundColor Yellow
        Write-Host "  - Wrong region (try: ./setup-token.ps1 -Region EU)" -ForegroundColor Yellow
        Write-Host "  - The authorization code has expired (generate a new one)" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host "SUCCESS: Tokens received" -ForegroundColor Green
Write-Host "  Access token:  $($response.access_token.Substring(0, 20))..."
if ($response.refresh_token) {
    Write-Host "  Refresh token: $($response.refresh_token.Substring(0, 20))..."
} else {
    Write-Host "  Refresh token: (not returned - reusing existing)" -ForegroundColor Yellow
}
Write-Host "  Expires in:    $($response.expires_in) seconds"

# Build updated config
$refreshToken = if ($response.refresh_token) { $response.refresh_token }
                elseif ($existingConfig -and $existingConfig.refreshToken) { $existingConfig.refreshToken }
                else { "NONE" }

$config = [ordered]@{
    accessToken  = $response.access_token
    orgId        = if ($orgId) { $orgId } else { "YOUR_ORG_ID" }
    clientId     = $grant.client_id
    clientSecret = $grant.client_secret
    refreshToken = $refreshToken
    region       = $Region
}

# Write config.json (UTF8 without BOM, cross-platform)
$json = $config | ConvertTo-Json
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $json | Set-Content $configPath -Encoding utf8
} else {
    [System.IO.File]::WriteAllText($configPath, $json, [System.Text.UTF8Encoding]::new($false))
}
Write-Host "Updated: $configPath" -ForegroundColor Green

if ($config.orgId -eq "YOUR_ORG_ID") {
    Write-Host ""
    Write-Host "NOTE: orgId is not set yet. Edit config.json and add your Zoho Desk Org ID." -ForegroundColor Yellow
    Write-Host "Find it at: Zoho Desk > Settings > Developer Space > API > API Details"
}

Write-Host ""
Write-Host "Done! Access token expires in 1 hour." -ForegroundColor Cyan
Write-Host "To refresh later, run: ./setup-token.ps1" -ForegroundColor Cyan
