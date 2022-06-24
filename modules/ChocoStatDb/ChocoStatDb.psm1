#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\ -Include *.ps1 -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\ -Include *.ps1 -Recurse -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
Remove-Module PSSQLite -ErrorAction SilentlyContinue
Import-Module -Name "..\PSSQLite\PSSQLite.psd1" -ErrorAction Stop