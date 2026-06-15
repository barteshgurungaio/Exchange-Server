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

Write-Host "PART 3 -- Creating C:\cert folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "C:\cert" -Force | Out-Null
Write-Host "  [OK] C:\cert folder created" -ForegroundColor Green
Write-Host "  [DONE] Part 3 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PAUSE -- SWITCH TO DC1
# ----------------------------------------------------------------

Pause-Script @"
  ACTION REQUIRED -- Switch to DC1 now:

  1. Run DC1_Full.ps1 on DC1
  2. Wait for AD CS to install and reboot
  3. Configure AD CS via Server Manager GUI after reboot:
       - Configure Active Directory Certificate Services
       - Choose and assign cert later --> Configure
       - Yes to additional role services
       - Certificate Enrollment Web Services --> Next
       - Windows Integrated auth, Built-in app pool identity
       - Choose and assign cert later --> Configure --> Close
  4. Verify certsrv works: $CertsrvUrl

  Once DC1 is ready, come back here and press any key.
"@

# ----------------------------------------------------------------
# PAUSE -- SUBMIT CSR VIA BROWSER
# ----------------------------------------------------------------

Pause-Script @"
  ACTION REQUIRED -- Submit CSR via browser on this server:

  1. Open browser --> $CertsrvUrl
  2. Request a certificate
  3. Advanced certificate request
  4. Open C:\ExchangeCert.req in Notepad --> Ctrl+A --> Ctrl+C
  5. Paste into Saved Request field
  6. Certificate Template: Web Server --> Submit
  7. Download Certificate --> save as C:\cert\Exchange.cer

  Then download Root CA certificate:
  8. Go back to certsrv home page
  9. Download a CA certificate, certificate chain, or CRL
  10. Download CA certificate --> save as C:\cert\Root.cer

  Verify both files exist in C:\cert before continuing.
"@

# Verify files exist
if (-not (Test-Path "C:\cert\Root.cer")) {
    Write-Host "  [ERROR] C:\cert\Root.cer not found!" -ForegroundColor Red
    Write-Host "  Download the Root CA certificate from certsrv first." -ForegroundColor Red
    exit
}
if (-not (Test-Path "C:\cert\Exchange.cer")) {
    Write-Host "  [ERROR] C:\cert\Exchange.cer not found!" -ForegroundColor Red
    Write-Host "  Download the Exchange certificate from certsrv first." -ForegroundColor Red
    exit
}
Write-Host "  [OK] Both certificate files found in C:\cert" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PART 4 -- IMPORT ROOT CERT TO TRUSTED STORE
# WHY: Makes Windows trust your DC1 CA so the browser
#      does not show a warning for DC1-issued certificates.
# NOTE: Import-Certificate is a PS cmdlet -- if it fails here
#       open regular PowerShell as Admin and run it there.
# ----------------------------------------------------------------

Write-Host "PART 4 -- Importing Root Certificate to Trusted Store..." -ForegroundColor Yellow
Write-Host "  WHY: Makes Windows trust your DC1 CA so no browser" -ForegroundColor Gray
Write-Host "       warning appears for DC1-issued certificates." -ForegroundColor Gray
Write-Host ""

Import-Certificate -FilePath "C:\cert\Root.cer" -CertStoreLocation Cert:\LocalMachine\Root

$rootCert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Issuer -like "*DC1*"}
if ($rootCert) {
    Write-Host "  [OK] Root certificate imported successfully" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Root cert not found -- try running Import-Certificate" -ForegroundColor Red
    Write-Host "            in regular PowerShell as Administrator" -ForegroundColor Red
}
Write-Host "  [DONE] Part 4 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PART 5 -- IMPORT AND ASSIGN EXCHANGE CERTIFICATE
# WHY: Installs the SSL cert into Exchange and assigns it
#      to IIS so OWA loads over HTTPS with no warning.
# ----------------------------------------------------------------

Write-Host "PART 5 -- Importing and Assigning Exchange Certificate..." -ForegroundColor Yellow
Write-Host "  WHY: Installs the SSL cert into Exchange and assigns" -ForegroundColor Gray
Write-Host "       it to IIS to enable HTTPS for OWA." -ForegroundColor Gray
Write-Host ""

Import-ExchangeCertificate `
    -FileData ([System.IO.File]::ReadAllBytes("C:\cert\Exchange.cer")) `
    -FriendlyName "ExchangeCert"

$thumbprint = (Get-ExchangeCertificate | Where-Object {$_.FriendlyName -eq "ExchangeCert"}).Thumbprint

if ($thumbprint) {
    Write-Host "  Found ExchangeCert thumbprint: $thumbprint" -ForegroundColor Gray
    Enable-ExchangeCertificate -Thumbprint $thumbprint -Services IIS -Force
    Write-Host "  [OK] ExchangeCert assigned to IIS" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] ExchangeCert not found after import" -ForegroundColor Red
    exit
}
Write-Host "  [DONE] Part 5 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PART 6 -- RESTART IIS
# WHY: IIS must restart to load the new certificate.
# NOTE: Must run in regular PowerShell -- not EMS.
#       If Access Denied -- open regular PS as Admin and run iisreset
# ----------------------------------------------------------------

Write-Host "PART 6 -- Restarting IIS..." -ForegroundColor Yellow
Write-Host "  WHY: IIS must restart to load the new SSL certificate." -ForegroundColor Gray
Write-Host "  NOTE: If Access Denied -- open regular PowerShell as" -ForegroundColor Gray
Write-Host "        Administrator and run: iisreset" -ForegroundColor Gray
Write-Host ""

iisreset

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Exchange Server Script Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Verify OWA loads -- open browser:" -ForegroundColor White
Write-Host "  https://$MailFQDN/owa" -ForegroundColor White
Write-Host ""
Write-Host "  If OWA loads with no warning -- switch to DC1" -ForegroundColor White
Write-Host "  and continue with DC1_Full.ps1 (Part 2 -- GPO)" -ForegroundColor White
Write-Host ""
