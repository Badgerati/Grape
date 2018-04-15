# dashboard
Add-PodeRoute GET '/' {
    param($session)
    Write-ViewResponse 'index'
}