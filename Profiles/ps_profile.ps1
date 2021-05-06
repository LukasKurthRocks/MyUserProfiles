#
#  Syncable PSProfile
#

# TODO: Optimizing Profile: https://devblogs.microsoft.com/powershell/optimizing-your-profile/
# Cleaning up this profile.

return
if ($PSVersionTable.PSVersion.Major -lt 3) {
    return
}

#region Configuration
# Set Default Parameters
$PSDefaultParameterValues['Get-Help:ShowWindow'] = $true
$PSDefaultParameterValues['Send-MailMessage:From'] = "kurth@$env:COMPUTERNAME.lokal"
$VerboseProfile = $false
#endregion

#region Profile Functions
function Get-PowerShellTerminalType {
    if ($PSVersionTable.PSEdition.ToString() -eq 'Core') {
        $parent = (Get-Process -Id $PID).Parent
        if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
            $parent = (Get-Process -Id $parent.ID).Parent
        }
    }
    else {
        $cimSession = New-CimSession
        $SessionProcess = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID" -Property ParentProcessId -CimSession $cimSession
        if ($null -ne $ParentProcess) {
            $parent = Get-Process -Id $SessionProcess.ParentProcessId
            if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
                $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($parent.ID)" -Property ParentProcessId -CimSession $cimSession).ParentProcessId
            }
        }
        else {
            if ($host.name -match ' ISE') {
                $parent = @{
                    ProcessName = "ISE"
                }
            }
            else {
                # NO FOUND
            }
        }
    }
    
    try {
        $terminal = switch ($parent.ProcessName) {
            { $PSItem -in 'explorer', 'conhost' } { 'Windows Console' }
            'Console' { 'Console2/Z' }
            'ConEmuC64' { 'ConEmu' }
            'WindowsTerminal' { 'Windows Terminal' }
            'FluentTerminal.SystemTray' { 'Fluent Terminal' }
            'Code' { 'Visual Studio Code' }
            'ISE' { 'Windows PowerShell ISE' }
            default { $PSItem }
        }
    }
    catch {
        $terminal = $parent.ProcessName
    }

    return @{
        title   = "Terminal"
        content = $terminal
    }
}

function IsConsoleRunningElevated {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $princ = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $princ.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Quad9Test {
    [CmdLetBinding()]
    param()

    $ping = New-Object -TypeName System.Net.NetworkInformation.Ping
    $pingreturns = $ping.send("9.9.9.9")
    
    if ($pingreturns.Status -eq "Success") {
        Write-Verbose "Quad9 test successful"
        return $true
    }
    else {
        Write-Verbose "Quad9 test failed $($pingreturns.Status). Please reconnect to network and try again."
        return $false
    }
}

# Weather Forecast. For more informations: (curl http://wttr.in/:help -UserAgent "curl" ).Content
function Get-Weather {
    [CmdLetBinding()]
    param()

    if (Quad9Test -Verbose:$VerbosePreference) {
        (Invoke-WebRequest "http://wttr.in/~Rothenburg,Germany?q0&lang=de" -UserAgent "curl" ).Content
    }
}
#endregion

# Apply ISE Code
if ($psISE -or (Get-PowerShellTerminalType).content -eq "Windows PowerShell ISE") {
    Write-Verbose "PowerShell Host Name: $($Host.Name)" -Verbose:$VerboseProfile
    #$Host.Name -eq 'Windows PowerShell ISE Host'
}
# ServerRemoteHost | RemoteHost => Sowohl Admin Center, als auch Enter-PSSession

$SystemFunction = Get-ChildItem function:
$SystemAliasses = Get-Alias

# Import Functions
if (Test-Path -Path "$PSScriptRoot\profile_scripts" -ErrorAction SilentlyContinue) {
    $Host.UI.RawUI.WindowTitle = "PROFILE: Loading scripts folder"

    Resolve-Path "$PSScriptRoot\profile_scripts\*.ps1" | `
        Where-Object { !($_.ProviderPath.Contains("TEST")) } | `
        Foreach-Object { . $_.ProviderPath }
}

#region Theme Settings
# Windows Terminal has THEME-ING with own prompt
if (!$env:WT_Session) {
    # set execution time before commands
    function global:prompt {
        $arrows = '>'
        if ($NestedPromptLevel -gt 0) {
            $arrows = $arrows * $NestedPromptLevel
        }
    
        # only last parent
        $currentDirectory = Split-Path (Get-Location) -Leaf

        $curUser = $env:USERNAME
        #$curComp = $env:COMPUTERNAME
        Write-Host -NoNewLine $curUser -ForegroundColor Cyan
        Write-Host -NoNewLine "@" -ForegroundColor Cyan
        Write-Host -NoNewLine "[" -ForegroundColor Yellow
        Write-Host -NoNewLine ("{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)) -ForegroundColor White
        Write-Host -NoNewLine "]" -ForegroundColor Yellow
        Write-Host -NoNewLine "-$(((Get-History -Count 1).ID + 1)) " -ForegroundColor Yellow
        Write-Host -NoNewLine "$currentDirectory" -ForegroundColor Cyan
        Write-Host -NoNewLine "$arrows" #-ForegroundColor Red
    
        if (IsConsoleRunningElevated) {
            $Admin = ""
        }
        else {
            $Admin = " (No Admin)"
        }

        #$host.UI.RawUI.WindowTitle = "PowerShell -- $curUser @ $curComp "
        $host.UI.RawUI.WindowTitle = "$([net.dns]::GetHostName()) $([string]::Join(".", ("$((Get-Host).Version)".Split(".")[0,1])))$Admin $(Get-Location)"
        #Write-VcsStatus
        return " "
    }
    
    # Bei mir ist die Farbe der Argumente falsch.
    Set-PSReadLineOption -Colors @{ Parameter = 'Gray' }
}
# Delugia.Nerd.Font.Complete.ttf + Delugia.Nerd.Font.ttf
# Install-Module posh-git -Scope CurrentUser
# Install-Module oh-my-posh -Scope CurrentUser
# Man kann Einstellungen fuer die Themes setzen: $ThemeSettings, $GitPromptSettings
# So sieht man anhand von "$ThemeSettings.PromptSymbols.ElevatedSymbol", dass es im Admin laeuft oder nicht.
else {
    if (IsConsoleRunningElevated) {
        # Versteckt den Namen, wenn Standard
        $DefaultUser = "Kurth"
    }
    if (get-module posh-git) {
        Import-Module posh-git
    }
    if (get-module oh-my-posh) {
        Import-Module oh-my-posh
    }

    # Installation Ordner: $ThemeSettings.MyThemesLocation
    # Offizielle Themes:   https://github.com/JanDeDobbeleer/oh-my-posh#themes
    Set-Theme Agnoster
}
#endregion

function Get-ProfileFunctions { Get-ChildItem function: | Where-Object { ($SystemFunction -notcontains $_) } }
function Get-ProfileAliasses { Get-Alias | Where-Object { ($SystemAliasses -notcontains $_) } }

Set-Alias -Name 'profileFunc' -Value 'Get-ProfileFunctions'
Set-Alias -Name 'profileAlias' -Value 'Get-ProfileAliasses'

# Winget Argument Completer
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# TODO: Still needing improvements
function Backup-PowerShellHistory {
    # "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
    # Current Session Log: Get-History
    [CmdLetBinding()]
    param([switch]$WhatIf)

    $YesterDayBackupDate = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-1)
    $PowerShellHistoryPath = (Get-PSReadlineOption).HistorySavePath

    if (!(Test-Path -Path "$PowerShellHistoryPath")) {
        Write-Verbose "PS history file '$PowerShellHistoryPath' not found."
        return
    }

    # *_history_202011.txt
    $PSHistoryItem = Get-Item -Path "$PowerShellHistoryPath"
    $NewHistoryName = "$($PSHistoryItem.BaseName)_$($YesterDayBackupDate.ToString("yyMMdd"))$($PSHistoryItem.Extension)"
    $NewHistoryPath = "$($PSHistoryItem.Directory.FullName)\$NewHistoryName"

    if (Test-Path "$NewHistoryPath") {
        Write-Verbose "File '$NewHistoryPath' already exist."
        return
    }

    $null = Copy-Item -Path "$PowerShellHistoryPath" -Destination "$NewHistoryPath" -WhatIf:$WhatIf
    #$null = Rename-Item -Path "$PowerShellHistoryPath" -NewName "$NewHistoryName" -WhatIf:$WhatIf
}
Backup-PowerShellHistory -WhatIf:$false -Verbose:$VerboseProfile

if (Test-Path C:\ -ErrorAction SilentlyContinue) {
    Set-Location C:\
}

# "language bug": https://github.com/PowerShell/PowerShellModuleCoverage/issues/18
#Invoke-WebRequest "https://raw.githubusercontent.com/lptstr/winfetch/master/winfetch.ps1" -UseBasicParsing | Invoke-Expression -ErrorAction SilentlyContinue -Verbose
if ((Get-PowerShellTerminalType).content -eq "Visual Studio Code") {
    Write-Verbose "Inside of code" -Verbose:$VerboseProfile
    #Clear-Host
}
else {
    if (Get-Command -Name "winfetch" -ErrorAction SilentlyContinue) {
        #winfetch
    }
    
    # Wetter Informationen anzeigen beim Starten des Profiles...
    #Get-Weather -Verbose:$VerboseProfile

    $Error.Clear()
}

# TODO: Shortcuts.ps1
#function imf($name) { Import-Module $name -force }
#Set-Alias np $env:SystemRoot\notepad.exe
#Set-Alias npp $env:ProgramFiles\Notepad++\notepad++.exe
#Set-Alias edit $env:ProgramFiles\Notepad++\notepad++.exe