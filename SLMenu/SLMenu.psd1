@{
    ModuleVersion = '1.0.3'
    Description = 'Text User Interface Module for Powershell Console'

    Author = 'Steve Lowe'
    CompanyName = ''
    Copyright = '(c) 2016 Steve Lowe. All rights reserved.'
    GUID = '4682988b-011a-42b7-a1b0-4bd875bef14c'

    RootModule = ''
    NestedModules = @(
        'SLMenu.ConsoleCursor.psm1'
        'SLMenu.LineState.psm1'
        'SLMenu.MenuItem.psm1'
        'SLMenu.Menus.psm1'
        'SLMenu.ShowMenu.psm1'
    )

    FunctionsToExport = @(
        'Clear-SLConsoleLine'
        'Move-SLConsoleCursor'
        'Write-SLLineState'
        'Write-SLLineText'
        'Get-SLMenuChar'
        'New-SLMenuItem'
        'New-SLMenuItemQuit'
        'New-SLMenuItemList'
        'New-SLMenuItemListFromEnum'
        'Show-SLMenu'
        'Show-SLMenuExecute'
        'Show-SLMenuYesNo'
    )
    CmdletsToExport = @()
    VariablesToExport = @(
        'NonInteractive'
    )
    AliasesToExport = @()

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.0'
}
