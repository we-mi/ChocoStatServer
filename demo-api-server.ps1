$ErrorActionPreference = "Stop"
remove-module ChocoStatServer,ChocoStatDb,PSSQLite,Pode -ErrorAction SilentlyContinue

Import-Module -Name (Join-Path $PSScriptRoot "ChocoStatServer.psd1")

$env:ChocoStatDbFile = "C:\ProgramData\ChocoStatServer\ChocoStatistics.db"

# Initialize the database
if ( -not (Test-Path $env:ChocoStatDbFile) ) {
    $null = New-ChocoStatServerDatabase -File $env:ChocoStatDbFile

    # create an admin user and attach an api token to it, which allows the user to modify everything through the REST-API
    New-ChocoStatUser -UserName "admin" -Password "demo" -PassThru | New-ChocoStatAPIToken -Type "admin" -PassThru

    # fill the database with some demo data
    for ($i = 0; $i -lt 10; $i++) {
        Write-Host "Creating demo computer $i"
        $computer = New-ChocoStatComputer -ComputerName "Computer-$i" -PassThru -Secret (Get-Random)

        for ($j = 0; $j -lt (Get-Random -Maximum 30); $j++) {
            $Package = @{PackageName = "Package-$(Get-Random -Maximum 20)"; Version = Get-Random }

            Update-ChocoStatComputerPackage -ComputerID $computer.ComputerID -PackageName $Package.PackageName -Version $Package.Version
        }
    }
}

Get-ChocoStatComputer -Packages

Start-ChocoStatServer
