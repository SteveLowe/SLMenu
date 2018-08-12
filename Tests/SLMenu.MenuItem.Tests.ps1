$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", ".psm1")
Import-Module "$here\..\SLMenu\$script"

Describe "Get-SLMenuChar" {
    $MenuChar = ''
    It "thows error with negative number" {
        {$MenuChar = Get-SLMenuChar -1} | Should -throw
    }
    It "thows error with too high number" {
        {$MenuChar = Get-SLMenuChar 1024} | Should -throw
    }
    It "returns Correct Char (1) for 1" {
        (Get-SLMenuChar 1) | Should -be '1'
    }
    It "returns Correct Char (a) for 10" {
        (Get-SLMenuChar 10) | Should -be 'a'
    }
    It "returns Correct Char (z) for 34" {
        (Get-SLMenuChar 34) | Should -be 'z'
    }
    It "returns Correct Char (X) for 57" {
        (Get-SLMenuChar 57) | Should -be 'x'
    }
    It "throws when number too high" {
        {Get-SLMenuChar ([int]::MaxValue)} | Should -throw
    }
    It 'Accepts pipeline input' {
        (1 | Get-SLMenuChar) | Should -be '1'
    }
    It 'Accepts multiple pipeline input' {
        $Results = 1..5 | Get-SLMenuChar
        $Results.Length | Should -be 5
    }
}

Describe "New-SLMenuItemList" {
    $MenuItems = New-SLMenuItemList
    It "returns PSObject List" {
        ,$MenuItems | Should -BeOfType "[System.Collections.Generic.List[PSObject]]"
    }
    It "returns empty list" {
        ,$MenuItems | Should -BeNullOrEmpty
    }
}
Describe "SLMenuItems" {
    It "thows with no parameters" {
        {New-SLMenuItem} | Should -throw
    }

    It "-Separator returns separator" {
        (New-SLMenuItem -Separator).IsSeparator | Should -be $true
    }
    It "dash key returns separator" {
        (New-SLMenuItem -Key '-').IsSeparator | Should -be $true
    }

    It "-Comment returns comment" {
        (New-SLMenuItem -Comment).IsComment | Should -be $true
    }
    It "space key returns separator" {
        (New-SLMenuItem -Key ' ').IsComment | Should -be $true
    }

    Context "MenuItem with Key 'a' and Name 'Test'" {
        $MenuItem = New-SLMenuItem -Key 'a' -Name 'Test'
        It "returns Key 'a'" {
            $MenuItem.Key | Should -be 'a'
        }
        It "returns Name 'Test'" {
            $MenuItem.Name | Should -be 'Test'
        }
        It "does not return Comment or Sepatator" {
            $MenuItem.IsComment -or $MenuItem.IsSeparator | Should -be $false
        }
    }
}

Describe "New-SLMenuItemQuit" {
    $MenuItem = New-SLMenuItemQuit -Name 'Quit'
    It "returns PSObject" {
        $MenuItem | Should -beOfType PSObject
    }

    It "returns -Key 'q'" {
        $MenuItem.Key | Should -be 'q'
    }

    It "return Name 'Quit'" {
        $MenuItem.Name | Should -be 'Quit'
    }

    It "returns ExtraKey 'Q'" {
        $MenuItem.ExtraKeys | Should -be 'Q'
    }

    It "returns KeyNums ESC and CTRL-C" {
        $MenuItem.KeyNums | Should -be @(27, 3)
    }
}

Describe 'New-SLMenuItemListFromEnum' {
    [int]$ConsoleColorLength = ([Enum]::GetValues([ConsoleColor]).Length)
    Context 'When passed Enum Type' {
        $MenuItems = New-SLMenuItemListFromEnum -Enum ([ConsoleColor])
        It 'Returns a List of MenuItems' {
            $MenuItems -is 'Collections.Generic.List[PSObject]' | Should -be $true
        }
    }
    Context 'When passed an Enum value' {
        $MenuItems = New-SLMenuItemListFromEnum -Enum ([ConsoleColor]::Red)
        It 'Returns a List of MenuItems' {
            $MenuItems -is 'Collections.Generic.List[PSObject]' | Should -be $true
        }
    }
    Context 'When passed invalud enum' {
        It 'throws an exception' {
            { $MenuItems = New-SLMenuItemListFromEnum -Enum 42 } | Should -throw
        }
    }
    Context 'No Filtering' {
        $MenuItems = New-SLMenuItemListFromEnum -Enum ([ConsoleColor])
        It 'Returns a List of MenuItems' {
            $MenuItems -is 'Collections.Generic.List[PSObject]' | Should -be $true
        }

        It 'Returns correct length' {
            $MenuItems.Count | Should -be $ConsoleColorLength
        }
    }

    Context 'With Include List' {
        $MenuItems = New-SLMenuItemListFromEnum -Enum ([ConsoleColor]) -Include 'Red', 'Blue', 'Fred'
        It 'Returns a List of MenuItems' {
            $MenuItems -is 'Collections.Generic.List[PSObject]' | Should -be $true
        }

        It 'Returns correct length' {
            $MenuItems.Count | Should -be 2
        }
    }

    Context 'With Exclude List' {
        $MenuItems = New-SLMenuItemListFromEnum -Enum ([ConsoleColor]) -Exclude 'Red', 'Blue', 'Fred'
        It 'Returns a List of MenuItems' {
            $MenuItems -is 'Collections.Generic.List[PSObject]' | Should -be $true
        }

        It 'Returns correct length' {
            $MenuItems.Count | Should -be ($ConsoleColorLength - 2)
        }
    }

    Context 'With Include and Exclude List' {
        $MenuItems = New-SLMenuItemListFromEnum -Enum ([ConsoleColor]) -Include 'Red', 'Blue', 'Green' -Exclude 'Green', 'NotAColour'
        It 'Returns a List of MenuItems' {
            $MenuItems -is 'Collections.Generic.List[PSObject]' | Should -be $true
        }

        It 'Returns correct length' {
            $MenuItems.Count | Should -be 2
        }
    }
}
