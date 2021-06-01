#
#  THIS IS MY PROFILE. THIS MIGHT BREAK YOURS!
#
# Inspired by: Optimizing Profile: https://devblogs.microsoft.com/powershell/optimizing-your-profile/
# TODO: Cleaning up this profile.
# TODO: Version matching multiple? Changing online or create function for this?
# MORE INFORMATION:
# - ShortCuts in ProfileScripts folder
# - WinFetch function in ProfileScripts folder
# - CMatrix Screensaver moved ...
# "language bug": https://github.com/PowerShell/PowerShellModuleCoverage/issues/18
#Invoke-WebRequest "https://raw.githubusercontent.com/lptstr/winfetch/master/winfetch.ps1" -UseBasicParsing | Invoke-Expression -ErrorAction SilentlyContinue -Verbose

# Skipping profile when testing with older PowerShell versions.
if ($PSVersionTable.PSVersion.Major -lt 5) {
    return
}

#region Configuration
# Set Default Parameters
$PSDefaultParameterValues['Get-Help:ShowWindow'] = $true
$PSDefaultParameterValues['Send-MailMessage:From'] = "$env:USERNAME@$env:COMPUTERNAME.lokal"
$VerboseProfile = $false
$IsPartOfDomain = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
$DoBackupPowerShellHistory = $true
#endregion

#region Syncable PS Profile
# NOTE: GitHub RAW has 'Cache-Control: max-age=300' setting. Means: Sync is 5 Minutes.
$CurrentProfileFileName = Split-Path $profile -Leaf
$GitHub_PSProfileFile = "https://raw.githubusercontent.com/LukasKurthRocks/MyUserProfiles/main/Profiles/$CurrentProfileFileName"
$GitHub_PSVersionsFile = "https://raw.githubusercontent.com/LukasKurthRocks/MyUserProfiles/main/VersionCheck/versions.json"
$PSProfileFileVersion = [Version](Invoke-RestMethod -Uri $GitHub_PSVersionsFile)."$CurrentProfileFileName"
$VersionFileLocal = [System.IO.Path]::Combine("$HOME", '.latest_profile_versions')

$PSLocalFileVersion = [Version]"0.0.0"
if (Test-Path -Path "$VersionFileLocal" -ErrorAction SilentlyContinue) {
    $PSLocalFileVersion = (Get-Content -Path "$VersionFileLocal" | ConvertFrom-Json)."$CurrentProfileFileName"
}

# Test Version - Mismatch
if ($PSLocalFileVersion -ne $PSProfileFileVersion) {
    Write-Verbose "Your version: $PSLocalFileVersion" -Verbose
    Write-Verbose "New version: $PSProfileFileVersion" -Verbose
    $choice = Read-Host -Prompt "Found newer profile, install? (Y)"
    if ($choice.ToLower() -eq "y" -or $choice -eq "") {
        try {
            # Save content in profile file
            $GitHub_FileContent = Invoke-RestMethod $GitHub_PSProfileFile -ErrorAction Stop
            Set-Content -Path $profile -Value $GitHub_FileContent -Force
            
            # Save version in file
            $GitHub_VersionFileContent = Invoke-RestMethod -Uri $GitHub_PSVersionsFile -ErrorAction Stop
            $VersionFileLocalContent = Get-Content -Path "$VersionFileLocal" -ErrorAction SilentlyContinue | ConvertFrom-Json
            $VersionFileLocalContent | Add-Member -MemberType NoteProperty -Name "$CurrentProfileFileName" -Value ($GitHub_VersionFileContent."$CurrentProfileFileName") -Force
            Set-Content -Path "$VersionFileLocal" -Value ( $VersionFileLocalContent | ConvertTo-Json ) # save versions to file
            
            Write-Verbose "Installed newer version of profile" -Verbose
            . $profile
            return
        }
        catch {
            # Git has rate limit issue, since using anonymous
            Write-Verbose "Error accessing github, try again next time." -Verbose
        }
    }
}
#endregion

# Save default functions for comparing imported functions
$SystemFunction = Get-ChildItem function:
$SystemAliasses = Get-Alias

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

# Import Functions
if (Test-Path -Path "$PSScriptRoot\profile_scripts" -ErrorAction SilentlyContinue) {
    $Host.UI.RawUI.WindowTitle = "PROFILE: Loading scripts folder"

    Resolve-Path "$PSScriptRoot\profile_scripts\*.ps1" | `
        Where-Object { !($_.ProviderPath.Contains("TEST")) } | `
        Foreach-Object { . $_.ProviderPath }
}
#endregion

#region Theme Settings
# Windows Terminal has THEME-ING with own prompt ...
# Delugia.Nerd.Font.Complete.ttf + Delugia.Nerd.Font.ttf
# Install-Module posh-git -Scope CurrentUser
# Install-Module oh-my-posh -Scope CurrentUser
# Setting for themes: $ThemeSettings, $GitPromptSettings
# Like setting "$ThemeSettings.PromptSymbols.ElevatedSymbol" for showing the admin status.
if ($env:WT_Session) {
    if (IsConsoleRunningElevated) {
        # Hiding user name from prompt when "Default" user
        $global:DefaultUser = [System.Environment]::UserName
        $env:POSH_SESSION_DEFAULT_USER = [System.Environment]::UserName
    }
    if (Get-Module posh-git) {
        Import-Module posh-git
    }
    if (Get-Module oh-my-posh) {
        Import-Module oh-my-posh
    }

    # Installation folder: $ThemeSettings.MyThemesLocation
    # Official themes  :   https://github.com/JanDeDobbeleer/oh-my-posh#themes
    if (Get-Command -Name "Set-Theme" -ErrorAction SilentlyContinue) {
        Set-Theme Agnoster
    }
    elseif (Get-Command -Name "Set-PoshPrompt" -ErrorAction SilentlyContinue) {
        Set-PoshPrompt Agnoster
    }
    else {
        Write-Host "Error: oh-my-posh not found. Please re-run install.ps1 script." -BackgroundColor Black -ForegroundColor Red
    }
}
else {
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
        
        $host.UI.RawUI.WindowTitle = "$([net.dns]::GetHostName()) $([string]::Join(".", ("$((Get-Host).Version)".Split(".")[0,1])))$Admin $(Get-Location)"
        return " "
    }
    
    if ($IsPartOfDomain) {
        # Color of "parameter" is broken on pc at work.
        Set-PSReadLineOption -Colors @{ Parameter = 'Gray' }
    }

    # Set location to main drive when using PowerShell without WindowsTerminal
    # WindowsTerminal has own settings for this.
    if (Test-Path C:\ -ErrorAction SilentlyContinue) {
        Set-Location C:\
    }
}
#endregion

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

if ($DoBackupPowerShellHistory) {
    # Could be improved... Sometime in the future...
    # Copying the current history into new file.
    & {
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
    }
}

function Get-ProfileFunctions { Get-ChildItem function: | Where-Object { ($SystemFunction -notcontains $_) } }
function Get-ProfileAliasses { Get-Alias | Where-Object { ($SystemAliasses -notcontains $_) } }

Set-Alias -Name 'profileFunc' -Value 'Get-ProfileFunctions'
Set-Alias -Name 'profileAlias' -Value 'Get-ProfileAliasses'

#region TESTING
# Apply ISE Code
$TerminalType = (Get-PowerShellTerminalType).content
if ($psISE -or $TerminalType -eq "Windows PowerShell ISE") {
    Write-Verbose "PowerShell Host Name: $($Host.Name)" -Verbose:$VerboseProfile
    #$Host.Name -eq 'Windows PowerShell ISE Host'
}
# ServerRemoteHost | RemoteHost => Sowohl Admin Center, als auch Enter-PSSession

if ($TerminalType -eq "Visual Studio Code") {
    Write-Verbose "Inside of VSCode" -Verbose:$VerboseProfile
    #Clear-Host
}
else {
    # Showing weather information for my "hometown"
    #Get-Weather -Verbose:$VerboseProfile
    #$Error.Clear()
}
Remove-Variable -Name "TerminalType"
#endregion