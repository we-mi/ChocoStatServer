function New-ChocoStatComputer {
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $ComputerName,

        [Parameter()]
        [datetime]
        $LastContact = "01-01-1970 00:00:00",

        [Parameter()]
        [Switch]
        $PassThru
    )

    process {

        $Query = "INSERT INTO Computers (ComputerName, LastContact) VALUES (@ComputerName,@LastContact)"
        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerName = $ComputerName
            LastContact = $LastContact
        }

        if ($PassThru.IsPresent) {
            Get-ChocoStatComputer | Where-Object { $_.ComputerName -eq $ComputerName }
        }        
    }
    
}