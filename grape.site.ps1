param (
    [Parameter()]
    $Port = 8085
)


# reload pode module
if ((Get-Module Pode) -ne $null) {
    Remove-Module Pode
}

Import-Module ..\Pode\src\Pode.psm1


# include any helper scripts
. ./helpers/general.ps1
. ./helpers/jobs.ps1


# setup grape server on passed port
Server -Port $Port {
    # set views to render using pode
    engine pode

    # create required dirs
    New-Item -ItemType Directory -Path ./jobs -Force | Out-Null
    New-Item -ItemType Directory -Path ./workspaces -Force | Out-Null

    # load the routes
    ./routes/pages.ps1
    ./routes/rest.ps1
}
