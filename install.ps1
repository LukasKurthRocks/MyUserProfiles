#region Syncable PS Profile
# NOTE: GitHub RAW has 'Cache-Control: max-age=300' setting. Means: Sync is 5 Minutes.
$CurrentProfileFileName = Split-Path $profile -Leaf
$GitHub_PSProfileFile = "https://raw.githubusercontent.com/LukasKurthRocks/MyUserProfiles/main/Profiles/$CurrentProfileFileName"
$GitHub_PSVersionsFile = "https://raw.githubusercontent.com/LukasKurthRocks/MyUserProfiles/main/VersionCheck/versions.json"
$PSProfileFileVersion = [Version](Invoke-RestMethod -Uri $GitHub_PSVersionsFile)."$CurrentProfileFileName"
$VersionFileLocal = [System.IO.Path]::Combine("$HOME", '.latest_profile_versions')

if (Test-Path -Path "$VersionFileLocal" -ErrorAction SilentlyContinue) {
    $PSLocalFileVersion = (Get-Content -Path "$VersionFileLocal" | ConvertFrom-Json)."$CurrentProfileFileName"
}
else {
    $PSLocalFileVersion = [Version]"0.0.0"
    Set-Content -Path "$VersionFileLocal" -Value ( [ordered]@{} | ConvertTo-Json )
}
Write-Verbose "Check: $PSLocalFileVersion, $PSProfileFileVersion; ProfileName: $CurrentProfileFileName" -Verbose

# Test Version - Mismatch
if ($PSLocalFileVersion -ne $PSProfileFileVersion) {
    Write-Verbose "Your version: $PSLocalFileVersion" -Verbose
    Write-Verbose "New version: $PSProfileFileVersion" -Verbose
    $choice = Read-Host -Prompt "Found newer profile, install? (Y)"
    if ($choice.ToLower() -eq "y" -or $choice -eq "") {
        try {
            # Save content in profile file
            $GitHub_FileContent = Invoke-RestMethod $GitHub_PSProfileFile -ErrorAction Stop
            if (!(Test-Path -Path "$(Split-Path $profile)")) { $null = New-Item -Path "$(Split-Path $profile)" -ItemType Directory }
            Set-Content -Path $profile -Value $GitHub_FileContent -Force
            
            # Save version in file
            $GitHub_VersionFileContent = Invoke-RestMethod -Uri $GitHub_PSVersionsFile -ErrorAction Stop
            $VersionFileLocalContent = Get-Content -Path "$VersionFileLocal" -ErrorAction SilentlyContinue | ConvertFrom-Json
            $VersionFileLocalContent | Add-Member -MemberType NoteProperty -Name "$CurrentProfileFileName" -Value ($GitHub_VersionFileContent."$CurrentProfileFileName") -Force
            #$VersionFileLocalContent."$CurrentProfileFileName" = $GitHub_VersionFileContent."$CurrentProfileFileName"
            #Set-Content -Path "$VersionFileLocal" -Value $GitHub_VersionFileContent # save versions to file
            Set-Content -Path "$VersionFileLocal" -Value ( $VersionFileLocalContent | ConvertTo-Json ) # save versions to file
            
            Write-Verbose "Installed newer version of profile" -Verbose
            . $profile
            return
        }
        catch {
            # we can hit rate limit issue with GitHub since we're using anonymous
            Write-Verbose "Was not able to access gist, try again next time. $($_.Exception.Message)" -Verbose
        }
    }
}
#endregion

if (Get-Module posh-git) {
    Import-Module posh-git
}
if (Get-Module oh-my-posh) {
    Import-Module oh-my-posh
}

# Extra checks in case I miss this.
if (!(Test-Path "$env:windir\Fonts\Delugia.Nerd.Font.ttf" -ErrorAction SilentlyContinue) -or !(Test-Path "$env:windir\Fonts\Delugia.Nerd.Font.Complete.ttf" -ErrorAction SilentlyContinue)) {
    $objShell = New-Object -ComObject Shell.Application
    $InstallFont = $objShell.Namespace(0x14) # 0x14 = Fonts
    
    # Check if font is registered (file existing does not count).
    if (!($InstallFont.Items() | Where-Object { $_.Name -match "Delugia Nerd Font" })) {
        @("Delugia.Nerd.Font.ttf", "Delugia.Nerd.Font.Complete.ttf") | ForEach-Object {
            $FontFileName = $_
            if (!(Test-Path "$env:windir\Fonts\$FontFileName" -ErrorAction SilentlyContinue)) {
                Write-Verbose "Loading '$FontFileName' ..." -Verbose
                Invoke-WebRequest -Uri "https://github.com/adam7/delugia-code/releases/latest/download/$FontFileName" -O "$env:TEMP\$FontFileName"
                $InstallFont.CopyHere("$env:TEMP\$FontFileName", 0x10)
                Remove-Item -Path "$env:TEMP\$FontFileName"
            }
        }
    }
}

# Extra check #02 (Delugia Nerd Fonts combined in "Delugia Complete")
if (!(Test-Path "$env:windir\Fonts\DelugiaComplete.ttf" -ErrorAction SilentlyContinue)) {
    $OutPath = $env:TEMP
    $objShell = New-Object -ComObject Shell.Application
    $InstallFont = $objShell.Namespace(0x14) # 0x14 = Fonts

    Write-Verbose "Loading Font Archive ..." -Verbose
    Invoke-WebRequest -Uri "https://github.com/adam7/delugia-code/releases/latest/download/delugia-complete.zip" -O "$OutPath\delugia-complete.zip"
    $null = New-Item -ItemType Directory -Path "$OutPath\delugia-complete\" -ErrorAction SilentlyContinue
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead("$OutPath\delugia-complete.zip")
    $zip.Entries | Where-Object { $_.FullName -like "*.ttf" } |
    ForEach-Object { 
        $FileName = $_.Name
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$OutPath\delugia-complete\$FileName", $true)
    }
    $zip.Dispose()

    Get-ChildItem -Recurse -Path "$OutPath\delugia-complete" | ForEach-Object {
        Write-Verbose "Install $_" -Verbose
    }
    #$InstallFont.CopyHere("$env:TEMP\$FontFileName", 0x10)
}


if (!(Get-Command -Name "Set-Theme" -ErrorAction SilentlyContinue) -and !(Get-Command -Name "Set-PoshPrompt" -ErrorAction SilentlyContinue)) {
    if (!(Get-Module -Name "posh-git")) {
        Write-Verbose "Module 'posh-git' ..." -Verbose
        Install-Module posh-git -Scope CurrentUser
    }
    if (!(Get-Module -Name "oh-my-posh")) {
        Write-Verbose "Module 'oh-my-posh' ..." -Verbose
        Install-Module oh-my-posh -Scope CurrentUser
    }
}