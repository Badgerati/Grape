function Get-RunPath {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId,

        [int]
        $runId,

        [switch]
        $overview,

        [switch]
        $config
    )

    $base = Join-Path (Get-JobsPath $jobId) 'runs'

    if ($runId -gt 0) {
        $base = Join-Path $base $runId

        if ($config) {
            $base = Join-Path $base 'config.json'
        }
    }
    else {
        if ($overview) {
            $base = Join-Path $base 'runs.json'
        }
    }

    return $base
}

function Get-RunOverviewObject {
    return @{
        'id' = 0;
        'name' = '';
        'status' = 'queued';
        'duration' = 0;
        'run' = @{
            'start' = $null;
        };
    }
}

function Get-RunObject {
    $date = Get-UtcDate

    return @{
        'id' = 0;
        'name' = '';
        'description' = '';
        'duration' = 0;
        'status' = 'queued';
        'run' = @{
            'scheduled' = $null;
            'created' = $date;
            'start' = $null;
            'end' = $null;
        }
    }
}

function Get-RunOverviewFile {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId
    )

    try {
        $path = Get-RunPath $jobId -overview
        return (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
    }
    catch {
        return @{ 'runs' = @(); }
    }
}

function Set-RunOverviewFile {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId,

        [ValidateNotNull()]
        $runs
    )

    $path = Get-RunPath $jobId -overview
    $runs | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Get-RunFile {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId,

        [int]
        $runId
    )

    try {
        $path = Get-RunPath $jobId $runId -config
        return (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
    }
    catch {
        return (Get-JobObject)
    }
}

function Set-RunFile {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId,

        [ValidateNotNull()]
        $run
    )

    $path = Get-RunPath $jobId $run.id -config
    $run | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Test-RunId {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId,

        [int]
        $runId
    )

    if (Test-Empty $runId) {
        throw 'No runId has been supplied'
    }

    $path = Get-RunPath $jobId $runId -config
    if (!(Test-Path $path)) {
        throw "The runId '$($runId)' does not exist for the jobId '$($jobId)'"
    }
}

function New-RunConfig {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId,

        [int]
        $runId,

        [string]
        $name,

        [string]
        $description,

        [string]
        $scheduled
    )

    $json = Get-RunOverviewFile $jobId

    # ensure job doesn't already have this runId
    if (($json.runs | Where-Object { $_.id -eq $runId } | Measure-Object).Count -ne 0) {
        throw "The runId '$($runId)' already exists for the jobId '$($jobId)'"
    }

    # create a new run overview
    $overview = Get-RunOverviewObject
    $overview.id = $runId
    $overview.name = $name

    # create a new run for the job
    $run = Get-RunObject
    $run.id = $runId
    $run.name = $name
    $run.description = $description
    $run.run.scheduled = $scheduled

    # create the run directory
    $path = Get-RunPath $jobId $runId
    New-Item -Path $path -ItemType Directory -Force | Out-Null

    # save the overview/config
    $json.runs += $overview
    Set-RunOverviewFile $jobId $json
    Set-RunFile $jobId $run

    return $run
}