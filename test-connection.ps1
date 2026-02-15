# Test Zoho Desk API Connection
# Reads credentials from config.json and verifies API access

$configPath = Join-Path $PSScriptRoot "config.json"

if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: config.json not found at $configPath" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

if (-not $config.accessToken -or -not $config.orgId) {
    Write-Host "ERROR: config.json must contain accessToken and orgId" -ForegroundColor Red
    exit 1
}

# Determine API base URL from region
$deskUrls = @{
    US = "https://desk.zoho.com"
    EU = "https://desk.zoho.eu"
    IN = "https://desk.zoho.in"
    AU = "https://desk.zoho.com.au"
    JP = "https://desk.zoho.jp"
    CA = "https://desk.zohocloud.ca"
}
$region = if ($config.region) { $config.region } else { "US" }
$deskUrl = $deskUrls[$region]

Write-Host "Testing Zoho Desk API connection..." -ForegroundColor Cyan
Write-Host "  Region: $region ($deskUrl)"
Write-Host "  Org ID: $($config.orgId)"

$headers = @{
    "Authorization" = "Zoho-oauthtoken $($config.accessToken)"
    "orgId"         = $config.orgId
}

try {
    $response = Invoke-RestMethod -Uri "$deskUrl/api/v1/tickets" -Headers $headers -Method Get
    Write-Host "SUCCESS: Connected to Zoho Desk API" -ForegroundColor Green
    Write-Host "Tickets returned: $($response.data.Count)"
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorBody = $_.ErrorDetails.Message

    Write-Host "FAILED: Could not connect to Zoho Desk API" -ForegroundColor Red
    Write-Host "Status code: $statusCode"

    if ($errorBody) {
        $errorJson = $errorBody | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($errorJson.errorCode) {
            Write-Host "Error code: $($errorJson.errorCode)" -ForegroundColor Yellow
            Write-Host "Message: $($errorJson.message)" -ForegroundColor Yellow
        }
        else {
            Write-Host "Response: $errorBody"
        }
    }

    if ($statusCode -eq 401) {
        Write-Host "`nYour access token is expired or invalid. Refresh it using your clientId, clientSecret, and refreshToken." -ForegroundColor Yellow
    }
}
