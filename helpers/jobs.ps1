function Get-JobsPath {
    return './jobs/'
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
            'runId' = 0;
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
        $path = Join-Path (Get-JobsPath) 'jobs.json'
        $jobs = (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
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

    $path = Join-Path (Get-JobsPath) 'jobs.json'
    $jobs | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Get-JobFile {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $id
    )

    try {
        $path = Join-Path (Join-Path (Get-JobsPath) $id) 'config.json'
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

    $path = Join-Path (Join-Path (Get-JobsPath) $job.id) 'config.json'
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

    $path = Join-Path (Join-Path (Get-JobsPath) $job.id) 'config.json'
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
    $id = Get-Id

    # create a new job overview, to help page/rest loading
    $overview = Get-JobOverviewObject
    $overview.id = $id
    $overview.name = $config.name

    # create a new job object with the main job config
    $job = Get-JobObject
    $job.id = $id
    $job.name = $config.name
    $job.description = $config.description
    $job.type = $config.type
    $job.grapefile = $config.grapefile
    $job.dir = $config.dir

    try {
        # create the job directory - using the jobId
        $path = Join-Path (Get-JobsPath) $id
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
        $schedule
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

    try {
        # setup new run for job
        $runId = $job.run.nextRunId++
        $job.status = 'queued'

        $jobOverview.status = 'queued'
        $jobOverview.run.runId = $runId

        # create dir/config for run

        # save run settings to job
        Set-JobFile $job
        Set-JobOverviewFile $overview
    }
    catch {
        # check if the run dir exists, and delete and reset nextRunId
    }

    try {
        # add to queue
        $queue = Get-QueueJobObject
        $queue.jobId = $jobId
        $queue.runId = ''
        $queue.run.schedule = $schedule
        Push-ToQueue $queue
    }
    catch {
        # do we need to remove it from queue?
    }
}