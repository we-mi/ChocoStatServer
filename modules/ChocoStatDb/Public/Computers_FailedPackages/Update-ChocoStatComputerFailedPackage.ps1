function Update-ChocoStatComputerFailedPackage {
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

        # A FailedPackageName which should be added to the computer
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

        [Parameter()]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $Parameters,

        [Parameter()]
        [datetime]
        $FailedOn
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $ComputerFailedPackageObject = Get-ChocoStatComputerFailedPackage -ComputerID $ComputerID -PackageName $PackageName

        if ($ComputerFailedPackageObject) {

            if ([String]::IsNullOrWhiteSpace($Version) -and [String]::IsNullOrWhiteSpace($Parameters) -and $null -eq $FailedOn) {
                Write-Warning "Nothing to update"
                return $null
            }

            if ([String]::IsNullOrWhiteSpace($Version)) {
                $Version = $ComputerFailedPackageObject.Version
            }

            if ([String]::IsNullOrWhiteSpace($Parameters)) {
                $Parameters = $ComputerFailedPackageObject.Parameters
            }

            if ($null -eq $FailedOn) {
                if ($null -eq $ComputerFailedPackageObject.FailedOn) {
                    $FailedOn = [datetime]"1970-01-01"
                } else {
                    $FailedOn = $ComputerFailedPackageObject.FailedOn
                }
            }

            $Query = "UPDATE Computers_FailedPackages SET Version=@Version, Parameters=@Parameters, FailedOn=@FailedOn WHERE ComputerID=@ComputerID AND PackageName=@PackageName"

            Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                ComputerID = $ComputerFailedPackageObject.ComputerID
                PackageName = $PackageName
                Version = $Version
                Parameters = $Parameters
                FailedOn = $FailedOn
            }
        } else {
            $splat = @{
                ComputerID = $ComputerID
                PackageName = $PackageName
                Version = $Version
            }

            if (-not [String]::IsNullOrWhiteSpace($Parameters)) {
                $splat.Parameters = $Parameters
            }

            if ($null -ne $FailedOn) {
                $splat.FailedOn = $FailedOn
            }

            Add-ChocoStatComputerFailedPackage @splat
        }

    }

}
