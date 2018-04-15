# dashboard
Add-PodeRoute GET '/' {
    param($session)

    # get list of jobs

    Write-ViewResponse 'index'
}


# jobs (just dashboard)
Add-PodeRoute GET '/jobs' {
    param($session)

    # get list of jobs

    Write-ViewResponse 'index'
}


# create a new job
Add-PodeRoute GET '/jobs/new' {
    param($session)
    Write-ViewResponse 'jobs/new'
}


# settings
Add-PodeRoute GET '/manage' {
    param($session)
}


# about
Add-PodeRoute GET '/about' {
    param($session)
}