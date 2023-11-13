#requires -version 5.1
Function Get-Status {
    [cmdletbinding(DefaultParameterSetName = 'name')]
    [alias("gst")]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the name of a computer',
            ParameterSetName = 'name')
        ]
        [ValidateNotNullOrEmpty()]
        [Alias("CN")]
        [string]$Computername = $env:computername,

        [Parameter(ParameterSetName = 'name')]
        [ValidateNotNullOrEmpty()]
        [Alias("RunAs")]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'Session', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [CimSession]$CimSession,

        [Parameter(HelpMessage = "Format values as [INT]")]
        [switch]$AsInt
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay)] Starting $($MyInvocation.MyCommand)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay)] Using parameter set $($PSCmdlet.ParameterSetName)"

        $SessParams = @{
            ErrorAction  = 'stop'
            computername = $null
        }
        $CimParams = @{
            ErrorAction = 'stop'
            ClassName   = $null
        }

        if ($PSCmdlet.ParameterSetName -eq 'name') {
            #create a temporary CimSession
            $SessParams.Computername = $Computername
            if ($Credential) {
                $SessParams.Credential = $credential
            }
            #if localhost use DCOM - it will be faster to create the session
            if ($Computername -eq $env:computername) {
                Write-Verbose "[$((Get-Date).TimeOfDay)] Creating a local session using DCOM"
                $SessParams.Add("SessionOption", (New-CimSessionOption -Protocol DCOM))
            }
            Try {
                Write-Verbose "[$((Get-Date).TimeOfDay)] $computername"
                $CimSession = New-CimSession @SessParams
                $TempSession = $True
            }
            catch {
                Write-Error $_
                #bail out
                return
            }
        }

        if ($CimSession) {
            $hash = [ordered]@{
                PSTypename   = "QuickStatus"
                Computername = $CimSession.computername.toUpper()
            }
            Try {
                $CimParams.ClassName = 'Win32_OperatingSystem'
                $CimParams.CimSession = $CimSession
                Write-Verbose "[$((Get-Date).TimeOfDay)] Using class $($CimParams.ClassName)"
                $OS = Get-CimInstance @CimParams
                $uptime = (Get-Date) - $OS.lastBootUpTime
                $hash.Add("Uptime", $uptime)

                $pctFreeMem = [math]::Round(($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 2)
                if ($AsInt) {
                    $pctFreeMem = $pctFreeMem -as [int]
                }
                $hash.Add("pctFreeMem", $pctFreeMem)

                $CimParams.ClassName = 'Win32_LogicalDisk'
                $CimParams.filter = "DriveType=3"

                Write-Verbose "[$((Get-Date).TimeOfDay)] Using class $($CimParams.ClassName)"
                Get-CimInstance @CimParams | ForEach-Object {
                    $name = "pctFree{0}" -f $_.DeviceID.substring(0, 1)
                    $pctFree = [math]::Round(($_.FreeSpace / $_.size) * 100, 2)
                    if ($AsInt) {
                        $pctFree = $pctFree -as [int]
                    }
                    $hash.add($name, $pctFree)
                }

                New-Object PSObject -Property $hash
            }
            catch {
                Write-Error $_
            }

            #only remove the CimSession if it was created in this function
            if ($TempSession) {
                Write-Verbose "[$((Get-Date).TimeOfDay)] Removing temporary CimSession"
                Remove-CimSession -CimSession $CimSession
            }
        } #if CimSession
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay)] Ending $($MyInvocation.MyCommand)"
    } #end
} #close function


# Update-FormatData $PSScriptRoot\quickstatus.format.ps1xml