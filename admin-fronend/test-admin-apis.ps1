param(
    [string]$Base = "http://localhost:5247/api/v1",
    [string]$AdminEmail = $env:ALLONBIZ_ADMIN_EMAIL,
    [string]$AdminPassword = $env:ALLONBIZ_ADMIN_PASSWORD
)

if ([string]::IsNullOrWhiteSpace($AdminEmail) -or [string]::IsNullOrWhiteSpace($AdminPassword)) {
    Write-Host "Provide -AdminEmail and -AdminPassword, or set ALLONBIZ_ADMIN_EMAIL and ALLONBIZ_ADMIN_PASSWORD." -ForegroundColor Red
    exit 1
}

$body = @{
    email = $AdminEmail
    password = $AdminPassword
} | ConvertTo-Json -Compress

Write-Host ""
Write-Host "=== STEP 1: Login Test ===" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "$Base/admin/auth/login" -Method POST -Headers @{"Content-Type"="application/json"} -Body $body -UseBasicParsing
    Write-Host "[PASS] Login: HTTP $($response.StatusCode)" -ForegroundColor Green
    $data = $response.Content | ConvertFrom-Json
    $token = $data.data.accessToken
    Write-Host "  Admin: $($data.data.admin.firstName) $($data.data.admin.lastName) ($($data.data.admin.role))" -ForegroundColor DarkGray
} catch {
    Write-Host "[FAIL] Login: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{ "Content-Type" = "application/json"; "Authorization" = "Bearer $token" }
$pass = 1
$fail = 0

function Test-API {
    param([string]$Name, [string]$Method, [string]$Url, [string]$Body = $null)
    try {
        $params = @{ Uri = $Url; Method = $Method; Headers = $headers; UseBasicParsing = $true }
        if ($Body) { $params["Body"] = $Body }
        $r = Invoke-WebRequest @params
        $script:pass++
        Write-Host "[PASS] $Name - HTTP $($r.StatusCode)" -ForegroundColor Green
        return $r
    } catch {
        $code = 0
        try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        $script:fail++
        Write-Host "[FAIL] $Name - HTTP $code $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host ""
Write-Host "=== STEP 2: Dashboard ===" -ForegroundColor Cyan
Test-API "GET /admin/dashboard" "GET" "$Base/admin/dashboard"

Write-Host ""
Write-Host "=== STEP 3: Users ===" -ForegroundColor Cyan
Test-API "GET /users" "GET" "$Base/users?page=1&pageSize=10"

Write-Host ""
Write-Host "=== STEP 4: Shops ===" -ForegroundColor Cyan
Test-API "GET /admin/shops" "GET" "$Base/admin/shops"

Write-Host ""
Write-Host "=== STEP 5: Categories ===" -ForegroundColor Cyan
Test-API "GET /admin/categories" "GET" "$Base/admin/categories"

Write-Host ""
Write-Host "=== STEP 6: Notifications ===" -ForegroundColor Cyan
Test-API "GET /admin/notifications" "GET" "$Base/admin/notifications?pageNumber=1&pageSize=10"

Write-Host ""
Write-Host "=== STEP 7: Auth - Me ===" -ForegroundColor Cyan
Test-API "GET /admin/auth/me" "GET" "$Base/admin/auth/me"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RESULTS: $pass PASSED, $fail FAILED" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
Write-Host "============================================" -ForegroundColor Cyan
