# ================================================================
# DC1 FULL SCRIPT
# Run on  : DC1 (192.168.10.10)
# Shell   : PowerShell as Administrator
# ================================================================
# PARAMETERS -- change these for different environments
# ================================================================
param(
    [string]$DC1IP      = "192.168.10.10",
    [string]$CAName     = "DC1-CA",
    [string]$Domain     = "bsol.online"
)

# ================================================================
# USAGE EXAMPLES:
#   Default (uses DC1 bsol.online):
#   .\DC1_Full.ps1
#
#   Different environment:
#   .\DC1_Full.ps1 -DC1IP "10.0.0.10" -CAName "CONTOSO-CA" -Domain "contoso.com"
# ================================================================

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
Write-Host "  DC1 Full Script" -ForegroundColor Cyan
Write-Host "  DC1 IP : $DC1IP" -ForegroundColor Cyan
Write-Host "  CA Name: $CAName" -ForegroundColor Cyan
Write-Host "  Domain : $Domain" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------
# PART 1 -- INSTALL AD CS ROLE
# WHY: Turns DC1 into a Certificate Authority so it can
#      issue and sign SSL certificates for your domain.
#      3 role services installed:
#      - AD-Certificate      = main CA role
#      - ADCS-Web-Enrollment = certsrv web page
#      - ADCS-Enroll-Web-Svc = Certificate Enrollment Web Service
# ----------------------------------------------------------------

Write-Host "PART 1 -- Installing AD CS Role..." -ForegroundColor Yellow
Write-Host "  WHY: Turns DC1 into a Certificate Authority (CA)" -ForegroundColor Gray
Write-Host "       that can issue SSL certs for your domain." -ForegroundColor Gray
Write-Host ""
Write-Host "  Installing 3 role services:" -ForegroundColor Gray
Write-Host "  - AD-Certificate (main CA)" -ForegroundColor Gray
Write-Host "  - ADCS-Web-Enrollment (certsrv page)" -ForegroundColor Gray
Write-Host "  - ADCS-Enroll-Web-Svc (enrollment web service)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Server will restart automatically after install..." -ForegroundColor Gray
Write-Host ""

Install-WindowsFeature AD-Certificate,ADCS-Web-Enrollment,ADCS-Enroll-Web-Svc -IncludeManagementTools -Restart

# Script pauses here due to restart
# After reboot run this script again and it will skip to Part 2


# ----------------------------------------------------------------
# CHECK IF AD CS IS INSTALLED BEFORE CONTINUING
# ----------------------------------------------------------------

$adcsInstalled = (Get-WindowsFeature AD-Certificate).Installed
if (-not $adcsInstalled) {
    Write-Host "  [ERROR] AD CS is not installed yet." -ForegroundColor Red
    Write-Host "  Run this script first to install AD CS, then rerun after reboot." -ForegroundColor Red
    exit
}

Write-Host "  [OK] AD CS is installed" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PAUSE -- CONFIGURE AD CS VIA SERVER MANAGER GUI
# WHY: AD CS configuration requires GUI -- no reliable
#      PowerShell method for the Enrollment Web Service
#      without an existing cert.
# ----------------------------------------------------------------

Pause-Script @"
  ACTION REQUIRED -- Configure AD CS via Server Manager GUI:

  1. Server Manager --> flag icon (top right) --> Configure AD CS
  2. Next --> Next
  3. Select role services:
       Certification Authority
       Certificate Enrollment Web Service
     --> Next
  4. Enterprise CA --> Next
  5. Root CA --> Next
  6. Create a new private key --> Next
  7. Keep defaults (SHA256, 2048) --> Next
  8. CA Name: $CAName --> Next
  9. Validity: 5 years --> Next --> Next --> Configure --> Close

  Then verify certsrv is working -- open browser on DC1:
  http://$DC1IP/certsrv

  If the certsrv page loads, your CA is ready.
  Then press any key to continue.
"@

# ----------------------------------------------------------------
# PART 2 -- CREATE CERT FOLDER ON DC1
# WHY: Stores the Root CA cert locally before
#      importing it into Group Policy.
# ----------------------------------------------------------------

Write-Host "PART 2 -- Creating C:\cert folder on DC1..." -ForegroundColor Yellow
Write-Host "  WHY: Stores Root.cer locally before GPO import." -ForegroundColor Gray
Write-Host ""

New-Item -ItemType Directory -Path "C:\cert" -Force | Out-Null
Write-Host "  [OK] C:\cert folder created" -ForegroundColor Green
Write-Host "  [DONE] Part 2 Complete" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------
# PAUSE -- DOWNLOAD ROOT CERT AND IMPORT TO GPO
# WHY: GPO cert import requires GUI.
#      Pushing Root CA cert via GPO makes all domain
#      computers automatically trust your internal CA.
# ----------------------------------------------------------------

Pause-Script @"
  ACTION REQUIRED -- Download Root cert and import to GPO:

  1. Open browser on DC1:
     http://$DC1IP/certsrv
     --> Download a CA certificate, certificate chain, or CRL
     --> Download CA certificate
     --> Save as C:\cert\Root.cer

  2. Group Policy Management
     --> expand domain ($Domain)
     --> Default Domain Policy --> Edit
     --> Computer Configuration
        --> Windows Settings
           --> Security Settings
              --> Public Key Policies
                 --> Trusted Root Certification Authorities
     --> Right-click --> Import
     --> Next --> select C:\cert\Root.cer
     --> Next --> Next --> Finish --> OK
     --> Close Group Policy Editor

  Then press any key to run gpupdate /force.
"@

# ----------------------------------------------------------------
# PART 3 -- FORCE GPO UPDATE
# WHY: Immediately pushes the Root CA cert GPO to all
#      domain machines without waiting for next scheduled update.
# ----------------------------------------------------------------

Write-Host "PART 3 -- Running gpupdate /force..." -ForegroundColor Yellow
Write-Host "  WHY: Immediately pushes Root CA cert to all domain" -ForegroundColor Gray
Write-Host "       machines so they trust your internal CA." -ForegroundColor Gray
Write-Host ""

gpupdate /force

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  DC1 Script Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Next: Switch to PC1 and run PC1_Full.ps1" -ForegroundColor White
Write-Host "        to verify OWA loads with no certificate warning." -ForegroundColor White
Write-Host ""
