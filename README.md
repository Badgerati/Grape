# Grape

* All job steps are defined using a Grapefile - which is just powershell (see picassio2). The only config is:
    * job name/description
    * job parameters
    * schedule (or multi-branch)
    * git repo (and branch)
    * Grapefile name/path (or blank for default ".\Grapefile")



PAGES

<jobId>       =   job name, lowercase and hyphenated/underscored
<branchId>    =   branch name, lowercase and hyphenated (slashes are hyphens)

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

/api/v1/jobs                                            <- POST     <- create new job
                                                         - GET      <- returns a list of jobs, with some filter/limit

/api/v1/jobs/<jobId>                                    <- GET      <- returns job details, and last x runs or x branches
                                                         - DELETE   <- deletes the job
                                                         - PUT      <- updates the job

/api/v1/jobs/<jobId>/runs                               <- POST     <- starts a new run for the job, or scan a repo for updated/new branches

/api/v1/jobs/<jobId>/runs/<runId>                       <- GET      <- returns run details
                                                         - DELETE   <- if running, forces the run to stop

/api/v1/jobs/<jobId>/branches/<branchId>                <- GET      <- returns branch details, and last x runs

/api/v1/jobs/<jobId>/branches/<branchId>/runs           <- POST     <- starts a new run for the branch

/api/v1/jobs/<jobId>/branches/<branchId>/runs/<runId>   <- GET      <- returns run details
                                                         - DELETE   <- if running, forces the run to stop




DIRECTORY STRUCTURE

./config.json
./grape.ps1

./jobs/<jobId>/config.json
              /runs/<runId>/config.json
                           /output.txt
              /branches/<branchId>/config.json
                                  /runs/<runId>/config.json
                                               /output.txt

./workspaces/<jobId>/
                    /<runId>/ (split by runId on a normal job if multiple can run at once - otherwise all runs share one workspace [top level])
                    /<branchId>/<runId> (all multi-branch jobs are parallel so all split by runId)



NOTES

https://bootswatch.com/pulse/

* How to manage steps in the Grapefile?
* Have an agent that can auto-clean-up completed workspaces (if enabled on job)
* Have an agent to allow scheduled jobs
* Ability to store credentials
* Ability to have process-environment variables set on every run (and parameterised jobs)