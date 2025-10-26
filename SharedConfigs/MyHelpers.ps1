function Show-JsonHelpMenu {
    <#
    .SYNOPSIS
        Displays an interactive help menu for PowerShell commands and functions.
    .DESCRIPTION
        This function provides a user-friendly interface to access various PowerShell commands,
        aliases, and other useful information. It supports selection via PSFzf, fzf, or Out-GridView
    .PARAMETER Key
        The key to trigger the help menu. Defaults to F10.
    .EXAMPLE
        Show-JsonHelpMenu
        Opens an interactive help menu where you can select commands to view their details.
    .EXAMPLE
        Show-JsonHelpMenu -Key F10
        Opens the help menu when the F10 key is pressed.
    #>
    Write-Host "Loading interactive JSON help menu..." -ForegroundColor Yellow
    $helpItems = @(
        [PSCustomObject]@{ Name = 'List All Cmdlets'
                         Action = { Get-Command | Sort-Object Name | ConvertTo-Json -Compress | Out-String } },
        [PSCustomObject]@{ Name = 'Show Aliases'
                         Action = { Get-Alias | Sort-Object Name | ConvertTo-Json -Compress | Out-String } },
        [PSCustomObject]@{ Name = 'PSReadLine Key Handlers'
                         Action = { Get-PSReadLineKeyHandler | ConvertTo-Json -Compress | Out-String } },
        [PSCustomObject]@{ Name = 'Profile Location'
                         Action = { $PROFILE | ConvertTo-Json -Compress | Out-String } },
        [PSCustomObject]@{ Name = 'List Environment Variables'
                         Action = { Get-ChildItem Env: | Sort-Object Name | ConvertTo-Json -Compress | Out-String } },
        [PSCustomObject]@{ Name = 'List Running Processes'
                         Action = { Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 | ConvertTo-Json -Compress | Out-String } },
        [PSCustomObject]@{ Name = 'List Windows Services'
                         Action = { Get-Service | Sort-Object Status,Name | ConvertTo-Json -Compress | Out-String } },
        [PSCustomObject]@{ Name = 'Exit Help'
                         Action = { return } }
    )
    $selection = $null
    # Try PSFzf first
    try {
        Import-Module -Name PSFzf -ErrorAction Stop
        $selection = $helpItems | ForEach-Object { "$($_.Name)" } | PSFzf --prompt "Help Menu> " --no-multi --no-hscroll
    }
    catch {
        Write-Warning "PSFzf not found. Attempting to use fzf..."
        try {
            # Make sure fzf.exe is in the path. This assumes Scoop installed it.
            $fzfPath = (Get-Command fzf).Path
            $selection = $helpItems | ForEach-Object { "$($_.Name)" } | & $fzfPath --prompt "Help Menu> " --no-multi --no-hscroll
        }
        catch {
            # If fzf isn't available, use Out-GridView
            Write-Warning "Neither PSFzf nor fzf found. Using Out-GridView."
            $selection = $helpItems | Out-GridView -Title "Help Menu" -OutputMode Single
            if (-not $selection) {
                return
            }
        }
    }
    if ($null -ne $selection) {
        $selectedFunction = $helpItems | Where-Object { $_.Name -eq $selection } | Select-Object -First 1
        if ($null -ne $selectedFunction) {
            Write-Host "Executing action for: $($selectedFunction.Name)" -ForegroundColor Green
            Clear-Host  # Clear the screen before executing
            try {
                Invoke-Command -ScriptBlock $selectedFunction.Action
            }
            catch {
                Write-Host "Error executing $($selectedFunction.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No function selected." -ForegroundColor Yellow
    }
}
function Show-MenuHelp {
    param()
    $scriptFolder = "C:\Scripts"
    $menuItems = @(
        [PSCustomObject]@{ Key = '1'; Name = 'List All Cmdlets';      Action = { Get-Command | Sort-Object Name | fzf --no-hscroll } }
        [PSCustomObject]@{ Key = '2'; Name = 'Show Aliases';          Action = { Get-Alias | Sort-Object Name | Format-Table } }
        [PSCustomObject]@{ Key = '3'; Name = 'PSReadLine Key Handlers'; Action = { Get-PSReadLineKeyHandler | Format-Table } }
        [PSCustomObject]@{ Key = '4'; Name = 'Profile Location';      Action = { "Your profile path:`n$($profile)" } }
        [PSCustomObject]@{ Key = '5'; Name = 'List Environment Variables';  Action = { Get-ChildItem Env: | Sort-Object Name | Format-Table -AutoSize } }
        [PSCustomObject]@{ Key = '6'; Name = 'List Running Processes';       Action = { Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 | Format-Table -AutoSize } }
        [PSCustomObject]@{ Key = '7'; Name = 'List Windows Services';        Action = { Get-Service | Sort-Object Status,Name | Format-Table -AutoSize } }
        [PSCustomObject]@{ Key = '8'; Name = 'Dynamic Module Loader';        Action = {
            if (-not (Test-Path $scriptFolder)) { Write-Error "Folder not found: $scriptFolder"; return; }
            # Let user pick a .ps1 file
            $script = Get-ChildItem -Path $scriptFolder -Filter '*.ps1' -File |
                      Select-Object -ExpandProperty FullName | fzf --prompt 'Select Script> ' --no-multi
            if (-not $script) { return }
            # Dot-source and invoke matching function
            . $script
            $fn = [IO.Path]::GetFileNameWithoutExtension($script)
            if (Get-Command $fn -ErrorAction SilentlyContinue) {
                & $fn
            } else {
                Write-Output "Script loaded: $script"
            }
        } }
        [PSCustomObject]@{ Key = '9'; Name = 'Exit Help';                    Action = { return } }
    )
    # Prepare the display list
    $choices = $menuItems | ForEach-Object {
        "{0} → {1}" -f $_.Key, $_.Name
    }
    # Launch fuzzy finder
    $selection = $choices | fzf --prompt "Help Menu> " --no-multi --no-hscroll
    if (-not $selection) {
        return
    }
    # Extract the key and execute associated action
    $key = ($selection -split '→')[0].Trim()
    $menuItems | Where-Object Key -eq $key | ForEach-Object { & $_.Action }
}
function Show-HelpMenu {
    <#
      .SYNOPSIS
          Displays an interactive menu of custom profile functions.
      .DESCRIPTION
          This function creates a menu of all functions defined in the user's profile
          and allows the user to select and execute them interactively. It prioritizes
          using `PSFzf` or `fzf` for a fuzzy-finder experience, falling back to
          `Out-GridView` if those tools are not found.
      .EXAMPLE
          Show-HelpMenu
          Displays an interactive menu and executes the selected function.
    #>
  Write-Host "Loading interactive help menu..." -ForegroundColor Yellow
    $profileDir = Split-Path -Path $PROFILE

    $functions = Get-ChildItem -Path Function: | Where-Object {
        $_.ScriptBlock.File -and ($_.ScriptBlock.File -like "$profileDir*") -and $_.Name -notmatch "(__.*|prompt|Microsoft|TabExpansion|Out|Format|Write)"
    }

    $helpItems = $functions | ForEach-Object {
        $help = Get-Help -Name $_.Name
        [PSCustomObject]@{
            Name = $_.Name
            # Synopsis = $help.Synopsis # Removed to avoid encoding issues
            Action = { & $_.Name }
        }
    } | Sort-Object Name

    $selection = $null

    # Try PSFzf first
    try {
        Import-Module -Name PSFzf -ErrorAction Stop
        $selection = $helpItems | ForEach-Object { "$($_.Name)" } | PSFzf --prompt "Help Menu> " --no-multi --no-hscroll
        # $selection = $helpItems | ForEach-Object { "$($_.Name) → $($_.Synopsis)" } | PSFzf --prompt "Help Menu> " --no-multi --no-hscroll
    }
    catch {
        # If PSFzf isn't available, try fzf
        try {
            # Make sure fzf.exe is in the path. This assumes Scoop installed it.
            $fzfPath = (Get-Command fzf).Path
            $selection = $helpItems | ForEach-Object { "$($_.Name)" } | & $fzfPath --prompt "Help Menu> " --no-multi --no-hscroll
            # $selection = $helpItems | ForEach-Object { "$($_.Name) → $($_.Synopsis)" } | & $fzfPath --prompt "Help Menu> " --no-multi --no-hscroll
        }
        catch {
            # If fzf isn't available, use Out-GridView
            Write-Warning "Neither PSFzf nor fzf found. Using Out-GridView."
            $selection = $helpItems | Out-GridView -Title "Help Menu" -OutputMode Single
            if (-not $selection) {
                return
            }
        }
    }

    if ($null -ne $selection) {
        $selectedName = $selection.Trim()  # Use the selected name directly
        $selectedFunction = $helpItems | Where-Object { $_.Name -eq $selectedName } | Select-Object -First 1

        if ($null -ne $selectedFunction) {
            Write-Host "Executing function: $($selectedFunction.Name)" -ForegroundColor Green
            try {
                & $selectedName # Execute directly
            }
            catch {
                Write-Host "Error executing function $($selectedFunction.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Selected function not found: $selectedName" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No function selected." -ForegroundColor Yellow
    }
}
function Show-Help {
    Write-Host ""
    Write-Host "================ Dynamic Profile Help Menu ================" -ForegroundColor Cyan

    # 1. Dynamic Key Bindings (Checks for custom overrides and descriptions)
    Write-Host ""
    Write-Host " Key Bindings (Alt/Ctrl/Shift overrides):" -ForegroundColor Yellow
    
    # Define keys we explicitly set in profile.ps1 to show the custom ones
    $customKeys = @('Shift+Tab', 'Alt+d', 'F10', 'Ctrl+R', 'Ctrl+L', 'Ctrl+N', 'Ctrl+LeftArrow', 'Ctrl+RightArrow', 'Tab')
    
    # Retrieve and format custom key handlers
    Get-PSReadLineKeyHandler | 
        Where-Object { $_.Key -in $customKeys } |
        Sort-Object Key |
        ForEach-Object {
            $desc = $_.BriefDescription
            if (-not $desc) {
                # Provide descriptive names for known custom script blocks and functions
                switch ($_.Key) {
                    'Shift+Tab'  { $desc = "Invoke-FzfTabCompletion (Requires PSFzf)" }
                    'Alt+d'      { $desc = "Invoke-SetFuzzyDirectory (Fuzzy CD via ZLocation)" }
                    'F10'        { $desc = "Show this menu" }
                    'Ctrl+R'     { $desc = "Reverse History Search" }
                    'Ctrl+L'     { $desc = "Clear Screen" }
                    'Tab'        { $desc = "Menu Complete (Default PowerShell completion)" }
                    default      { $desc = "Built-in function: $($_.Function)" }
                }
            }
            Write-Host "   $('{0,-12}' -f ($_.Key + ':')) $desc" -ForegroundColor Green
        }
    
    # 2. Custom Aliases (Checks for the specific aliases defined in MyAliases.ps1)
    Write-Host ""
    Write-Host " Custom Aliases (from MyAliases.ps1):" -ForegroundColor Yellow
    
    $aliasNames = @('l', 'll', 'g', 'profile.edit', 'notes')
    $aliasNames | ForEach-Object {
        $alias = Get-Alias -Name $_ -ErrorAction SilentlyContinue
        if ($alias) {
            Write-Host "   $('{0,-12}' -f ($alias.Name + ':')) $($alias.Definition)" -ForegroundColor Green
        }
    }

    # 3. Loaded Utility Modules (Checks if the module is actually loaded)
    Write-Host ""
    Write-Host " Utility Modules Status:" -ForegroundColor Yellow
    
    $modulesToCheck = @(
        @{ Name = 'Posh-Git'; 			Description = 'Git status in prompt' },
        @{ Name = 'ZLocation'; 			Description = 'Jump to frequent directories' },
        @{ Name = 'Terminal-Icons'; Description = 'Icons next to files/folders' },
        @{ Name = 'PowerColorLS'; 	Description = 'Colorizes ls/dir output' },
        @{ Name = 'PSFzf'; 					Description = 'Fuzzy search commands and history' },
        @{ Name = 'MenuFramework'; 	Description = 'Custom menu framework support' },
        @{ Name = 'MyUtilities'; 		Description = 'Your custom utility module' }
    )
    
    $modulesToCheck | ForEach-Object {
        $module = Get-Module -Name $_.Name -ErrorAction SilentlyContinue
        $color = if ($module) { 'Green' } else { 'DarkYellow' }
        $status = if ($module) { '[LOADED]' } else { '[MISSING]' }
        
        Write-Host "   $('{0,-15}' -f ($_.Name + ':')) $($_.Description) $status" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Cyan
}
function Invoke-SetFuzzyDirectory {
		<#
			.SYNOPSIS
				Opens a fuzzy finder interface (fzf) to quickly change directories.
			.DESCRIPTION
				This function is bound to the 'Alt+d' key handler in the profile. It aggregates 
				directories from two sources: highly-ranked paths from the ZLocation module 
				(if installed) and recent directories found recursively under the user's home path.
				It pipes this combined list to the 'fzf' tool, allowing the user to fuzzy-search 
				and select a directory, then changes the current location (Set-Location).
			.NOTES
				Requires the 'fzf' executable to be installed and available in the system PATH.
				Leverages the 'ZLocation' module if it is imported to provide intelligent 
				ranking of frequently used paths.
		#>
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning "fzf executable not found. Cannot run fuzzy directory picker."
        return
    }
    
    $searchPaths = @()
    
    # 1. Add ZLocation history (frequent paths)
    if (Get-Command Get-ZLocation -ErrorAction SilentlyContinue) {
        Write-Verbose "Adding paths from ZLocation history."
        # Select the Path and sort by ZScore (reverse for fzf preference)
        $searchPaths += Get-ZLocation | 
                        Sort-Object -Property ZScore -Descending |
                        Select-Object -ExpandProperty Path
    }

    # 2. Add local search paths (recursive search in Home)
    Write-Verbose "Adding recent/local paths."
    $searchPaths += Get-ChildItem -Path "$HOME" -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue | 
                     Select-Object -ExpandProperty FullName 

    # Filter for unique directories and pipe to fzf
    $selectedDir = $searchPaths | 
                   Select-Object -Unique | 
                   Sort-Object |
                   fzf --reverse --header "Fuzzy Directory Change (Alt+d - Z/Local)"

    if ($selectedDir) {
        Set-Location $selectedDir
        # Optional: Use z if ZLocation is loaded to update score
        if (Get-Command z -ErrorAction SilentlyContinue) {
             z $selectedDir | Out-Null
        }
    }
}
function Invoke-FzfTabCompletion {
		<#
			.SYNOPSIS
				Invokes the PSFzf module's tab completion feature.
			.DESCRIPTION
				This function is primarily used as a PSReadLine key handler (Shift+Tab)
				to enable fuzzy tab completion for commands, parameters, and paths 
				via the 'PSFzf' module. It acts as a wrapper, ensuring the original
				PSFzf function is only called if the module is loaded.
			.NOTES
				Requires the 'PSFzf' module to be imported. If the module is not found,
				a warning is displayed, and the completion is skipped.
		#>
    if (Get-Module -Name PSFzf -ErrorAction SilentlyContinue) {
        # This will call the function provided by PSFzf
        Invoke-Command -ScriptBlock { Invoke-FzfTabCompletion }
    } else {
        Write-Warning "PSFzf module is not loaded. Tab completion binding skipped."
    }
}