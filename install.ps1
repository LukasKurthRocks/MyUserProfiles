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
Write-Verbose "Check: $PSLocalFileVersion, $PSProfileFileVersion" -Verbose

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

# Extra check in case i miss this. Removed this from the profile.
if (!(Get-Command -Name "Set-Theme" -ErrorAction SilentlyContinue) -and !(Get-Command -Name "Set-PoshPrompt" -ErrorAction SilentlyContinue)) {
    if (!(Test-Path "$env:windir\Fonts\Delugia.Nerd.Font.ttf" -ErrorAction SilentlyContinue)) {
        Write-Verbose "Loading 'Delugia.Nerd.Font.ttf' ..." -Verbose
        Invoke-WebRequest -Uri "https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.ttf" -O "$env:windir\Fonts\Delugia.Nerd.Font.ttf"
    }
    if (!(Test-Path "$env:windir\Fonts\Delugia.Nerd.Font.Complete.ttf" -ErrorAction SilentlyContinue)) {
        Write-Verbose "Loading 'Delugia.Nerd.Font.Complete.ttf' ..." -Verbose
        Invoke-WebRequest -Uri "https://github.com/adam7/delugia-code/releases/latest/download/Delugia.Nerd.Font.Complete.ttf" -O "$env:windir\Fonts\Delugia.Nerd.Font.Complete.ttf"
    }
    if (!(Get-Module -Name "posh-git")) {
        Write-Verbose "Module 'posh-git' ..." -Verbose
        Install-Module posh-git -Scope CurrentUser
    }
    if (!(Get-Module -Name "oh-my-posh")) {
        Write-Verbose "Module 'oh-my-posh' ..." -Verbose
        Install-Module oh-my-posh -Scope CurrentUser
    }
}