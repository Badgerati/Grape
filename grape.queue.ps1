param (
    [Parameter()]
    [int]
    $Interval = 10,

    [Parameter()]
    [int]
    $Threads = 2
)


# reload pode module
if ((Get-Module Pode) -ne $null) {
    Remove-Module Pode
}

Import-Module ..\Pode\src\Pode.psm1


# run startup script
./helpers/startup.ps1


# setup grape queue server
Server -Interval $Interval {

    # get the current running/pending queues
    $pending = Get-QueueFile -pending
    $running = Get-QueueFile -running

    # remove any from running are are done/aborted
    $done = $running.queue | Where-Object {
        
    }

    # check how many are currently running
    if (($running.queue | Measure-Object).Count -ge $Threads) {
        return
    }



}
