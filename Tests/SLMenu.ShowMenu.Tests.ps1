$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
Import-Module "$here\..\SLMenu\SLMenu.ConsoleCursor.psm1"
Import-Module "$here\..\SLMenu\SLMenu.MenuItem.psm1"
Import-Module "$here\..\SLMenu\$script"

# Read this:
# https://github.com/pester/Pester/wiki/Unit-Testing-within-Modules

Describe "Show-SLMenu" {
    # Mock all the UI function so they do nothing
    Mock Move-SLConsoleCursor {}
    Mock Clear-SLConsoleLine {}
    Mock Write-Host {}

    It "throws with no input" {
        {Show-SLMenu} | Should Throw
    }
}

Describe "SLMenu GetValidPositions" {
    InModuleScope 'SLMenu.ShowMenu' {
        # Mock MenuItems
        $MenuItems = [PSObject[]]@(
            ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
        )

        It "throws when given empty menu" {
            $MenuItems = @()
            {GetValidPositions -MenuItems $MenuItems} | Should Throw
        }

        It "throws when given menu with no selectable elements" {
            $MenuItems = [PSObject[]]@(
                ([PSCustomObject]@{IsComment = $true; IsSeparator = $false})
            )
            {GetValidPositions -MenuItems $MenuItems} | Should Throw
        }

        Context "When given menu with 4 items and only first one is selectable" {
            $MenuItems = [PSObject[]]@(
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $true; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $true})
                ([PSCustomObject]@{IsComment = $true; IsSeparator = $false})
            )
            $ValidPositions = GetValidPositions -MenuItems $MenuItems

            It "returns array of length 1" {
                $ValidPositions.Length | Should Be 1
            }
            It "returns value 0" {
                $ValidPositions[0] | Should Be 0
            }
        }

        Context "when given menu with 5 items and all selectable" {
            $MenuItems = [PSObject[]]@(
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
            )
            $ValidPositions = GetValidPositions -MenuItems $MenuItems

            It "returns array of length 5" {
                $ValidPositions.Length | Should Be 5
            }
            0..4 | ForEach-Object {
                It "returns value $_ for index $_" {
                    $ValidPositions[$_] | Should Be $_
                }
            }
        }

        Context "when given menu with 5 items; 1 comment and 1 separator" {
            $MenuItems = [PSObject[]]@(
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $true; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $true})
                ([PSCustomObject]@{IsComment = $false; IsSeparator = $false})
            )
            $ValidPositions = GetValidPositions -MenuItems $MenuItems

            It "returns array of length 3" {
                $ValidPositions.Length | Should Be 3
            }
            It "returns value 0 for index 0" {
                $ValidPositions[0] | Should Be 0
            }
            It "returns value 2 for index 1" {
                $ValidPositions[1] | Should Be 2
            }
            It "returns value 4 for index 2" {
                $ValidPositions[2] | Should Be 4
            }
        }
    }
}

Describe "SLMenu ValidateMenuItems" {
    It "throws with duplicate key" {
        $MenuItems = New-SLMenuItemList
        $MenuItems.Add( (New-SLMenuItem -Key 'a') )
    }
}
