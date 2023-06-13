function Get-RandomCharacters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$length,

        [Parameter()]
        [String]$characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    )
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
