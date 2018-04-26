function Get-RunObject {
    $date = Get-UtcNow

    return @{
        'id' = 0;
        'created' = $date;
        'start' = $null;
        'end' = $null;
        'duration' = 0;
        'status' = 'queued';
    }
}

function New-RunConfig {
    param (
        [string]
        $jobId,

        [int]
        $runId
    )
}