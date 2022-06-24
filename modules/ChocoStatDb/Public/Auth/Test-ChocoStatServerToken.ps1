function Test-ChocoStatServerToken {
    <#
    .SYNOPSIS
        Checks if the given token corresponds to a valid token in the database
    .DESCRIPTION
        This is a helper function which checks if the given token corresponds to a valid token for a given user and the desired type in the database and if the lifetime of the token has not expired yet
    .EXAMPLE
        Test-ChocoStatServerToken -Token "aa8c06c2ee0c420b872f09d6afc6ee01a497f76dac5849ab91bc43fc272ca344" -Type "write"
        
        Checks if the token matches the type "write" and if the lifetime is valid
    #>
    
    [CmdletBinding()]
    [OutputType([Bool])]

    param (
        # The token to test
        [Parameter(Mandatory)]
        [String]
        [AllowEmptyString()]
        $Token,

        # The type to test (admin includes read, write; write includes read)
        [Parameter(Mandatory)]
        [ValidateSet("read","write","admin")]
        [String]
        $Type
    )
    
    process {
        $UserToken = Get-ChocoStatServerToken -Token $Token

        $result = $False
        if ($null -ne $UserToken) { # user has a token, check the other things

            switch ($Type) {
                "read" { $DesiredType = 1 }
    
                "write" { $DesiredType = 2 }
    
                "admin" { $DesiredType = 3 }
    
                default { $DesiredType = 0 }
            }

            switch ($UserToken.Type) {
                "read" { $UserType = 1 }
    
                "write" { $UserType = 2 }
    
                "admin" { $UserType = 3 }
    
                default { $UserType = 0 }
            }

            if ($UserToken.Token -eq $Token) { # Token matches the user. check the other things...

                if ($UserType -ge $DesiredType) { # Type matches. Only the lifetime-check is left...cross your fingers

                    $WhenCreated = ([datetimeoffset] '1970-01-01Z').AddSeconds($UserToken.WhenCreated).LocalDateTime

                    # (time of creation)+(duration) greater than current time? -> time has not exceeded and token is valid
                    if ( $WhenCreated.AddSeconds($UserToken.Duration) -gt (Get-Date) ) { # Whooohooo...the token is valid
                        $result = $True
                    }
                }
            }
        }

        $result
    }
}