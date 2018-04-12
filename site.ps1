if ((Get-Module Pode) -ne $null)
{
    Remove-Module Pode
}

Import-Module ..\Pode\src\Pode.psm1


Server -Port 8083 {
    Add-PodeRoute 'GET' 'api/ping/:job/runs/:runId' {
        param($session)

        $content = $session.Query['content']
        $file = $session.Query['file']
        $job = $session.Parameters['job']
        $runId = $session.Parameters['runId']

        #Start-Job -ScriptBlock {
        #    param($content, $file)
        #    'starting...' | Out-File "c:\projects\grape\$($file).txt" -Force | Out-Null
        #    Start-Sleep -Seconds 20
        #    $content | Out-File "c:\projects\grape\$($file).txt" -Force -Append | Out-Null
        #    Start-Sleep -Seconds 20
        #    'stopping...' | Out-File "c:\projects\grape\$($file).txt" -Force -Append | Out-Null
        #} -ArgumentList $content, $file | Out-Null

        Write-JsonResponse @{ 'value' = 'pong'; 'content' = $content; 'file' = $file; 'job' = $job; 'runId' = $runId }
    }

    Add-PodeRoute 'GET' 'api/ping' {
        param($session)

        $content = $session.Query['content']
        $file = $session.Query['file']
        Write-JsonResponse @{ 'value' = 'pong'; 'content' = $content; 'file' = $file; }
    }
}