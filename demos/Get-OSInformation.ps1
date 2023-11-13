Function Get-OSInformation {

    <#
    .SYNOPSIS
    Get fun os information
    .DESCRIPTION
    use CIM and get os information
    .PARAMETER ComputerName
    Specify the computer name to query. Default is localhost
    .EXAMPLE
    PS C:\> Get-OSInformation -computername dom1

    ComputerName    : DOM1
    OperatingSystem : Microsoft Windows Server 2019 Standard Evaluation
    Version         : 10.0.17763
    Edition         : ServerStandardEval
    Installed       : 10/19/2023 5:05:04 PM
    Age             : 24.00:17:45.7803985

    some description

    .LINK
    Get-CimInstance

    .LINK
    Get-Service
    #>

    [cmdletbinding()]
    [OutputType('psOSInformation')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the computer name to query. Default is localhost'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $ENV:COMPUTERNAME
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Using PowerShell host $($host.name)"

        $splat = @{
            ClassName    = 'Win32_OperatingSystem'
            Property     = 'CSName', 'Caption', 'Version', 'InstallDate'
            ErrorAction  = 'Stop'
            ComputerName = $null
        }

        #a private helper function to get additional information from the registry
        Function _GetRegistryDetail {
            Param([string]$Computername = $ENV:ComputerName)
            Invoke-Command {
                $get = @{
                    Path        = 'HKLM:\SOFTWARE\Microsoft\windows nt\CurrentVersion'
                    Name        = 'EditionID'
                    ErrorAction = 'SilentlyContinue'
                }
                Get-ItemPropertyValue @get
            } -HideComputerName -ComputerName $Computername
        }
    } #begin

    Process {
        #update the splatting hashtable with each processed computername
        $splat.ComputerName = $Computername
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $($splat.Computername)"
        Try {
            $os = Get-CimInstance @splat
            [PSCustomObject]@{
                PSTypeName      = 'psOSInformation'
                ComputerName    = $os.CSName
                OperatingSystem = $os.caption
                Version         = $os.version
                Edition         = _GetRegistryDetail $splat.ComputerName
                Installed       = $os.installDate
                Age             = (Get-Date) - $os.InstallDate
            }
        } #try
        Catch {
            Write-Error "Failed to query $($Computername.ToUpper()). $($_.Exception.Message)"
        } #catch

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-OSInformation