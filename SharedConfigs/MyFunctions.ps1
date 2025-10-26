#==================================================================#
#============= Custom Functions (MyFunctions.ps1) =================#
#==================================================================#
# Ensure the script is using UTF-8 encoding
# [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
#==================================================================#
function Get-CmdletAlias {
    <#
      .SYNOPSIS
        Finds all aliases pointing to a specified cmdlet.
      .DESCRIPTION
        Uses Get-Alias to filter and display aliases whose definition matches the provided cmdlet name.
        The search is case-insensitive and uses wildcards for partial matches.
      .PARAMETER CmdletName
        The name of the cmdlet to search for, e.g., 'Get-ChildItem' or just 'Get-Child*'.
      .EXAMPLE
        Get-CmdletAlias 'Get-ChildItem'
        Lists all aliases (like 'ls' or 'dir') that point to Get-ChildItem.
    #>
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true, Position=0)]
      [string]$cmdletName
    )
    Get-Alias |
      Where-Object -FilterScript {$_.Definition -like "*$cmdletName*"} |
        Format-Table -Property Definition, Name -AutoSize
}
function Get-SystemLogEvent {
    <#
      .SYNOPSIS
        Gets the most recent events from the System log.
      .DESCRIPTION
        A wrapped version of Get-WinEvent focused on the System log for quick checks.
      .PARAMETER MaxEvents
        The maximum number of events to retrieve. Defaults to 50.
      .EXAMPLE
        Get-SystemLogEvent
        Gets the last 50 System events.
      .EXAMPLE
        Get-SystemLogEvent -MaxEvents 10
        Gets the last 10 System events.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$MaxEvents = 50
    )
    Get-WinEvent -LogName System -MaxEvents $MaxEvents
}
function Get-ApplicationLogEvent {
    <#
      .SYNOPSIS
        Gets the most recent events from the Application log.
      .DESCRIPTION
        A wrapped version of Get-WinEvent focused on the Application log for quick checks.
      .PARAMETER MaxEvents
        The maximum number of events to retrieve. Defaults to 50.
      .EXAMPLE
        Get-ApplicationLogEvent
        Gets the last 50 Application events.
      .EXAMPLE
        Get-ApplicationLogEvent -MaxEvents 10
        Gets the last 10 Application events.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$MaxEvents = 50
    )
    Get-WinEvent -LogName Application -MaxEvents $MaxEvents
}
function uptime {
    ## Print system uptime

    If ($PSVersionTable.PSVersion.Major -eq 5 ) {
        Get-WmiObject win32_operatingsystem |
        Select-Object @{EXPRESSION = { $_.ConverttoDateTime($_.lastbootuptime) } } | Format-Table -HideTableHeaders
    }
    Else {
        net statistics workstation | Select-String "since" | foreach-object { $_.ToString().Replace('Statistics since ', '') }
    }
}
function cd-home {
    <#
      .SYNOPSIS
          Navigates to the user's home directory.
      .DESCRIPTION
          This function is a simple shortcut to change the current location to
          the home directory of the current user.
      .EXAMPLE
          cd-home
          Changes the current directory to $HOME.
    #>
    Set-Location $HOME
}
function .. {
    <#
    .SYNOPSIS
        Navigates up one directory in the file system.
    .DESCRIPTION
        This function is a simple alias for 'Set-Location ..', making it easy
        to move up a directory without typing out the full command.
    #>
    Set-Location ..
}
function Test-CommandExists {
    <#
      .SYNOPSIS
        Checks if a specified command or executable exists.
      .DESCRIPTION
        This function checks if a command, cmdlet, function, or executable is
            available in the current environment by attempting to get the command object.
      .PARAMETER Command
        The name of the command to check for.
      .EXAMPLE
        Test-CommandExists "git"
        Returns 'True' if 'git' is a recognized command.
    #>
    param(
          [string]$Command
      )
      try {
          Get-Command -Name $Command -ErrorAction Stop
          return $true
      }
      catch {
          return $false
      }
}
Function Get-ConsoleColors {
    <#
			.SYNOPSIS
					Displays all color options on the screen at one time
			.DESCRIPTION
					Displays all color options on the screen at one time
			.EXAMPLE
					Get-ConsoleColors
		#>
		[CmdletBinding()]
				Param()

				$List = [enum]::GetValues([System.ConsoleColor])

				ForEach ($Color in $List){
						Write-Host "      $Color" -ForegroundColor $Color -NonewLine
						Write-Host ""

				} #end foreground color ForEach loop

				ForEach ($Color in $List){
						Write-Host "                   " -backgroundColor $Color -noNewLine
						Write-Host "   $Color"

				} #end background color ForEach loop
}

#==================================================================#
#region * Network Functions *
#==================================================================#
function Get-DnsResult {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'A', 'A_AAAA', 'AAAA', 'AFSDB', 'ANY', 'CNAME', 'DHCID', 'DNSKEY', 'DS', 'DNAME', 'HINFO', 'ISDN',
            'MD', 'MF', 'MINFO', 'MX', 'MR', 'NSEC', 'NSEC3', 'NSEC3PARAM', 'NULL', 'OPT', 'PTR', 'RP', 'RRSIG',
            'SRV', 'SOA', 'TXT', 'WINS', 'WKS', 'X25', 'NS', 'RT', 'UNKNOWN', 'MB', 'MG', 'MR'
        )]
        [string]$recordType,

        [Parameter(Mandatory = $true)]
        [string]$domain
    )

    try {
        # Resolving the DNS record with a custom timeout
        $result = Resolve-DnsName -Name $domain -Type $recordType

        if ($result) {
            # Returning results in a structured way
            return $result
        }
        else {
            Write-Warning "No DNS record found for $domain with type $recordType."
        }
    }
    catch {
        Write-Error "Failed to resolve DNS for domain $domain. Error: $_"
    }
}

function Get-MyPublicIP {
    try {
        $ipInfo = Invoke-RestMethod -Uri 'https://ipinfo.io' -TimeoutSec 5

        if ($ipInfo -and $ipInfo.ip) {
            [PSCustomObject]@{
                'Public IP' = $ipInfo.ip
                'Host Name' = $ipInfo.hostname
                'ISP'       = $ipInfo.org
                'City'      = $ipInfo.city
                'Region'    = $ipInfo.region
                'Country'   = $ipInfo.country
            }
        }
        else {
            Write-Warning "Received an unexpected response from $ApiUrl"
        }
    }
    catch [System.Net.WebException] {
        Write-Warning "Network error: $_"
    }
    catch {
        Write-Warning "Failed to retrieve public IP information: $_"
    }
}

function Get-NetConfig {
    param (
        [string]$cidr,
        [switch]$showSubnets,
        [switch]$showIpv4CidrTable,
        [switch]$azure
    )

    # Load System.Numerics for BigInteger support
    Add-Type -AssemblyName 'System.Numerics'

    # Function to convert IPv4 address to integer
    function ConvertTo-IntIPv4 {
        param ($ip)
        $i = 0
        $ip.Split('.') | ForEach-Object {
            [int]$_ -shl (8 * (3 - $i++))
        } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    }

    # Function to convert integer to IPv4 address
    function ConvertTo-IPv4 {
        param ($int)
        $bytes = 3..0 | ForEach-Object { ($int -shr 8 * $_) -band 255 }
        return ($bytes -join '.')
    }

    # Function to generate a CIDR table
    function New-CidrTable {
        param (
            [string]$baseIp,
            [int]$basePrefix
        )

        # Convert base IP to integer
        $baseInt = ConvertTo-IntIPv4 -ip $baseIp
        $cidrTable = @()

        for ($prefix = $basePrefix; $prefix -le 32; $prefix++) {
            $subnetSize = [math]::Pow(2, (32 - $prefix))
            $networkInt = $baseInt -band (([math]::Pow(2, 32) - 1) - ([math]::Pow(2, 32 - $prefix) - 1))
            $subnetMask = ConvertTo-IPv4 -int $subnetSize
            $totalHosts = [int]($subnetSize - 2)  # Remove leading zeros

            $cidrTable += [PSCustomObject]@{
                CIDR       = "$baseIp/$prefix"
                SubnetMask = $subnetMask
                TotalHosts = $totalHosts
            }
        }

        return $cidrTable
    }

    # Function to convert prefix length to IPv4 subnet mask
    function ConvertTo-SubnetMaskIPv4 {
        param ($prefix)
        $maskInt = ([math]::Pow(2, $prefix) - 1) * [math]::Pow(2, 32 - $prefix)
        ConvertTo-IPv4 -int $maskInt
    }

    # Function to determine IPv4 class
    function Get-IPv4Class {
        param ($ip)
        $firstOctet = [int]$ip.Split('.')[0]
        switch ($firstOctet) {
            { $_ -ge 1 -and $_ -le 126 } { return 'A' }
            { $_ -ge 128 -and $_ -le 191 } { return 'B' }
            { $_ -ge 192 -and $_ -le 223 } { return 'C' }
            default { return 'Unknown' }
        }
    }

    # Extract base IP and prefix length
    $baseIP, $prefix = $cidr -split '/'
    $prefix = [int]$prefix

    $isIPv6 = $baseIP.Contains(':')

    if ($showIpv4CidrTable) {
        # Generate CIDR table for IPv4
        return (New-CidrTable -baseIp $baseIP -basePrefix $prefix) | Format-Table -AutoSize
    }

    if ($azure) {
        # Azure specific logic for usable IPs
        if ($isIPv6) {
            Write-Output "Azure networking for IPv6 is not yet supported."
        }
        else {
            $baseInt = ConvertTo-IntIPv4 -ip $baseIP
            $subnetMask = [math]::Pow(2, 32 - $prefix)

            # Network calculation
            $networkInt = $baseInt -band $subnetMask

            # For Azure, first usable IP is +4 due to reserved IPs (.0, .1, .2, .3)
            $firstUsableIP = ConvertTo-IPv4 -int ($networkInt + 4)
            $lastUsableIP = ConvertTo-IPv4 -int ($networkInt + $subnetMask - 2)
            $broadcastAddress = ConvertTo-IPv4 -int ($networkInt + $subnetMask - 1)

            $usableHostCount = $subnetMask - 4

            return [PSCustomObject]@{
                IPClass          = Get-IPv4Class -ip $baseIP
                CIDR             = $cidr
                NetworkAddress   = ConvertTo-IPv4 -int $networkInt
                FirstUsableIP    = $firstUsableIP
                LastUsableIP     = $lastUsableIP
                BroadcastAddress = $broadcastAddress
                UsableHostCount  = $usableHostCount
                SubnetMask       = ConvertTo-SubnetMaskIPv4 -prefix $prefix
            }
        }
    }

    if ($isIPv6) {
        # IPv6 logic
        Write-Output "IPv6 logic is still a placeholder for future use."
    }
    else {
        # IPv4 logic for non-Azure cases
        $baseInt = ConvertTo-IntIPv4 -ip $baseIP
        $networkSize = [math]::Pow(2, 32 - $prefix)
        $subnetMask = ([math]::Pow(2, 32) - [math]::Pow(2, 32 - $prefix))

        $networkInt = $baseInt -band $subnetMask

        if ($showSubnets) {
            # Show subnets within this range
            $subnetPrefix = 24
            $subnetSize = [math]::Pow(2, 32 - $subnetPrefix)

            $currentSubnetInt = $networkInt
            $subnets = @()

            while ($currentSubnetInt -lt $networkInt + $networkSize) {
                $subnetStart = $currentSubnetInt
                $subnetEnd = [math]::Min($currentSubnetInt + $subnetSize - 1, $networkInt + $networkSize - 1)

                if ($subnetEnd -gt $subnetStart) {
                    $subnetStartIP = ConvertTo-IPv4 -int ($subnetStart + 1)
                    $subnetEndIP = ConvertTo-IPv4 -int ($subnetEnd - 1)

                    $subnets += "Subnet: $subnetStartIP - $subnetEndIP"
                }

                $currentSubnetInt = $currentSubnetInt + $subnetSize
            }

            return $subnets
        }
        else {
            # Output results for standard IPv4
            return [PSCustomObject]@{
                IPClass          = Get-IPv4Class -ip $baseIP
                CIDR             = $cidr
                NetworkAddress   = ConvertTo-IPv4 -int $networkInt
                FirstUsableIP    = ConvertTo-IPv4 -int ($networkInt + 1)
                LastUsableIP     = ConvertTo-IPv4 -int ($networkInt + $networkSize - 2)
                BroadcastAddress = ConvertTo-IPv4 -int ($networkInt + $networkSize - 1)
                UsableHostCount  = ($networkSize - 2).ToString()
                SubnetMask       = ConvertTo-SubnetMaskIPv4 -prefix $prefix
            }
        }
    }
}
#endregion
#==================================================================#
#region * Background Import Module *
#==================================================================#
function Use-MyUtilities {
    if (-not (Get-Module -Name MyUtilities)) {
      # -DisableNameChecking is necessary to suppress the "unapproved verbs" warning
      Import-Module MyUtilities -DisableNameChecking -ErrorAction Stop
    }
}
Set-Alias mu Use-MyUtilities
function Use-MenuFramework {
    if (-not (Get-Module -Name MenuFramework)) {
      # Start-ThreadJob is preferred for faster, in-process loading
      if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) {
        Start-ThreadJob -ScriptBlock { Import-Module MenuFramework -DisableNameChecking } | Out-Null
      } else {
        # Fallback for older PowerShell versions
        Start-Job -ScriptBlock { Import-Module MenuFramework -DisableNameChecking } | Out-Null
      }
    }
}
Set-Alias mf Use-MenuFramework
function Use-PSFzf { 
    # Use dot sourcing to run the init script in the current scope
    . $env:USERPROFILE\dotfiles\psfzf\init.ps1 
}
Set-Alias fzf-init Use-PSFzf
#endregion
#==================================================================#
#region * Profile Functions *
#==================================================================#
function Get-Profiles {
    $PROFILE | Select-Object *Host* | Format-List
}
function Show-Profile {
    <#
      .SYNOPSIS
        Prints the PowerShell profile in the Terminal.
      .DESCRIPTION
        This function is a simple Print PROFILE Script in the Terminal.
      .EXAMPLE
        Show-Profile
        Opens the profile for editing.
    #>
    cat $PROFILE
}
function Edit-Profile {
    <#
      .SYNOPSIS
        Opens the current PowerShell profile file in a preferred editor.
      .DESCRIPTION
        This function tries to open the user's $PROFILE script using VS Code ('code'),
        falls back to PowerShell ISE ('ise'), and finally falls back to Notepad.
      .EXAMPLE
        Edit-Profile
        Opens the Microsoft.PowerShell_profile.ps1 file.
    #>
    [CmdletBinding()]
    param()

    $profilePath = $PROFILE

    # 1. Check if 'code' (VS Code) is available
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Write-Verbose "Opening profile in VS Code: $profilePath"
        code $profilePath
    }
    # 2. Check if 'ise' (PowerShell ISE) is available
    elseif (Get-Command ise -ErrorAction SilentlyContinue) {
        Write-Warning "VS Code ('code' command) not found. Opening profile in PowerShell ISE."
        ise $profilePath
    }
    # 3. Fallback to notepad
    elseif (Get-Command notepad -ErrorAction SilentlyContinue) {
        Write-Warning "VS Code and ISE not found. Opening profile in Notepad."
        notepad $profilePath
    }
    else {
        Write-Error "Could not find a suitable editor (VS Code, ISE, or Notepad) to open the profile."
    }
}
function Reload-Profile {
    <#
      .SYNOPSIS
        Reloads the current PowerShell profile.
      .DESCRIPTION
        Re-executes the user's PowerShell profile script ($PROFILE), applying
        any changes made to functions, aliases, and environment variables.
      .EXAMPLE
        Reload-Profile
        Reloads the profile to make recent changes active.
    #>
    Write-Host "Reloading $PROFILE" -ForegroundColor Yellow
    . $PROFILE
}
function Sync-Profile {
    <#
      .SYNOPSIS
        Runs all profile setup and integration functions.
      .DESCRIPTION
        This is a convenience function that executes a series of setup commands,
        including installing modules and integrating Scoop, to ensure the profile
        is fully configured.
      .EXAMPLE
        Sync-Profile
        Initializes and syncs the entire profile.
    #>
    Install-ProfileModules
    Install-ScoopIntegration
    Integrate-Scoop
}
#endregion
#==================================================================#
#region * Measure Functions *
#==================================================================#
function Get-ResourceSnapshot {
    $p = Get-Process -Id $PID
    [PSCustomObject]@{
        Timestamp     = [DateTime]::UtcNow
        CPU           = $p.CPU
        WorkingSetMB  = [math]::Round($p.WorkingSet64 / 1MB, 2)
        PrivateMemMB  = [math]::Round($p.PrivateMemorySize64 / 1MB, 2)
    }
}
function Measure-Section {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $Action
    $sw.Stop()
    $ms = [int]$sw.Elapsed.TotalMilliseconds
    $color = Get-ColorFromMs -ms $ms
    Write-Host ("{0,-25} {1,6} ms" -f $Name, $ms) -ForegroundColor $color
}
function Measure-Block {
    param(
        [ScriptBlock]$Block,
        [string]$Name
    )
    $startSnap = Get-ResourceSnapshot
    $timer     = Start-Timer
    & $Block
    $timer     = Stop-Timer $timer
    $endSnap   = Get-ResourceSnapshot

    [PSCustomObject]@{
        Name          = $Name
        DurationMs    = [math]::Round($timer.Elapsed.TotalMilliseconds, 2)
        CpuDelta     = [math]::Round($endSnap.CPU - $startSnap.CPU, 2)
        MemDeltaMB    = [math]::Round($endSnap.WorkingSetMB - $startSnap.WorkingSetMB, 2)
    }
}
function Measure-ExecutionTime {
    <#
      .SYNOPSIS
        Measures the elapsed time of a scriptblock.
      .DESCRIPTION
        Runs the scriptblock, times it, and returns a PSCustomObject with
        Elapsed (TimeSpan) and TotalSeconds (Double).
      .PARAMETER Script
        The scriptblock to execute.
      .OUTPUTTYPE
        System.Management.Automation.PSCustomObject
      .EXAMPLE
        $result = Measure-ExecutionTime { Start-Sleep 2 }
        "$($result.TotalSeconds) seconds"
      .NOTES
        Does not catch exceptions; they bubble up.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock] $Script
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $Script
    $sw.Stop()
    return [PSCustomObject]@{
        Elapsed     = $sw.Elapsed
        TotalSeconds= [math]::Round($sw.Elapsed.TotalSeconds, 3)
    }
}
function Start-Spinner {
    <#
      .SYNOPSIS
        Starts a console spinner in the background.
      .DESCRIPTION
        Launches a background job that writes a rotating spinner (|/–\).
        Use Stop-Spinner to terminate and clear the spinner.
      .PARAMETER Activity
        Optional text label to show beside the spinner.
      .EXAMPLE
        $job = Start-Spinner -Activity 'Waiting'
        Start-Sleep -Seconds 3
        Stop-Spinner -SpinnerJob $job
      .NOTES
        Spinner writes directly to the host via Write-Host -NoNewline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Activity
    )
    $spinnerChars = '|/-\'
    $job = Start-Job -ScriptBlock {
        param($chars,$act)
        $i = 0
        while ($true) {
            Write-Output '"`r$act $($chars[$i++ % $chars.Length])" -NoNewline'
            Start-Sleep -Milliseconds 100
        }
    } -ArgumentList ($spinnerChars.ToCharArray(), $Activity)
    return $job
}
function Stop-Spinner {
    <#
      .SYNOPSIS
        Stops a spinner job started with Start-Spinner.
      .DESCRIPTION
        Terminates the background job, clears its output, and erases the spinner line.
      .PARAMETER SpinnerJob
        The Job object returned by Start-Spinner.
      .EXAMPLE
        Stop-Spinner -SpinnerJob $job
      .NOTES
        Ensures the spinner line is cleared after stopping.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.Job] $SpinnerJob
    )
    Stop-Job $SpinnerJob | Out-Null
    Receive-Job $SpinnerJob | Out-Null
    Remove-Job $SpinnerJob | Out-Null
    Write-Output '"`r" -NoNewline'
}
function Convert-MillisecondsToSeconds {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Milliseconds
    )
    # Convert milliseconds to seconds
    $Seconds = $Milliseconds / 1000
    return [math]::Round($Seconds, 2) # Rounded to 2 decimal places
}
Set-Alias -Name mstosec -Value Convert-MillisecondsToSeconds
#endregion
#==================================================================#
#region * Json Functions *
#==================================================================#
function Get-Json {
    <#
      .SYNOPSIS
        Reads a JSON file and converts to objects.
      .DESCRIPTION
        Loads the entire file as text and invokes ConvertFrom-Json.
      .PARAMETER Path
        Path to the .json file.
      .OUTPUTTYPE
        Deserialized JSON object (custom PS objects, arrays, primitives).
      .EXAMPLE
        $cfg = Get-Json -Path .\config.json
      .NOTES
        Throws if the file is missing or invalid JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Path
    )
    if (-not (Test-Path $Path)) {
        throw "JSON file not found: $Path"
    }
    Get-Content $Path -Raw | ConvertFrom-Json
}
function Save-Json {
    <#
      .SYNOPSIS
        Serializes an object as JSON and saves to a file.
      .DESCRIPTION
        Uses ConvertTo-Json with configurable depth and writes UTF8 text.
      .PARAMETER Object
        The object graph to serialize.
      .PARAMETER Path
        Destination file path.
      .PARAMETER Depth
        Maximum JSON depth (default 5).
      .EXAMPLE
        Save-Json -Object $cfg -Path .\config.json -Depth 10
      .NOTES
        Overwrites the file if it already exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object] $Object,
        [Parameter(Mandatory)][string] $Path,
        [int] $Depth = 5
    )
    $j = $Object | ConvertTo-Json -Depth $Depth
    $j | Set-Content -Path $Path -Encoding utf8
}
#endregion
#==================================================================#