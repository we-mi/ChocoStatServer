<#
    .DESCRIPTION
        This script will return the specified data to the Client.
    .EXAMPLE
        Invoke-GetProcess.ps1 -RequestArgs $RequestArgs -Body $Body
    .NOTES
        This will return data
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", '')]
param(
    $RequestArgs,
    $Body
)

Remove-Module choco-stat-server -ErrorAction SilentlyContinue
Import-Module C:\Users\Michael\Documents\git\github.com\choco-stat-server\choco-stat-server.psd1

Connect-ChocoStatServerDatabase -File "C:\Users\michael\ChocoStatistics.db" | Out-Null

$newbody = $body | ConvertFrom-Json

$ComputerName   = $newbody.ComputerName
$Packages       = $newbody.Packages

Write-Host "Got $($Packages.Count) packages for $computername"

Update-ChocoStatComputer -ComputerName $ComputerName

foreach ($package in $Packages) {
    $PackageName    = $package.PackageName
    $Version        = $package.Version
    $Parameters     = $package.Parameters
    $InstalledOn    = $package.InstalledOn

    Write-Host "Handling package $packageName"

    New-ChocoStatPackage -PackageName $PackageName
    Update-ChocoStatComputerPackage -ComputerName $ComputerName -PackageName $PackageName -Version $Version -Parameters $Parameters -InstalledOn $InstalledOn

}

#$Message = Get-Process -Name $ProcessName | Where-Object { $_.MainWindowTitle -like "*$MainWindowTitle*" } | Select-Object ProcessName, Id, MainWindowTitle

return (Get-ChocoStatComputerPackage -ComputerName $ComputerName)