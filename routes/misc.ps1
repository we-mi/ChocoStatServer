Add-PodeRouteGroup -Path (Get-PodeConfig).BaseUrl -Routes {

    # get all computers including packages and sources
    Add-PodeRoute -Method Get -Path "/stat" -Authentication "AuthenticateRead" -ScriptBlock {

        try {
            $computers = Get-ChocoStatComputer
            $computerPackages = Get-ChocoStatComputerPackage
            $packages = Get-ChocoStatPackage
            $users = Get-ChocoStatUser

        } catch {
            Set-PodeResponseStatus -Code 500 -Description "Error while retrieving stats" -Exception $_ -NoErrorPage
            return
        }

        $stats = [PSCustomObject]@{
            computers = $computers.Count
            totalPackages = $computersPackages.Count
            uniquePackages = $packages.Count
            users = $users.Count
            lastComputerContact = $computers | Sort-Object -Property LastContact -Descending | Select-Object -First 1 -ExpandProperty LastContact
        }

        Write-PodeJsonResponse $stats

    }
}
