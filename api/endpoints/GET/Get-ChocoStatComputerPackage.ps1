<#
    .DESCRIPTION
        This script will return the specified data to the Client.
    .EXAMPLE
        Invoke-GetProcess.ps1 -RequestArgs $RequestArgs -Body $Body
    .NOTES
    	This will return data
#>

param(
    $RequestArgs,
    $Body,
    $varRouteValue
)

# This section Parses the RequestArgs Parameter

if ($RequestArgs -like '*&*') {
    # Split the Argument Pairs by the '&' character
    $ArgumentPairs = $RequestArgs.split('&')
    $RequestObj = New-Object System.Object
    foreach ($ArgumentPair in $ArgumentPairs) {
        # Split the Pair data by the '=' character
        $Property, $Value = $ArgumentPair.split('=')
        $RequestObj | Add-Member -MemberType NoteProperty -Name $Property -value $Value
    }

} else {
    $Property, $Value = $RequestArgs.split("=")
    $RequestObj = New-Object System.Object
    $RequestObj | Add-Member -MemberType NoteProperty -Name $Property -value $Value
}

# This Section Parses the body Parameter
# You will need to customize this section to consume the Json correctly for your application
<# Write-Host $body
$newbody = $body | ConvertFrom-Json

$body

 #>

Remove-Module choco-stat-server -ErrorAction SilentlyContinue
Import-Module C:\Users\Michael\Documents\git\github.com\choco-stat-server\choco-stat-server.psd1

Connect-ChocoStatServerDatabase -File "C:\Users\michael\ChocoStatistics.db" | Out-Null

if ($null -ne $varRouteValue) {
    $all = Get-ChocoStatComputerPackage -ComputerName $varRouteValue
} else {
    $all = Get-ChocoStatComputerPackage
}

if ($RequestObj.PackageName) {
    $all = $all | Where-Object { $_.PackageName -like $RequestObj.PackageName }
}

return $all