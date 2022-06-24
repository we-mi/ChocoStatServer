# Documentation Overview

This is an overview of the individual components of this project and their development state.  
`completed` means that the Cmdlet/Endpoint/whatever is completed by the means of the current design.

## ChocoStatDB-Module (Chocolatey Status Database Module)

This is the low-level database module which helps to retrieve and insert data into/from the SQLite-database in a powershellish-way.
The enduser most likely won't need any of this.

### Computer related Cmdlets

[Get-ChocoStatComputer.ps1](../modules/ChocoStatDb/Public/Computers/Get-ChocoStatComputer.ps1) - completed  
[New-ChocoStatComputer.ps1](../modules/ChocoStatDb/Public/Computers/New-ChocoStatComputer.ps1)  - completed  
[Update-ChocoStatComputer.ps1](../modules/ChocoStatDb/Public/Computers/Update-ChocoStatComputer.ps1) - completed  
[Remove-ChocoStatComputer.ps1](../modules/ChocoStatDb/Public/Computers/Remove-ChocoStatComputer.ps1) - completed  

### Package related Cmdlets

[Get-ChocoStatPackage.ps1](../modules/ChocoStatDb/Public/Packages/Get-ChocoStatPackage.ps1)  
[New-ChocoStatPackage.ps1](../modules/ChocoStatDb/Public/Packages/New-ChocoStatPackage.ps1)  
[Update-ChocoStatPackage.ps1](../modules/ChocoStatDb/Public/Packages/Update-ChocoStatPackage.ps1)  
[Remove-ChocoStatPackage.ps1](../modules/ChocoStatDb/Public/Packages/Remove-ChocoStatPackage.ps1)  

### Source related Cmdlets

[Get-ChocoStatSource.ps1](../modules/ChocoStatDb/Public/Sources/Get-ChocoStatSource.ps1)  
[New-ChocoStatSource.ps1](../modules/ChocoStatDb/Public/Sources/New-ChocoStatSource.ps1)  
[Update-ChocoStatSource.ps1](../modules/ChocoStatDb/Public/Sources/Update-ChocoStatSource.ps1)  
[Remove-ChocoStatSource.ps1](../modules/ChocoStatDb/Public/Sources/Remove-ChocoStatSource.ps1)  

### Computer-Package related Cmdlets

[Get-ChocoStatComputerPackage.ps1](../modules/ChocoStatDb/Public/Computer_Packages/Get-ChocoStatComputerPackage.ps1)  
[New-ChocoStatComputerPackage.ps1](../modules/ChocoStatDb/Public/Computer_Packages/New-ChocoStatComputerPackage.ps1)  
[Update-ChocoStatComputerPackage.ps1](../modules/ChocoStatDb/Public/Computer_Packages/Update-ChocoStatComputerPackage.ps1)  
[Remove-ChocoStatComputerPackage.ps1](../modules/ChocoStatDb/Public/Computer_Packages/Remove-ChocoStatComputerPackage.ps1)  

### Computer-Source related Cmdlets

[Get-ChocoStatComputerSource.ps1](../modules/ChocoStatDb/Public/Computer_Sources/Get-ChocoStatComputerSource.ps1)  
[New-ChocoStatComputerSource.ps1](../modules/ChocoStatDb/Public/Computer_Sources/New-ChocoStatComputerSource.ps1)  
[Update-ChocoStatComputerSource.ps1](../modules/ChocoStatDb/Public/Computer_Sources/Update-ChocoStatComputerSource.ps1)  
[Remove-ChocoStatComputerSource.ps1](../modules/ChocoStatDb/Public/Computer_Sources/Remove-ChocoStatComputerSource.ps1)  

### Computer-Config related Cmdlets

[Get-ChocoStatComputerConfig.ps1](../modules/ChocoStatDb/Public/Computer_Configs/Get-ChocoStatComputerConfig.ps1)  
[New-ChocoStatComputerConfig.ps1](../modules/ChocoStatDb/Public/Computer_Configs/New-ChocoStatComputerConfig.ps1)  
[Update-ChocoStatComputerConfig.ps1](../modules/ChocoStatDb/Public/Computer_Configs/Update-ChocoStatComputerConfig.ps1)  
[Remove-ChocoStatComputerConfig.ps1](../modules/ChocoStatDb/Public/Computer_Configs/Remove-ChocoStatComputerConfig.ps1)  

### Auth related cmdlets

[Get-ChocoStatServerToken.ps1](../modules/ChocoStatDb/Public/Auth/Get-ChocoStatServerToken.ps1) - completed  
[New-ChocoStatServerToken.ps1](../modules/ChocoStatDb/Public/Auth/New-ChocoStatServerToken.ps1) - completed  
[Remove-ChocoStatServerToken.ps1](../modules/ChocoStatDb/Public/Auth/Remove-ChocoStatServerToken.ps1) - completed  
[Update-ChocoStatServerToken.ps1](../modules/ChocoStatDb/Public/Auth/Update-ChocoStatServerToken.ps1)  
[Test-ChocoStatServerToken.ps1](../modules/ChocoStatDb/Public/Auth/Test-ChocoStatServerToken.ps1) - completed  

### Other Cmdlets

[New-ChocoStatServerDatabase.ps1](../modules/ChocoStatDb/Public/New-ChocoStatServerDatabase.ps1)  
[Connect-ChocoStatServerDatabase.ps1](../modules/ChocoStatDb/Public/Connect-ChocoStatServerDatabase.ps1)  

## ChocoStatServer (Chocolatey Status Server)

This is the REST-API Server which will serve the data over HTTP or HTTPS

### Computer endpoints

[GET /api/v1/computers](../api/endpoints/GET/Get-ChocoStatComputer.ps1)  
[POST /api/v1/computers](../api/endpoints/POST/Get-ChocoStatComputer.ps1)  
[PUT /api/v1/computers](../api/endpoints/PUT/Get-ChocoStatComputer.ps1)  
[DELETE /api/v1/computers](../api/endpoints/DELETE/Get-ChocoStatComputer.ps1)  

[GET /api/v1/computer/:ComputerID:](../api/endpoints/GET/Get-ChocoStatComputerDetailed.ps1)  
[POST /api/v1/computer/:ComputerID:](../api/endpoints/POST/Get-ChocoStatComputerDetailed.ps1)  
[PUT /api/v1/computer/:ComputerID:](../api/endpoints/PUT/Get-ChocoStatComputerDetailed.ps1)  
[DELETE /api/v1/computer/:ComputerID:](../api/endpoints/DELETE/Get-ChocoStatComputerDetailed.ps1)  

### Package endpoints

[GET /api/v1/packages](../api/endpoints/GET/Get-ChocoStatPackage.ps1)  
[POST /api/v1/packages](../api/endpoints/POST/Get-ChocoStatPackage.ps1)  
[PUT /api/v1/packages](../api/endpoints/PUT/Get-ChocoStatPackage.ps1)  
[DELETE /api/v1/packages](../api/endpoints/DELETE/Get-ChocoStatPackage.ps1)  

### Source endpoints

[GET /api/v1/sources](../api/endpoints/GET/Get-ChocoStatSource.ps1)  
[POST /api/v1/sources](../api/endpoints/POST/Get-ChocoStatSource.ps1)  
[PUT /api/v1/sources](../api/endpoints/PUT/Get-ChocoStatSource.ps1)  
[DELETE /api/v1/sources](../api/endpoints/DELETE/Get-ChocoStatSource.ps1)  

### Computer-Package endpoints

[GET /api/v1/computer/:ComputerID:/packages](../api/endpoints/GET/Get-ChocoStatComputerPackage.ps1)  
[POST /api/v1/computer/:ComputerID:/packages](../api/endpoints/POST/Get-ChocoStatComputerPackage.ps1)  
[PUT /api/v1/computer/:ComputerID:/packages](../api/endpoints/PUT/Get-ChocoStatComputerPackage.ps1)  
[DELETE /api/v1/computer/:ComputerID:/packages](../api/endpoints/DELETE/Get-ChocoStatComputerPackage.ps1)  

### Computer-Source endpoints

[GET /api/v1/computer/:ComputerID:/sources](../api/endpoints/GET/Get-ChocoStatComputerSource.ps1)  
[POST /api/v1/computer/:ComputerID:/sources](../api/endpoints/POST/Get-ChocoStatComputerSource.ps1)  
[PUT /api/v1/computer/:ComputerID:/sources](../api/endpoints/PUT/Get-ChocoStatComputerSource.ps1)  
[DELETE /api/v1/computer/:ComputerID:/sources](../api/endpoints/DELETE/Get-ChocoStatComputerSource.ps1)  

### Computer-Config endpoints

[GET /api/v1/computer/:ComputerID:/config](../api/endpoints/GET/Get-ChocoStatComputerConfig.ps1)  
[POST /api/v1/computer/:ComputerID:/config](../api/endpoints/POST/Get-ChocoStatComputerConfig.ps1)  
[PUT /api/v1/computer/:ComputerID:/config](../api/endpoints/PUT/Get-ChocoStatComputerConfig.ps1)  
[DELETE /api/v1/computer/:ComputerID:/config](../api/endpoints/DELETE/Get-ChocoStatComputerConfig.ps1)  

### User (auth) endpoints

[GET /api/v1/auth/self](../api/endpoints/GET/Get-ChocoStatServerSelf.ps1) - completed  
[GET /api/v1/auth/users](../api/endpoints/GET/Get-ChocoStatServerUsers.ps1)  
[POST /api/v1/auth/login](../api/endpoints/GET/Invoke-ChocoStatServerLogin.ps1)  
[GET /api/v1/auth/logout](../api/endpoints/GET/Invoke-ChocoStatServerLogout.ps1)  

### Other endpoints

[GET /api/v1/server/status](../api/endpoints/GET/Get-ChocoStatServerStatus.ps1)  
[POST /api/v1/server/shutdown](../api/endpoints/POST/Stop-ChocoStatServer.ps1)  
[POST /api/v1/server/restart](../api/endpoints/POST/Restart-ChocoStatServer.ps1)  

## ChocoStatClient (Chocolatey Status Client/Agent)

Just a simple script right now, needs more of everything :p

## ChocoStatGUI (Chocolatey Status GUI)

Not started