[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
param ()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

################################################################################
#.SYNOPSIS
# Return a valid Menu character given an int
#.EXAMPLE
# > Get-SLMenuChar 5
# 5
# > Get-SLMenuChar 35
# r
################################################################################
function Get-SLMenuChar {
    param (
        [ValidateRange(1, 59)]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [int]$MenuNumber
    )
    Process {
        if ($MenuNumber -lt 10) {
            [char]$MenuChar = [char]$MenuNumber.ToString() #1-9
        }
        elseif ($MenuNumber -lt 26) {
            [char]$MenuChar = [char]($MenuNumber + 87) # a-p
        } # skip q
        elseif ($MenuNumber -lt 35) {
            [char]$MenuChar = [char]($MenuNumber + 88) # r-z
        }
        elseif ($MenuNumber -lt 51) {
            [char]$MenuChar = [char]($MenuNumber + 30) # A-P
        } # skip Q
        else { #if ($MenuNumber -lt 60)
            [char]$MenuChar = [char]($MenuNumber + 31) # R-Z
        }
        $MenuChar
    }
} # end Get-SLMenuChar

################################################################################
#.SYNOPSIS
# Returns a list to Add MenuItems too
#.EXAMPLE
# $MenuItems = New-SLMenuItemList
#
# $MenuItems.Add( (New-SLMenuItemQuit) )
################################################################################
function New-SLMenuItemList {
    New-Object System.Collections.Generic.List[PSObject]
} # end New-SLMenuItemList

################################################################################
#.SYNOPSIS
# Return a New MenuItem
#
#.DESCRIPTION
#
#
#.PARAMETER Key
# The character to press to select this MenuItem
#
#.PARAMETER Name
# The text to show in the Menu
#
#.PARAMETER Data
# The Object to return when Show-SLMenu is run
# This should be a ScriptBlock when calling Show-SLMenuExecute
#
#.PARAMETER Arguments
# Array of objects to be passed to Data as arguments, if it is a ScriptBlock and Show-SLMenuExecute is used.
#
#.PARAMETER ExtraKeys
# Extra Characters that can be pressed to select this MenuItem
#
#.PARAMETER KeyNums
# Extra Characters that can be pressed to select this MenuItem (by character code)
# This is for non-printable characters (e.g. ESC)
#
#.PARAMETER Message
# Optional Message to dispaly after Name
#
#.PARAMETER ForegroundColor
# Foreground Colour of Optional Message
#
#.PARAMETER BackgroundColor
# background Colour of Optional Message
#
#.PARAMETER Separator
# Make this MenuItem a Separator (draw a line of ---)
# Can also use dash for the Key to select this
#
#.PARAMETER Comment
# Make this MenuItem a Comment (Is not selectable)
# Can also use space for the key to select this
#
#.EXAMPLE
################################################################################
function New-SLMenuItem {
    [cmdletbinding(DefaultParameterSetName='MenuItem')]
    param (
        [parameter(Position=1)]
        [char]$Key,
        [parameter(Position=2)]
        [string]$Name,
        [parameter(Position=3)]
        [Object]$Data = $null,

        [parameter()]
        [Object[]]$Arguments = @(),

        [char[]]$ExtraKeys = @(),
        [int[]]$KeyNums = @(),

        [parameter(ParameterSetName='MenuItem')]
        [string]$Message = '',
        [parameter(ParameterSetName='MenuItem')]
        [string]$ForegroundColor = $Host.UI.RawUI.ForegroundColor.ToString(),
        [parameter(ParameterSetName='MenuItem')]
        [string]$BackgroundColor = $Host.UI.RawUI.BackgroundColor.ToString(),

        [parameter(ParameterSetName='Separator')]
        [switch]$Separator,

        [parameter(ParameterSetName='Comment')]
        [switch]$Comment
    )
    [PSObject]$MenuItem = [PSCustomObject]@{
        Key = $Key
        Name = $Name
        Data = $Data
        Arguments = $Arguments
        Number = 0
        ExtraKeys = $ExtraKeys
        KeyNums = $KeyNums
        Message = $Message
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        IsSeparator = [bool]($PsCmdlet.ParameterSetName -ieq 'Separator' -and $Separator)
        IsComment = [bool]($PsCmdlet.ParameterSetName -ieq 'Comment' -and $Comment)
    }
    # Make sure Key and Is<x> match
    if ($Key -ieq ' ') { $MenuItem.IsComment = $true }
    elseif ($Key -ieq '-') { $MenuItem.IsSeparator = $true }

    if ($MenuItem.IsComment) { $MenuItem.Key = ' ' }
    elseif ($MenuItem.IsSeparator) { $MenuItem.Key = '-' }

    if ($MenuItem.IsSeparator -and $MenuItem.IsComment) {
        throw "MenuItem $Key ($Name) - cannot be both Comment and Separator"
    }

    if ([int][char]$MenuItem.Key -eq 0) {
        throw "MenuItem $Key ($Name) - Key cannot be null char"
    }

    # if int 1-9 was passed as -Key then show the string value instead of char num 1-9
    if (([int][char]$MenuItem.Key) -lt 10) {
        $MenuItem.Key = [char]([int]$MenuItem.Key).ToString()
    }

    return $MenuItem
} # end New-SLMenuItem

################################################################################
#.SYNOPSIS
# Create a new 'Quit' MenuItem
#
#.DESCRIPTION
# Creates a new MenuItem and add the following Keys:
# - ESC
# - CTRL-C
# - q
# - Q
#
#.PARAMETER Name
# The Name of the Menu. Default 'Quit'
################################################################################
function New-SLMenuItemQuit {
    param (
        [string]$Name = 'Quit'
    )
    # 27 ESC
    # 3 CTRL-C
    New-SLMenuItem -Key 'q' -ExtraKeys 'Q' -KeyNums 27, 3 -Name $Name
} # End New-SLMenuItemQuit



################################################################################
#.SYNOPSIS
# Create a new MenuItemList with a value from an Enum
#
#.DESCRIPTION
# Creates a new MenuItemList, and populate it with all possible enum values
# the values can be filtered with an Include and Exclude filter
#
#.PARAMETER Enum
# The Enum to get the values from.
#
#.PARAMETER Include
# A string array of enum values to include in the output. If not empty, any
# values not in this list will not be inlcluded in the MenuItemList
#
#.PARAMETER Exclude
# A string array of enum values to exclude from the output. If not empty, any
# values in this list will not be included in the MenuItemList
#
################################################################################
function New-SLMenuItemListFromEnum {
    param (
        [Parameter(Mandatory=$true)]
        $Enum,

        [Parameter()]
        [string[]]$Include = @(),

        [Parameter()]
        [string[]]$Exclude = @()
    )
    # handle passing as [Enum]::Value
    if ($Enum -is [enum]) {
        $Enum = $Enum.GetType()
    }
    if (!($Enum -is [type])) {
        throw '-Enum is wrong type'
    }
    if (!$Enum.IsEnum) {
        throw '-Enum is not an enum'
    }

    $MenuItems = New-SLMenuItemList

    [bool]$IncludeFilter = $Include.Length -gt 0
    [bool]$ExcludeFilter = $Exclude.Length -gt 0

    [int]$KeyNum = 0
    foreach ($Value in [Enum]::GetValues($Enum)) {
        if ($IncludeFilter -and $Include -inotcontains $Value.ToString()) {
            continue
        }
        if ($ExcludeFilter -and $Exclude -icontains $Value.ToString()) {
            continue
        }

        $KeyNum++

        $MenuItems.Add((
            New-SLMenuItem -Key (Get-SLMenuChar $KeyNum) -Name $Value.ToString() -Data $Value
        ))
    }

    return ,$MenuItems
} # end New-SLMenuItemListFromEnum
