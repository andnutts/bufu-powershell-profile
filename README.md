# bufu-powershell-profile

A modular PowerShell profile framework with reusable scripts and oh-my-posh themes — built for reliability, safe onboarding, and easy customization.

## Structure

bufu-powershell-profile
├── .gitignore
├── README.md
├── PowerShell
│   ├── .psscriptanalyzer.psd1
│   ├── Microsoft.PowerShell_profile.ps1
│   └── profile.ps1
└── SharedConfigs
    ├── MyAliases.ps1
    ├── MyFunctions.ps1
    ├── MyHelpers.ps1
    └── Themes
        ├── dracula.omp.json
        ├── example.omp.json
        ├── multiverse-neon.omp.json
        └── mytheme.omp.json


## Quick start

1.  Clone:
    `powershell
    cd $HOME\Documents
    git clone https://github.com/andnutts/bufu-powershell-profile.git
    `

2.  Dependencies:
    * oh-my-posh: winget install JanDeDobbeleer.OhMyPosh
    * PSReadLine: Install-Module PSReadLine -Scope CurrentUser

## Customization
* Edit themes under SharedConfigs\Themes.
* Add functions, aliases, and helpers in SharedConfigs.
* Switch the active theme in PowerShell\Microsoft.PowerShell_profile.ps1.
