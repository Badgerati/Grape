
$Global:_jobsPath = './jobs/jobs.json'
$Global:_jobsConfig = $null

function Global:Get-JobsConfig {
    if ($Global:_jobsConfig -eq $null) {
        $Global:_jobsConfig = Get-Content $Global:_jobsPath -Force | ConvertFrom-Json
    }
}

function Global:Write-JobsConfig {
    $Global:_jobsConfig | ConvertTo-Json | Out-File -FilePath $Global:_jobsPath -Encoding utf8 -Force | Out-Null
}


# get list of all jobs
route get '/api/jobs' {
    param($session)

    $result = @{
        'error' = $null;
        'count' = 0;
        'jobs' = @();
    }

    try {
        Global:Get-JobsConfig

        # read in the jobs json
        $jobs = $Global:_jobsConfig.jobs
        $count = ($jobs | Measure-Object).Count

        # if it's not empty, sort by name and limit results if supplied
        if ($count -gt 0)
        {
            $jobs = $jobs | Sort-Object name 

            $limit = [int](?? $session.Query['limit'] '-1')
            if ($limit -gt -1)
            {
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

    $result = @{
        'error' = $null;
        'job' = $null;
    }

    try {
        Global:Get-JobsConfig

        $name = $session.Data.name
        $desc = $session.Data.description

        $job = @{
            'name' = $name;
            'description' = $desc;
        }

        $Global:_jobsConfig.jobs += $job
        Write-JobsConfig

        $result.job = $job

        # write new job back
        Write-JsonResponse -Value $result
    }
    catch {
        $result.error = $_.Exception.Message
        Write-JsonResponse -Value $result
    }


    #    * job name/description
    #    * job parameters
    #    * schedule (or multi-branch)
    #    * git repo (and branch)
    #    * Grapefile name/path (or blank for default ".\Grapefile")
}