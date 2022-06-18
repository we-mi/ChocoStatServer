function Update-ChocoStatComputer {
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $ComputerName,

        [Parameter()]
        [datetime]
        $LastContact
    )

    process {

        $computerObject = Get-ChocoStatComputer -ComputerName $ComputerName

        if ($null -eq $LastContact) {
            $LastContact = Get-Date
        }

        if ($computerObject) {            

            $Query = "UPDATE Computers SET LastContact=@LastContact WHERE ComputerName=@ComputerName"
            Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                ComputerName = $ComputerName
                LastContact = $LastContact
            }
        } else {
            New-ChocoStatComputer -ComputerName $ComputerName -LastContact $LastContact
        }
        
    }
    
}