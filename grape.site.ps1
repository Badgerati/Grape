param (
    [Parameter()]
    $Port = 8085
)


# reload pode module
if ((Get-Module Pode) -ne $null) {
    Remove-Module Pode
}

Import-Module ..\Pode\src\Pode.psm1


# setup any aliases
function _coalesce($a, $b) { if ($a -eq $null) { $b } else { $a } }
New-Alias '??' _coalesce -Force


# include any helper scripts
. ./helpers/jobs.ps1


# setup grape server on passed port
Server -Port $Port {
    # set views to render using pode
    engine pode

    # create required dirs
    New-Item -ItemType Directory -Path ./jobs -Force | Out-Null
    New-Item -ItemType Directory -Path ./workspaces -Force | Out-Null

    # populate default content in dirs
    #if (!(Test-Path ./jobs/jobs.json)) {
    #    @{ 'jobs' = @(); } | ConvertTo-Json | Out-File -FilePath ./jobs/jobs.json -Encoding utf8 -Force | Out-Null
    #}

    # load the routes
    ./routes/pages.ps1
    ./routes/rest.ps1
}
