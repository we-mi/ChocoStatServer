function New-ChocoStatPackage {
    <#
    .SYNOPSIS
        Creates a new package in the database
    .DESCRIPTION
        Creates a new package in the database
    .NOTES
        There are no other columns right now available for packages. Only the name
    .EXAMPLE
        New-ChocoStatPackage -PackageName "firefox"

        Creates a new package "firefox"
    #>
    
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # Name of the package
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]        
        [String]
        $PackageName,

        # Return the newly created object
        [Parameter()]
        [Switch]
        $PassThru,

        # Don't actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    process {

        # Check for existing name
        $double = Get-ChocoStatPackage -PackageName $PackageName
        if ($double.PackageName -eq $PackageName) {
            Throw "PackageName already present"
        }        

        $Query = "INSERT INTO Packages (PackageName) VALUES (@PackageName);"
        Write-Verbose "New-ChocoStatPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would create package with name '$PackageName'"
        } else {
            Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                PackageName = $PackageName
            }
        }

        if ($PassThru.IsPresent) {
            Get-ChocoStatPackage | Where-Object { $_.PackageName -eq $PackageName }
        }        
    }    
}
