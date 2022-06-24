function New-ChocoStatServerToken {
    <#
    .SYNOPSIS
        Generates an API Token after the user was authenticated and stores it in the database
    .DESCRIPTION
        Generates an API Token after the user was authenticated and stores it in the database. You need to pass a username a type and a duration
    .EXAMPLE
        New-ChocoStatServerToken -Username "demo" -Type "write" -Duration "7200"
        
        Generates an API Token for user demo who is allowed to write to the database and with a "lifetime" of 7200 seconds (2 hours)
    #>
    
    [CmdletBinding()]
    [OutputType([String])]

    param (
        # Username
        [Parameter(Mandatory)]
        [String]
        $UserName,

        # Type which decides what the user is allowed to do
        [Parameter(Mandatory)]
        [ValidateSet("read","write","admin")]
        [String]
        $Type,

        # Duration in seconds
        [Parameter()]
        [Int]
        $Duration = 7200
    )

    process {
        $Token = @( (New-Guid), (New-Guid) ) -join '' -replace '-'
        $WhenCreated = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        
        $Query = "INSERT INTO Tokens (Token, UserName, Type, WhenCreated, Duration) VALUES (@Token, @UserName, @Type, @WhenCreated, @Duration)"

        Write-Verbose "Get-ChocoStatComputer: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            Token       = $Token
            UserName    = $UserName
            Type        = $Type
            WhenCreated = $WhenCreated
            Duration    = $Duration
        }

        [PSCustomObject]@{
            UserName = $UserName
            Token = $Token
            Type = $Type
            WhenCreated = $WhenCreated
            Duration = $Duration
        }
    }    
}
