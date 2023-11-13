return 'This is a demo script file.'
Function Get-FileAge {
    [cmdletbinding()]
    Param([string]$Path)

    Get-Item -Path $Path |
    Select-Object Directory, Name, FullName,
    CreationTime, LastWriteTime,
    @{Name = 'CreationAge'; Expression = { New-TimeSpan -Start $_.CreationTime -End (Get-Date) } },
    @{Name = 'ModificationAge'; Expression = { New-TimeSpan -Start $_.LastWriteTime -End (Get-Date) } }
}

Get-FileAge .\hol.ps1

#region defining parameters
Function Get-FileAge {
    [cmdletbinding()]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = 'Specify a file name and path.'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ }, ErrorMessage = 'Failed to verify the file.')]
        [string]$Path
    )

    Get-Item -Path $Path |
    Select-Object Directory, Name, FullName,
    CreationTime, LastWriteTime,
    @{Name = 'CreationAge'; Expression = { New-TimeSpan -Start $_.CreationTime -End (Get-Date) } },
    @{Name = 'ModificationAge'; Expression = { New-TimeSpan -Start $_.LastWriteTime -End (Get-Date) } }
}

#endregion

#region custom output
Function Get-FileAge {
    #this version should work cross-platform
    [cmdletbinding()]
    [OutputType('psFileAge')]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = 'Specify a file name and path.'
        )]
        [ValidateScript( { Test-Path $_ }, ErrorMessage = 'Failed to verify the file.')]
        [alias('File')]
        [string]$Path
    )

    $file = Get-Item -Path $Path

    [PSCustomObject]@{
        PSTypeName      = 'psFileAge'
        Folder          = $file.Directory
        Name            = $File.Name
        FullName        = $File.FullName
        CreationTime    = $File.CreationTime
        LastWriteTime   = $File.LastWriteTime
        CreationAge     = New-TimeSpan -Start $file.CreationTime -End (Get-Date)
        ModificationAge = New-TimeSpan -Start $file.LastWriteTime -End (Get-Date)
        Computername    = [System.Environment]::MachineName
    }
}
help Get-FileAge

Get-Fileage -file .\hol.ps1 | tee -Variable f | Get-Member
#endregion

#region advanced versions

Function Get-FileAge {
    #this version should work cross-platform
    [cmdletbinding()]
    [Alias("gfa")]
    [OutputType('psFileAge')]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            HelpMessage = 'Specify a file name and path.'
        )]
        [ValidateScript( { Test-Path $_ }, ErrorMessage = 'Failed to verify the file.')]
        [alias('File')]
        [string]$Path
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under $($PSVersionTable.PSVersion)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] PowerShell Host: $($Host.Name)"
    } #begin
    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $path"

        $file = Get-Item -Path $Path

        [PSCustomObject]@{
            PSTypeName      = 'psFileAge'
            Directory       = $file.Directory
            Name            = $File.Name
            FullName        = $File.FullName
            CreationTime    = $File.CreationTime
            LastWriteTime   = $File.LastWriteTime
            CreationAge     = New-TimeSpan -Start $file.CreationTime -End (Get-Date)
            ModificationAge = New-TimeSpan -Start $file.LastWriteTime -End (Get-Date)
            Computername    = [System.Environment]::MachineName
        }
    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end
}


$r = dir *.ps1 | get-fileage -Verbose

#endregion