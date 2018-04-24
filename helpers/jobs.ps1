function Get-JobsPath {
    return './jobs/'
}

function Get-JobOverviewObject {
    return @{
        "id" = "";
        "name" = "";
        "type" = "";
        "status" = 'none';
        "duration" = 0;
        "run" = @{
            "last" = $null;
        };
    }
}

function Get-JobObject {
    return @{
        "id" = "";
        "name" = "";
        "description" = "";
        "created" = [DateTime]::Now.ToString();
        "updated" = [DateTime]::Now.ToString();
        "type" = "";
        "status" = "none";
        "duration" = 0;
        "grapefile" = "";
        "repo" = @{
            "url" = "";
            "branch" = "";
        };
        "run" = @{
            "schedule" = "";
            "last" = $null;
            "next" = $null;
        };
    }
}

function Get-JobOverviewFile {
    try {
        $path = Join-Path (Get-JobsPath) 'jobs.json'
        return (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
    }
    catch {
        return @{ 'jobs' = @(); }
    }
}

function Set-JobOverviewFile {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $jobs
    )

    $path = Join-Path (Get-JobsPath) 'jobs.json'
    $jobs | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Get-JobFile {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $id
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
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $job
    )

    $path = Join-Path (Join-Path (Get-JobsPath) $job.id) 'config.json'
    $job | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function New-JobConfig {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $name,

        [string] $description
    )

    $json = Get-JobOverviewFile

    # ensure job with name doesn't exist
    if (($json.jobs | Where-Object { $_.name } | Measure-Object).Count -ne 0) {
        throw "There is already a job called '$($name)'"
    }

    # generate a new jobId - bit hacky, but hey ¯\_(ツ)_/¯
    $id = ([Guid]::NewGuid().ToString() -split '-')[0]

    # create a new job overview, to help page/rest loading
    $overview = Get-JobOverviewObject
    $overview.id = $id
    $overview.name = $name
    $overview.type = 'single'

    # create a new job object with the main job config
    $job = Get-JobObject
    $job.id = $id
    $job.name = $name
    $job.description = $description
    $job.type = 'single'

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
    }

    return $job
}