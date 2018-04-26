
function _coalesce($a, $b) {
    if (!([bool]$a)) {
        $b
    } 
    else {
        $a
    }
}

New-Alias '??' _coalesce -Force


function _ifelse([bool]$bool, $a, $b) {
    if ($bool) {
        $a
    }
    else {
        $b
    }
}

New-Alias '???' _ifelse -Force


function Get-Id {
    # bit hacky, but hey ¯\_(ツ)_/¯
    return ([Guid]::NewGuid().ToString() -split '-')[0]
}

function Test-Empty {
    param (
        $Value
    )

    if ($Value -eq $null) {
        return $true
    }

    if ($Value.GetType().Name -ieq 'string') {
        return [string]::IsNullOrWhiteSpace($Value)
    }

    if ($Value.GetType().Name -ieq 'hashtable') {
        return $Value.Count -eq 0
    }

    $type = $Value.GetType().BaseType.Name.ToLowerInvariant()
    switch ($type) {
        'valuetype' {
                return $false
            }

        'array' {
                return (($Value | Measure-Object).Count -eq 0 -or $Value.Count -eq 0)
            }
    }

    return ([string]::IsNullOrWhiteSpace($Value) -or ($Value | Measure-Object).Count -eq 0 -or $Value.Count -eq 0)
}

function Get-UtcDate {
    return [DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')
}

function ConvertTo-Date {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $date
    )

    return [DateTime]::Parse($date)
}

function Test-Date {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $date
    )

    try {
        ConvertTo-Date $date | Out-Null
        return $true
    }
    catch {
        return $false
    }
}