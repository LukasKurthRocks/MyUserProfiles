# MyUserProfiles - Meine Profile

Unter anderem für meine experimentellen winget settings, meine PowerShell Profile (POSH + PWSH)...

Installation: `iex "& { $(irm https://github.com/LukasKurthRocks/MyUserProfiles/releases/latest/download/install.ps1) } -UseMSI"`

## Pfade
### Windows

- PowerShell (same name)
    - Windows PowerShell: `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
    - PowerShell: `$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
    - VSCode: `$HOME\Documents\PowerShell\Microsoft.VSCode_profile.ps1`
- VS Code
    - Visual Studio Code
    - Visual Studio Code Insider
- Terminal
    - Windows Terminal
    - Windows Terminal Preview
- Visual Studio
    - Extensions
    - Settings
- WinGet (Desktop Installer)

## Vorraussetzungen
Die Sachen hier packe ich so nicht in das Profil mit rein (vielleicht als Kommentar). Einmal installiert braucht diese Abfrage wieder keiner.

- Schriftarten
    - https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.ttf
    - https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.Complete.ttf
- Module
    - Install-Module posh-git -Scope CurrentUser
    - Install-Module oh-my-posh -Scope CurrentUser
- PowerShell Core (wenn gewünscht)
    - OneLiner: `iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"`

OneLiner:\
`iwr https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.ttf -O "$env:windir\Fonts\Delugia.Nerd.Font.ttf"; iwr https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.Complete.ttf -O "$env:windir\Fonts\Delugia.Nerd.Font.Complete.ttf"; Install-Module posh-git, oh-my-posh -Scope CurrentUser`

## Testing
Hinweise:

- https://devblogs.microsoft.com/powershell/optimizing-your-profile/
    - https://www.powershellgallery.com/packages/PSProfiler
        - Measure-Script