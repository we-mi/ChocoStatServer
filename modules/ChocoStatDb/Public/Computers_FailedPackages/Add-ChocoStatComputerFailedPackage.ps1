# TODO:
#  Check if FailedPackage already added -> helpful error message and use Update-ChocoStatComputerFailedPackage
function Add-ChocoStatComputerFailedPackage {
    <#
    .SYNOPSIS
        Adds a FailedPackage to a computer
    .DESCRIPTION
        Adds a FailedPackage with a version and (optional) a install date to a computer. You cannot have multiple versions of one FailedPackage linked to one computer. You have to update the dataset to update the version (Update-ChocoStatComputerFailedPackage) or remove the FailedPackage from the computer (Remove-ChocoStatComputerFailedPackage) and add it again
    .NOTES
        The parameter "Parameters" has no effect yet as there is currently no way to read the parameters which were used when the FailedPackage was installed
    .EXAMPLE
        Add-ChocoStatComputerFailedPackage -ComputerName "foo.example.org" -PackageName "vlc" -Version 1.0

        Adds the FailedPackage "vlc" in version "1.0" to the computer "foo.example.org"
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # ComputerID for adding the FailedPackages
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int]
        $ComputerID,

        # A PackageName which should be added to the computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $PackageName,

        # The version of the FailedPackage
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $Version,

        # The parameters with which the FailedPackage was installed
        [Parameter()]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $Parameters,

        # The date the FailedPackage was installed or updated to
        [Parameter()]
        [AllowNull()]
        [datetime]
        $FailedOn = "01.01.1970 00:00:00",

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerObject = Get-ChocoStatComputer -ComputerID $ComputerID -FailedPackages

        if ($null -eq $ComputerObject) {
            Throw "Computer with ID '$ComputerID' does not exist"
        }

        if ($ComputerObject.FailedPackages.PackageName -contains $PackageName) {
            Throw "FailedPackage '$PackageName' already attached to computer with ID '$ComputerID'"
        }

        $Query = "INSERT INTO Computers_FailedPackages (ComputerID, PackageName, Version, Parameters, FailedOn) VALUES (@ComputerID, @PackageName, @Version, @Parameters, @FailedOn)"
        Write-Verbose "Add-ChocoStatComputerFailedPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would add FailedPackage '$PackageName' to computer with ID '$ComputerID'"
        } else {

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerObject.ComputerID
                PackageName = $PackageName
                Version = $Version
                Parameters = $Parameters
                FailedOn = $FailedOn
            }
        }
    }
}
