function Get-QueuePath {
    return './queue/'
}

function Get-QueueJobObject {
    $date = Get-UtcNow

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
    try {
        $path = Join-Path (Get-QueuePath) 'queue.json'
        return (Get-Content $path -Force -ErrorAction Stop | ConvertFrom-Json)
    }
    catch {
        return @{ 'queue' = @(); }
    }
}

function Set-QueueFile {
    param (
        [ValidateNotNull()]
        $queue
    )

    $path = Join-Path (Get-QueuePath) 'queue.json'
    $queue | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $path -Encoding utf8 -Force | Out-Null
}

function Push-ToQueue {
    param (
        [ValidateNotNull()]
        $job
    )

    $queue = Get-QueueFile
    $queue.queue += $job
    Set-QueueFile $queue
}