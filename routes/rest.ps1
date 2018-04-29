# get list of all jobs
route get '/api/jobs' {
    param($session)
    $limit = [int](?? $session.Query['limit'] '-1')
    $name = (?? $session.Query['name'] '')
    $match = [Convert]::ToBoolean((?? $session.Query['match'] $true))

    $result = @{
        'error' = $null;
        'count' = 0;
        'jobs' = @();
    }

    try {
        # read in the jobs json
        $jobs = (Get-JobOverviewFile).jobs
        $count = ($jobs | Measure-Object).Count

        # if it's not empty, sort by name and limit results if supplied
        if ($count -gt 0) {
            if (!(Test-Empty $name)) {
                if ($match) {
                    $jobs = $jobs | Where-Object { $_.name -ieq $name }
                }
                else {
                    $jobs = $jobs | Where-Object { $_.name -imatch $name }
                }
            }

            $jobs = $jobs | Sort-Object name

            if ($limit -gt -1) {
                $jobs = $jobs | Select-Object -First $limit
            }
        }

        $result.count = $count
        $result.jobs = $jobs

        # write jobs back
        Write-JsonResponse -Value $result
    }
    catch {
        $result.error = $_.Exception.Message
        Write-JsonResponse -Value $result
    }
}

# create a new job
route post '/api/jobs' {
    param($session)
    $data = $session.Data

    $result = @{
        'error' = $null;
        'job' = $null;
    }

    try {
        $job = New-JobConfig $data
        $result.job = $job

        # write new job back
        Write-JsonResponse -Value $result
    }
    catch {
        $result.error = $_.Exception.Message
        Write-JsonResponse -Value $result
    }
}

# get details about a specific job
route get '/api/jobs/:jobId' {
    param($session)
    $jobId = $session.Parameters['jobId']

    $result = @{
        'error' = $null;
        'job' = @{};
    }

    try {
        # get the job config
        $job = Get-JobFile $jobId
        $result.job = $job

        # write job back
        Write-JsonResponse -Value $result
    }
    catch {
        $result.error = $_.Exception.Message
        Write-JsonResponse -Value $result
    }
}

# delete the specified job
route delete '/api/jobs/:jobId' {
    param($session)
    $jobId = $session.Parameters['jobId']
}

# update the specified job
route put '/api/jobs/:jobId' {
    param($session)
    $jobId = $session.Parameters['jobId']
}

# start a new run for the passed job
route post '/api/jobs/:jobId/runs' {
    param($session)
    $jobId = $session.Parameters['jobId']
    $name = (?? $session.Data.name '')
    $description = (?? $session.Data.description '')
    $schedule = (?? $session.Data.schedule '')

    $result = @{
        'error' = $null;
        'run' = @{};
    }

    try {
        # validate job the job actually exists
        Test-JobId $jobId

        # schedule the job to run
        $run = Start-Job $jobId $schedule $name $description
        $result.run = $run
        Write-JsonResponse -Value $result
    }
    catch {
        $result.error = $_.Exception.Message
        Write-JsonResponse -Value $result
    }
}

# return items from the queue type (pending/running)
route get '/api/queue/:type' {
    param($session)
    $type = $session.Parameters['type']

    $result = @{
        'error' = $null;
        'count' = 0;
        'queue' = @();
    }

    try {
        # get the queue config
        switch ($type.ToLowerInvariant()) {
            'pending' {
                $queue = (Get-QueueFile -pending).queue
            }

            'running' {
                $queue = (Get-QueueFile -running).queue
            }

            default {
                throw 'Incorrect queue type passed, should be either pending or running'
            }
        }

        $result.queue = $queue
        $result.count = ($queue | Measure-Object).Count

        # write job back
        Write-JsonResponse -Value $result
    }
    catch {
        $result.error = $_.Exception.Message
        Write-JsonResponse -Value $result
    }
}