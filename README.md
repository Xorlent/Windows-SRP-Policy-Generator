# Windows-SRP-Policy-Generator
Generates a custom Policy.pol file for hash-based software restriction group policies  
### Purpose
Windows Software Restriction Policies can help prevent execution of common living off the land (LOL) tools, but the Group Policy editor is severely limited for hash-based restrictions.  To add a hash-based rule, you need to have a copy of the file in question.  For executables like Powershell.exe, this would require hunting down a copy of every version published to ensure complete coverage.  
- This tool generates a custom .pol file from a supplied hash list that can then be copied to your group policy folder, bypassing this Group Policy editor limitation.
### Usage
