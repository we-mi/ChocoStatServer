Remove-Module choco-stat-server -ErrorAction SilentlyContinue
Import-Module .\choco-stat-server.psd1


New-ChocoStatServerDatabase -File (Join-Path $env:USERPROFILE "ChocoStatistics.db") -Force

New-ChocoStatPackage -PackageName test
New-ChocoStatPackage -PackageName test

Update-ChocoStatComputer -ComputerName "testcomputer" -LastContact (Get-Date)

Update-ChocoStatComputerPackage -ComputerName "testcomputer" -PackageName "test" -Version 37.0


New-ChocoStatComputer -ComputerName "testcomputer" -PassThru
New-ChocoStatComputer -ComputerName "testcomputer2"
New-ChocoStatComputer -ComputerName "testcomputer3"

#Remove-ChocoStatComputer -ComputerName "testcomputer"

Update-ChocoStatComputer -ComputerName "testcomputer" -LastContact (Get-Date)



New-ChocoStatPackage -PackageName "firefox"
New-ChocoStatPackage -PackageName "7zip"
New-ChocoStatPackage -PackageName "notepadplusplus"

Remove-ChocoStatPackage -PackageName "7zip"

Get-ChocoStatPackage


Add-ChocoStatComputerPackage -ComputerName testcomputer -PackageName "firefox" -Version "100.0.2"
Add-ChocoStatComputerPackage -ComputerName testcomputer -PackageName "7zip" -Version "100.0.2"
Add-ChocoStatComputerPackage -ComputerName testcomputer3 -PackageName "firefox" -Version "100.0.2"

Get-ChocoStatComputerPackage | ft

Remove-ChocoStatComputerPackage -ComputerName testcomputer -PackageName "7zip"

Get-ChocoStatComputerPackage | ft

Update-ChocoStatComputerPackage -ComputerName testcomputer -PackageName "firefox" -Version 200.0.1

Get-ChocoStatComputerPackage | ft