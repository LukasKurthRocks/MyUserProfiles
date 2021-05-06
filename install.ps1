#region Syncable PS Profile
# NOT: GitHub RAW has 'Cache-Control: max-age=300' setting. Means: Sync is 5 Minutes.
$CurrentProfileFileName = Split-Path $profile -Leaf
$GitHub_PSProfileFile = "https://raw.githubusercontent.com/LukasKurthRocks/MyUserProfiles/main/Profiles/$CurrentProfileFileName"
$GitHub_PSVersionsFile = "https://raw.githubusercontent.com/LukasKurthRocks/MyUserProfiles/main/VersionCheck/versions.json"
$PSProfileFileVersion = [Version](Invoke-RestMethod -Uri $GitHub_PSVersionsFile)."$CurrentProfileFileName"
$VersionFileLocal = [System.IO.Path]::Combine("$HOME", '.latest_profile_versions')

$PSLocalFileVersion = [Version]"0.0.0"
if (Test-Path -Path "$VersionFileLocal" -ErrorAction SilentlyContinue) {
    $PSLocalFileVersion = (Get-Content -Path "$VersionFileLocal" | ConvertFrom-Json)."$CurrentProfileFileName"
}
Write-Verbose "Check: $PSLocalFileVersion, $PSProfileFileVersion" -Verbose
Write-Host "Test: $VersionFileLocal, $CurrentProfileFileName"
return

# Test Version - Mismatch
if ($PSLocalFileVersion -ne $PSProfileFileVersion) {
    Write-Verbose "Your version: $PSLocalFileVersion" -Verbose
    Write-Verbose "New version: $PSProfileFileVersion" -Verbose
    $choice = Read-Host -Prompt "Found newer profile, install? (Y)"
    if ($choice.ToLower() -eq "y" -or $choice -eq "") {
        try {
            # Save content in profile file
            $GitHub_FileContent = Invoke-RestMethod $GitHub_PSProfileFile -ErrorAction Stop
            Set-Content -Path $profile -Value $GitHub_FileContent
            
            # Save version in file
            $GitHub_VersionFileContent = Invoke-RestMethod -Uri $GitHub_PSVersionsFile -ErrorAction Stop | ConvertTo-Json
            Set-Content -Path "$VersionFileLocal" -Value $GitHub_VersionFileContent # save versions to file
            
            Write-Verbose "Installed newer version of profile" -Verbose
            . $profile
            return
        }
        catch {
            # we can hit rate limit issue with GitHub since we're using anonymous
            Write-Verbose "Was not able to access gist, try again next time $($_.Exception.Message)" -Verbose
        }
    }
}
#endregion
