return 'This is a demo script file.'

<#
This is my master outline for the day
There are lab exercises we didn't get a chance to do
so I encourage you try them on your own.
#>

#region Welcome

#Setting Expectations
#Why are you here?
#What do you want to learn?
#What burning questions do you have?

#Use an editor for commands
#focus on concepts and techniques

#endregion

#region PowerShell review

#terms and concepts

# Variables
# Arrays
# Hashtables

#endregion

#region PSDrives and Providers

Get-PSProvider
help about_alias_provider

#dynamic parameters based on PSDrive
dir c:\work -File
dir HKLM:\SOFTWARE -file
dir Cert:\CurrentUser\my -DocumentEncryptionCert

# Install-Module PSScriptTools
#run in the console to see highlighting
Get-CommandSyntax Get-ChildItem
#Run in WIN10 with AD module loaded

# Get-ParameterInfo
Get-ParameterInfo Get-ChildItem
cd Cert:
Get-ParameterInfo Get-ChildItem

#managing the registry
psedit .\reg-demo.ps1

#endregion

#region Pipeline Binding

<#
This concept applies to how you might consume command output
as well as how you might want to structure your own commands.
#>

help Sort-Object -Parameter InputObject
help Get-ChildItem -Parameter Path
help Get-Counter -Parameter Counter

#Install-Module PSScriptTools
Get-ParameterInfo Get-Counter | Select-Object Name, Value*

#ByValue
'C:\Windows' | Get-Item
1, 4, 6, 2, 77, 3, 5 | Sort-Object -Descending

#ByPropertyName
Get-Counter -ListSet Memory
#don't assume the output is the actual property name - verify
Get-Counter -ListSet Memory | Get-Member -MemberType Properties

Get-Counter -ListSet Memory | Get-Counter

'C:\work', $env:Temp, 'c:\scripts' |
Get-ChildItem -Directory -PipelineVariable pv |
ForEach-Object {
    Write-Progress -Activity 'Measuring Folder' -Status $_.FullName
    $_ | Get-ChildItem -File -Recurse |
    Measure-Object -Property Length -Sum |
    Select-Object @{Name = 'Parent'; Expression = { $pv.Parent } },
    @{Name = 'Directory'; Expression = { $pv.Name } },
    Count, Sum
} | Where-Object { $_.Sum -ge 500KB } |
Sort-Object Parent, Sum |
Format-Table -GroupBy Parent -Property Directory, Count,
@{Name = 'SumKB'; Expression = { [math]::Round($_.Sum / 1KB, 4) } }

# !! READ THE HELP !!

<#

Create a text file of service names.
1. Write a command that pipes the list of names to a command that
sets the service to automatically start.
2. Create a CSV file with the service name and the start mode (automatic,disabled,manual)
How could you use the file to configure services
#>

<#
Get-Content .\services.txt | Set-Service -StartupType Automatic -WhatIf

import-csv .\services.csv |
foreach-object {
    set-service -name $_.name -StartType $_.starttype  -PassThru
} | Select name,start*
#>

#endregion

#region splatting

Get-WinEvent -LogName System -MaxEvents 10 -ComputerName $env:ComputerName -OutVariable w -ErrorAction Stop

$paramHash = @{
    LogName      = 'System'
    MaxEvents    = 20
    ComputerName = $env:ComputerName
    ErrorAction  = 'Stop'
    OutVariable  = 'w'
    Verbose      = $true
}

Get-WinEvent @paramHash

<#
Using splatting, write PowerShell code to get only directories,
recursing from the %TEMP% folder. Then modify the hashtable by
modifying the path, and retry the command.
#>

psedit .\Get-OSInformation.ps1
. .\Get-OSInformation.ps1
Get-OSInformation -verbose
'dom1', 'win10', 'localhost', 'foo', 'srv1' | Get-OsInformation

psedit .\Get-OS.ps1
. .\Get-OS.ps1
Get-OS -verbose

#endregion

#region Error handling

#review error system
Get-Error -Newest 1
$error

$ErrorActionPreference
Get-Service bits, foo, winrm
$error[0] | select *
Get-Error -Newest 1

$ErrorActionPreference = 'SilentlyContinue'
Get-Service bits, foo2, winrm
Get-Error -Newest 1

$ErrorActionPreference = 'Ignore'
Get-Service bits, foo3, winrm
Get-Error -Newest 1

$ErrorActionPreference = 'stop'
Get-Service bits, foo4, winrm
Get-Error -Newest 1

# help about_Try_Catch_Finally
#reset to default
$ErrorActionPreference = 'Continue'
psedit .\demo-trycatch.ps1
psedit .\demo-trycatch2.ps1

#endregion

#region Writing Functions

#parameter definitions

psedit .\Get-FileAge.ps1

#parameter validation
#parameter aliases
#typed custom objects
#endregion

#region Advanced function concepts
psedit .\Get-OS.ps1
psedit .\Get-OSInformation.ps1
psedit .\get-eventlogusage.ps1
. .\get-eventlogusage.ps1
$r = Get-EventLogUsage -logname system -Computername dom1, foo, srv1, srv2, srv3 -Verbose

#function aliases
#parameter sets
psedit .\Get-OS.ps1
psedit .\getstat.ps1

<#
Create an advanced PowerShell function that takes a
directory path from the pipeline. The function should have
an option to recurse. The function should write a custom object
to the pipeline that shows each file extension, the total number
of files for each extension, the average and total sizes  x.

Bonus point to remove the period from the extension.
Bonus points be able to exclude one or more extensions
Incorporate everything we've covered, You are encouraged to work
in groups.

#>

#endregion

#region Enhancing output

#Adding help

#type extensions
$f = Get-FileExtensionInfo -Verbose
Update-TypeData -TypeName psExtensionInfo -MemberType AliasProperty -MemberName Directory -Value Path -Force
Update-TypeData -TypeName psExtensionInfo -MemberType ScriptProperty -MemberName SizeKB -Value { [math]::Round($this.TotalSize / 1kb, 2) } -Force

$f | Get-Member
$f | Select-Object Directory, Extension, SizeKB, AverageSize

#format extensions
# Install-Module PSScriptTools
help New-PSFormatXML

# $f[-1] | New-PSFormatXML -Path .\psExtensionInfo.format.ps1xml -GroupBy Path -Properties Extension,Count,AverageSize,TotalSize
psedit .\psExtensionInfo.format.ps1xml
Update-FormatData .\psExtensionInfo.format.ps1xml

#add a view
$paramHash = @{
    InputObject = $f[1]
    Path       = '.\psExtensionInfo.format.ps1xml'
    GroupBy    = 'Path'
    Properties = "Extension", "Count", @{Name="AvgKB";Expression = {[math]::Round($_.AverageSize/1kb,2)}},@{Name="TotalKB";Expression = {[math]::Round($_.TotalSize/1kb,2)}}
    Append = $true
    ViewName = "kb"
}

# New-PSFormatXML @paramHash

Update-FormatData .\psExtensionInfo.format.ps1xml
$f | Format-Table -view kb

#endregion

#region Creating modules

#module layout
#design considerations

#endregion

#region Open Workshop

# Work on a project of your choosing
# Create a module using the functions you've built today

#endregion

# Open Q&A
