function Get-JobsPath {
    param (
        [string]
        $jobId,

        [switch]
        $overview,

        [switch]
        $config
    )

    $base = './jobs/'

    if (!(Test-Empty $jobId)) {
        $base = Join-Path $base $jobId

        if ($config) {
            $base = Join-Path $base 'config.json'
        }
    }
    else {
        if ($overview) {
            $base = Join-Path $base 'jobs.json'
        }
    }

    return $base

}

function Get-JobOverviewObject {
    return @{
        'id' = '';
        'name' = '';
        'status' = 'none';
        'duration' = 0;
        'run' = @{
            'last' = $null;
            'next' = $null;
            'lastRunId' = 0;
        };
    }
}

function Get-JobObject {
    $date = Get-UtcDate

    return @{
        'id' = '';
        'name' = '';
        'description' = '';
        'created' = $date;
        'updated' = $date;
        'type' = '';
        'status' = 'none';
        'duration' = 0;
        'grapefile' = '';
        'repo' = @{
            'type' = '';
            'multi' = $false;
            'url' = '';
            'branch' = '';
        };
        'dir' = @{
            'path' = '';
        }
        'run' = @{
            'max' = 0;
            'parallel' = $false;
            'schedule' = '';
            'last' = $null;
            'next' = $null;
            'nextRunId' = 1;
        };
    }
}

function Get-JobOverviewFile {
    try {
        $path = Get-JobsPath -overview
        return (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
    }
    catch {
        return @{ 'jobs' = @(); }
    }
}

function Set-JobOverviewFile {
    param (
        [ValidateNotNull()]
        $jobs
    )

    $path = Get-JobsPath -overview
    $jobs | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Get-JobFile {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $jobId
    )

    try {
        $path = Get-JobsPath $jobId -config
        return (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
    }
    catch {
        return (Get-JobObject)
    }
}

function Set-JobFile {
    param (
        [ValidateNotNull()]
        $job
    )

    $path = Get-JobsPath $job.id -config
    $job | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Test-JobId {
    param (
        [string]
        $jobId
    )

    if (Test-Empty $jobId) {
        throw 'No jobId has been supplied'
    }

    $path = Get-JobsPath $jobId -config
    if (!(Test-Path $path)) {
        throw "The jobId '$($jobId)' does not exist"
    }
}

function Test-JobConfig {
    param (
        $config
    )

    # ensure we have some config settings
    if (Test-Empty $config) {
        throw 'No job configuration supplied'
    }

    # do we have a job name?
    if (Test-Empty $config.name) {
        throw 'No job name supplied'
    }

    # ensure the job type if right
    $types = @('scm', 'dir')
    if ($types -inotcontains $config.type) {
        throw "Invalid job type supplied, valid values: $($types -join ', ')"
    }

    # check the settings for the job type
    switch ($config.type.ToLowerInvariant()) {
        'dir' {
            if (Test-Empty $config.dir) {
                throw 'No directory configuration supplied for job'
            }

            if (Test-Empty $config.dir.path) {
                throw 'No directory path supplied for job'
            }
        }

        'scm' {

        }
    }

    # check run meta logic
    if (!(Test-Empty $config.run)) {
        if ($config.run.max -ne $null -and $config.run.max -lt 0) {
            throw 'Invalid value for max number of runs to keep supplied, should be 0 or greater'
        }
    }
}

function New-JobConfig {
    param (
        $config
    )

    Test-JobConfig $config
    $json = Get-JobOverviewFile

    # ensure job with name doesn't exist
    if (($json.jobs | Where-Object { $_.name -ieq $config.name } | Measure-Object).Count -ne 0) {
        throw "There is already a job called '$($config.name)'"
    }

    # generate a new jobId
    $jobId = Get-Id

    # create a new job overview, to help page/rest loading
    $overview = Get-JobOverviewObject
    $overview.id = $jobId
    $overview.name = $config.name

    # create a new job object with the main job config
    $job = Get-JobObject
    $job.id = $jobId
    $job.name = $config.name
    $job.description = $config.description
    $job.type = $config.type
    $job.grapefile = $config.grapefile
    $job.dir = $config.dir

    if (!(Test-Empty $config.run)) {
        $job.run.max = (?? $config.run.max 0)
    }

    try {
        # create the job directory
        $path = Get-JobsPath $jobId
        New-Item -Path $path -ItemType Directory -Force | Out-Null

        # save the overview/job configs
        $json.jobs += $overview
        Set-JobOverviewFile $json
        Set-JobFile $job
    }
    catch {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force | Out-Null
        }

        throw
    }

    return $job
}

function Start-Job {
    param (
        [string]
        $jobId,

        [string]
        $schedule,

        [string]
        $name,

        [string]
        $description
    )

    # get the job and overview
    $job = Get-JobFile $jobId
    $overview = Get-JobOverviewFile
    $jobOverview = ($overview.jobs | Where-Object { $_.id -ieq $jobId })

    # use the passed schedule, or now
    $schedule = (?? $schedule (Get-UtcDate))

    # can the schedule be parsed as a date?
    if (!(Test-Date $schedule)) {
        throw "Schedule date is of an invalid format: $($schedule)"
    }

    # setup new run for job
    try {
        $runId = $job.run.nextRunId++
        $jobStatus = $job.status
        $overStatus = $jobOverview.status

        $job.status = 'queued'
        $job.updated = Get-UtcDate

        $jobOverview.status = 'queued'
        $jobOverview.run.lastRunId = $runId

        # save run settings to job
        Set-JobFile $job
        Set-JobOverviewFile $overview

        # create dir/config for run
        New-RunConfig $jobId $runId $name $description $schedule | Out-Null
    }
    catch {
        # attempt to reset run
        $job.run.nextRunId--
        $job.status = $jobStatus
        $jobOverview.status = $overStatus
        $jobOverview.run.lastRunId--

        Set-JobFile $job
        Set-JobOverviewFile $overview

        # NEED REMOVE-JOB/-RUN FUNCTIONS

        throw
    }

    try {
        # add run to queue
        $run = Get-QueueRunObject
        $run.jobId = $jobId
        $run.runId = $runId
        $run.run.scheduled = $schedule
        Push-RunToQueue $run -pending
    }
    catch {
        Pop-RunFromQueue $run -pending
        throw
    }

    return $run
}