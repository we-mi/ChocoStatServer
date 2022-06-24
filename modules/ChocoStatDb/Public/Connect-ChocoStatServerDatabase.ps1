function Connect-ChocoStatServerDatabase {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $File
    )

    process {

        $script:File = $File
        [System.IO.FileInfo]$File
    }
    
}