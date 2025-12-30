@{
    # Module metadata
    RootModule        = 'PSKit.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = 'f7e3a1b2-9c4d-4e5f-8a6b-2d1c3e4f5a6b'
    Author            = 'Agnė Lukoševičiūtė'
    CompanyName       = 'Microsoft'
    Copyright         = '(c) 2025. All rights reserved.'
    Description       = 'PSKit - PowerShell toolbox'
    
    # Requirements
    PowerShellVersion = '7.0'
    
    # Exported functions
    FunctionsToExport = @(
        'Initialize-PSKit'
        'Get-PSKitStatus'
        'Uninstall-PSKit'
    )
}
