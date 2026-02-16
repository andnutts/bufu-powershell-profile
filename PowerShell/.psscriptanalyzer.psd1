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

# SIG # Begin signature block
# MIIFvwYJKoZIhvcNAQcCoIIFsDCCBawCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA8REzg0DZOMIGl
# 6Mr6aBjAOXXOpn5uDb0IPQOZUwj0NKCCAyYwggMiMIICCqADAgECAhBTL0G9/1qW
# u0vZWRqoGigBMA0GCSqGSIb3DQEBCwUAMCkxJzAlBgNVBAMMHlNldEVudkludGVy
# YWN0aXZlIENvZGUgU2lnbmluZzAeFw0yNTEyMTExNjE2MDdaFw0zMDEyMTExNjI2
# MDdaMCkxJzAlBgNVBAMMHlNldEVudkludGVyYWN0aXZlIENvZGUgU2lnbmluZzCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMINkqJcrKIzkS6j5yHr4BRQ
# sxbufzzhaTcFk5GPw9MBm2w4728lOUg8XWxF0PB1nNz9SeQnSV+/v7nXE/siXOni
# f77MRhzqjwYvYVNnueXg+En+TeCfLsVJ3xL+/Dum+GDo0MGBA+/Xz/3HTNtMZzHU
# qO92G3t36C8rJaEU0NfV6MOn7pQUcDyNUKXcPnFADMn23V1JhTqYe3DI1/Qe2TJ3
# pFkh72IJ7Zq4fn6egOlYaPbxxOnLA8e4WizW/OEP7SG7gFn/0skeslbB8ICs0U9x
# TdFsUNgK+W1SkJL8LqRTnbG0LqiYBHqa+kzLN7zPAzaCllaZbXkKhl2dz6n89nEC
# AwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0G
# A1UdDgQWBBQHDipZfdXTdLr+9/8M/LJlU+lKITANBgkqhkiG9w0BAQsFAAOCAQEA
# QamQPBxTtg+sE9mApfJMOMuFR3iBOJL/7gjgONmbh5vfv6YBX3rF5Povf6bqXgJr
# 37yR1siuZRFw65hprf8mkx47rIRKgDGeJ7/lKtkvJjW1mPFC5TDqGfMcfsSmH8wD
# VcSR8RdTTCP+s3cco6vaAvJHqtFi2omzUbhbPNDExjAvm+6ctauqMmAisfU0xuW+
# SNNz7FdcQbfoVwq9SionBeC6F+phSQM265IGBnTmpkInoedqwwMDejnTmTiLuatr
# 42yxv4IoJcqjjhF5lxT7Vj/RW+MdPGpRoCYDQ0shXOu4vh5RerTIIrS2m8XZl5gN
# N5Vhd+hERzeerNtkHWyD7jGCAe8wggHrAgEBMD0wKTEnMCUGA1UEAwweU2V0RW52
# SW50ZXJhY3RpdmUgQ29kZSBTaWduaW5nAhBTL0G9/1qWu0vZWRqoGigBMA0GCWCG
# SAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcN
# AQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUw
# LwYJKoZIhvcNAQkEMSIEIJZ5iNL7E8EAx6r1Ovgc4ac7pM9Ut1UGEUB32/46lz6v
# MA0GCSqGSIb3DQEBAQUABIIBAJr8u8U7fW9cbKPZpAGM7H4PKOwx2kwbGIkSjI/g
# XpAD2O0iKrVe6aspYKQcLf0RJbuoY410sxaX5BCPz6yKZ0nj1uilrphzHfI+rweB
# Scb6pmYnDOTAM3sCIafjuDguXMmO8kb3ZqdyuO+OCEbZNLksoD5GX4hwuODzdbY8
# NiGgdNLDmYoWgmYqMA0XX1KPlqiLG7CeLm7UPiJXPp5f3puJasyTWTjWYPQ361BQ
# N3lBVmZtL1otF4qZg+mHRmLTygC4tNMtZ3CM10jiYaf9d8+L5bkvtZdDn/9fuqPe
# ZaWw9WnaeILnMElWXHIM9Ui827rnTOF3GqdMdPPlx+KlUAA=
# SIG # End signature block
