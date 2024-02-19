# Windows-SRP-Policy-Generator
Generates a custom Registry.pol file for hash-based software restriction group policies  
### Purpose
Windows Software Restriction Policies can help prevent execution of common living off the land (LOL) tools, but the Group Policy editor is severely limited for hash-based restrictions.  To add a hash-based rule, you need to have a copy of the file in question.  For executables like Powershell.exe, this would require somehow obtaining a copy of every version published to ensure complete coverage.  
#### This tool generates a custom .pol file from a supplied hash list that can then be copied to your group policy object folder, bypassing this Group Policy editor limitation.
### Usage
- Download the repository code ZIP
- Right-click on the downloaded file, select "Properties" and click "Unblock"
- Click "OK"
- Unzip the file to your desired location
- Following the .csv examples in the /hashes folder, add .csv fiels or edit the existing to include all hashes you would like in your Software Restriction Policy
  - All fields are required, hashes are case insensitive
  - Ensure MD5 values are 32 hexadecimal characters in length
  - Ensure SHA256 values are 64 hexadecimal characters in length
- In a PowerShell window, navigate to the directory where Create-SRPPolicy.ps1 is located
- Run .\Create-SRPPolicy.ps1
  - Note, the script will process ALL .csv files in the /hashes folder so make sure it contains only what you want in your custom SRP policy
- Open Group Policy Management, create a new group policy object and edit this new policy
- Create a Software Restriction Policy
  - Can be found under User Configuration/Windows Settings/Security Settings/Software Restriction Policies
- Exit the GPO editor
- Copy the Windows SRP Policy Generator-generated Registry.pol file over your newly created group policy Registry.pol file
  - The Registry.pol file can be found in "C:\Windows\SYSVOL\sysvol\your.domain.name\Policies\{Unique GPO ID}\User" on your domain controller
  - Ensure the new Registry.pol file does not have the mark of the web (_BEFORE_ copying, right-click, Properties, uncheck "Unblock")
- Open Group Policy Management and browse to the GPO.  If the Registry.pol file permissions are incorrect, you will be prompted to have them corrected automatically
- Open the GPO in the GPO editor, navigate to the Software Restriction Policy and ensure it loads with no errors
- Test your new GPO
### Where do I get the hash values needed to make my own .csv entries?
- In a Windows command prompt, issue the following commands and copy the value returned into the respective .csv data columns
```
  certutil -hashfile <path to file> MD5
  certutil -hashfile <path to file> SHA256
  dir /-C <path to file>
```
### Where do I get the Unique GPO ID?
- Open Group Policy Management, select the GPO in question, click on the "Details" tab and find the "Unique ID" entry.

### Disclaimer
This tool generates a random identifier for each SRP entry.  There is an infinitesimally small chance of an identifier value created by this script overlapping an existing SRP identifier.
