# include any helper scripts
. ./helpers/general.ps1
. ./helpers/jobs.ps1
. ./helpers/runs.ps1
. ./helpers/queue.ps1


# create required dirs
New-Item -ItemType Directory -Path ./jobs -Force | Out-Null
New-Item -ItemType Directory -Path ./workspaces -Force | Out-Null
New-Item -ItemType Directory -Path ./queue -Force | Out-Null