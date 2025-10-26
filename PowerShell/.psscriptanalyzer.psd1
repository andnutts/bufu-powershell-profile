@{
  # Settings file version (informational)
  SettingsVersion = '1.0'

  # Global switches and paths
  ExcludePath = @('docs\**', 'vendor\**')  # paths to skip from analysis
  CustomRulePath = @('tools\CustomRules')  # optional folder with custom rules

  # Rule control: enable/disable or configure individual rules
  Rules = @{
    # Disable single rule completely
    PSAvoidUsingCmdletAliases = @{
      Enable = $false
    }

    # Enable and set severity for a rule
    PSUseDeclaredVarsMoreThanAssignments = @{
      Enable = $true
      Severity = 'Warning'    # Valid values: Error, Warning, Information
    }

    # Configure a rule with extra settings (rule-specific keys)
    PSAvoidUsingWriteHost = @{
      Enable = $true
      Severity = 'Information'
      RuleSettings = @{
        # Example rule-specific setting; actual keys are rule-defined
        AllowColorizedOutput = $false
      }
    }
  }

  # Quick lists to include or exclude whole rules by name
  ExcludeRules = @(
    'PSAvoidUsingCmdletAliases',
    'PSUseApprovedVerbs'
  )

  IncludeRules = @(
    'PSUseDeclaredVarsMoreThanAssignments'
  )
}
