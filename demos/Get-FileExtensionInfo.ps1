#requires -version 7.3

Function Get-FileExtensionInfo {
    <#
    .SYNOPSIS
    Get a file extension report
    .DESCRIPTION
    Run this command to get a report on file extension usage for a given folder.
    .PARAMETER Path
    Specify the top level folder to search. The default is the current folder.
    .PARAMETER Exclude
    Enter a set of file exclusions like *.gif. Specifying an exclusion requires -Recurse.
    .EXAMPLE
    PS C:\> Get-FileExtensionInfo d:\temp -Recurse

    Extension    : json
    Count        : 1
    TotalSize    : 42
    AverageSize  : 42
    Path         : D:\temp
    ComputerName : PROSPERO
    ReportDate   : 11/7/2023 3:11:33 PM

    Extension    : txt
    Count        : 2
    TotalSize    : 1278147
    AverageSize  : 639073.5
    Path         : D:\temp
    ComputerName : PROSPERO
    ReportDate   : 11/7/2023 3:11:33 PM
    .Link
    Get-ChildItem
    #>
    [cmdletbinding(DefaultParameterSetName = 'root')]
    [OutputType('psExtensionInfo')]
    [alias('fei')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the top level folder to search.',
            ParameterSetName = 'root'
        )]
        [Parameter( Position = 0,ParameterSetName = 'recurse')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'Failed to verify the specified path.')]
        [alias('Directory', 'Folder')]
        [string]$Path = '.',

        [Parameter(ParameterSetName = 'recurse')]
        [switch]$Recurse,
        [Parameter(
            HelpMessage = 'Enter a set of file exclusions like *.gif. Specifying an exclusion requires -Recurse.',
            ParameterSetName = 'recurse'
        )]
        [String[]]$Exclude
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"

        #add a parameter to PSBoundParameters
        $PSBoundParameters.Add('File', $True)

        if ($Exclude -AND (-Not $Recurse)) {
            Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Exclusion detected. Forcing -Recurse"
            $PSBoundParameters.Add('Recurse', $True)
        }

        #set the report date to be used in output
        $Report = Get-Date
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Detected parameter set -> $($PSCmdlet.ParameterSetName)"
        $PSBoundParameters['Path'] = Convert-Path $Path
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $($PSBoundParameters['Path'])"

        $files = Get-ChildItem @PSBoundParameters
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Found $($files.count) files"
        $grouped = $files | Group-Object -Property { $_.Extension -replace '\.', '' }

        Foreach ($group in $grouped) {
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Analyzing $($group.count) $($group.Name) file(s)"
            $stats = $group.group | Measure-Object -Property Length -Sum -Average
            [PSCustomObject]@{
                PSTypeName   = 'psExtensionInfo'
                Extension    = $group.Name
                Count        = $group.Count
                TotalSize    = $stats.Sum
                AverageSize  = $stats.Average
                Path         = $PSBoundParameters['Path']
                ComputerName = [System.Environment]::MachineName
                ReportDate   = $Report
            }
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FileExtensionInfo