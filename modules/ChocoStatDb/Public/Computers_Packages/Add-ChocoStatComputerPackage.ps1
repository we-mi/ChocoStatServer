function Add-ChocoStatComputerPackage {
    <#
    .SYNOPSIS
        Adds a package to a computer
    .DESCRIPTION
        Adds a package with a version and (optional) a install date to a computer. You cannot have multiple versions of one package linked to one computer. You have to update the dataset to update the version (Update-ChocoStatComputerPackage) or remove the package from the computer (Remove-ChocoStatComputerPackage) and add it again
    .NOTES
        The parameter "Parameters" has no effect yet as there is currently no way to read the parameters which were used when the package was installed
    .EXAMPLE
        Add-ChocoStatComputerPackage -ComputerName "foo.example.org" -PackageName "vlc" -Version 1.0

        Adds the package "vlc" in version "1.0" to the computer "foo.example.org"
    #>

    [CmdletBinding(DefaultParameterSetName = "ComputerName")]
    [OutputType([Object[]])]

    param (
        # a ComputerIDs to add the packages
        [Parameter(
            Mandatory,
            ParameterSetName = "ComputerID",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]
        [Int]
        $ComputerID,

        # a ComputerName to add the packages (can contain SQL wildcards)
        [Parameter(
            Mandatory,
            ParameterSetName = "ComputerName",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]
        [String]
        $ComputerName,

        # A PackageName which should be added to the computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1
        )]
        [String]
        $PackageName,

        # The version of the package
        [Parameter(Mandatory)]
        [String]
        $Version,

        # The parameters with which the package was installed
        [Parameter()]
        [String]
        $Parameters,

        # The date the package was installed or updated to
        [Parameter()]
        [datetime]
        $InstalledOn,

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    process {

        if ($ComputerName) { # find related ComputerID
            $ComputerObject = Get-ChocoStatComputer -ComputerName $ComputerName
        } else { # find with ID
            $ComputerObject = Get-ChocoStatComputer -ComputerID $ComputerID
        }

        if ($null -eq $ComputerObject) {
            Throw "Computer with ID '$ComputerID' does not exist"
        }        

        $PackageObject = Get-ChocoStatPackage -PackageName $PackageName
        if ($null -eq $PackageObject) {
            Throw "Package with Name '$PackageName' does not exist"
        }
        
        $Query = "INSERT INTO Computers_Packages (ComputerID, PackageName, Version, Parameters, InstalledOn) VALUES (@ComputerID, @PackageName, @Version, @Parameters, @InstalledOn)"
        Write-Verbose "Add-ChocoStatComputerPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would add package '$PackageName' to computer with ID '$ComputerID'"
        } else {

            Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                ComputerID = $ComputerObject.ComputerID
                PackageName = $PackageName
                Version = $Version
                Parameters = $Parameters
                InstalledOn = $InstalledOn
            }
        }
    }    
}