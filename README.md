# MyUserProfiles - Meine Profile

Unter anderem für meine experimentellen winget settings, meine PowerShell Profile (POSH + PWSH)...

## Pfade
### Windows

- PowerShell
    - Windows PowerShell
    - PowerShell
- Terminal
    - Windows Terminal
    - Windows Terminal Preview
- VS Code
    - Visual Studio Code
    - Visual Studio Code Insider
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

OneLiner:\
`iwr https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.ttf -O "$env:windir\Fonts\Delugia.Nerd.Font.ttf"; iwr https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.Complete.ttf -O "$env:windir\Fonts\Delugia.Nerd.Font.Complete.ttf"; Install-Module posh-git, oh-my-posh -Scope CurrentUser`

## Testing
Hinweise:

- https://devblogs.microsoft.com/powershell/optimizing-your-profile/
    - https://www.powershellgallery.com/packages/PSProfiler
        - Measure-Script