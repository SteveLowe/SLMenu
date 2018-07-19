Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Host.Name -ilike '*ISE*') {
    Write-Warning 'SLMenu cannot be used in the Powershell ISE'
}

<#
.SYNOPSIS
Show the Menu, and return the MenuItem selected

.DESCRIPTION


.PARAMETER Title
Title to display above the Menu

.PARAMETER MenuItems
Array of MenuItems to Show

.PARAMETER Message
Message to display after the Menu

.PARAMETER Clear
Clear the whole screen buffer before drawing the Menu

.PARAMETER ClearAfter
Clear the area of screen taken up by the Menu, after the selection is made

.PARAMETER PreScript
ScriptBlock to execute before drawing the menu items (but after the header)

.PARAMETER PostScript
ScriptBlock to execute after drawing the menu, before prompting for selection

.PARAMETER Position
Which MenuItem to select first (0 indexed)

.PARAMETER Inline
Draw in Inline Menu:
- No Line above or below menu

.PARAMETER FlushInput
Flush the input buffer before accepting user input
This is to prevent keypress before the menu is drawn from being used
.EXAMPLE
$MenuItems = New-SLMenuItemList
$MenuItems.Add( (New-SLMenuItem -Key 'a' -Name 'Alpha') )
$MenuItems.Add( (New-SLMenuItem -Key 'b' -Name 'Bravo') )

Show-SLMenu -Title 'Test Menu' -MenuItems $MenuItems -Message 'Please select an item'

-- Test Menu ------------------------------------------------------
 a: Alpha
 b: Bravo
----------
Please select an item
-------------------------------------------------------------------
#>
function Show-SLMenu {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [string]$Title = $(throw "-Title is required"),
        [PSObject[]]$MenuItems = @(),
        [string]$Message = '',
        [switch]$Clear,
        [switch]$ClearAfter,
        [ScriptBlock]$PreScript = $null,
        [ScriptBlock]$PostScript = $null,
        [int]$Position = 0,
        [switch]$Inline,
        [Switch]$FlushInput
    )
    Write-Debug "Show-SLMenu($Title)"
    if ($NonInteractive) {
        Write-Error 'Cannot run menu when -NonInteractive'
    }
    if ($Host.Name -ilike '*ISE*') {
        Write-Error 'Cannot run in ISE'
    }

    ValidateMenuItems $MenuItems

    [int]$TitleMaxWidth = ($Host.UI.RawUI.BufferSize.Width) - 6
    if ($Title.Length -gt $TitleMaxWidth) { $Title = $Title.SubString(0, $TitleMaxWidth) }
    [PSObject]$MenuArgs = [PSCustomObject]@{
        Title = $Title
        MenuItems = $MenuItems
        Message = $Message
        Inline = $Inline.ToBool()
    }
    [PSObject]$MenuData = [PSCustomObject]@{
        Position = 0
        ValidPositions = [int[]]@()
        KeyPress = $null
    }

    try {
        # Get Valid Positions
        $MenuData.ValidPositions = GetValidPositions $MenuItems
        # Make sure Position is valid, and convert it to a ValidPosition
        if ($MenuData.ValidPositions.Contains($Position)) {
            $MenuData.Position = $MenuData.ValidPositions.IndexOf($Position)
        }

        if ($FlushInput) {
            # Ignore any buffered input
            $Host.UI.RawUI.FlushInputBuffer()
        }
        if (![console]::IsOutputRedirected) {
            # don't show flashing cursor
            [console]::CursorVisible = $false
        }

        if ($Clear) {
            Clear-Host
        }
        else {
            # make sure we have enough space left in the buffer
            # 2 --- lines + leave one line blank at end + menu items + message
            # possible issues: Pre/Post script could still cause issues if they write any lines
            [int]$LinesToClear = 2 + $MenuItems.Length + [Math]::Ceiling($Message.Length / $Host.UI.RawUI.BufferSize.Width)
            Clear-SLConsoleLine -Count $LinesToClear -Return
            # move to new line if we are not at the start of the current line
            if ($Host.UI.RawUI.CursorPosition.X -gt 0) {
                Clear-SLConsoleLine
            }
        }

        DrawMenuHeader -MenuArgs $MenuArgs
        Invoke-MenuScript $PreScript
        $MenuItemsPos = $Host.UI.RawUI.CursorPosition
        DrawMenuBody -MenuArgs $MenuArgs -MenuData $MenuData -NoPosition
        DrawMenuFooter -MenuArgs $MenuArgs -MenuData $MenuData
        Invoke-MenuScript $PostScript
        $MenuEndPos = $Host.UI.RawUI.CursorPosition


        [PSObject]$Selected = [PSCustomObject]@{
            MenuItem = $null
            KeyPress = $null
            Data = $null
        }
        while ($true) {
            Move-SLConsoleCursor -CursorPosition $MenuItemsPos

            # Wrap Position
            if ($MenuData.Position -lt 0) { $MenuData.Position = $MenuData.ValidPositions.Length - 1 }
            elseif ($MenuData.Position -ge $MenuData.ValidPositions.Length) { $MenuData.Position = 0 }

            # Draw Menu
            DrawMenuBody -MenuArgs $MenuArgs -MenuData $MenuData

            # If we made a valid selction on the previous run then exit here
            if ($null -ne $Selected.MenuItem) {
                break
            }

            # read key from user
            $KeyPress = GetUserInput
            $MenuData.KeyPress = $KeyPress

            # up/down
            if ($KeyPress.VirtualKeyCode -eq 38) { $MenuData.Position--; continue }
            if ($KeyPress.VirtualKeyCode -eq 40) { $MenuData.Position++; continue }

            $SelectedMenuItem = HandleUserInput -MenuArgs $MenuArgs -MenuData $MenuData
            if ($null -eq $SelectedMenuItem) { continue }

            $Selected.KeyPress = $KeyPress
            $Selected.MenuItem = $SelectedMenuItem
        }
        Move-SLConsoleCursor -CursorPosition $MenuEndPos

        if ($ClearAfter) {
            # return cursor to original position and clear menu
            Move-SLConsoleCursor -Up $LinesToClear
            Clear-SLConsoleLine -Count $LinesToClear -FromStart -Return
        }
    }
    finally {
        if (![console]::IsOutputRedirected) {
            [console]::CursorVisible = $true
        }
    }

    if ($null -ne $Selected.MenuItem) {
        $Selected.Data = $Selected.MenuItem.Data
    }
    return $Selected
} # end function Show-SLMenu

################################################################################
#.SYNOPSIS
# Show the Menu, and execute the ScriptBlock selected
#
#.DESCRIPTION
#
#
#.PARAMETER Title
# Title to display above the Menu
#
#.PARAMETER MenuItems
# Array of MenuItems to Show
#
#.PARAMETER Message
# Message to display after the Menu
#
#.PARAMETER Clear
# Clear the whole screen buffer before drawing the Menu
#
#.PARAMETER PreScript
# ScriptBlock to execute before drawing the menu
#
#.PARAMETER PostScript
# ScriptBlock to execute after drawing the menu, before prompting for selection
#
#.PARAMETER GetMenuItems
# ScriptBlock to generate MenuItem List.
# This is executed before the menu is drawn each time
#
#.PARAMETER LoopAfterChoice
# Show the menu again after selction is made and ScriptBlock executed
#
#.PARAMETER FlushInput
# Flush the input buffer before accepting user input
# This is to prevent keypress before the menu is drawn from being used
#.EXAMPLE
# $MenuItems = New-SLMenuItemList
# $MenuItems.Add( (New-SLMenuItem -Key 'a' -Name 'Alpha' -Data { Write-Output 'Hello World1' }) )
# $MenuItems.Add( (New-SLMenuItem -Key 'b' -Name 'Bravo' -Data { Write-Output 'Hello World2' }) )
#
# Show-SLMenuExecute -Title 'Test Menu' -MenuItems $MenuItems -Message 'Please select an item'
#
#-- Test Menu ------------------------------------------------------
# a: Alpha
# b: Bravo
#----------
#Please select an item
#-------------------------------------------------------------------
################################################################################
function Show-SLMenuExecute {
    param (
        [string]$Title = '',
        [PSObject[]]$MenuItems = @(),
        [string]$Message = '',
        [switch]$Clear,
        [ScriptBlock]$PreScript = $null,
        [ScriptBlock]$PostScript = $null,
        [ScriptBlock]$GetMenuItems = $null,
        [switch]$LoopAfterChoice
    )
    Write-Debug "Show-SLMenuExecute($Title)"

    if ($GetMenuItems -eq $null) {
        ValidateMenuItemsExecute -MenuItems $MenuItems
    }

    while ($true) {
        if ($GetMenuItems -ne $null) {
            try {
                $MenuItems = $GetMenuItems.Invoke()
            }
            catch {
                # Ignore the 'Error calling Invoke' exception
                throw $_.Exception.InnerException
            }
            ValidateMenuItemsExecute -MenuItems $MenuItems
        }

        $Response = Show-SLMenu -Title $Title -MenuItems $MenuItems -Message $Message -Clear:$Clear -PreScript $PreScript -PostScript $PostScript
        try {
            if ($null -eq $Response.Data) {
                return
            }
            if ($Response.Data -is [ScriptBlock]) {
                # Note: We are using & here instead of .Invoke()
                # .Invoke() blocks output until the scriptblock has finished executing
                $Arguments = $Response.MenuItem.Arguments
                &$Response.Data @Arguments
                if (!$LoopAfterChoice) {
                    return
                }
            }
            else {
                throw 'MenuItem Data is not a ScriptBlock'
            }
        }
        catch {
            Write-Host "Menu Option: '$($Response.MenuItem.Name)' Failed" -ForegroundColor 'Red'
            Write-Host $_.ToString() -ForegroundColor 'Red'
            if ($null -ne $_.Exception.InnerException) {
                Write-Host $_.Exception.InnerException.Message
            }
            Write-Host ''
            Write-Host $_.ScriptStackTrace -ForegroundColor 'Yellow'
            #throw "Menu Option: '$($Response.MenuItem.Name)' Failed - $($_)"
            pause
        }
        Write-Host ''
    }
} # end Show-SLMenuExecute

# ------------------------------------------------------------------------------
# Private Functions
# ------------------------------------------------------------------------------
function DrawMenuHeader {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [PSObject]$MenuArgs
    )
    Write-Debug "DrawMenuHeader()"

    if ($MenuArgs.Inline) {
        # if inline, show message before
        if ($MenuArgs.Message -ne '') {
            Write-Host $MenuArgs.Message
        }
    }

    Write-Host "-- $($MenuArgs.Title) --" -NoNewLine
    if ($MenuArgs.Inline) {
        Clear-SLConsoleLine
    }
    else {
        Clear-SLConsoleLine -Char '-'
    }
} # end DrawMenuHeader
# ------------------------------------------------------------------------------
function DrawMenuBody {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [PSObject]$MenuArgs,
        [PSObject]$MenuData,
        [switch]$NoPosition
    )
    Write-Debug "DrawMenuBody()"

    [int]$MenuPosition = $MenuData.ValidPositions[$MenuData.Position]
    if ($NoPosition) {
        $MenuPosition = -1
    }
    foreach ($MenuItem in $MenuArgs.MenuItems) {

        # if this is the selected menu item, then swap background and foreground colour
        if ($MenuPosition -eq $MenuItem.Number) {
            $fg = $MenuItem.BackgroundColor
            $bg = $MenuItem.ForegroundColor
        }
        else {
            $fg = $MenuItem.ForegroundColor
            $bg = $MenuItem.BackgroundColor
        }
        if ($MenuItem.IsComment) {
            Write-Host $MenuItem.Name -NoNewLine
            Clear-SLConsoleLine
        }
        elseif ($MenuItem.IsSeparator){
            Write-Host '--------' -NoNewLine
            Clear-SLConsoleLine
        }
        else {
            Write-Host " $($MenuItem.Key): $($MenuItem.Name)" -NoNewLine -ForegroundColor $fg -BackgroundColor $bg
            if ($MenuItem.Message -ne '') {
                Write-Host ' ' -NoNewLine
                Write-Host $MenuItem.Message -ForegroundColor $MenuItem.ForegroundColor -BackgroundColor $MenuItem.BackgroundColor -NoNewLine
            }
            Clear-SLConsoleLine
        }
    }
} # End DrawMenuBody
# ------------------------------------------------------------------------------
function DrawMenuFooter {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [PSObject]$MenuArgs,
        [PSObject]$MenuData
    )
    Write-Debug "DrawMenuFooter()"

    if ($MenuArgs.Inline) {
        Write-Host '----------' -NoNewLine; Clear-SLConsoleLine
    }
    else {
        if ($MenuArgs.Message -ne '') {
            Write-Host '----------' -NoNewLine; Clear-SLConsoleLine
            Write-Host $MenuArgs.Message
        }
        Clear-SLConsoleLine -Char '-'
    }
} # end DrawMenuFooter
# ------------------------------------------------------------------------------
function Invoke-MenuScript {
    param (
        [ScriptBlock]$Script
    )
    if ($null -ne $Script) {
        try {
            $Script.Invoke()
        }
        catch {
            throw $_.Exception.InnerException
        }
    }
} # end Invoke-MenuScript
# ------------------------------------------------------------------------------

function GetUserInput {
    $Host.UI.RawUI.ReadKey('AllowCtrlC,NoEcho,IncludeKeyDown')
} # end GetUserInput

function HandleUserInput {
    param (
        [PSObject]$MenuArgs,
        [PSObject]$MenuData
    )
    Write-Debug "HandleUserInput()"

    # Enter
    if ($MenuData.KeyPress.VirtualKeyCode -in 10, 13) {
        return $MenuArgs.MenuItems[$MenuData.ValidPositions[$MenuData.Position]]
    }

    # invalid
    if ($MenuData.KeyPress.Character -eq [char]::MinValue) { return $null }

    # Check if menu item char/num is selected
    foreach ($MenuItem in $MenuArgs.MenuItems) {
        if ($MenuItem.IsComment) { continue }
        if ($MenuItem.IsSeparator) { continue }

        [bool]$ThisMenuItemSelected = $false
        if ($MenuData.KeyPress.Character -ceq $MenuItem.Key) {
            $ThisMenuItemSelected = $true
        }

        foreach ($Key in $MenuItem.ExtraKeys) {
            if ($MenuData.KeyPress.Character -ceq $Key) {
                $ThisMenuItemSelected = $true
                break
            }
        }

        foreach ($KeyNum in $MenuItem.KeyNums) {
            if (([int]$MenuData.KeyPress.Character) -eq $KeyNum) {
                $ThisMenuItemSelected = $true
                break
            }
        }

        if ($ThisMenuItemSelected -eq $true) {
            $MenuData.Position = $MenuData.ValidPositions.Indexof($MenuItem.Number)
            return $MenuItem
        }
    }
    Write-Debug "Input Error: '$($MenuData.KeyPress)' is not a valid option!"
    return $null
} # end HandleUserInput

# Given a menu, return a list of valid positions in the menu
function GetValidPositions {
    param (
        [PSObject[]]$MenuItems
    )
    $ValidPositions = New-Object System.Collections.Generic.List[int]
    $MenuItemsLength = $MenuItems.Length
    for ([int]$i = 0; $i -lt $MenuItemsLength; $i++) {
        $MenuItem = $MenuItems[$i]
        if ($MenuItem.IsComment) { continue }
        if ($MenuItem.IsSeparator) { continue }

        $ValidPositions.Add($i)
    }
    if ($ValidPositions.Count -eq 0) {
        throw "MenuItems has no selectable entries"
    }
    return ,$ValidPositions.ToArray()
} # end GetValidPositions

# Make sure MenuItems is valid
function ValidateMenuItems {
    param (
        [PSObject[]]$MenuItems
    )
    $Keys = New-Object System.Collections.Generic.HashSet[char]
    $KeyNums = New-Object System.Collections.Generic.HashSet[int]
    [int[]]$ReservedKeyNums = 10,13,38,40
    [int]$MenuNumber = 0
    foreach ($MenuItem in $MenuItems) {
        $MenuItem.Number = $MenuNumber
        $MenuNumber++
        if ($MenuItem.IsComment) { continue }
        if ($MenuItem.IsSeparator) { continue }
        if (!$Keys.Add($MenuItem.Key)) {
            throw "Duplicate Key in MenuItem: $($MenuItem.Key) ($($MenuItem.Name))"
        }
        foreach ($Key in $MenuItem.ExtraKeys) {
            if (!$Keys.Add($Key)) {
                throw "Duplicate Key in MenuItem: $($MenuItem.Key) ($($MenuItem.Name)). Key: $Key"
            }
        }
        foreach ($KeyNum in $MenuItem.KeyNums) {
            if (!$KeyNums.Add($KeyNum)) {
                throw "Duplicate KeyNum in MenuItem: $($MenuItem.Key) ($($MenuItem.Name)). KeyNum: $KeyNum"
            }
            if ($KeyNum -in $ReservedKeyNums) {
                throw "Reserved KeyNums ($ReservedKeyNums) cannot be used"
            }
        }
    }
} # end ValidateMenuItems

function ValidateMenuItemsExecute {
    param (
        [PSObject[]]$MenuItems
    )
    [bool]$NullDataPresent = $false
    foreach ($MenuItem in $MenuItems) {
        if ($MenuItem.IsComment) { continue }
        if ($MenuItem.IsSeparator) { continue }

        # allow one item to have $null Data - for quit
        # rest must all be [ScriptBlock]
        if ($null -eq $MenuItem.Data) {
            if ($NullDataPresent -eq $true) {
                throw "Only one Item can have no -Data"
            }
            $NullDataPresent = $true
        }
        elseif ($MenuItem.Data -isnot [ScriptBlock]) {
            throw "-Data must be ScriptBlock"
        }
    }
} # end ValidateMenuItemsExecute
