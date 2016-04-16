param ()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Note: This module contains only UI code, so has no pester tests

<#
Would be good to get this without having to parse the command line args
but cannot work out where it is stored
#>
[bool]$NonInteractive  = ([Environment]::GetCommandLineArgs() -icontains '-NonInteractive')

<#
.SYNOPSIS
Clear the content of the current line.
It can optionally return the cursor to the start of the line
and optionally repeat for multiple lines
#>
function Clear-SLConsoleLine {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [switch]$FromStart,
        [switch]$Return,
        [int]$Count = 1
    )
    if ($FromStart) { Move-SLConsoleCursor -X 0 }

    $InitialPos = $Host.UI.RawUI.CursorPosition

    [int]$ScreenWidthRemaining = $Host.UI.RawUI.BufferSize.Width - $Host.UI.RawUI.CursorPosition.X
    Write-Host ''.PadRight($ScreenWidthRemaining, ' ') -NoNewLine
    for ($i = 1; $i -lt $Count; $i++) {
        Write-Host ''.PadRight($Host.UI.RawUI.BufferSize.Width, ' ') -NoNewLine
    }

    if ($Return) {
        # use relative movement to return in case we have hit the end of the buffer
        Move-SLConsoleCursor -Up $Count
        if (!$FromStart) {
            Move-SLConsoleCursor -X $InitialPos.X
        }
    }
} # End Clear-SLConsoleLine

<#
.SYNOPSIS
Move the cursor around the screen.

There are three ways to specify where to move to:
1. With a Management.Automation.Host.Coordinates object (-CursorPosition)
This is the object that is used in $Host.UI.RawUI.CursorPosition

2. With X, Y coordinates (-X and/or -Y)

3. Relative to the current position (-Up, -Down, -Left, -Right)
Only one of these arguments needs to be specified
-Up 2 and -Down 2 will cancel each other out (same with -Left, -Right)
#>
function Move-SLConsoleCursor {
    [cmdletbinding(DefaultParameterSetName="XY")]
    param (
        [Parameter(ParameterSetName="CursorPosition",Position=0, Mandatory=$true)]
        [System.Management.Automation.Host.Coordinates]$CursorPosition,

        [Parameter(ParameterSetName="XY",Position=0)]
        [int]$X = -1,
        [Parameter(ParameterSetName="XY",Position=1)]
        [int]$Y = -1,

        [Parameter(ParameterSetName="UpRightDownLeft",Position=0)]
        [int]$Up = 0,
        [Parameter(ParameterSetName="UpRightDownLeft",Position=1)]
        [int]$Right = 0,
        [Parameter(ParameterSetName="UpRightDownLeft",Position=2)]
        [int]$Down = 0,
        [Parameter(ParameterSetName="UpRightDownLeft",Position=3)]
        [int]$Left = 0
    )
    [bool]$MoveCursor = $false
    switch ($PsCmdlet.ParameterSetName) {
        'CursorPosition' {
            $MoveCursor = $true
            break
        }
        'XY' {
            $CursorPosition = $Host.UI.RawUI.CursorPosition
            if ($X -ge 0) {
                $CursorPosition.X = $X
            }
            if ($Y -ge 0) {
                $CursorPosition.Y = $Y
            }
            $MoveCursor = $true
            break
        }
        'UpRightDownLeft' {
            $CursorPosition = $Host.UI.RawUI.CursorPosition

            [int]$MoveY = $Down - $Up
            $CursorPosition.Y = $CursorPosition.Y + $MoveY

            [int]$MoveX = $Right - $Left
            $CursorPosition.X = $CursorPosition.X + $MoveX

            $MoveCursor = $true
            break
        }
    }
    if ($MoveCursor) {
        # make sure we don't try to move cursor outside of buffer
        if ($CursorPosition.X -lt 0) {
            $CursorPosition.X = 0
        }
        if ($CursorPosition.X -ge $Host.UI.RawUI.BufferSize.Width) {
            $CursorPosition.X = $Host.UI.RawUI.BufferSize.Width - 1
        }

        if ($CursorPosition.Y -lt 0) {
            $CursorPosition.Y = 0
        }
        if ($CursorPosition.Y -ge $Host.UI.RawUI.BufferSize.Height) {
            $CursorPosition.Y = $Host.UI.RawUI.BufferSize.Height - 1
        }

        Write-Debug "Move Cursor to $CursorPosition"
        $Host.UI.RawUI.CursorPosition = $CursorPosition
    }
} # end Move-SLConsoleCursor

# This seems to be needed to export variables
# (just including it in the psd1 does not work)
Export-ModuleMember -Variable @('NonInteractive') -Function @(
    'Clear-SLConsoleLine',
    'Move-SLConsoleCursor'
)
