# Windows-SRP-Policy-Generator
## WORK IN PROGRESS.  CURRENT CODE IS UNTESTED IN PRODUCTION.
Generates a custom Policy.pol file for hash-based software restriction group policies  
### Purpose
Windows Software Restriction Policies can help prevent execution of common living off the land (LOL) tools, but the Group Policy editor is severely limited for hash-based restrictions.  To add a hash-based rule, you need to have a copy of the file in question.  For executables like Powershell.exe, this would require hunting down a copy of every version published to ensure complete coverage.  
- This tool generates a custom .pol file from a supplied hash list that can then be copied to your group policy folder, bypassing this Group Policy editor limitation.
### Usage
- Download the repository code ZIP
- Right-click on the downloaded file, select "Properties" and click "Unblock"
- Click "OK"
- Unzip the file to your desired location
- Following the .csv examples in the /hashes folder, add or update to include all hashes you would like in your Software Restriction Policy
  - All fields are required, hashes are case insensitive
  - Ensure MD5 values are 32 hexadecimal characters in length
  - Ensure SHA256 values are 64 hexadecimal characters in length
- In a PowerShell window, navigate to the directory where Create-SRPPolicy.ps1 is located
- Run .\Create-SRPPolicy.ps1
### Where do I get the hash values needed to make my own .csv entries?
- In a Windows command prompt, issue the following commands and copy the value returned into the respective .csv data columns
```
  certutil -hashfile <path to file> MD5
  certutil -hashfile <path to file> SHA256
  dir /-C <path to file>
```
### Disclaimer
This tool generates a random identifier for each SRP entry.  There is an infinitesimally small chance of an identifier value created by this script overlapping an existing SRP identifier.
