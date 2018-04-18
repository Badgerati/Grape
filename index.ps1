param (
    [Parameter()]
    $Port = 8085
)


# reload pode module
if ((Get-Module Pode) -ne $null)
{
    Remove-Module Pode
}

Import-Module ..\Pode\src\Pode.psm1


# setup grape server on passed port
Server -Port $Port {
    # set views to render using pode
    Set-ViewEngine PODE

    # load the routes
    ./routes/pages.ps1
    ./routes/rest.ps1
}
