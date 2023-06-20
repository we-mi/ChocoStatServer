[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$Server,

    [Parameter()]
    [ValidateRange(1,65535)]
    [int]$Port = 2306,

    [Parameter()]
    [ValidateSet("https","http")]
    [String]$Protocol = "https",

    [Parameter()]
    [switch]$SkipCertificateCheck,

    # apikey write-access for adding new computers. Is sent, but not needed for updating a computer
    [Parameter(Mandatory)]
    [String]$APIToken
)
$ErrorActionPreference = "Stop"

if ($SkipCertificateCheck.IsPresent -and $Host.Version.Major -le 5) {
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

function Start-Choco { # implement the pschoco module from https://gitlab.com/Paxz/choco_gui/tree/master/pschoco into this script, for better integration
    <#
    .SYNOPSIS
    Chocolatey Output Parserfunction

    .DESCRIPTION
    This function behaves like the normal choco.exe, except that it interepretes the given results of some commands and parses them to PSCustomObjects.
    This should make working with chocolatey alot easier if you really want to integrate it into your scripts.

    .PARAMETER command
    Chocolatey Command - basically the same command you would write after `choco`.
    Original Documentation to Chocolatey Commands: https://github.com/chocolatey/choco/wiki/CommandsList

    .PARAMETER options
    Chocolatey Options - the same options that you would write after the command of an `choco`-Invoke
    Original Documentation to Chocolatey Options and Switches: https://github.com/chocolatey/choco/wiki/CommandsReference#default-options-and-switches

    .INPUTS
    Options can be given through the pipeline. Further explained in Example 4.

    .OUTPUTS
    [System.Management.Automation.PSCustomObject], PSCustomObject of all important informations returned by the `choco` call

    .EXAMPLE
    PS C:\>Start-Choco -Command "list" -Option "-lo"
    Runs `choco list -lo` and parses the output to an object with the Attributes `PackageName` and `Version`.
    The options parameter has to be written in `"` or `'` so that powershell doesn't interpret the Value as an extra Parameter for this function

    .EXAMPLE
    PS C:\>Start-Choco info vscode
    Runs `choco info vscode` and parses the output to an PSCustomObject

    .EXAMPLE
    PS C:\>pschoco outdated
    Runs `choco outdated` over the function alias and parses the output like explained in the first example.

    .EXAMPLE
    PS C:\>@("vscode","firefox") | Start-Choco info
    Options can be passed through the pipeline. Thisway each entry will be given as the option: `Start-Choco info <PipeElement>`.

    .LINK
    https://github.com/chocolatey/choco/wiki/CommandsList
    https://github.com/chocolatey/choco/wiki/CommandsReference#default-options-and-switches

    .NOTES
    Currently Supported Chocolatey Commands (everything else works like the default `choco.exe`):
        - outdated
        - search|list|find
        - source|sources
        - info
        - config
        - feature
        - pin
    #>

    [CmdletBinding()]
    [alias("schoco","pschoco")]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $command,

        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [string[]]
        $options = @()
    )

    begin {

        $proc = $null
        try {
            $proc = Start-Process -FilePath "roco" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
        } catch { }

        if ($null -eq $proc -or $proc.ExitCode -ne 0) {
            $ChocoEXE = "choco"
        } else {
            $ChocoEXE = "roco"
        }

        Write-Verbose "Using $ChocoEXE"
    }

    process {
        switch -Regex ($command) {
            '^(outdated)$' {
                & $ChocoEXE $command @options | Select-String -Pattern '^([\w-.]+)\|(.*)\|(.*)\|.*$' | ForEach-Object {
                    [PSCustomObject]@{
                        PackageName = $_.matches.groups[1].value
                        currentVersion = $_.matches.groups[2].value
                        newVersion = $_.matches.groups[3].value
                    }
                }
            }

            '^(search|list|find)$' {
                & $ChocoEXE $command @options | Select-String -Pattern '^([\w-.]+) ([\d.]+)' | ForEach-Object {

                    $package = [PSCustomObject]@{
                        PackageName = $_.matches.groups[1].value
                        Version = $_.matches.groups[2].value
                        InstalledOn = $null
                    }

                    if ($command -eq "list" -and ($options -contains "--local-only" -or $options -contains "--lo") ) {
                        $nupkg = Get-Item -Path (Join-Path $env:ProgramData "chocolatey\lib\$($package.PackageName)\$($package.PackageName).nupkg")

                        $package.InstalledOn = $nupkg.CreationTime
                    }

                    $package

                }

            }

            '^(source[s]*)$' {
                if($options -notcontains 'add|disable|enable|remove') {
                    & $ChocoEXE $command @options | Select-String -Pattern '^([\w-.]+)( \[Disabled\])? - (\S+) \| Priority (\d)\|Bypass Proxy - (\w+)\|Self-Service - (\w+)\|Admin Only - (\w+)\.$' | ForEach-Object {
                        if ($_.matches.groups[2].value -eq ' [Disabled]') {
                            $Enabled = $False
                        } else {
                            $Enabled = $True
                        }
                        [PSCustomObject]@{
                            SourceName = $_.matches.groups[1].value
                            Enabled = $Enabled
                            Url = $_.matches.groups[3].value
                            Priority = $_.matches.groups[4].value
                            "Bypass Proxy" = $_.matches.groups[5].value
                            "Self-Service" = $_.matches.groups[6].value
                            "Admin Only" = $_.matches.groups[7].value
                        }
                    }
                }
                else {
                    & $ChocoEXE $command @options
                }
            }

            '^(info)$' {
                $infoArray = (((& $ChocoEXE $command @options) -split '\|') | Where-Object {$_ -match '.*: .*'}).trim() -replace ': ','=' | ConvertFrom-StringData

                $infoReturn = New-Object PSObject
                foreach ($infoItem in $infoArray) {
                    Add-Member -InputObject $infoReturn -MemberType NoteProperty -Name $infoItem.Keys -Value ($infoItem.Values -as [string])
                }
                return $infoReturn
            }

            '^(config)$' {
                if($options -notcontains 'get|set|unset') {
                    $chocoResult = & $ChocoEXE $command @options

                    $Settings = foreach ($line in $chocoResult) {
                        Select-String -InputObject $line -Pattern "^(\w+) = (\w+|) \|.*"| ForEach-Object {
                            [PSCustomObject]@{
                                "Setting" = $_.matches.groups[1].value
                                "Value" = $_.matches.groups[2].value
                            }
                        }
                    }

                    $Features = foreach ($line in $chocoResult) {
                        Select-String -InputObject $line -Pattern "\[([x ])\] (\w+).*" | ForEach-Object {
                            if($_.matches.groups[1].value -eq "x") {
                                $value = $true
                            }
                            else {
                                $value = $false
                            }
                            [PSCustomObject]@{
                                "Setting" = $_.matches.groups[2].value
                                "Enabled" = $value
                            }
                        }
                    }

                    return [PSCustomObject]@{
                        Settings = $Settings
                        Features = $Features
                    }
                }
                else {
                    & $ChocoEXE $command $options
                }
            }

            '^(feature[s]*)$' {
                if($options -notcontains 'disable|enable') {
                    & $ChocoEXE $command @options | Select-String -Pattern '\[([x ])\] (\w+).*' | ForEach-Object {
                        if($_.matches.groups[1].value -eq "x") {
                            $value = $true
                        }
                        else {
                            $value = $false
                        }
                        [PSCustomObject]@{
                            "Setting" = $_.matches.groups[2].value
                            "Enabled" = $value
                        }
                    }
                }
            }

            '^(pin)$' {
                if($options -notcontains 'add|remove') { # options enthält nicht add oder remove
                    & $ChocoEXE $command @options | Select-String -Pattern '^(.+)\|(.+)' | ForEach-Object {
                        [PSCustomObject]@{
                            packageName = $_.matches.groups[1].value
                            pinnedVersion = $_.matches.groups[2].value
                        }
                    }
                }
                else {
                    & $ChocoEXE $command @options
                }
            }

            '^(failed)' {
                Get-ChildItem -Directory -Path (Join-Path $env:ProgramData "chocolatey/lib-bad") | ForEach-Object {
                    [PSCustomObject]@{
                        PackageName = $_.Name
                        Version = ([xml](Get-Content -Path (Join-Path $_.Fullname "$($_.Name).nuspec"))).package.metadata.version
                        FailedOn = (Get-Item -Path (Join-Path $_.Fullname "$($_.Name).nupkg")).CreationTime
                    }
                }
            }
            Default {
                & $ChocoEXE $command @options
            }
        }
    }

    end {
    }
}

$APIUrl = "$($Protocol)://$($Server):$($Port)/api/v1.0"

# Request Headers for API calls. The API-Key can only be used for updating a computer if it is an "admin"-apikey. The computer secret is used instead. This is retrieved only when creating a new computer
$Headers = @{
    "Content-Type" = "application/json"
    "X-API-KEY" = $APIToken
}

# Request Body. Contains the computername and all packages which are installed on this computer
$Body = @{
    ComputerName = $env:COMPUTERNAME
    Packages = Start-Choco -command "list" -Options "--lo"
    FailedPackages = Start-Choco -command "failed"
    Sources = Start-Choco -command "source" | Select-Object SourceName,
                            @{N='SourceURL';E={$_.Url}},
                            @{N='Enabled';E={$_.Enabled}},
                            Priority,
                            @{N='ByPassProxy';E={ if ($_.'Bypass Proxy' -eq "False") { $False } else { $True } } },
                            @{N='SelfService';E={ if ($_.'Self-Service' -eq "False") { $False } else { $True } } },
                            @{N='AdminOnly';E={ if ($_.'Admin Only' -eq "False") { $False } else { $True } } }
    Config = Start-Choco -command "config" | Select-Object -ExpandProperty Settings
    Features = Start-Choco -command "features"
}

# Where the secret computer key is stored is stored
$baseDir = Join-Path $env:ProgramData "ChocoStatClient"
$keyfile = Join-Path $baseDir "secret.xml"

# We cant update a computer without the computersecret. We assume that the computer exists in the database when the secret.xml is available
# TODO: need something if the secret.xml is not present but the computer is already saved in the DB
if (Test-Path -PathType Leaf -Path $keyfile) {
    Write-Host "Updating existing computer"

    # Read computer secret (username is the computer id)
    try {
        $cred = Import-Clixml $keyfile -ErrorAction Stop
        $Body.Secret = $Cred.GetNetworkCredential().Password
    } catch {
        Throw "Keyfile could not be read ($_)"
    }

    $RestSplat = @{
        Uri = "$APIUrl/computers/$($cred.UserName)"
        Body = $Body | ConvertTo-Json
        Headers = $Headers
        Method = "PUT"
        TimeoutSec = 10
    }

    if ($SkipCertificateCheck.IsPresent -and $Host.Version.Major -ge 7) {
        $RestSplat += @{SkipCertificateCheck = $True}
    }

    try {
        Invoke-RestMethod @RestSplat
    } catch {
        Throw "Error sending our updates to the ChocoStatServer ($_)"
    }

} else {

    Write-Host "Creating new computer"

    $RestSplat = @{
        Uri = "$APIUrl/computers"
        Body = $Body | ConvertTo-Json
        Headers = $Headers
        Method = "POST"
        TimeoutSec = 10
    }

    if ($SkipCertificateCheck.IsPresent -and $Host.Version.Major -ge 7) {
        $RestSplat += @{SkipCertificateCheck = $True}
    }

    try {
        $computer = Invoke-RestMethod @RestSplat
    } catch {
        Throw "Error sending our data to the ChocoStatServer ($_)"
    }

    if ($null -eq $computer) {
        Throw "Creating a new computer failed (no output received from server)"
    }

    $cred = New-Object System.Management.Automation.PSCredential ($computer.ComputerID).ToString(),($computer.Secret | ConvertTo-SecureString -AsPlainText -Force)

    New-Item -ItemType Directory -Path $baseDir -ErrorAction SilentlyContinue

    $cred | Export-Clixml -Path $keyfile
}
