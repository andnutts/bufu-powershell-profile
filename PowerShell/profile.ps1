#==================================================================#
#------------------ CurrentUserAllHosts ---------------------------#
#==================================================================#
$ErrorActionPreference = 'Stop'
#==================================================================#
#region ------ Environment Variables  -----------------------------#
#==================================================================#
$psMajor = $PSVersionTable.PSVersion.Major
$themeDir = "$HOME\Documents\SharedConfigs\Themes"
$sharedConfigs = "$HOME\Documents\SharedConfigs"
$ENV:LOG_DIR = "C:\Logs"
$ENV:FZF_DEFAULT_OPTS = '--color=fg:-1,fg+:#ffffff,bg:-1,bg+:#3c4048 --color=hl:#5ea1ff,hl+:#5ef1ff,info:#ffbd5e,marker:#5eff6c --color=prompt:#ff5ef1,spinner:#bd5eff,pointer:#ff5ea0,header:#5eff6c --color=gutter:-1,border:#3c4048,scrollbar:#7b8496,label:#7b8496 --color=query:#ffffff --border="rounded" --border-label="" --preview-window="border-rounded" --height 40% --preview="bat -n --color=always {}"'
# $ENV:WindotsLocalRepo = Find-WindotsRepository -ProfilePath $PSScriptRoot
# $ENV:STARSHIP_CONFIG = "$ENV:WindotsLocalRepo\starship\starship.toml"
# $ENV:_ZO_DATA_DIR = $ENV:WindotsLocalRepo
# $ENV:OBSIDIAN_PATH = "$HOME\git\obsidian-vault"
# $ENV:BAT_CONFIG_DIR = "$ENV:WindotsLocalRepo\bat"

#endregion
#==================================================================#
#region ------ Functions ------------------------------------------#
#==================================================================#
function Import-IfAvailable {
    param([string]$Name)
    if (Get-Module -ListAvailable $Name) {
        Import-Module $Name -ErrorAction SilentlyContinue
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
function Ensure-PSReadLine {
    param(
        [ValidateSet('Preview','Stable')]
        [string]$Channel = 'Preview',
        [bool]$SkipOnline = $false
    )

    $loaded = Get-Module PSReadLine
    if ($loaded -and $Channel -eq 'Stable') { return $loaded }

    $hasGallery = [bool](Get-Command Find-Module -ErrorAction SilentlyContinue)
    $installed = @()
    try {
        $installed = Get-InstalledModule PSReadLine -AllowPrerelease -ErrorAction SilentlyContinue
    } catch { }

    $isPreview = { param($v) ($v -as [string]) -match '-' }
    $pickCandidate = {
        param($channel, $mods)
        if ($channel -eq 'Preview') {
            $mods | Where-Object { & $isPreview $_.Version } |
                Sort-Object Version -Descending | Select-Object -First 1
        } else {
            $mods | Where-Object { -not (& $isPreview $_.Version) } |
                Sort-Object Version -Descending | Select-Object -First 1
        }
    }

    $candidate = & $pickCandidate $Channel $installed

    if (-not $candidate -and $Channel -eq 'Preview' -and $hasGallery -and -not $SkipOnline) {
        try {
            Install-Module PSReadLine -AllowPrerelease -Force -Scope CurrentUser -ErrorAction Stop
            $installed = Get-InstalledModule PSReadLine -AllowPrerelease -ErrorAction SilentlyContinue
            $candidate = & $pickCandidate $Channel $installed
        } catch {
            Write-Verbose "Failed to install PSReadLine preview: $($_.Exception.Message)"
        }
    }

    try {
        if ($candidate) {
            $psd1 = Join-Path $candidate.InstalledLocation 'PSReadLine.psd1'
            if (Test-Path $psd1) {
                if ($loaded) { Remove-Module PSReadLine -Force -ErrorAction SilentlyContinue }
                return Import-Module $psd1 -PassThru
            }
        }
        if (-not (Get-Module PSReadLine)) {
            return Import-Module PSReadLine -PassThru
        } else {
            return Get-Module PSReadLine
        }
    } catch {
        Write-Warning "PSReadLine import failed: $($_.Exception.Message)"
        throw
    }
}
$psrlModule = Ensure-PSReadLine
#endregion
#==================================================================#
#region ------ Aliases --------------------------------------------#
#==================================================================#
Set-Alias ll Get-ChildItem
Set-Alias note notepad.exe
#endregion
#==================================================================#
#region ------ Load Modules ---------------------------------------#
#==================================================================#
$commonmodules = @(
    'PSScriptAnalyzer'
    'ZLocation'
    'PowerColorLS'
    'Terminal-Icons'
)
if ($psMajor -ge 7) {
    $versionModules = @(
        'PSFzf'
        'Microsoft.PowerShell.SecretManagement'
    )
} else {
  $versionModules = @(
        #'Posh-Git'
        'Pester'
  )
}
$modulesToImport = $commonmodules + $versionModules
foreach ($module in $modulesToImport) {
    try   { Import-IfAvailable -Name $module }
    catch { Write-Warning "Failed to import '$module' : $($_.Exception.Message)" }
}
#endregion
#==================================================================#
#region ------ Predictors -----------------------------------------#
#==================================================================#
$predictorModules = @(
    'Az.Tools.Predictor'
    'CompletionPredictor'
    'PSCompletions'
)
$importedPredictor = $false
foreach ($module in $predictorModules) {
    if ($importedPredictor) { break }

    try {
        $ok = Import-IfAvailable -Name $module

        if ($ok) {
            $importedPredictor = $true
            Write-Verbose "Successfully loaded predictor module: '$module'"
            break
        }
        else {
            Write-Verbose "Predictor module not available: '$module'"
        }
    }
    catch {
        Write-Verbose "Failed to import predictor module '$module': $($_.Exception.Message)"
    }
}
if (-not $importedPredictor) {
    Write-Verbose "No predictor module was successfully loaded."
}
#endregion
#==================================================================#

#==================================================================#
# Examples 
#$env:DevServerUrl = "https://dev.myapp.internal"
#$env:MapboxToken = "pk_1234abcd" 
# Invoke-RestMethod "$env:DevServerUrl/healthcheck"
# oh-my-posh init pwsh --config ~/jandedobbeleer.omp.json | Invoke-Expression
#==================================================================#