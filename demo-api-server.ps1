Remove-Module ChocoStatServer -ErrorAction SilentlyContinue
Import-Module (Join-Path $PSScriptRoot "ChocoStatServer.psd1")

$serverCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=server.example.org" }

Start-ChocoStatServer -Force