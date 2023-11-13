Clear-Host
$services = "bits","foo","winrm","spooler"
Try {
    write-Host "Trying to get services" -ForegroundColor green
    Get-Service $services -ErrorAction Stop
}
Catch {
    write-Host "Caught an error" -ForegroundColor magenta
    $_
}
Finally {
    write-host "I am finally here" -ForegroundColor yellow
}

Write-Host "Continuing code" -ForegroundColor cyan