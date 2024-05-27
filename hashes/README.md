### hashes .csv source files
- This folder includes hash data for some commonly abused LOL executables that a typical corporate user should not be running.  
- To create your own hash file, all colums must be populated or the SRP will not function.
  - The Create-SRPPolicy script will ignore entries with missing or incpomplete data.
> [!NOTE]
> Have a list of other LOL executables to block and want to share with the security community?  Create a pull request to add .csv files to this list!
### Where do I get the hash values needed to make my own .csv entries?
- In a Windows command prompt, issue the following commands and copy the value returned into the respective .csv data columns
```
  certutil -hashfile <path to file> MD5
  certutil -hashfile <path to file> SHA256
  dir /-C <path to file>
```
- In a PowerShell command prompt, you can use the following command to output the result directly to a CSV file
```
  Get-ChildItem <path to file> | Select-Object -Property @{Name="MD5";expression={(Get-FileHash $_.FullName -Algorithm MD5).hash}},@{Name="SHA256";expression={(Get-FileHash $_.FullName).hash}},@{Name="SIZE";expression={$_.Length}} | export-csv <path to csv file>
```
