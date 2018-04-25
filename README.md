# Grape

* All job steps are defined using a Grapefile - which is just powershell (see picassio2). The only config is:
    * job name/description
    * job parameters
    * schedule (or multi-branch)
    * git repo (and branch)
    * Grapefile name/path (or blank for default ".\Grapefile")



PAGES

<jobId>       = 12 random chars   =   job name: lowercase and hyphenated/underscored
<branchId>    = 12 random chars   =   branch name: lowercase and hyphenated (slashes are hyphens)

/                                                   <- dashboard
/manage                                             <- manage settings of grape

/jobs/                                              <- dashboard
/jobs/new                                           <- create a new job

/jobs/<jobId>                                       <- overview of a job, including last runs, average time
/jobs/<jobId>/run                                   <- start a new run of the job / supply parameters / scan repo for updated branches to build
/jobs/<jobId>/runs/<runId>                          <- overview of the run

/jobs/<jobId>/branches                              <- list of branches for the multi-branch job
/jobs/<jobId>/branches/<branchId>                   <- overview of a branch, including last runs
/jobs/<jobId>/branches/<branchId>/run               <- start a run of the branch
/jobs/<jobId>/branches/<branchId>/runs/<runId>      <- overview of the run




API

/api/jobs                                            <- POST     <- create new job
                                                      - GET      <- returns a list of jobs, with some filter/limit

/api/jobs/<jobId>                                    <- GET      <- returns job details, and last x runs or x branches
                                                      - DELETE   <- deletes the job
                                                      - PUT      <- updates the job

/api/jobs/<jobId>/runs                               <- POST     <- starts a new run for the job, or scan a repo for updated/new branches

/api/jobs/<jobId>/runs/<runId>                       <- GET      <- returns run details
                                                      - DELETE   <- if running, forces the run to stop

/api/jobs/<jobId>/branches/<branchId>                <- GET      <- returns branch details, and last x runs

/api/jobs/<jobId>/branches/<branchId>/runs           <- POST     <- starts a new run for the branch

/api/jobs/<jobId>/branches/<branchId>/runs/<runId>   <- GET      <- returns run details
                                                      - DELETE   <- if running, forces the run to stop




DIRECTORY STRUCTURE

./config.json
./grape.ps1

./jobs/<jobId>/config.json
              /runs.json
              /branches.json
              /runs/<runId>/config.json
                           /output.txt
              /branches/<branchId>/config.json
                                  /runs.json
                                  /runs/<runId>/config.json
                                               /output.txt
      /jobs.json

./workspaces/<jobId>/
                    /<runId>/ (split by runId on a normal job if multiple can run at once - otherwise all runs share one workspace [top level])
                    /<branchId>/<runId> (all multi-branch jobs are parallel so all split by runId)
          ??/workspaces.json

./queue/queue.json



OBJECTS

-- "jobs.json" object - only needs the quick info for loading a page

```json
"jobs": [
    {
        "id": "<jobId>",
        "name": "core website",
        "status": "success", // or queued, running, failed, disabled, aborted, or none
        "duration": "<milliseconds>",
        "run": {
            "last": "2018-04-24 19:27:02.000"
        }
    }
]
```

-- "config.json" for a job - more info, like grapefile etc

```json
{
    "id": "<jobId>",
    "name": "core website",
    "description": "",
    "created": "",
    "updated": "",
    "type": "scm", // scm for git/svn, or dir for copying a directory
    "status": "success",
    "duration": "<milliseconds>",
    "grapefile": "", // path to file, or blank for ./Grapefile default
    "repo": {
        "type": "git",
        "multi": false,
        "url": "",
        "branch": "", // if type is multi, this is empty
    },
    "dir": {
        "path": ""
    },
    "run": {
        "parallel": false,
        "schedule": "", // cronjob format, or empty if no schedule
        "last": "2018-04-24 19:27:02.000",
        "next": "2018-04-24 19:28:02.000"
    }
}
```

-- "runs.json"

```json
"runs": [
    {
        "id": 1,
        "start": "<date>",
        "end": "<date>",
        "duration": "<milliseconds>",
        "status": "success"
    }
]
```

-- "config.json" for a run

```json
{

}
```

-- "queue.json"

```json
"queue": [
    {
        "jobId": "",
        "runId": "",
        "running": false,
        "run": {
            "queued": "<date/time queued>",
            "started": "<date/time started>"
        }
    }
]
```


NOTES

https://bootswatch.com/pulse/
https://yarnpkg.com/en/

* How to manage steps in the Grapefile?
* Have an agent that can auto-clean-up completed workspaces (if enabled on job)
* Have an agent to allow scheduled jobs
* Ability to store credentials
* Ability to have process-environment variables set on every run (and parameterised jobs)