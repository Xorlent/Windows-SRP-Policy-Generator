<#
Feb 17 2024
TO DO:
    Update FriendlyName name so every entry is not showing "PowerShell.exe (..."
    Update LastModified date?  Doubt this is important.
#>

$hashPath = $PWD.Path + '\hashes'
$polHeaderFile = $PWD.Path + '\Header.pol'
$polEntryTemplate = $PWD.Path + '\EntryTemplate.pol'
$outputFile = $PWD.Path + '\Registry.pol'

$polFile = Get-Content $polHeaderFile -Raw -Encoding Byte
$polString = $polFile.ForEach('ToString', 'X2') -join ' '
$polString += ' '

$placeholderUID = '31 00 31 00 31 00 31 00 31 00 31 00 31 00 31 00 2D 00 31 00 31 00 31 00 31 00 2D 00 31 00 31 00 31 00 31 00 2D 00 31 00 31 00 31 00 31 00 2D 00 31 00 31 00 31 00 31 00 31 00 31 00 31 00 31 00 31 00 31 00 31 00 31 00'
$placeholderMD5 = 'B3 AD 53 64 CF 04 B6 AB 05 61 6D D4 83 AA F6 18'
$placeholderSHA256 = '73 75 AD ED B8 2F D6 2C EF C6 B6 FD 20 A7 04 A1 64 E0 56 02 2F 3B 8C 2E 1B 94 F3 A9 B8 36 14 78'
$placeholderSize = '3B 00 00 C4 06 00'
$placeholderDTS = '2B 7D 8F 77 E5 5E DA 01'

$polEntry = Get-Content $polEntryTemplate -Raw -Encoding Byte
$entryTemplate = $polEntry.ForEach('ToString', 'X2') -join ' '

# Get the list of csv files in the \hashes subdirectory
$hashesList = Get-ChildItem -Path $hashPath -Filter "*.csv" | select Name

# Process each of the .csv files
foreach($hashFile in $hashesList){
    $fullHashPath = $hashPath + '\' + $hashFile.Name
    $hashFile = Import-Csv $fullHashPath
    $fullHashPath

    #Process each hash entry within the current .csv file
    foreach($hash in $hashFile){

        ###### Convert file size in bytes to hex string
        $entryLength = [convert]::ToString($hash.SIZE,16)
        $len = $entryLength.Length
        ###### /Convert file size in bytes to hex string

        if(($len -lt 9) -and ($len -gt 1) -and $hash.MD5.Length -eq 32 -and $hash.SHA256.Length -eq 64){ # We have a valid record to process
            ###### Convert file size in bytes to little endian QWORD
            $entrySize = ''
            $getLastByte = 0

            if(($len % 2) -eq 1){ # The string is an odd number of chars so we need to grab the hanging byte at the end of the process
                $getLastByte = 1
            }

            $len = $len - 2

            while($len -gt -1){ # Invert the words
                $entrySize += $entryLength.Substring($len,2) + ' '
                $len = $len - 2
            }

            if($getLastByte){ # We have a hanging byte
                $entrySize += '0' + $entryLength.Substring(0,1)
            }

            while($entrySize.Length -lt 11){ # Not a full QWORD yet
                $entrySize += ' 00'
            }
            ###### /Convert file size in bytes to little endian QWORD

            ###### Convert MD5 hash to string
            $entryMD5 = $hash.MD5.ToUpper() -split "([A-Z0-9]{2})" -join ' '
            $entryMD5 = $entryMD5.Trim(' ')
            ###### /Convert MD5 hash to string

            ###### Convert SHA256 hash to string
            $entrySHA256 = $hash.SHA256.ToUpper() -split "([A-Z0-9]{2})" -join ' '
            $entrySHA256 = $entrySHA256.Trim(' ')
            ###### /Convert SHA256 hash to string

            ###### Create a unique ID for the entry
            $entryUID = ''
            while($entryUID.Length -lt 215){
                if($entryUID.Length -eq 48 -or $entryUID.Length -eq 78 -or $entryUID.Length -eq 108 -or $entryUID.Length -eq 138){
                    $entryUID += '2D'
                    $entryUID += ' 00 '
                }
                $entryUID += "30","31","32","33","34","35","36","37","38","39","61","62","63","64","65","66" | Get-Random
                $entryUID += ' 00 '
            }
            $entryUID = $entryUID.Trim(' ')
            ###### /Create a unique ID for the entry

            ###### Replace entry template with necessary values
            $entrySize = '3B 00 ' + $entrySize
            $entryString = $entryTemplate
            $entryString = $entryString.Replace($placeholderUID,$entryUID) # Set UID for this SRP entry
            $entryString = $entryString.Replace($placeholderMD5,$entryMD5) # Set MD5 for this SRP entry
            $entryString = $entryString.Replace($placeholderSHA256,$entrySHA256) # Set SHA256 for this SRP entry
            $entryString = $entryString.Replace($placeholderSize,$entrySize) # Set Size for this SRP entry
            ###### /Replace entry template with necessary values

            # Add entry to the running pol file data
            $polString += $entryString + ' '
        }
    }
}

###### Write final string to Registry.pol

[byte[]] $policyByteArray = -split $polString -replace '^', '0x'
Set-Content $outputFile -Encoding Byte -Value $policyByteArray

###### /Write final string to Registry.pol
