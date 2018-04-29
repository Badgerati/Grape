function Get-QueuePath {
    param (
        [switch]
        $pending,

        [switch]
        $running
    )

    $base = './queue/'

    if ($pending) {
        $base = Join-Path $base 'pending.json'
    }
    elseif ($running) {
        $base = Join-Path $base 'running.json'
    }

    return $base
}

function Get-QueueRunObject {
    $date = Get-UtcDate

    return @{
        'jobId' = '';
        'runId' = '';
        'running' = $false;
        'run' = @{
            'scheduled' = '';
            'queued' = $date;
            'started' = '';
        };
    }
}

function Get-QueueFile {
    param (
        [switch]
        $pending,

        [switch]
        $running
    )

    try {
        $path = Get-QueuePath -pending:$pending -running:$running
        return (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
    }
    catch {
        return @{ 'queue' = @(); }
    }
}

function Set-QueueFile {
    param (
        [ValidateNotNull()]
        $queue,

        [switch]
        $pending,

        [switch]
        $running
    )

    $path = Get-QueuePath -pending:$pending -running:$running
    $queue | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Get-RunOnQueue {
    param (
        [string]
        $jobId,

        [int]
        $runId,

        $file = $null,

        [switch]
        $pending,

        [switch]
        $running
    )

    if ((Test-Empty $jobId) -or $runId -le 0) {
        return $null
    }

    if ($file -eq $null) {
        $file = Get-QueueFile -pending:$pending -running:$running
    }

    return ($file.queue | Where-Object {
        $_.jobId -ieq $jobId -and
        $_.runId -eq $runId
    } | Select-Object -First 1)
}

function Push-RunToQueue {
    param (
        [ValidateNotNull()]
        $run,

        [switch]
        $pending,

        [switch]
        $running
    )

    $json = Get-QueueFile -pending:$pending -running:$running

    if ((Get-RunOnQueue $run.jobId $run.runId $json) -eq $null) {
        $json.queue += $run
        Set-QueueFile $json -pending:$pending -running:$running
    }
}

function Pop-RunFromQueue {
    param (
        [string]
        $jobId,

        [int]
        $runId,

        [switch]
        $pending,

        [switch]
        $running
    )

    if ((Test-Empty $jobId) -or $runId -le 0) {
        return $null
    }

    $json = Get-QueueFile -pending:$pending -running:$running
    $item = Get-RunOnQueue $jobId $runId $json

    if ($item -ne $null) {
        $json.queue = ($json.queue | Where-Object {
            $_.jobId -ine $jobId -and
            $_.runId -ne $runId
        })

        Set-QueueFile $json -pending:$pending -running:$running
    }

    return $item
}