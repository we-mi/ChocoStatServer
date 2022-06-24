function Remove-ChocoStatComputerPackage {
    <#
    .SYNOPSIS
        Removes a package from a computer from the database
    .DESCRIPTION
        Removes a package from a computer from the database. You will need the ComputerID, have a look at 'Get-ChocoStatComputer'. You can pipe the output from Get-ChocoStatComputer to this cmdlet.
    .NOTES
        This cmdlet does not check if the package was linked to the computer beforehand
    .EXAMPLE
        Remove-ChocoStatComputerPackage -ComputerID 5 -PackageName "firefox"
        
        Removes firefox from computer with ID 5
    .EXAMPLE
        Remove-ChocoStatComputerPackage -ComputerName "foo.example.org" -PackageName "firefox"
        
        Removes firefox from computer with name "foo.example.org"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName "%.example.org" | Remove-ChocoStatComputerPackage -PackageName "firefox"

        Removes firefox from all computers which names end with '.example.org'
    #>
    
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # ComputerID to remove the package from
        [Parameter(
            Mandatory,
            ParameterSetName = "ComputerID",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]
        [Int[]]
        $ComputerID,

        # ComputerName to remove the package from (can contain SQL wildcards)
        [Parameter(
            Mandatory,
            ParameterSetName = "ComputerName",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]
        [String[]]
        $ComputerName,

        # One or more PackageNames to search for (can contain SQL wildcards)
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 1
        )]
        [String]
        $PackageName,

        [Parameter()]
        [Bool]
        $Confirm = $True,
        
        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    process {

        $Query = "DELETE FROM Computers_Packages WHERE PackageName=@PackageName"

        # we need the ComputerID, so get it with Get-ChocoStatComputer, if a ComputerName was provided
        if ($PSCmdlet.ParameterSetName -eq "ComputerName") {
            $ComputerID = Get-ChocoStatComputer -ComputerName $ComputerName | Select-Object -ExpandProperty ComputerID
        }        

        $Query += " AND ("
        $Query += ($ComputerID | ForEach-Object { " ComputerID LIKE '$_'" } ) -join ' OR '
        $Query += " )"

        Write-Verbose "Remove-ChocoStatComputerPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would remove package '$PackageName' from computer with IDs '$($ComputerIDs -join ',')'"
        } else {
            $GoAhead = $False
            if ($Confirm) {
                $answer = Read-Host -Prompt "Remove package '$PackageName' from computer with IDs '$($ComputerID -join ',')' from database? (y/N)"
                if ($answer -eq "y") { $GoAhead = $True }
            } else { $GoAhead = $True }

            if ($GoAhead) {
                Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                    PackageName = $PackageName
                }
            } else {
                Write-Host -ForegroundColor Magenta "You chose not to remove the package from the computers"
            }
        }        
    }    
}
