Clear-Host
$services = "bits","foo","winrm","spooler"
Foreach ($service in $services) {
    Try {
        write-Host "Trying to get service $service" -ForegroundColor green
        Get-Service $service -ErrorAction Stop -ErrorVariable +ev
    }
    Catch {
        write-Host "Caught an error" -ForegroundColor magenta
        write-warning $_.Exception.Message
    }
    Finally {
        #write-host "I am finally here" -ForegroundColor yellow
        # write-host $ev.message
    }
}
if ($ev.count -gt 0) {
    $ev | export-clixml -Path c:\temp\ev.xml
}

Write-Host "Continuing code" -ForegroundColor cyan


