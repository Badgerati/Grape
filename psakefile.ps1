$scriptsPath = './public/libs/scripts/'
$cssPath = './public/libs/css/'
$fontsPath = './public/libs/fonts/'

########################################
# Tasks
########################################

# install required yarn packages
Task Build {
    if ((Get-Module Pode) -ne $null)
    {
        Remove-Module Pode
    }

    Import-Module ..\Pode\src\Pode.psm1

    pode install

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
    Copy-Item -Path './pode_modules/jquery/dist/jquery.min.js' -Destination $scriptsPath -Force | Out-Null

    # moment
    Copy-Item -Path './pode_modules/moment/min/moment.min.js' -Destination $scriptsPath -Force | Out-Null

    # validator
    Copy-Item -Path './pode_modules/validator/validator.min.js' -Destination $scriptsPath -Force | Out-Null

    # bootstrap
    Copy-Item -Path './pode_modules/bootstrap/dist/css/*.min.css' -Destination $cssPath -Force | Out-Null
    Copy-Item -Path './pode_modules/bootstrap/dist/js/*.min.js' -Destination $scriptsPath -Force | Out-Null
    Copy-Item -Path './pode_modules/bootstrap/dist/fonts/*' -Destination $fontsPath -Force | Out-Null

    # bootstrap-select
    Copy-Item -Path './pode_modules/bootstrap-select/dist/css/*.min.css' -Destination $cssPath -Force | Out-Null
    Copy-Item -Path './pode_modules/bootstrap-select/dist/js/*.min.js' -Destination $scriptsPath -Force | Out-Null
}

# all done
Task Finished -Depends Libraries {
    Write-Host 'Finished'
}

Task default -Depends Finished
