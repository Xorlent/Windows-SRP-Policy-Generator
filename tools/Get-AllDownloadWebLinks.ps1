<#
Get-AllDownloadWebLinks.ps1
Fetches every matching ZIP download URL from the specified download page, extracts the specified executable,
and automatically generates a .csv hash file for use with the Windows-SRP-Policy-Generator

Usage:
  Get-AllDownloadWebLinks -download <Download URL> -x32 <32-bit ZIP file search string> -x64 <64-bit ZIP file search string> -exe <executable to process>

Examples:
  PowerShell Core repository at https://github.com/PowerShell/PowerShell:
  Get-AllDownloadWebLinks.ps1 -download https://www.python.org/downloads/windows/ -x32 embed-win32.zip -x64 embed-amd64.zip -exe python.exe

#>
param (
    [string]$downloadURL = $( Read-Host "Enter the full download page URL.  Example: https://www.python.org/downloads/windows/" ),
    [string]$x32 = $( Read-Host "Enter the 32-bit download URL search string to use.  The file MUST be a ZIP.  Example: embed-win32.zip" ),
    [string]$x64 = $( Read-Host "Enter the 64-bit download URL search string to use.  The file MUST be a ZIP.  Example: embed-amd64.zip" ),
    [string]$exe = $( Read-Host "Enter executable name to process into a hash csv file.  Example: python.exe" )
 )

Add-Type -Assembly System.IO.Compression.FileSystem

$FetchList = New-Object System.Collections.Generic.List[System.Object]

$WorkingDir = $PWD.Path + "\temp\"

# If the working directory does not exist, create it
if (-not(Test-Path -Path $WorkingDir -PathType Container)){$null = New-Item -Path $WorkingDir -ItemType Directory}

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Page = Invoke-WebRequest -Uri $downloadURL
foreach($Link in $Page.Links.Href){
    if($Link.Contains($x64) -or $Link.Contains($x32)){
            $FetchList.Add($Link) # Add the maching download URL to our list of files we need to download
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