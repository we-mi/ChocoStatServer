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
    }
    
    process {
        switch -Regex ($command) {
            '^(outdated)$' {
                & choco $command @options | Select-String -Pattern '^([\w-.]+)\|.*\|(.*)\|.*$' | ForEach-Object {
                    [PSCustomObject]@{
                        PackageName = $_.matches.groups[1].value
                        newVersion = $_.matches.groups[2].value
                    }
                }
            }

            '^(search|list|find)$' {
                & choco $command @options | Select-String -Pattern '^([\w-.]+) ([\d.]+)' | ForEach-Object {
                    [PSCustomObject]@{
                        PackageName = $_.matches.groups[1].value
                        Version = $_.matches.groups[2].value
                    }
                }
            }

            '^(source[s]*)$' {
                if($options -notcontains 'add|disable|enable|remove') {
                    & choco $command @options | Select-String -Pattern '^([\w-.]+)( \[Disabled\])? - (\S+) \| Priority (\d)\|Bypass Proxy - (\w+)\|Self-Service - (\w+)\|Admin Only - (\w+)\.$' | ForEach-Object {
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
                    & choco $command @options
                }
            }

            '^(info)$' {
                $infoArray = (((& choco $command @options) -split '\|') | Where-Object {$_ -match '.*: .*'}).trim() -replace ': ','=' | ConvertFrom-StringData
                
                $infoReturn = New-Object PSObject
                foreach ($infoItem in $infoArray) {
                    Add-Member -InputObject $infoReturn -MemberType NoteProperty -Name $infoItem.Keys -Value ($infoItem.Values -as [string])
                }
                return $infoReturn
            }
            
            '^(config)$' {
                if($options -notcontains 'get|set|unset') {
                    $chocoResult = & choco $command @options
                    
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
                    & choco $command $options
                }
            }

            '^(feature[s]*)$' {
                if($options -notcontains 'disable|enable') {
                    & choco $command @options | Select-String -Pattern '\[([x ])\] (\w+).*' | ForEach-Object {
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
                    & choco $command @options | Select-String -Pattern '^(.+)\|(.+)' | ForEach-Object {
                        [PSCustomObject]@{
                            packageName = $_.matches.groups[1].value
                            pinnedVersion = $_.matches.groups[2].value
                        }
                    }
                }
                else {
                    & choco $command @options
                }
            }
            Default {
                & choco $command @options
            }
        }
    }
    
    end {
    }
}

$packages = @()

Start-Choco -Command list -Option "--lo" | ForEach-Object {
    try {
        $InstalledOn = Get-Item (Join-Path "C:\ProgramData\chocolatey\lib" $_.PackageName) -ErrorAction Stop | Select-Object -ExpandProperty LastWriteTime
    } catch {
        $InstalledOn = "01-01-1970"
    }

    $packages += @{
        PackageName = $_.PackageName
        Version = $_.Version
        InstalledOn = $InstalledOn
        Parameters = "NA"
    }
}

$Body = @{ComputerName = $env:COMPUTERNAME; Packages = $Packages}

Invoke-RestMethod -Uri http://127.0.0.1:8080/api/stat -Method PUT -Body ($Body | ConvertTo-Json)