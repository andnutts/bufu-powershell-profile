# bufu-powershell-profile

A modular PowerShell profile framework with reusable scripts and oh-my-posh themes — built for reliability, safe onboarding, and easy customization.

## Structure

![image](https://github.com/user-attachments/assets/88a16c34-fdf1-4080-a256-e277a9a7d0b3)

## Quick start

1. Clone:
    `powershell
    cd $HOME\Documents
    git clone https://github.com/andnutts/bufu-powershell-profile.git
    `

2. Dependencies:
   * oh-my-posh: winget install JanDeDobbeleer.OhMyPosh
   * PSReadLine: Install-Module PSReadLine -Scope CurrentUser

## Customization

* Edit themes under SharedConfigs\Themes.
* Add functions, aliases, and helpers in SharedConfigs.
* Switch the active theme in PowerShell\Microsoft.PowerShell_profile.ps1.
