function New-ChocoStatComputer {
    <#
    .SYNOPSIS
        Creates a new computer in the database
    .DESCRIPTION
        Creates a new computer in the database. You can choose to pass the LastContact date or leave it out, then it will default to 1970-01-01 00:00:00
    .NOTES
        It is possible to create a computer whose name already exists in the database. However, this might lead to inconsistent behaviour and you should never really use this. Might remove this "feature" in the future.
    .EXAMPLE
        New-ChocoStatComputer -ComputerName "foo.example.org" -LastContact (Get-Date)

        Creates a new computer "foo.example.org" and set the LastContact date to the current date
    #>
    
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # Name of the computer. Use force to create a computer if the name already exists
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]        
        [String]
        $ComputerName,

        # Date of last contact
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [datetime]
        $LastContact = "01-01-1970 00:00:00",

        # Return the newly created object
        [Parameter()]
        [Switch]
        $PassThru,

        # Use if you want to create a computer whose name already exists. You should not use this (this might lead to inconsistent behaviour)
        [Parameter()]
        [Switch]
        $Force
    )

    process {

        # Check for existing name
        $double = Get-ChocoStatComputer -ComputerName $ComputerName
        if ($double.ComputerName -eq $ComputerName -and -not $Force.IsPresent) {
            Throw "Computername already present. Use -Force to create it nevertheless"
        }        

        $Query = "INSERT INTO Computers (ComputerName, LastContact) VALUES (@ComputerName,@LastContact);"
        Write-Verbose "New-ChocoStatComputer: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would create computer with name '$ComputerName'"
        } else {
            Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                ComputerName = $ComputerName
                LastContact = $LastContact
            }
        }

        if ($PassThru.IsPresent) {
            Get-ChocoStatComputer | Where-Object { $_.ComputerName -eq $ComputerName }
        }        
    }    
}
