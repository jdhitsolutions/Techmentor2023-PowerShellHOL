#requires -version 5.1
Function Get-EventLogUsage {
    [cmdletbinding()]
    [OutputType('evUsage')]
    [alias('gelu')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'The name of a Windows Event log. The default is all event logs.'
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$LogName = '*',

        [Parameter(HelpMessage = 'Get enabled logs only.')]
        [Alias("eo")]
        [switch]$EnabledOnly,

        [Parameter(HelpMessage = 'The name of a computer to query.')]
        [ValidateNotNullOrEmpty()]
        [Alias("CN")]
        [string[]]$Computername = $env:COMPUTERNAME
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        $Audit = Get-Date
        $sb = {
            Param($LogName, $EnabledOnly)
            $VerbosePreference = $using:VerbosePreference
            Write-Verbose "[$((Get-Date).TimeOfDay) REMOTE ] Getting log information from $($env:COMPUTERNAME)"
            $logs = Get-WinEvent -ListLog $LogName

            if ($enabledOnly) {
                $logs = $logs | Where-Object IsEnabled
            }
            #only select what I need
            $logs | Select-Object -Property LogName, LogMode, FileSize, MaximumSizeInBytes,
            RecordCount, IsLogFull, LastWriteTime, LogType, IsEnabled
        } #close scriptblock

        $icmSplat = @{
            ScriptBlock  = $sb
            ArgumentList = @($LogName, $EnabledOnly)
            ComputerName = $Null
            ErrorAction  = 'Stop'
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing LogName = $($LogName -join ',')"

        foreach ($Computer in $Computername) {
            #update the splatting hashtable
            $icmSplat.ComputerName = $Computer
            Try {
                Invoke-Command @icmSplat | ForEach-Object {
                    #create the typed object locally
                    [PSCustomObject]@{
                        PSTypeName    = 'evUsage'
                        LogName       = $_.LogName
                        LogMode       = $_.LogMode
                        LogType       = $_.LogType
                        FileSize      = $_.FileSize
                        MaxSize       = $_.MaximumSizeInBytes
                        PctFull       = ($_.FileSize / $_.maximumSizeInBytes) * 100
                        RecordCount   = $_.RecordCount
                        IsLogFull     = $_.IsLogFull
                        IsEnabled     = $_.IsEnabled
                        LastWriteTime = $_.LastWriteTime
                        Computername  = $_.PSComputerName
                        Audit         = $Audit
                    }
                }
            } #Try
            Catch {
                Write-Warning "Failed to query $($Computer.ToUpper()). $($_.Exception.Message)"
            }
        } #foreach computer
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-EventLogUsage