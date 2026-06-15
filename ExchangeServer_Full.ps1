# Allow script to run without digital signature
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# ================================================================
# EXCHANGE SERVER FULL SCRIPT
# Run on  : MAIL-SERVER
# Shell   : Exchange Management Shell (EMS) as Administrator
# ================================================================
# PARAMETERS -- change these for different environments
# ================================================================
param(
    [string]$ServerName = "MAIL-SERVER",
    [string]$Domain     = "bsol.online",
    [string]$MailFQDN   = "mail-server.bsol.online",
    [string]$Org        = "bsol",
    [string]$Department = "IT",
    [string]$City       = "NY",
    [string]$State      = "NY",
    [string]$Country    = "US",
    [string]$DC1IP      = "192.168.10.10"
)

# ================================================================
# USAGE EXAMPLES:
#   Default (uses bsol.online):
#   .\ExchangeServer_Full.ps1
#
#   Different domain:
#   .\ExchangeServer_Full.ps1 -Domain "contoso.com" -MailFQDN "mail.contoso.com" -Org "Contoso" -DC1IP "10.0.0.10"
# ================================================================

# Build URLs from parameters
$OwaUrl         = "https://$MailFQDN/owa"
$EcpUrl         = "https://$MailFQDN/ecp"
$OabUrl         = "https://$MailFQDN/OAB"
$ActiveSyncUrl  = "https://$MailFQDN/Microsoft-Server-ActiveSync"
$MapiUrl        = "https://$MailFQDN/mapi"
$EwsUrl         = "https://$MailFQDN/EWS/Exchange.asmx"
$CertsrvUrl     = "http://$DC1IP/certsrv"

function Pause-Script($message) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "  PAUSE -- ACTION REQUIRED" -ForegroundColor Magenta
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host $message -ForegroundColor White
    Write-Host ""
    Write-Host "  Press any key when done to continue..." -ForegroundColor Magenta
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}

Clear-Host
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  EXCHANGE SSL CERTIFICATE LAB" -ForegroundColor Cyan
Write-Host "  Exchange Server Full Script" -ForegroundColor Cyan
Write-Host "  Server : $ServerName" -ForegroundColor Cyan
Write-Host "  Domain : $Domain" -ForegroundColor Cyan
Write-Host "  DC1    : $DC1IP" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------
# PART 1 -- VIRTUAL DIRECTORIES
# WHY: Sets matching Internal and External URLs on Exchange so
#      the certificate covers the correct domain names.
# ----------------------------------------------------------------

Write-Host "PART 1 -- Configuring Virtual Directories..." -ForegroundColor Yellow
Write-Host "  WHY: Sets Internal + External URLs before generating" -ForegroundColor Gray
Write-Host "       the CSR so the cert covers the right domains." -ForegroundColor Gray
Write-Host ""

Set-OwaVirtualDirectory -Identity "$ServerName\OWA (Default Web Site)" -InternalUrl $OwaUrl -ExternalUrl $OwaUrl
Write-Host "  [OK] OWA  --> $OwaUrl" -ForegroundColor Green

Set-EcpVirtualDirectory -Identity "$ServerName\ECP (Default Web Site)" -InternalUrl $EcpUrl -ExternalUrl $EcpUrl
Write-Host "  [OK] ECP  --> $EcpUrl" -ForegroundColor Green

Set-OabVirtualDirectory -Identity "$ServerName\OAB (Default Web Site)" -InternalUrl $OabUrl -ExternalUrl $OabUrl
Write-Host "  [OK] OAB  --> $OabUrl" -ForegroundColor Green

Set-ActiveSyncVirtualDirectory -Identity "$ServerName\Microsoft-Server-ActiveSync (Default Web Site)" -InternalUrl $ActiveSyncUrl -ExternalUrl $ActiveSyncUrl
Write-Host "  [OK] ActiveSync --> $ActiveSyncUrl" -ForegroundColor Green

Set-MapiVirtualDirectory -Identity "$ServerName\mapi (Default Web Site)" -InternalUrl $MapiUrl
Set-MapiVirtualDirectory -Identity "$ServerName\mapi (Default Web Site)" -ExternalUrl $MapiUrl
Write-Host "  [OK] MAPI --> $MapiUrl" -ForegroundColor Green

Set-WebServicesVirtualDirectory -Identity "$ServerName\EWS (Default Web Site)" -InternalUrl $EwsUrl -ExternalUrl $EwsUrl
Write-Host "  [OK] EWS  --> $EwsUrl" -ForegroundColor Green

Write-Host ""
Write-Host "  Verifying OWA Virtual Directory..." -ForegroundColor Gray
Get-OwaVirtualDirectory | Format-List InternalUrl, ExternalUrl
Write-Host "  [DONE] Part 1 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PART 2 -- GENERATE CSR
# WHY: Creates the certificate request file that will be
#      submitted to DC1 CA to get the SSL certificate.
# ----------------------------------------------------------------

Write-Host "PART 2 -- Generating Certificate Request (CSR)..." -ForegroundColor Yellow
Write-Host "  WHY: Creates ExchangeCert.req -- the application form" -ForegroundColor Gray
Write-Host "       sent to DC1 CA to request an SSL certificate." -ForegroundColor Gray
Write-Host ""

New-ExchangeCertificate `
    -FriendlyName "ExchangeCert" `
    -GenerateRequest `
    -KeySize 2048 `
    -RequestFile "C:\ExchangeCert.req" `
    -SubjectName "C=$Country,S=$State,L=$City,O=$Org,OU=$Department,CN=$MailFQDN" `
    -DomainName "$MailFQDN","autodiscover.$Domain"

Write-Host ""
Write-Host "  CSR saved to: C:\ExchangeCert.req" -ForegroundColor Green
Write-Host ""
Write-Host "  CSR Contents:" -ForegroundColor Gray
Write-Host "  --------------------------------------------------------" -ForegroundColor Gray
Get-Content C:\ExchangeCert.req
Write-Host "  --------------------------------------------------------" -ForegroundColor Gray
Write-Host "  [DONE] Part 2 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PART 3 -- CREATE CERT FOLDER
# WHY: Folder to store downloaded certificates from certsrv.
# ----------------------------------------------------------------

Write-Host "PART 3 -- Creating C: