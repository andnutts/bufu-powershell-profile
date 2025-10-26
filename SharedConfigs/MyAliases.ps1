# MyAliases.ps1
# This script defines aliases and binds keys for quick access to functions.
#==================================================================#
Set-Alias -Name galias 	-Value Get-CmdletAlias 															-Description "Finds aliases pointing to a specific cmdlet."
Set-Alias -Name a       -Value Get-Alias 																					-Description "Get Aliases"
Set-Alias -Name touch   -Value New-Item 																						-Description "New Item"
#Set-Alias -Name mv      -Value Move-Item                      -Description "Move items"
#Set-Alias -Name rm      -Value Remove-Item                    -Description "Remove items"
Set-Alias -Name gdir    -Value Get-MemberInfo 																-Description "Get Member Info"
Set-Alias -Name cat     -Value Get-Content  -Option AllScope 	-Description "Display file content"
Set-Alias -Name grep    -Value findstr                        -Description "Select String"
# --- Listing Files & Directories Aliases ---
Set-Alias -Name l 			   -Value Get-ChildItem 																	-Description "Short list format"
Set-Alias -Name ls      -Value PowerColorLS -Option AllScope
Set-Alias -Name ll      -Value 'ls -a'      -Option AllScope  -Description "List items"
# --- Help Menu Aliases ---
Set-Alias -Name help    -Value Show-HelpMenu
Set-Alias -Name helpj   -Value Show-JsonHelpMenu
# --- Fuzzy Aliases ---
Set-Alias -Name ife     -Value Invoke-FuzzyEdit
Set-Alias -Name ifs     -Value Invoke-FuzzyScoop
Set-Alias -Name ifh     -Value Invoke-FuzzyHistory
Set-Alias -Name ifg     -Value Invoke-FuzzyGitStatus
Set-Alias -Name ifk     -Value Invoke-FuzzyKillProcess
Set-Alias -Name ifd     -Value Invoke-SetFuzzyDirectory
Set-Alias -Name cch     -Value Clear-CommandHistory
#Set-Alias -Name grep    -Value Select-String                  -Description "Select String"
# Set-Alias -Name touch   -Value New-Item
# --- Process management aliases ---
Set-Alias -Name ps      -Value Get-Process                  	 -Description "Show Processes"
Set-Alias -Name kill    -Value Stop-Process                 	 -Description "Stop Process"
# --- Service management aliases ---
Set-Alias -Name gs      -Value Get-Service                  	 -Description "Get service"
# --- Module management aliases ---
Set-Alias -Name rlmd    -Value Reload-Module                  -Description "Reload Module"
Set-Alias -Name imd     -Value Import-Module                	 -Description "Import Module"
Set-Alias -Name lmd     -Value Get-Module                   	 -Description "List Module"
Set-Alias -Name rmd     -Value Remove-Module                	 -Description "Remove Module"
# --- Git Aliases ---
Set-Alias -Name g       -Value git                            -Description "Run git"
# --- Custom Aliases ---
Set-Alias -Name version -Value "$PSVersionTable"            	 -Description "Powershell Version"
# --- Network aliases ---
Set-Alias -Name tn      -Value Test-NetConnection           	 -Description "Test Network Connection"
Set-Alias -Name pubip   -Value Get-PubIP                    	 -Description "Get public IP address"
# --- Event Log Aliases ---
Set-Alias -Name glog    -Value Get-SystemLogEvent 												-Description "Get last 50 system events (via Get-SystemLogEvent)"
Set-Alias	-Name alog    -Value Get-ApplicationLogEvent 								-Description "Get last 50 application events (via Get-ApplicationLogEvent)"
# --- Editor/Tools ---
Set-Alias -Name profile.edit -Value 'code $PROFILE'                  -Description "Open the current profile in VS Code"
Set-Alias -Name notes 							-Value 'code "$HOME\Documents\Notes" '  -Description "Open my notes directory"
# --- Directory navigation aliases ---
Set-Alias -Name docs    -Value 'Set-Location C:\Users\$USERNAME\Documents'   		-Description "Go to User Documents Folder"
Set-Alias -Name dl      -Value 'Set-Location C:\Users\$USERNAME\Downloads'   		-Description "Go to User Downloads Folder"
Set-Alias -Name desktop -Value 'Set-Location C:\Users\$USERNAME\Desktop'     		-Description "Go to User Desktop Folder"
# --- Program Aliases ---
#Set-Alias -Name note    -Value notepad++.exe                -Description "Open Notepad++"
#==================================================================#
# Set-Alias -Name md      -Value New-Item -ItemType Directory -Description "Make directory"
# Set-Alias -Name cp      -Value Copy-Item                    -Description "Copy items"
#==================================================================#
