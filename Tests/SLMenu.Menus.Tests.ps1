$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
Import-Module "$here\..\SLMenu\SLMenu.MenuItem.psm1"
Import-Module "$here\..\SLMenu\SLMenu.ShowMenu.psm1"
Import-Module "$here\..\SLMenu\$script"

Describe "Show-SLMenuYesNo" {
    Mock -ModuleName 'SLMenu.Menus' Show-SLMenu { return $MenuItems[$Position] } -Veryifiable

    It "called Show-SLMenu" {
        Show-SLMenuYesNo > $null
        Assert-MockCalled -ModuleName 'SLMenu.Menus' Show-SLMenu -Times 1 -Exactly
    }

    It "passed -Title to Show-SLMenu" {
        Show-SLMenuYesNo -Title 'Test Test Test' > $null
        Assert-MockCalled -ModuleName 'SLMenu.Menus' Show-SLMenu -Times 1 -ParameterFilter { $Title -eq 'Test Test Test' }
    }

    It "called Show-SLMenu with -FlushInput" {
        Show-SLMenuYesNo > $null
        Assert-MockCalled -ModuleName 'SLMenu.Menus' Show-SLMenu -Times 1 -ParameterFilter { $FlushInput -eq $true }
    }

    It "returns true when yes is default and default selected" {
        Show-SLMenuYesNo | Should Be $true
    }

    It "returns false when no is default and default selected" {
        Show-SLMenuYesNo -DefaultNo | Should Be $false
    }
}
