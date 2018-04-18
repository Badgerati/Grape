# dashboard
route get '/' {
    param($session)

    # get list of jobs

    Write-ViewResponse 'index'
}


# jobs (just dashboard)
route get '/jobs' {
    param($session)

    # get list of jobs

    Write-ViewResponse 'index'
}


# create a new job
route get '/jobs/new' {
    param($session)
    Write-ViewResponse 'jobs/new'
}


# settings
route get '/manage' {
    param($session)
}


# about
route get '/about' {
    param($session)
}