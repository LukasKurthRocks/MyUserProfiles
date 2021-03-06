#
#  THIS IS MY PROFILE. THIS MIGHT BREAK YOURS!
#  + This is ISE, profile is shorter!
#
# Inspired by: Optimizing Profile: https://devblogs.microsoft.com/powershell/optimizing-your-profile/
# TODO: Cleaning up this profile.
# TODO: Version matching multiple? Changing online or create function for this?
# MORE INFORMATION:
# - ShortCuts in ProfileScripts folder
# - WinFetch function in ProfileScripts folder
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
#endregion

#region Syncable PS Profile
# Ping check. Version check does not work otherwise.
if ((New-Object System.Net.NetworkInformation.Ping).SendPingAsync('raw.githubusercontent.com').Result.Status -ne "Success") {
    Write-Host "GitHub not reachable." -BackgroundColor Black -ForegroundColor Red
}
else {
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

# Import Functions
if (Test-Path -Path "$PSScriptRoot\profile_scripts" -ErrorAction SilentlyContinue) {
    #$Host.UI.RawUI.WindowTitle = "PROFILE: Loading scripts folder"

    Resolve-Path "$PSScriptRoot\profile_scripts\*.ps1" | `
        Where-Object { !($_.ProviderPath.Contains("TEST")) } | `
        Foreach-Object { . $_.ProviderPath }
}
#endregion

if (Test-Path C:\ -ErrorAction SilentlyContinue) {
    Set-Location C:\
}

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