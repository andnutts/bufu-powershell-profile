#==================================================================#
#============= Dynamic PowerShell Profile Script ==================#
#==================================================================#
# Set to $true for detailed timing, $false for summary only
$detailedTimes = $false
#$detailedTimes = $true
#==================================================================#
#region ----------- Timer Functions -------------------------------#
#==================================================================#
$global:__ProfileTimers = [ordered]@{}
$global:__ProfileLineWidth = 40 # Max width for lines

function Start-ProfileTimer($Name) {
    <#
      .SYNOPSIS
        Starts a new profile timer section.
      .DESCRIPTION
        This function initializes a timer for a specified section of the profile loading process.
        It records the start time and prepares to log the duration of the section.
      .PARAMETER Name
        The name of the profile timer section.
      .EXAMPLE
        Start-ProfileTimer "Module Loading"
        This example starts a timer for the "Module Loading" section.
    #>
    $global:__ProfileTimers[$Name] = [pscustomobject]@{
        Start = Get-Date
        End   = $null
        Total = $null
        Steps = @()
    }
    if ($detailedTimes -and $Name -ne 'Overall') { # Initial line for detailed timing
        $line = ("{0} " -f $Name).PadRight($global:__ProfileLineWidth, '-')
        Write-Host $line -ForegroundColor 'Yellow'
    }
}

function Stop-ProfileTimer($Name) {
    <#
      .SYNOPSIS
        Stops the profile timer section and logs the duration.
      .DESCRIPTION
        This function stops the timer for a specified section of the profile loading process.
        It calculates the total time taken and outputs the result to the console with appropriate formatting.
      .PARAMETER Name
        The name of the profile timer section to stop.
      .EXAMPLE
        Stop-ProfileTimer "Module Loading"
        This example stops the timer for the "Module Loading" section and logs the duration.
    #>
    $timer = $global:__ProfileTimers[$Name]
    if ($null -eq $timer) { return }

    $timer.End   = Get-Date
    $timer.Total = ($timer.End - $timer.Start).TotalMilliseconds
    $ms = [math]::Round($timer.Total)
    $msStr = "$($ms) ms"

    if ($detailedTimes -and $Name -ne 'Overall') { # Final line for detailed timing
        $line = (" Done in {0}" -f $msStr).PadLeft($global:__ProfileLineWidth, '-')
        Write-Host $line -ForegroundColor 'Yellow'
    } elseif (-not $detailedTimes -and $Name -ne 'Overall') { # Final line for summary only
        # Format as: "Section Name......... Done in 123 ms"
        $nameStr = "{0}.." -f $Name
        # Pad the name string to 25 chars. 25 + " Done in "(9) + "X ms"(~6) = 40
        $namePadded = $nameStr.PadRight(25, '.')
        
        Write-Host ("{0} Done in " -f $namePadded) -NoNewline
        Write-Host $msStr -ForegroundColor (Get-ColorFromMs -ms $ms)
    }
    # Do nothing if $Name is 'Overall', it has custom formatting at the end
}

function Step-ProfileTimer {
    <#
      .SYNOPSIS
        Measures the time taken to execute a script block as a step within a profile timer section.
      .DESCRIPTION
        This function executes a provided script block and measures the time taken to complete it.
        It logs the time taken for the step and, if detailed timing is enabled, outputs the duration
        to the console with appropriate formatting.
      .PARAMETER TimerName
        The name of the profile timer section to which this step belongs.
      .PARAMETER Section
        A descriptive name for the step being measured.
      .PARAMETER Step
        A script block containing the code to be executed and timed.
      .EXAMPLE
        Step-ProfileTimer "Module Loading" "Importing Module X" {
            Import-Module X
        }
        This example measures the time taken to import Module X as part of the "Module Loading" section.
      .NOTES
        Ensure that the `Step` parameter is provided as a script block (enclosed in curly braces `{}`).
    #>
    param(
        [string]$TimerName,
        [string]$Section,
        [scriptblock]$Step
    )

    if (-not ($Step -is [scriptblock])) {
        throw "Parameter `Step` must be a script block (e.g., enclosed in curly braces `{...}`)."
    }
    $start = Get-Date
    & $Step
    $end = Get-Date
    $ms = [math]::Round(($end - $start).TotalMilliseconds)
    $msStr = "Step took $ms ms"

    if ($detailedTimes) { # Detailed timing
        # Format as: ".... Step Name......... Step took 123 ms"
        # Pad Lift with 4 dots and space for alignment
        $nameStr = ".... {0}.." -f $Section
        # Pad the name string to 22 chars. 22 + " "(1) + "Step took X ms"(~17) = 40
        $namePadded = $nameStr.PadRight(22, '.')
        Write-Host ("{0} {1}" -f $namePadded, $msStr) -ForegroundColor DarkGray
    }

    $timer = $global:__ProfileTimers[$TimerName]
    if ($null -ne $timer -and $timer.PSObject.Properties.Name -contains 'Steps') {
        $timer.Steps += [pscustomobject]@{ Step=$Section; Time=$ms }
    }
}

#endregion
#==================================================================#
#region ----------- Helper Functions ------------------------------#
#==================================================================#
function Get-ColorFromMs {
    <#
      .SYNOPSIS
        Returns a console color based on the provided milliseconds value.
      .DESCRIPTION
        This function maps a given time in milliseconds to a corresponding console color.
        It uses predefined thresholds to determine the appropriate color for the time duration.
      .PARAMETER ms
        The time in milliseconds to evaluate.
      .PARAMETER Thresholds
        An optional hashtable defining custom thresholds and their associated colors.
        If not provided, default thresholds will be used.
      .EXAMPLE
        $color = Get-ColorFromMs -ms 150
        This example retrieves the console color for a duration of 150 milliseconds.
      .EXAMPLE
        $timerColor = Get-ColorFromMs -ms $ms
        This example retrieves the console color for the variable `$ms`.
      .EXAMPLE
        Write-Host $msStr -ForegroundColor (Get-ColorFromMs -ms $ms)
        This example writes the string `$msStr` to the host with a color based on the value of `$ms`.
    #>
    param(
      [double]$ms,
      [hashtable]$Thresholds = $null
    )
    if (-not $Thresholds) {
      $Thresholds = [ordered]@{
        25   = 'DarkGreen'
        50   = 'Green'
        75   = 'DarkCyan'
        100  = 'Cyan'
        150  = 'DarkYellow'
        200  = 'Yellow'
        300  = 'DarkMagenta'
        400  = 'Magenta'
        500  = 'Blue'
        650  = 'DarkBlue'
        800  = 'Gray'
        1000 = 'DarkGray'
        1500 = 'DarkRed'
        2000 = 'Red'
        [double]::PositiveInfinity = 'White'
      }
    }
    foreach ($limit in ($Thresholds.Keys | Sort-Object {[double]$_})) {
      if ($ms -le [double]$limit) { return $Thresholds[$limit] }
    }
}

function Import-IfAvailable {
    <#
      .SYNOPSIS
        Imports a PowerShell module if it is available.
      .DESCRIPTION
        This function checks if a specified PowerShell module is available on the system.
        If the module is found, it imports the module into the current session.
        The function returns $true if the module was successfully imported, and $false otherwise.
      .PARAMETER Name
        The name of the PowerShell module to import.
      .EXAMPLE
        $success = Import-IfAvailable -Name "Pester"
        This example attempts to import the "Pester" module and stores the result in the `$success` variable.
      .EXAMPLE
        Import-IfAvailable -Name "Az.Tools.Predictor"
        This example attempts to import the "Az.Tools.Predictor" module.
      .EXAMPLE
        if (Import-IfAvailable -Name "PSFzf") {
            Write-Host "PSFzf module imported successfully."
        } else {
            Write-Host "PSFzf module is not available."
        }
        This example checks if the "PSFzf" module is available and imports it if so, providing feedback to the user.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string] $Name
    )

    if (Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue) {
        Import-Module -Name $Name -ErrorAction Stop
        Write-Verbose "Imported module '$Name' : True"
        return    # no output to pipeline
    }

    Write-Verbose "Module '$Name' not available : False"
    return
}

function Write-Banner {
    <#
      .SYNOPSIS
        Writes a formatted banner to the console.
      .DESCRIPTION
        This function outputs a banner line to the console with specified text, surrounded by borders.
        The text and border colors can be customized using parameters.
      .PARAMETER Text
        The text to display in the banner.
      .PARAMETER ColorText
        The color of the text in the banner. Default is 'White'.
      .PARAMETER ColorBorder
        The color of the border in the banner. Default is 'DarkCyan'.
      .EXAMPLE
        Write-Banner -Text "Starting Profile Load"
        This example writes a banner with the text "Starting Profile Load" using default colors.
      .EXAMPLE
        Write-Banner -Text "Profile Loaded" -ColorText "Green" -ColorBorder "Red"
        This example writes a banner with custom text and colors.
    #>
    param(
        [Parameter(Mandatory)][string]$Text,
        [ConsoleColor]$ColorText   = 'White',
        [ConsoleColor]$ColorBorder = 'DarkCyan'
    )

    $lineWidth = 40
    $content = " $Text "

    $paddingTotal = $lineWidth - $content.Length
    if ($paddingTotal -lt 0) {
        # Truncate if too long
        $content = " " + $Text.Substring(0, $lineWidth - 5) + "... "
        $paddingTotal = $lineWidth - $content.Length
    }

    $padLeft  = [math]::Floor($paddingTotal / 2)
    $padRight = $paddingTotal - $padLeft

    $leftBorder  = "=" * $padLeft
    $rightBorder = "=" * $padRight

    Write-Host $leftBorder  -ForegroundColor $Global:ColorBorder -NoNewline
    Write-Host $content     -ForegroundColor $Global:ColorText   -NoNewline
    Write-Host $rightBorder -ForegroundColor $Global:ColorBorder
}

#endregion
#==================================================================#
#region ----------- Initialize Overall Timer ----------------------#
#==================================================================#
$ms = 0
$timerColor = "Green"

Start-ProfileTimer "Overall"

Write-Banner "Starting Profile Load"
#endregion
#==================================================================#
#region ------ Environment Variables  -----------------------------#
#==================================================================#
Start-ProfileTimer "Setting ENV: Variables"

# --- Get Powershell Version ---
$psMajor          = $PSVersionTable.PSVersion.Major
# --- Directory Paths ---
$logDir           = "C:\Logs"
$profileDir       = Split-Path $PROFILE -Parent
$sharedConfigs    = Join-Path (Split-Path $profileDir) -ChildPath "SharedConfigs"
$themeDir         = Join-Path $sharedConfigs 'Themes'
# --- File Paths ---
$myThemeFile      = Join-Path $themeDir 'mytheme.omp.json'
# --- FZF Options ---
$FZF_DEFAULT_OPTS = '--color=fg:-1,fg+:#ffffff,bg:-1,bg+:#3c4048 --color=hl:#5ea1ff,hl+:#5ef1ff,info:#ffbd5e,marker:#5eff6c --color=prompt:#ff5ef1,spinner:#bd5eff,pointer:#ff5ea0,header:#5eff6c --color=gutter:-1,border:#3c4048,scrollbar:#7b8496,label:#7b8496 --color=query:#ffffff --border="rounded" --border-label="" --preview-window="border-rounded" --height 40% --preview="bat -n --color=always {}"'

# --- Define Global Colors ---
$Global:ColorText     = 'Green'
$Global:ColorLabel    = 'Magenta'
$Global:ColorSubText  = 'DarkGrey'
$Global:ColorBorder   = 'Red'
$Global:ColorSpacer   = 'Yellow'
$Global:BorderGlyph   = '═'
$Global:SpacerGlyph   = '─'

# --- Ensure Global Colors are set ---
if (-not $Global:ColorText)     { $Global:ColorText     = 'Green' }
if (-not $Global:ColorLabel)    { $Global:ColorLabel    = 'Magenta' }
if (-not $Global:ColorSubText)  { $Global:ColorSubText  = 'DarkGrey' }
if (-not $Global:ColorBorder)   { $Global:ColorBorder   = 'Red' }
if (-not $Global:ColorSpacer)   { $Global:ColorSpacer   = 'Yellow' }
if (-not $Global:ColorDots)     { $Global:ColorDots     = 'DarkGray' }
if (-not $Global:BorderGlyph)   { $Global:BorderGlyph   = '═' }
if (-not $Global:SpacerGlyph)   { $Global:SpacerGlyph   = '─' }


Stop-ProfileTimer "Setting ENV: Variables"
#endregion
#==================================================================#
#region ------ Loading Custom Functions Aliases Helpers -----------#
#==================================================================#
Start-ProfileTimer "Source Funcs/Aliases"

#region ~~ Loading Custom Functionality ~~
$filesToLoad = @(
  @{ Name = 'Functions'; File = Join-Path -Path $sharedConfigs -ChildPath 'MyFunctions.ps1' }
  @{ Name = 'Aliases';   File = Join-Path -Path $sharedConfigs -ChildPath 'MyAliases.ps1' }
#  @{ Name = 'Helpers';   File = Join-Path -Path $sharedConfigs -ChildPath 'MyHelpers.ps1' }
)

foreach ($item in $filesToLoad) {
  Step-ProfileTimer "Custom Scripts" "Loading $($item.Name)" {
    $path = $item.File
    if (-not (Test-Path -Path $path)) {
      Write-Warning "File not found: '$path'"
      return
    }

    try {
      if ($item.Name -eq 'Aliases') {
        # Capture aliases before loading
        $before = Get-Alias | Select-Object -Property Name,Definition,Options

        # Dot-source the aliases file in the current session
        . $path

        # Capture aliases after loading
        $after = Get-Alias | Select-Object -Property Name,Definition,Options

        # Find newly defined aliases
        $new = $after | Where-Object { -not ($before.Name -contains $_.Name) }

        foreach ($a in $new) {
          if ($a.Options -and ($a.Options -contains 'AllScope')) {
            try {
              New-Alias -Name $a.Name -Value $a.Definition -Force
              Write-Verbose "Shadowed AllScope alias '$($a.Name)'"
            } catch {
              Write-Warning "Failed to shadow alias '$($a.Name)': $($_.Exception.Message)"
            }
          }
        }
      } else {
        # Normal dot-source for other files
        . $path
      }
    } catch {
      if ($_.Exception.Message -match 'AllScope') {
        Write-Verbose "Handled AllScope alias conflict while loading '$path'."
      } else {
        Write-Warning "Failed to load $($item.Name) from '$path': $($_.Exception.Message)"
      }
    }
  }
}
#endregion

Stop-ProfileTimer "Source Funcs/Aliases"
#endregion
#==================================================================#
#region ------ Importing Common Versioned and Predictor Modules ---#
#==================================================================#
Start-ProfileTimer "Importing Modules"

#region ~~ Modules arrys ~~
$customModules = @(
  'MyUtilities'
  'MenuFramework'
)
$commonModules = @(
  'PSScriptAnalyzer'
)
$versionModules = @(
  if ($psMajor -ge 7) {
    @(
      'PSFzf'
    #  'Microsoft.PowerShell.SecretManagement'
    )
  } else {
    @(
      'Pester'
    )
  }
)
$predictorModules = @('Az.Tools.Predictor', 'CompletionPredictor', 'PSCompletions')

$groups = @(
#  @{ Name   = 'Custom';     Message = 'Import Custom Modules....';        SingleSuccess = $false; Modules = { $customModules } }
  @{ Name   = 'Common';     Message = 'Import Common Modules....';        SingleSuccess = $false; Modules = { $commonModules } }
  @{ Name   = 'Versioned';  Message = "Import Vr $psMajor Modules......"; SingleSuccess = $false; Modules = { $versionModules } }
#  @{ Name   = 'Predictor';  Message = 'Importing Predictor......';        SingleSuccess = $true ; Modules = { $predictorModules } }
)
#endregion

#region ~~ Import Modules ~~
foreach ($group in $groups) {
    Step-ProfileTimer "Import Modules" "$($group.Name)" {
        # Write-Host $group.Message -NoNewline

        $moduleList = & $group.Modules

        $importedOne = $false
        foreach ($module in $moduleList) {
          try {
            $ok = Import-IfAvailable -Name $module
            if ($ok) {
              $importedOne = $true
              if ($group.SingleSuccess) {
                Write-Verbose "Successfully loaded module (single success): '$module'"
                break
              } else {
                Write-Verbose "Successfully loaded module: '$module'"
              }
            } else {
              Write-Verbose "Module not available: '$module'"
            }
          } catch {
            Write-Warning "Failed to import '$module' : $($_.Exception.Message)"
            Write-Verbose "Import error for '$module': $($_.Exception.Message)"
          }
        }

        if ($group.SingleSuccess -and -not $importedOne) {
          Write-Verbose "No predictor module was successfully loaded."
        }
    }
}
#endregion

Stop-ProfileTimer "Importing Modules"
#endregion
#==================================================================#
#region ------ PSReadLine Initialization (timed pieces) -----------#
#==================================================================#
Start-ProfileTimer "PSReadLine Setup"

#region --- Feature detection ---
Step-ProfileTimer "PSReadLine" "Feature Detection" {
  $script:psrlCmd = Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue
  $script:psrlKeyCmd = Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue
  $script:supported = @()
  if ($script:psrlCmd) { $script:supported = $script:psrlCmd.Parameters.Keys }
  $script:psMajor = [int]$PSVersionTable.PSVersion.Major
}
#endregion

#region --- Piece 2: Build safe options hashtable ---
Step-ProfileTimer "PSReadLine" "Build Options" {
  function Use-SafeColor {
      param($name, $fallback='Gray')
      if ($name -and ($name -is [string])) { return $name }
      return $fallback
  }
  $safeColors = @{
    Command          = Use-SafeColor 'Yellow'
    Parameter        = Use-SafeColor 'Cyan'
    String           = Use-SafeColor 'Magenta'
    Comment          = Use-SafeColor 'Green'
    InlinePrediction = Use-SafeColor 'DarkGray'
    Error            = Use-SafeColor 'Red'
  }
  $script:psrlOptions = @{}
  if ($script:supported -contains 'EditMode')            { $script:psrlOptions.EditMode            = 'Windows' }
  if ($script:supported -contains 'MaximumHistoryCount') { $script:psrlOptions.MaximumHistoryCount = 4096 }
  if ($script:supported -contains 'HistorySaveStyle')    { $script:psrlOptions.HistorySaveStyle    = 'SaveIncrementally' }
  if ($script:supported -contains 'AddToHistoryHandler') {
    $script:psrlOptions.AddToHistoryHandler = {
      param($line)
      if (-not $line) { return $false }
      if ($line.StartsWith('Get-PSReadLineOption')) { return $false }
      return $true
    }
  }
  if ($script:supported -contains 'Colors') { $script:psrlOptions.Colors = $safeColors }
  if ($script:psMajor -ge 7) {
    if ($script:supported -contains 'PredictionSource')    { $script:psrlOptions.PredictionSource    = 'HistoryAndPlugin' }
    if ($script:supported -contains 'PredictionViewStyle'){ $script:psrlOptions.PredictionViewStyle = 'ListView' }
  }
}
#endregion

#region --- Piece 3: Apply options (if supported) ---
Step-ProfileTimer "PSReadLine" "Apply Options" {
  if ($script:psrlCmd) {
    try {
      Set-PSReadLineOption @script:psrlOptions
    } catch {
      Write-Verbose "Set-PSReadLineOption failed: $($_.Exception.Message)"
    }
  }
}
#endregion

#region --- Piece 4: Register key handlers (if supported) ---
Step-ProfileTimer "PSReadLine" "Register Keys" {
  if ($script:psrlKeyCmd) {
    $psrlKeyHandlers = @(
      @{ Key = 'Tab';             Function     = 'MenuComplete' }
      @{ Key = 'Ctrl+R';          Function     = 'ReverseSearchHistory' }
      @{ Key = 'Ctrl+L';          Function     = 'ClearScreen' }
      @{ Key = 'Ctrl+N';          Function     = 'MenuComplete' }
      @{ Key = 'Ctrl+LeftArrow';  Function     = 'BackwardWord' }
      @{ Key = 'Ctrl+RightArrow'; Function     = 'ForwardWord' }
      @{ Key = 'Shift+Tab';       ScriptBlock  = { Invoke-FzfTabCompletion } }
      @{ Key = 'Alt+d';           ScriptBlock  = { Invoke-SetFuzzyDirectory } }
      @{ Key = 'F10';             ScriptBlock  = { Show-HelpMenu }; BriefDescription = 'Custom Function' }
    )
    foreach ($handler in $psrlKeyHandlers) {
      try { Set-PSReadLineKeyHandler @handler } catch { Write-Verbose "Key handler failed for $($handler.Key): $($_.Exception.Message)" }
    }
  }
}
#endregion

Stop-ProfileTimer "PSReadLine Setup"
#endregion
#==================================================================#
#region ------ FzfMenu function -----------------------------------#
#==================================================================#
Start-ProfileTimer "PSFzf Setup"

#region -- Dot-source Functons Show-FzfHelpMenu --
$helperFile = Join-Path $sharedConfigs 'Show-EnvVariables.ps1'
if (Test-Path $helperFile) { . $helperFile }
#endregion

#region --- PSFzf settings ---
if ((Get-Module -Name 'PSFzf' -ErrorAction SilentlyContinue) -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Set-PsFzfOption -TabExpansion
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
} else {
    Write-Verbose "PSFzf not imported, skipping configuration."
}
#endregion

Stop-ProfileTimer "PSFzf Setup"
#endregion
#==================================================================#
#region ------ Prompt Customization (oh-my-posh) ----------------- #
#==================================================================#
Start-ProfileTimer "Integrating oh-my-posh"

#region --- Configuring oh-my-posh ---
# Import Posh-Git before initializing oh-my-posh for git status integration
Import-Module -Name Posh-Git -ErrorAction SilentlyContinue

# Only initialize oh-my-posh when in an interactive terminal session
if ($Host.Name -eq 'ConsoleHost' -or $Host.Name -eq 'WindowsTerminal') {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        # Define the path to your theme
        $ompConfig = $myThemeFile

        # Ensure the theme file exists, create a default one if it doesn't
        if (-not (Test-Path $ompConfig)) {
            Write-Verbose "Theme file not found at '$ompConfig', creating a default one."
            $themeDir = Split-Path $ompConfig -Parent
            if (-not (Test-Path $themeDir)) {
                New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
            }
            @"
{
  "final_space": true,
  "blocks": [
    { "type": "prompt", "alignment": "left",
      "segments": [
        { "type": "path", "style": "powerline", "foreground": "#FFFFFF", "background": "#007ACC" },
        { "type": "git",  "style": "plain",     "foreground": "#FFCC00", "properties": { "fetch_status": true } }
      ]
    }
  ]
}
"@ | Set-Content -Encoding UTF8 -Path $ompConfig
        }

        # Initialize oh-my-posh using the recommended method
        oh-my-posh init pwsh --config "$ompConfig" | Invoke-Expression

    } else {
        Write-Warning "oh-my-posh command not found. You will get a default prompt."
        function global:prompt {
            "PS $(Get-Location)> "
        }
    }
}
#endregion

Stop-ProfileTimer "Integrating oh-my-posh"
#endregion
#==================================================================#
#region ----------- Overall Timer ---------------------------------#
#==================================================================#
Stop-ProfileTimer "Overall"
$overallTimer = $global:__ProfileTimers["Overall"]
if ($null -ne $overallTimer) {
    $overallTimer.End   = Get-Date
    $overallTimer.Total = ($overallTimer.End - $overallTimer.Start).TotalMilliseconds
} else {
    Write-Warning "Overall timer not found."
    return
}
$ms = [math]::Round($overallTimer.Total)
$timerColor = Get-ColorFromMs -ms $ms
Write-Banner -Text "Profile Loaded in $ms ms"
#endregion
#==================================================================#
#\\ https://vitormv.github.io/fzf-themes#eyJib3JkZXJTdHlsZSI6InJvdW5kZWQiLCJib3JkZXJMYWJlbCI6IkhlbGxvIiwiYm9yZGVyTGFiZWxQb3NpdGlvbiI6MCwicHJldmlld0JvcmRlclN0eWxlIjoidGhpbmJsb2NrIiwicGFkZGluZyI6IjAiLCJtYXJnaW4iOiIwIiwicHJvbXB0IjoiPiAiLCJtYXJrZXIiOiI+IiwicG9pbnRlciI6IuKXhiIsInNlcGFyYXRvciI6IuKUgCIsInNjcm9sbGJhciI6InwiLCJsYXlvdXQiOiJkZWZhdWx0IiwiaW5mbyI6ImRlZmF1bHQiLCJjb2xvcnMiOiJmZzojZDBkMGQwLGZnKzojZDBkMGQwLGJnOiMxMjEyMTIsYmcrOiMyNjI2MjYsaGw6IzI0ZmZhYixobCs6IzVmZDdmZixpbmZvOiMwMGM2ZTAsbWFya2VyOiM4N2ZmMDAscHJvbXB0OiM3YTAwNTEsc3Bpbm5lcjojYWY1ZmZmLHBvaW50ZXI6I2FmNWZmZixoZWFkZXI6Izg3YWZhZixndXR0ZXI6IzUyMDAwMCxib3JkZXI6IzQ1MDFiMixzZXBhcmF0b3I6IzY4Y2Q0YyxwcmV2aWV3LWJvcmRlcjojY2YwMjFhLHByZXZpZXctc2Nyb2xsYmFyOiMwMDBhYzcsbGFiZWw6I2ZmMDAwMCxxdWVyeTojZmYwMDAwIn0=

#export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
#  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626
#  --color=hl:#24ffab,hl+:#5fd7ff,info:#00c6e0,marker:#87ff00
#  --color=prompt:#7a0051,spinner:#af5fff,pointer:#af5fff,header:#87afaf
#  --color=gutter:#520000,border:#4501b2,separator:#68cd4c,preview-border:#cf021a
#  --color=preview-scrollbar:#000ac7,label:#ff0000,query:#ff0000
#  --border="rounded" --border-label="Hello" --border-label-pos="0" --preview-window="border-thinblock"
#  --prompt="> " --marker=">" --pointer="◆" --separator="─"
#  --scrollbar="|"'
