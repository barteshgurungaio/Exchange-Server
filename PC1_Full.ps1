# Allow script to run without digital signature
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# ================================================================
# PC1 FULL SCRIPT
# Run on  : PC1 (domain client)
# Shell   : PowerShell as Administrator
# ================================================================
# PARAMETERS -- change these for different environments
# ================================================================
param(
    [string]$MailFQDN = "mail-server.bsol.online",
    [string]$Domain   = "bsol.online"
)

# ================================================================
# USAGE EXAMPLES:
#   Default (uses bsol.online):
#   .\PC1_Full.ps1
#
#   Different domain:
#   .\PC1_Full.ps1 -MailFQDN "mail.contoso.com" -Domain "contoso.com"
# ================================================================

Clear-Host
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  EXCHANGE SSL CERTIFICATE LAB" -ForegroundColor Cyan
Write-Host "  PC1 Verification Script" -ForegroundColor Cyan
Write-Host "  Mail Server : $MailFQDN" -ForegroundColor Cyan
Write-Host "  Domain      : $Domain" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------
# PART 1 -- FORCE GPO UPDATE
# WHY: Pulls the Root CA cert from DC1 via Group Policy
#      so PC1 trusts your internal Certificate Authority.
# ----------------------------------------------------------------

Write-Host "PART 1 -- Running gpupdate /force..." -ForegroundColor Yellow
Write-Host "  WHY: Pulls Root CA cert GPO from DC1 so PC1 trusts" -ForegroundColor Gray
Write-Host "       your internal Certificate Authority." -ForegroundColor Gray
Write-Host ""

gpupdate /force

Write-Host ""
Write-Host "  [DONE] Part 1 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PART 2 -- VERIFY ROOT CA CERT IS TRUSTED
# WHY: Confirms the Root CA cert was successfully pushed
#      to PC1 via Group Policy.
# ----------------------------------------------------------------

Write-Host "PART 2 -- Verifying Root CA cert in Trusted Root store..." -ForegroundColor Yellow
Write-Host "  WHY: Confirms PC1 now trusts your internal CA." -ForegroundColor Gray
Write-Host ""

$rootCert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Issuer -like "*DC1*"}

if ($rootCert) {
    Write-Host "  [OK] Root CA certificate found:" -ForegroundColor Green
    Write-Host "       Subject : $($rootCert.Subject)" -ForegroundColor Gray
    Write-Host "       Issuer  : $($rootCert.Issuer)" -ForegroundColor Gray
    Write-Host "       Expires : $($rootCert.NotAfter)" -ForegroundColor Gray
} else {
    Write-Host "  [WARNING] Root CA cert not found yet." -ForegroundColor Red
    Write-Host "            Wait a few minutes and run gpupdate /force again." -ForegroundColor Red
}

Write-Host ""
Write-Host "  [DONE] Part 2 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# FINAL -- OPEN OWA IN BROWSER
# ----------------------------------------------------------------

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  PC1 Script Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Open browser on PC1 and go to:" -ForegroundColor White
Write-Host "  https://$MailFQDN/owa" -ForegroundColor White
Write-Host ""
Write-Host "  If OWA loads with NO certificate warning -- LAB COMPLETE!" -ForegroundColor Green
Write-Host ""
