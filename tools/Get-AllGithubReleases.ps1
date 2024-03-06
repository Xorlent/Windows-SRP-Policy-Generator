<#
Get-AllGithubReleases.ps1
Fetches every available release version of matching Windows .ZIP assets for the specified repository, extracts the specified executable,
and automatically generates a .csv hash file for use with the Windows-SRP-Policy-Generator

Usage:
  Get-AllGitHubReleases -owner <GitHub repo owner> -repo <GitHub repo name> -exe <executable to process>

Examples:
  PowerShell Core repository at https://github.com/PowerShell/PowerShell:
  Get-AllGitHubReleases -owner PowerShell -repo PowerShell -exe pwsh.exe

#>
param (
    [string]$APIURL = "https://api.github.com",
    [string]$owner = $( Read-Host "Enter repo owner.  Example: Microsoft" ),
    [string]$repo = $( Read-Host "Enter repo name.  Example: PowerShell" ),
    [string]$exe = $( Read-Host "Enter executable name to process into a hash csv file.  Example: pwsh.exe" )
 )

Add-Type -Assembly System.IO.Compression.FileSystem

# Initialize API URL
$ReleasesURL = "$APIURL/repos/$owner/$repo/releases?per_page=100"
$FetchList = New-Object System.Collections.Generic.List[System.Object]
$WorkingDir = $PWD.Path + "\temp\$owner-$repo\"

# If the working directory does not exist, create it
if (-not(Test-Path -Path $WorkingDir -PathType Container)){$null = New-Item -Path $WorkingDir -ItemType Directory}

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get the list of releases, 100 items at a time (API limit)
$Response = Invoke-WebRequest -Method GET -Uri $ReleasesURL -Headers @{ 'Accept' = 'application/vnd.github.json'; 'X-Github-Api-Version' = '2022-11-28'} -UseBasicParsing

if($Response.Statuscode -ne 200){exit -1} # Quit if we get an invalid result code from API
$i = 1
while($Response.Headers.link.Contains('rel="next"')){ # Walk through every page of responses
    $ReleaseList = ConvertFrom-Json $response.Content
    $i++
    foreach($record in $ReleaseList){
        foreach($asset in $record.assets){
            if($asset.browser_download_url.Contains('x64.zip') -or $asset.browser_download_url.Contains('x86.zip') -or $asset.browser_download_url.Contains('amd64.zip')){
                $FetchList.Add($asset.browser_download_url) # Add the maching download URL to our list of files we need to download
                }
            }
        }
    $ReleasesURLNext = $ReleasesURL + '&page=' + $i # Increment the API call page number
    # Get the next list of up to 100 items
    $Response = Invoke-WebRequest -Method GET -Uri $ReleasesURLNext -Headers @{ 'Accept' = 'application/vnd.github.json'; 'X-Github-Api-Version' = '2022-11-28'} -UseBasicParsing
}
# Only one page in API call results or we've now reached the last page of results
$ReleaseList = ConvertFrom-Json $response.Content

foreach($record in $ReleaseList){
    foreach($asset in $record.assets){
        if($asset.browser_download_url.Contains('x64.zip') -or $asset.browser_download_url.Contains('x86.zip') -or $asset.browser_download_url.Contains('amd64.zip')){
            $FetchList.Add($asset.browser_download_url) # Add the maching download URL to our list of files we need to download
            }
        }
    }

$i = 1
foreach($URL in $FetchList){
    $FileName = $WorkingDir + $i + '.zip'
    # Download the file.  Assumes we're grabbing .zip releases only, not packaged installers.
    Invoke-Webrequest -URI $URL -OutFile $FileName
    $FileName

    $destinationDir = $WorkingDir + $i
    # If the destination directory dows not exits, create it
    $null = New-Item $destinationDir -ItemType Directory -Force

    $zipFile = [IO.Compression.ZipFile]::OpenRead( $FileName )
    try {
        # Check the archive volume for the file in question.  If found, extract it into a subfolder with the same name as the zip file.
        if( $foundFile = $zipFile.Entries.Where({ $_.Name -eq $exe }, 'First') ) {
            $destinationFile = Join-Path $destinationDir $foundFile.Name
            [IO.Compression.ZipFileExtensions]::ExtractToFile( $foundFile[ 0 ], $destinationFile )
        }
        else {
            Write-Error "Did you supply the wrong executable name?  $exe was not found in the archive."
        }
    }
    finally {
        if( $zipFile ) {
            $zipFile.Dispose()
        }
    }
    # We're done with this downloaded file.  Delete it.
    Remove-Item -Path $FileName
    $i++
}
$splitExe = $exe.Split(".")
$csvOutput = $PWD.Path + '\' + $splitExe[0] + '.csv'

# Get the list of all maching files in our working directory (recursively), piping to a formatted table and sending that table to a ready-to-use CSV file.
Get-ChildItem $WorkingDir -Recurse -filter $exe | Select-Object -Property @{Name="MD5";expression={(Get-FileHash $_.FullName -Algorithm MD5).hash}},@{Name="SHA256";expression={(Get-FileHash $_.FullName).hash}},@{Name="SIZE";expression={$_.Length}} | export-csv $csvOutput
