function Update-ChocoStatComputer {
    <#
    .SYNOPSIS
        Updates a computer in the database
    .DESCRIPTION
        Can alter the name of the computer. The LastContact-Datetime is always updated, but you can specify a date instead of the current date
        If the computer you wish to update does not exist yet, you can enforce its creation with the '-Force' parameter. You must provide the computername for the creation, the ComputerID you searched for will then be ignored
    .NOTES
        This cmdlet will throw an error if a new computer should be created and the name does already exist. Use 'New-ChocoStatComputer' with the '-Force' parameter instead
    .EXAMPLE
        Update-ChocoStatComputer -ComputerID 1 -ComputerName "newname.example.org"

        Will change the name for the computer with ID '1' to "newname.example.org". The computer will not be created if it does not exist.
    .EXAMPLE
        Update-ChocoStatComputer -ComputerID -1 -ComputerName "demo.example.org" -Force
        Will create the computer "demo.example.org" because the ID "-1" won't exist
    #>
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # ID of the computer. Will be ignored if a new computer shall be created (see Description)
        [Parameter(Mandatory)]        
        [Int]
        $ComputerID,

        # New name of the computer. Can be anything you want but should be the FQDN of the computer
        [Parameter()]
        [String]
        $ComputerName,

        # Date of the lastcontact with the server. Will always be updated. If not provided the current datetime is saved
        [Parameter()]
        [datetime]
        $LastContact,

        # The updated (or newly created computer object) will be returned
        [Parameter()]
        [Switch]
        $PassThru,

        # Used when this cmdlet should create a computer that was not found over its ID
        [Parameter()]
        [Switch]
        $Force,

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    process {

        if ($null -eq $ComputerName -and $null -eq $LastContact) {
            Throw "Nothing to insert or update. Gimme some data"
        }

        $ComputerObject = Get-ChocoStatComputer -ComputerID $ComputerID
        
        # always set LastContact to the current date, no matter if the computer exists or not
        if ($null -eq $LastContact) {
            $LastContact = Get-Date
        }

        if ($null -ne $ComputerObject) { # update existing object
            Write-Verbose "Update-ChocoStatComputer: Computer with ID '$ComputerID' was found. Update its data"

            # adopt computername in update command if it is not changed
            if ($null -eq $ComputerName) {
                $Computername = $ComputerObject.ComputerName
            }

            $Query = "UPDATE Computers SET LastContact=@LastContact,ComputerName=@ComputerName WHERE ComputerID=@ComputerID;"
            Write-Debug -Message "Update-ChocoStatComputer: Execute SQL Query: $Query"
            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would update computer with ID '$ComputerID'"
            } else {
                Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                    ComputerID = $ComputerID
                    ComputerName = $ComputerName
                    LastContact = $LastContact
                }
            }

            if ($PassThru.IsPresent) {
                Get-ChocoStatComputer -ComputerID $ComputerID
            }

        } else { # create new object (needs -Force and -ComputerName at least)
            Write-Verbose "Update-ChocoStatComputer: Computer with ID '$ComputerID' was not found. Check if we should enforce its creation"
            if (-not $Force.IsPresent) {
                Throw "Computer with ID '$ComputerID' does not exist. Use -Force to create it nevertheless"
            }
            if ( [String]::IsNullOrWhiteSpace($ComputerName) ) {
                Throw "Creating a computer requires a computername"
            }

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would create new computer with name '$ComputerName'"
            } else {
                if ($PassThru.IsPresent) {
                    New-ChocoStatComputer -ComputerName $ComputerName -LastContact $LastContact -PassThru
                } else {
                    New-ChocoStatComputer -ComputerName $ComputerName -LastContact 
                    $LastContact
                }
            }
        }        
    }
}