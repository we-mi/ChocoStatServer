Remove-Module ChocoStatDb -ErrorAction SilentlyContinue
Import-Module (Join-Path $PSScriptRoot "modules/ChocoStatDb/ChocoStatDb.psd1")

# Create a new database file
New-ChocoStatServerDatabase -File (Join-Path $env:USERPROFILE "ChocoStatistics.db") -Force | Out-Null

New-ChocoStatComputer -ComputerName "foo.example.org" -LastContact (Get-Date)
New-ChocoStatComputer -ComputerName "bar.example.org" -LastContact (Get-Date)

New-ChocoStatPackage -PackageName "vlc"
New-ChocoStatPackage -PackageName "firefox"

Add-ChocoStatComputerPackage -ComputerName "foo.example.org" -PackageName "vlc" -Version 1.0
Add-ChocoStatComputerPackage -ComputerName "foo.example.org" -PackageName "firefox" -Version 1.0
Add-ChocoStatComputerPackage -ComputerName "bar.example.org" -PackageName "vlc" -Version 1.0

Get-ChocoStatComputerPackage -Verbose -PackageName "vlc" -ComputerID 1,2

Update-ChocoStatComputerPackage -ComputerName foo.example.org -PackageName vlc -Version 20.0