function Use-Environment {
    [CmdletBinding()]
    param (
        $Config
    )
    
    begin {
        
    }
    
    process {
        $json = Get-Content -Path $config -Encoding UTF8 -Raw | ConvertFrom-Json

        $script:DbModule = $json.ChocoStatDbModulePath
        $script:DbFile = $json.DbFile

        Remove-Module ChocoStatDb -ErrorAction SilentlyContinue
        Import-Module $script:DbModule

        Connect-ChocoStatServerDatabase -File $script:DbFile | Out-Null
    }
    
    end {
        
    }
}