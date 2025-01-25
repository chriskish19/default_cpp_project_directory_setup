<h1>About</h1>
<p>A powershell script that creates some needed files for a typical c++ project. Includes a cmake file with boilerplate code to get started from my github.</p>

<h1>Prerequisites</h1>
<li>Atleast Powershell 5.1</li>
<li>Git</li>
<p></p>

<h1>How to:</h1>
<li>-dir</li>
<p>the directory where to create the folders.</p>
<li>-create</li>
<p>a flag for creating the given directory (-dir)</p>

<p>In your terminal...</p>

```powershell
# runs the script
PS C:\Users\chris> ./directory_structure.ps1 -dir "C:/create/folders/here" -create

# setup an enviroment variable to run the script from anywhere
PS C:\Users\chris> [Environment]::SetEnvironmentVariable("directory_structure","C:\script\location\directory_structure.ps1","User")

# once set it can be invoked from the terminal
PS C:\Users\chris> & $env:directory_structure -dir "C:/create/folders/here" -create

