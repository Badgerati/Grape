param (
    [Parameter()]
    [int]
    $Port = 8085
)


# reload pode module
if ((Get-Module Pode) -ne $null) {
    Remove-Module Pode
}

Import-Module ..\Pode\src\Pode.psm1


# run startup script
./helpers/startup.ps1


# setup grape site/rest server on passed port
Server -Port $Port {
    # set views to render using pode
    engine pode

    # load the routes
    ./routes/pages.ps1
    ./routes/rest.ps1
}
