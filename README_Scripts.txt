================================================================
   EXCHANGE SSL CERTIFICATE LAB - SCRIPTS README
   Personal Practice | VMware Home Lab
================================================================

3 SCRIPTS -- RUN IN THIS ORDER:
----------------------------------------------------------------

SCRIPT 1 - ExchangeServer_Full.ps1
  Run on  : MAIL-SERVER
  Shell   : Exchange Management Shell (EMS) as Administrator
  Does    : Virtual Directories + CSR + Cert folder +
            Import certs + Assign to IIS + iisreset

  Script auto-pauses when you need to:
  - Switch to DC1 for AD CS install
  - Submit CSR via certsrv browser
  Then press any key to continue.


SCRIPT 2 - DC1_Full.ps1
  Run on  : DC1 (192.168.10.10)
  Shell   : PowerShell as Administrator
  Does    : Installs AD CS + Creates cert folder +
            GPO import guide + gpupdate /force

  Script auto-pauses when you need to:
  - Configure AD CS via Server Manager GUI after reboot
  - Download Root.cer and import into GPO via GUI
  Then press any key to continue.

  NOTE: Run this script TWICE:
  - First run  --> installs AD CS + server reboots
  - Second run --> continues from where it left off


SCRIPT 3 - PC1_Full.ps1
  Run on  : PC1 (domain client)
  Shell   : PowerShell as Administrator
  Does    : gpupdate /force + verifies Root CA cert


================================================================
PARAMETERS -- CUSTOMIZE FOR ANY ENVIRONMENT
================================================================

  Default (uses your bsol.online lab settings -- no changes needed):

  .\ExchangeServer_Full.ps1
  .\DC1_Full.ps1
  .\PC1_Full.ps1

  Different domain (pass parameters):

  .\ExchangeServer_Full.ps1 -Domain "contoso.com" -MailFQDN "mail.contoso.com" -Org "Contoso" -DC1IP "10.0.0.10"
  .\DC1_Full.ps1 -DC1IP "10.0.0.10" -CAName "CONTOSO-CA" -Domain "contoso.com"
  .\PC1_Full.ps1 -MailFQDN "mail.contoso.com" -Domain "contoso.com"


================================================================
WHAT STILL NEEDS GUI
================================================================

  1. Configure AD CS after reboot (Server Manager)
  2. Submit CSR via certsrv browser (Exchange Server)
  3. Download certs from certsrv (Exchange Server + DC1)
  4. Import Root cert into Default Domain Policy (DC1)

  Scripts will pause and guide you through each of these.


================================================================
CHECKLIST
================================================================

  MAIL-SERVER
  [ ] ExchangeServer_Full.ps1 started
  [ ] Script paused -- switched to DC1 and ran DC1_Full.ps1
  [ ] DC1 rebooted + AD CS configured via GUI
  [ ] certsrv verified at http://192.168.10.10/certsrv
  [ ] Back on Exchange -- pressed key to continue script
  [ ] CSR submitted via certsrv browser
  [ ] Exchange.cer saved to C:\cert
  [ ] Root.cer saved to C:\cert
  [ ] Pressed key -- script completed cert import + IIS assign
  [ ] OWA loads at https://mail-server.bsol.online/owa

  DC1
  [ ] DC1_Full.ps1 run (first time -- AD CS install + reboot)
  [ ] AD CS configured via Server Manager GUI
  [ ] certsrv loads at http://192.168.10.10/certsrv
  [ ] DC1_Full.ps1 run again -- continued to GPO section
  [ ] Root.cer downloaded from certsrv on DC1
  [ ] Root cert imported into Default Domain Policy (GUI)
  [ ] gpupdate /force run

  PC1
  [ ] PC1_Full.ps1 completed
  [ ] OWA loads with NO certificate warning -- DONE!

================================================================
