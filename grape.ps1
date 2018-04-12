param (
    [Parameter()]
    $Port = 8085
)


# reload pode module
if ((Get-Module Pode) -ne $null)
{
    Remove-Module Pode
}

Import-Module Pode -ErrorAction Stop


# setup grape server on passed port
Server -Port $Port {
    Set-PodeViewEngine -Engine PSHTML
}