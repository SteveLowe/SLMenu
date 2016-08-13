#Requires -Version 3
[CmdletBinding()]
param ()
if ($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters['Debug'].ToBool()) { $DebugPreference = [System.Management.Automation.ActionPreference]::Continue }
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module .\SLMenu\SLMenu.psd1

function main {
    $MenuItems = New-SLMenuItemList
    $MenuItems.Add( (New-SLMenuItem -Key '1' -Name 'YesNo' -Data { MenuYesNo }) )

    $MenuItems.Add( (New-SLMenuItem -Comment) )

    $MenuItems.Add( (New-SLMenuItem -Key '2' -Name 'Menu Message' -Data { MenuMessage }) )
    $MenuItems.Add( (New-SLMenuItem -Key '3' -Name 'Menu Position, no loop' -Data { MenuPosition }) )
    $MenuItems.Add( (New-SLMenuItem -Key '4' -Name 'Menu Position bad' -Data { MenuPositionBad }) )
    $MenuItems.Add( (New-SLMenuItem -Key '5' -Name 'Menu Script' -Data { MenuScript }) )
    $MenuItems.Add( (New-SLMenuItem -Key '6' -Name 'Menu from Array' -Data { MenuArray }) )
    $MenuItems.Add( (New-SLMenuItem -Key '7' -Name 'Dynamic Menu' -Data { MenuDynamic }) )

    $MenuItems.Add( (New-SLMenuItem -Separator) )
    $MenuItems.Add( (New-SLMenuItemQuit) )

    Show-SLMenuExecute -MenuItems $MenuItems -Title 'Test' -Clear -LoopAfterChoice
}

function MenuYesNo {
    Write-Verbose "MenuYesNo"
    $MenuItems = New-SLMenuItemList
    $MenuItems.Add( (New-SLMenuItem -Key '1' -Name 'YesNo' -Data {Show-SLMenuYesNo -Title 'Confirm: Do This?';Pause}) )
    $MenuItems.Add( (New-SLMenuItem -Key '2' -Name 'YesNoMessage' -Data {Show-SLMenuYesNo -Title 'Confirm: Do This?' -Message 'This will ask you what to do';Pause}) )
    $MenuItems.Add( (New-SLMenuItem -Key '3' -Name 'YesNoClear' -Data {Show-SLMenuYesNo -Title 'Confirm: Do This?' -ClearAfter;Pause}) )
    $MenuItems.Add( (New-SLMenuItem -Key '4' -Name 'YesNoMessageClear' -Data {Show-SLMenuYesNo -Title 'Confirm: Do This?' -Message 'This will ask you what do to' -ClearAfter;Pause}) )

    $MenuItems.Add( (New-SLMenuItem -Separator) )
    $MenuItems.Add( (New-SLMenuItemQuit -Name 'Back') )
    Show-SLMenuExecute -MenuItems $MenuItems -Title 'Test YesNo' -Clear -LoopAfterChoice
}

function MenuMessage {
    Write-Verbose "MenuMessage"
    $MenuItems = New-SLMenuItemList
    $MenuItems.Add( (New-SLMenuItemQuit -Name 'Back') )
    Show-SLMenu -MenuItems $MenuItems -Title 'Test Message' -Message 'This is a message' -Clear -LoopAfterChoice
}

function MenuPosition {
    Write-Verbose "MenuPosition"
    $MenuItems = New-SLMenuItemList
    $MenuItems.Add( (New-SLMenuItem -Key '1' -Name 'One') )
    $MenuItems.Add( (New-SLMenuItem -Key '2' -Name 'Two') )
    $MenuItems.Add( (New-SLMenuItem -Key '3' -Name 'Three') )
    $MenuItems.Add( (New-SLMenuItem -Separator) )
    $MenuItems.Add( (New-SLMenuItemQuit -Name 'Back') )
    $Message = 'Option 2 should be selected by default. Selecting any option should show selection info, then return to prev menu'
    Show-SLMenu -MenuItems $MenuItems -Title 'Test Position' -Message $Message -Clear -Position 1 | Format-List
    Pause
}
function MenuPositionBad {
    Write-Verbose "MenuPositionBad"
    $MenuItems = New-SLMenuItemList
    $MenuItems.Add( (New-SLMenuItem -Key '1' -Name 'One') )
    $MenuItems.Add( (New-SLMenuItem -Key '2' -Name 'Two') )
    $MenuItems.Add( (New-SLMenuItem -Key '3' -Name 'Three') )
    $MenuItems.Add( (New-SLMenuItem -Separator) )
    $MenuItems.Add( (New-SLMenuItemQuit -Name 'Back') )
    $Message = 'Option 1 should be selected by default. No errors should occur'
    Show-SLMenu -MenuItems $MenuItems -Title 'Test Position' -Message $Message -Clear -Position 15 | Format-List
    Pause
}

function MenuScript {
    Write-Verbose "MenuScript"
    $MenuItems = New-SLMenuItemList
    $MenuItems.Add( (New-SLMenuItemQuit -Name 'Back') )
    $Message = 'You should see "PreScript run" above the menu items, and "PostScript ran" below the menu footer'
    Show-SLMenu -MenuItems $MenuItems -Title 'Test Scripts' -Message $Message -Clear -PreScript {Write-Output 'PreScript Ran'} -PostScript {Write-Output 'PostScript Ran'} | Format-List
    pause
}

function MenuArray {
    Write-Verbose "MenuArray"
    $MenuItems = @(
        (New-SLMenuItem -Key '1' -Name 'One')
        (New-SLMenuItem -Key '2' -Name 'Two')
        (New-SLMenuItem -Key '3' -Name 'Three')
        (New-SLMenuItem -Separator)
        (New-SLMenuItemQuit -Name 'Back')
    )
    Show-SLMenu -MenuItems $MenuItems -Title 'Test Array' -Clear | Format-List
    Pause
}

function MenuDynamic {
    Write-Verbose "MenuDynamic"
    Show-SLMenuExecute -GetMenuItems {
        $MenuItems = New-SLMenuItemList

        $ItemCount = Get-Random -Minimum 2 -Maximum 5
        for ([int]$i = 1; $i -le $ItemCount; $i++) {
            Write-Debug $i
            $Name = "Item $i`_$(Get-Random)"
            $MenuItems.Add( (New-SLMenuItem -Key "$i" -Name $Name -Data {$Name;Pause}.GetNewClosure()) )
        }

        $MenuItems.Add( (New-SLMenuItem -Separator) )
        $MenuItems.Add( (New-SLMenuItemQuit -Name 'Back') )

        $MenuItems.ToArray()
    } -Title 'Test Dynamic' -Message 'This will show 2 - 4 Random menu items. The MenuItems list is recreated every time you return to the menu' -Clear -LoopAfterChoice
}

try {
    main
}
catch {
    $_.ToString()
    $_.ScriptStackTrace
}
