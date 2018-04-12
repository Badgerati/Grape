$scriptsPath = './public/libs/scripts/'
$cssPath = './public/libs/css/'
$fontsPath = './public/libs/fonts/'

########################################
# Tasks
########################################

# install required yarn packages
Task Build {
    yarn install --force

    if (!(Test-Path $scriptsPath))
    {
        New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
    }

    if (!(Test-Path $cssPath))
    {
        New-Item -Path $cssPath -ItemType Directory -Force | Out-Null
    }

    if (!(Test-Path $fontsPath))
    {
        New-Item -Path $fontsPath -ItemType Directory -Force | Out-Null
    }
}

# load yarn libraries
Task Libraries -Depends Build {
    # jquery
    Copy-Item -Path './node_modules/jquery/dist/jquery.min.js' -Destination $scriptsPath -Force | Out-Null

    # moment
    Copy-Item -Path './node_modules/moment/min/moment.min.js' -Destination $scriptsPath -Force | Out-Null

    # validator
    Copy-Item -Path './node_modules/validator/validator.min.js' -Destination $scriptsPath -Force | Out-Null

    # bootstrap
    Copy-Item -Path './node_modules/bootstrap/dist/css/*.min.css' -Destination $cssPath -Force | Out-Null
    Copy-Item -Path './node_modules/bootstrap/dist/js/*.min.js' -Destination $scriptsPath -Force | Out-Null
    Copy-Item -Path './node_modules/bootstrap/dist/fonts/*' -Destination $fontsPath -Force | Out-Null

    # bootstrap-select
    Copy-Item -Path './node_modules/bootstrap-select/dist/css/*.min.css' -Destination $cssPath -Force | Out-Null
    Copy-Item -Path './node_modules/bootstrap-select/dist/js/*.min.js' -Destination $scriptsPath -Force | Out-Null
}

# all done
Task Finished -Depends Libraries {
    Write-Host 'Finished'
}

Task default -Depends Finished
