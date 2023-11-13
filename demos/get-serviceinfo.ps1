# requires -version 5.1

Function Get-ServiceInfo {
    Param(
        $Name,
        $Computername = $env:COMPUTERNAME
    )

    $properties = "Name","DisplayName","StartType","Status"

    Get-Service -name $Name -computername $Computername |
    Select-Object -Property $properties

} #close function
