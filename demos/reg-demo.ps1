return 'This is a demo script file.'

dir hklm:
dir HKLM:\SOFTWARE

dir HKLM:\SOFTWARE\RegisteredApplications\
Get-Item HKLM:\SOFTWARE\RegisteredApplications\
Get-ItemProperty -Path HKLM:\SOFTWARE\RegisteredApplications\ -Name Notepad

#don't forget this is a rich object
Get-Item HKLM:\SOFTWARE\RegisteredApplications\ | select *
Get-Item HKLM:\SOFTWARE\RegisteredApplications\ | Get-Member
$ra = Get-Item HKLM:\SOFTWARE\RegisteredApplications
$ra.property

#create
#open RegEdit to see changes
regedit.exe
cd HKCU:\

#How would you create a new key called TMOrlando?
<#
New-Item -Path . -name TMOrlando
#>

#create TMOrlando\PowerShell
<#
New-Item -Path .\TMOrlando -name PowerShell
#>

#add a property called PSVersion with your current powerShell version
<#
New-itemProperty -path TMOrlando\Powershell -name PSVersion -value $PSVersionTable.PSVersion
#>

#add a property called Foo with a DWord Value of 0
<#
New-itemProperty -path TMOrlando\Powershell -name Foo -value 0 -propertyType DWord
#>

#change FOO to 1
<#
Set-ItemProperty -path .\TMOrlando\PowerSHell -Name Foo -value 1
#>

#delete the Foo property
<#
Remove-ItemProperty -path .\TMOrlando\PowerSHell -Name Foo
#>

#change to the file system
cd C:\
#define a variable that holds the value of PSversion from the registry
<#
$ver = Get-ItemPropertyValue HKCU:\TMOrlando\PowerShell\ -name PSVersion
#>

#delete the PSVersion property
<#
Remove-ItemProperty -Path HKCU:\TMOrlando\PowerShell -name PSVersion
#>

#delete TMOrlando
Remove-Item HKCU:\TMOrlando -Force -Recurse

<#
Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion
Write code to query this location and create a custom object showing:

Computername
Current DateTime
Registered owner
Registered organization
Product Name
Edition ID
DisplayVersion

Extra bonus points to convert InstallDate - number of seconds since 1/1/1970 in UTC

#>
<#

Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\windows nt\CurrentVersion' |
Select-Object ProductName, EditionID,DisplayVersion,RegisteredOwner, RegisteredOrganization,
@{Name = 'Installed'; Expression = { (Get-Date '1/1/1970').AddSeconds($_.InstallDate).ToLocalTime() } },
@{Name = 'Audit'; Expression = { (Get-Date) } },
@{Name = 'Computername' ; Expression = { $ENV:COMPUTERNAME } }

#>