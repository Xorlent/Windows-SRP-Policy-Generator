### Hash-generating tools
#### Get-AllGithubReleases.ps1
- This tool allows the user to specify a GitHub repo and target executable file from which a hash csv is generated from all available releases in the repo.  
- Usage:
  ```
  Get-AllGitHubReleases -owner <GitHub repo owner> -repo <GitHub repo name> -exe <executable to process>
  ```
  The script will prompt for input if any parameters are missing.
- Limitations:
  - The script will only find and extract executables from release assets ending in, "x86.zip", "x64.zip", "amd64.zip"
  - If the repo you are targeting has different naming convention for the Windows ZIP releases, edit lines 44 and 58 of the script.
