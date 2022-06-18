Function Start-ChocoStatServer {
    [CmdletBinding()]
    param (
            
    )

    process {
        #Start-RestPSListener -RoutesFilePath .\api\endpoints\RestPSRoutes.json -Port 8080 -SSLThumbPrint "269B9340D7CD697653D9136C6E03FA8EA6A366BC" -VerificationType "VerifyRootCA"

        Start-RestPSListener -RoutesFilePath C:\Users\Michael\Documents\git\github.com\choco-stat-server\api\endpoints\RestPSRoutes.json -Port 8080
    }        
}