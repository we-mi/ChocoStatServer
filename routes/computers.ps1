Add-PodeRouteGroup -Path (Get-PodeConfig).BaseUrl -Routes {

    # get all computers including packages and sources
    Add-PodeRoute -Method Get -Path "/computers" -Authentication "AuthenticateRead" -ScriptBlock {

        try {
            $computers = Get-ChocoStatComputer -Packages -Sources

            if (!$computers) {
                Set-PodeResponseStatus -Code 404 -Description "No computer was registered yet" -Exception $_ -NoErrorPage
                return
            }
        } catch {
            Set-PodeResponseStatus -Code 500 -Description "Error while retrieving infos about computers" -Exception $_ -NoErrorPage
            return
        }

        Write-PodeJsonResponse @($computers)

    }

    # get single computer with ID including packages and sources
    Add-PodeRoute -Method Get -Path "/computers/:computerId" -Authentication "AuthenticateRead" -ScriptBlock {

        $id = $WebEvent.Parameters['computerId']
        try {
            $computer = Get-ChocostatComputer -ComputerID $id -Packages -Sources
            if (!$computer) {
                Set-PodeResponseStatus -Code 404 -Description "Computer with ID '$id' not found" -Exception $_ -NoErrorPage
                return
            }
        } catch {
            Set-PodeResponseStatus -Code 500 -Description "Error while retrieving infos for computer with id '$id'" -Exception $_ -NoErrorPage
            return
        }

        Write-PodeJsonResponse @($computer)

    }

    # get packages for single computer with id
    Add-PodeRoute -Method Get -Path "/computers/:computerId/packages" -Authentication "AuthenticateRead" -ScriptBlock {

        $id = $WebEvent.Parameters['computerId']
        try {
            $packages = Get-ChocoStatComputerPackage -ComputerID $id | Select-Object PackageName,Version
            if (!$packages) {
                Set-PodeResponseStatus -Code 404 -Description "No packages were found for computer with ID '$id'" -Exception $_ -NoErrorPage
                return
            }
        } catch {
            Set-PodeResponseStatus -Code 500 -Description "Error while retrieving packages for computer with id '$id'" -Exception $_ -NoErrorPage
            return
        }

        Write-PodeJsonResponse @($packages)
    }

    # get sources for single computer with id
    Add-PodeRoute -Method Get -Path "/computers/:computerId/sources" -Authentication "AuthenticateRead" -ScriptBlock {

        $id = $WebEvent.Parameters['computerId']
        try {
            $sources = Get-ChocoStatComputerSource -ComputerID $id | Select-Object -ExcludeProperty ComputerID,ComputerName
            if (!$sources) {
                Set-PodeResponseStatus -Code 404 -Description "No sources were found for computer with ID '$id'" -Exception $_ -NoErrorPage
                return
            }
        } catch {
            Set-PodeResponseStatus -Code 500 -Description "Error while retrieving sources for computer with id '$id'" -Exception $_ -NoErrorPage
            return
        }

        Write-PodeJsonResponse @($sources)

    }

    # add new computer
    Add-PodeRoute -Method Post -Path "/computers" -Authentication "AuthenticateWrite" -ScriptBlock {

        # check name
        if ( [String]::IsNullOrWhiteSpace($WebEvent.Data.ComputerName) ) {
            Set-PodeResponseStatus -Code 400 -Description "Missing field 'ComputerName'" -Exception $_ -NoErrorPage
            return
        }

        # try to parse anything before actually creating a new computer
        try {

            foreach ($package in $WebEvent.Data.Packages) {

                if (-not $package.ContainsKey("PackageName") -or -not $package.ContainsKey("Version") ) {
                    Set-PodeResponseStatus -Code 400 -Description "Malformed package object ('PackageName' and 'Version' are required in '$($package)'" -NoErrorPage
                    return
                }
            }

            foreach ($source in $WebEvent.Data.Sources) {

                if (-not $source.ContainsKey("SourceName") -or -not $source.ContainsKey("SourceURL") ) {
                    Set-PodeResponseStatus -Code 400 -Description "Malformed package object ('SourceName' and 'SourceURL' are required in '$($source)'" -NoErrorPage
                    return
                }
            }

        } catch {
            Write-Host $_
            Set-PodeResponseStatus -Code 400 -Description "Malformed json" -Exception $_ -NoErrorPage
            return
        }

        # if we got to this point we can import a new computer and hopefully attach packages and sources to it without getting syntax errors
        try {
            $ComputerSecret = Get-RandomPassword -Length 64
            $computer = New-ChocoStatComputer -ComputerName $WebEvent.Data.ComputerName -Secret $ComputerSecret -PassThru
        } catch {
            Write-Host $_
            Set-PodeResponseStatus -Code 500 -Description "Error while creating a new computer '$($WebEvent.Data.ComputerName)'" -Exception $_ -NoErrorPage
            return
        }

        foreach ($package in $WebEvent.Data.Packages) {
            try {
                if ( $package.InstalledOn -is [DateTime] ) {
                    Add-ChocoStatComputerPackage -ComputerID $computer.ComputerId -PackageName $package.PackageName -Version $package.Version -InstalledOn $package.InstalledOn
                } else {
                    Add-ChocoStatComputerPackage -ComputerID $computer.ComputerId -PackageName $package.PackageName -Version $package.Version
                }
            } catch {
                Write-Host $_
                Set-PodeResponseStatus -Code 500 -Description "Error while attaching package '$($package)' to new computer '$($WebEvent.Data.ComputerName)': $_" -Exception $_
                return
            }
        }

        foreach ($source in $WebEvent.Data.Sources) {
            try {
                Add-ChocoStatComputerSource -ComputerID $computer.ComputerId @source
            } catch {
                Write-Host $_
                Set-PodeResponseStatus -Code 500 -Description "Error while attaching source '$($source)' to new computer '$($WebEvent.Data.ComputerName)': $_" -Exception $_
                return
            }
        }

        # fetch result back from database and return it to client
        $computer = Get-ChocoStatComputer -ComputerID $computer.ComputerId -Packages -Sources

        # Add secret to computer result so client can save it
        $computer | Add-Member -MemberType NoteProperty -Name "Secret" -Value $ComputerSecret

        Write-PodeJsonResponse $computer

    }

    # Update an existing computer
    Add-PodeRoute -Method Put -Path "/computers/:computerId" -Authentication "AuthenticateAdminOrSelf" -ScriptBlock {
        try {
            $id = $WebEvent.Parameters['computerId']

            # check name
            if ( [String]::IsNullOrWhiteSpace($id) ) {
                Set-PodeResponseStatus -Code 400 -Description "Missing field 'ComputerID'" -Exception $_ -NoErrorPage
                return
            }

            $computer = Get-ChocoStatComputer -ComputerId $id -Packages -Sources
            if(!$computer) {
                Set-PodeResponseStatus -Code 404 -Description "Computer with ID '$id' was not found" -Exception $_ -NoErrorPage
                return
            }

            $newName = $WebEvent.Data.ComputerName

            if ([String]::IsNullOrWhiteSpace($newName) -and !($WebEvent.Data.Packages) -and !($WebEvent.Data.Sources)) {
                Set-PodeResponseStatus -Code 400 -Description "At least one of 'ComputerName', 'Packages' or 'Sources' is required" -Exception $_ -NoErrorPage
                return
            }

            # try to parse anything before actually creating a new computer
            try {

                foreach ($package in $WebEvent.Data.Packages) {

                    if (-not $package.ContainsKey("PackageName") -or -not $package.ContainsKey("Version") ) {
                        Set-PodeResponseStatus -Code 400 -Description "Malformed package object ('PackageName' and 'Version' are required in '$($package)'" -NoErrorPage
                        return
                    }
                }

                foreach ($source in $WebEvent.Data.Sources) {

                    if (-not $source.ContainsKey("SourceName") -or -not $source.ContainsKey("SourceURL") ) {
                        Set-PodeResponseStatus -Code 400 -Description "Malformed package object ('SourceName' and 'SourceURL' are required in '$($source)'" -NoErrorPage
                        return
                    }
                }

            } catch {
                Set-PodeResponseStatus -Code 400 -Description "Malformed json" -Exception $_ -NoErrorPage
                return
            }

            # if we got to this point we can update a computer and hopefully update packages and sources of it without getting syntax errors
            if ( -not [String]::IsNullOrWhiteSpace($newName) ) {
                try {
                    $computer = Update-ChocoStatComputer -ComputerID $id -ComputerName $newName -PassThru
                } catch {
                    Set-PodeResponseStatus -Code 500 -Description "Error while updating computer name" -Exception $_ -NoErrorPage
                    return
                }
            }

            # update all packages from json object
            foreach ($package in $WebEvent.Data.Packages) {
                try {
                    Update-ChocoStatComputerPackage -ComputerId $computer.ComputerID -PackageName $package.PackageName -Version $package.Version
                } catch {
                    Write-Host $_
                    Set-PodeResponseStatus -Code 500 -Description "Error while attaching package '$($package)' to new computer '$id'" -Exception $_ -NoErrorPage
                    return
                }
            }

            try {
                # remove packages from computer which are missing in json object
                $currentPackages = $computer.Packages.PackageName
                $futurePackages = $WebEvent.Data.Packages.PackageName

                if ($currentPackages) {
                    Compare-Object $currentPackages $futurePackages | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object {
                        Remove-ChocoStatComputerPackage -ComputerID $computer.ComputerID -PackageName $_.InputObject -Confirm:$False
                    }
                }
            } catch {
                Write-Host $_
                Set-PodeResponseStatus -Code 500 -Description "Error while removing packages not installed anymore" -Exception $_ -NoErrorPage
                return
            }

            # update all sources from json object
            foreach ($source in $WebEvent.Data.Sources) {
                try {
                    Update-ChocoStatComputerSource -ComputerId $computer.ComputerID @source
                } catch {
                    Write-Host $_
                    Set-PodeResponseStatus -Code 500 -Description "Error while updating source '$($source)' of computer '$id'" -Exception $_ -NoErrorPage
                    return
                }
            }

            try {
                # remove sources from computer which are missing in json object
                $currentSources = $computer.Sources.SourceName
                $futureSources = $WebEvent.Data.Sources.SourceName

                if ($currentSources) {
                    Compare-Object $currentSources $futureSources | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object {
                        Remove-ChocoStatComputerSource -ComputerID $computer.ComputerID -SourceName $_.InputObject -Confirm:$False
                    }
                }
            } catch {
                Write-Host $_
                Set-PodeResponseStatus -Code 500 -Description "Error while removing sources not installed anymore" -Exception $_ -NoErrorPage
                return
            }

            # fetch result back from database and return it to client
            $computer = Get-ChocoStatComputer -ComputerID $id -Packages -Sources

            Write-PodeJsonResponse $computer
        } catch {
            Write-Host $_
            Set-PodeResponseStatus -Code 500 -Description "Error while updating computer '$id'" -Exception $_ -NoErrorPage
            return
        }
    }

    # Remove a computer
    Add-PodeRoute -Method Delete -Path "/computers/:computerId" -Authentication "AuthenticateAdmin" -ScriptBlock {

        $id = $WebEvent.Parameters['computerId']
        try {
            $computer = Get-ChocostatComputer -ComputerID $id
            if (!$computer) {
                Set-PodeResponseStatus -Code 404 -Description "Computer with ID '$id' not found" -Exception $_ -NoErrorPage
                return
            }
        } catch {
            Set-PodeResponseStatus -Code 500 -Description "Error while retrieving infos for computer with id '$id'" -Exception $_ -NoErrorPage
            return
        }

        try {
            Remove-ChocoStatComputer -ComputerID $id -Confirm:$false
        } catch {
            Set-PodeResponseStatus -Code 500 -Description "Error while removing computer with id '$id'" -Exception $_ -NoErrorPage
            return
        }

        Write-PodeJsonResponse @($computer)
    }
}
