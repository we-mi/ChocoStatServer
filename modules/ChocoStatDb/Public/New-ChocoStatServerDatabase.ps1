function New-ChocoStatServerDatabase {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $File,

        [Parameter()]
        [Switch]
        $Force
    )

    process {

        $createDBCode = {
            $Query = "CREATE TABLE Tokens (UserName varchar(255) NOT NULL PRIMARY KEY, Token varchar(64) NOT NULL, Type varchar(50) NOT NULL, WhenCreated int(11) NOT NULL, Duration INTEGER NOT NULL);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Computers (ComputerID INTEGER NOT NULL PRIMARY KEY, ComputerName varchar(255) NOT NULL, LastContact DATETIME);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Packages (PackageName varchar(255) NOT NULL PRIMARY KEY);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Sources (SID INTEGER NOT NULL PRIMARY KEY, SourceName varchar(255) NOT NULL, SourceURL varchar(255) NOT NULL);"
            Invoke-SqliteQuery -Query $Query -Database $File

            $Query = "CREATE TABLE Computers_Packages (ComputerID INTEGER NOT NULL, PackageName varchar(255) NOT NULL, Version varchar(255) NOT NULL, Parameters varchar(255) NULL, InstalledOn varchar(255) NULL, PRIMARY KEY (ComputerID, PackageName) );"
            Invoke-SqliteQuery -Query $Query -Database $File
        }

        if ( (Test-Path -Path $File) -eq $False) {
            Invoke-Expression -Command $createDBCode.ToString()
        } elseif ( (Test-Path -Path $File -PathType Container)) {
            Throw "'$File' is a container, and cannot be used for creating a new database. Choose a file instead"
        } elseif ( (Test-Path -Path $File -PathType Leaf)) {
            if ($Force.IsPresent) {
                Remove-Item -Path $File -Force
                Invoke-Expression -Command $createDBCode.ToString()
            } else {
                Throw "'$File' does already exist. Choose a non-existing file name or use the '-Force'-Parameter to overwrite the file"
            }
        }

        $script:File = $File
        [System.IO.FileInfo]$File
    }
    
}