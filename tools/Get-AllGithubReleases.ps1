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

$Response = Invoke-WebRequest -Method GET -Uri $ReleasesURL -Headers @{ 'Accept' = 'application/vnd.github.json'; 'X-Github-Api-Version' = '2022-11-28'} -UseBasicParsing

if($Response.Statuscode -ne 200){exit -1} # Invalid result code from API
$i = 1
while($Response.Headers.link.Contains('rel="next"')){ # Walk through every page of responses
    $ReleaseList = ConvertFrom-Json $response.Content
    $i++
    foreach($record in $ReleaseList){
        foreach($asset in $record.assets){
            if($asset.browser_download_url.Contains('win-x64.zip') -or $asset.browser_download_url.Contains('win-x86.zip')){
                $FetchList.Add($asset.browser_download_url)
                }
            }
        }
    $ReleasesURLNext = $ReleasesURL + '&page=' + $i
    $Response = Invoke-WebRequest -Method GET -Uri $ReleasesURLNext -Headers @{ 'Accept' = 'application/vnd.github.json'; 'X-Github-Api-Version' = '2022-11-28'} -UseBasicParsing
}
$ReleaseList = ConvertFrom-Json $response.Content

foreach($record in $ReleaseList){
    foreach($asset in $record.assets){
        if($asset.browser_download_url.Contains('win-x64.zip') -or $asset.browser_download_url.Contains('win-x86.zip')){
            $FetchList.Add($asset.browser_download_url)
            }
        }
    }

$i = 1
foreach($URL in $FetchList){
    $FileName = $WorkingDir + $i + '.zip'
    Invoke-Webrequest -URI $URL -OutFile $FileName
    $FileName

    $destinationDir = $WorkingDir + $i
    # If the destination directory dows not exits, create it
    $null = New-Item $destinationDir -ItemType Directory -Force

    $zipFile = [IO.Compression.ZipFile]::OpenRead( $FileName )
    try {
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
    Remove-Item -Path $FileName
    $i++
}
$splitExe = $exe.Split(".")
$csvOutput = "$PWD.Path\hashes\$splitExe[0].csv"
Get-ChildItem $WorkingDir -Recurse -filter $exe | Select-Object -Property @{Name="MD5";expression={(Get-FileHash $_.FullName -Algorithm MD5).hash}},@{Name="SHA256";expression={(Get-FileHash $_.FullName).hash}},@{Name="SIZE";expression={$_.Length}} | export-csv $csvOutput