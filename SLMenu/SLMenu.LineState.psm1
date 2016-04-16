Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[int]$Script:LineStateWidth = 6
# ------------------------------------------------------------------------------

<#
.SYNOPSIS
    Write a line state block at the start of the current line.

    Is Intended to be used with Write-SLLineText

    There are several pre-defined message:
    -OK
    -Warn
    -Fail
    -None
    -Dots

    or you can use your own text with:
    -Message 'My Message'

    if you don't use any params, then dots '....' will be used

.EXAMPLE
    Write-SLLineState
[....]
    Write-SLLineState -OK
[ ok ]
#>
function Write-SLLineState {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding(DefaultParametersetName="Init")]
    param (
        [parameter(ParameterSetName="Message")]
            [string]$Message,
        [parameter(ParameterSetName="Message")]
            [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor,
        [parameter(ParameterSetName="OK")]
            [switch]$OK,
        [parameter(ParameterSetName="Warn")]
            [switch]$Warn,
        [parameter(ParameterSetName="Fail")]
            [switch]$Fail,
        [parameter(ParameterSetName="None")]
            [switch]$None,
        [parameter(ParameterSetName="Dots")]
            [switch]$Dots,

        [switch]$Next,
        [switch]$ClearLine
    )
    # move cursor to start of line
    $StartCursorPosX = $Host.UI.RawUI.CursorPosition.X
    Move-SLConsoleCursor -X 0
    [int]$OriginalLineStateWith = $Script:LineStateWidth

    Write-Host '[' -NoNewLine
    switch ($PSCmdlet.ParameterSetName) {
        'Message' {
            $Message = $Message.Trim()
            # Make sure $Message is not too long
            [int]$MaxWidth = [Math]::Ceiling($Host.UI.RawUI.BufferSize.Width / 3)
            if ($Message.Length -gt $MaxWidth) {
                $Message = $Message.SubString(0, $MaxWidth)
            }
            # Pad if message is too short
            [bool]$PadFront = $true
            while ($Message.Length -lt 4) {
                if ($PadFront) {
                    $Message = " $Message"
                }
                else {
                    $Message = "$Message "
                }
                $PadFront = !$PadFront
            }
            $Script:LineStateWidth = $Message.Length + 2
            Write-Host $Message -ForegroundColor $ForegroundColor -NoNewLine
        }
        'OK' {
            $Script:LineStateWidth = 6
            Write-Host ' ok ' -ForegroundColor 'Green' -NoNewLine
        }
        'Warn' {
            $Script:LineStateWidth = 6
            Write-Host 'warn' -ForegroundColor 'Yellow' -NoNewLine
        }
        'Fail' {
            $Script:LineStateWidth = 6
            Write-Host 'FAIL' -ForegroundColor 'Red' -NoNewLine
        }
        'None' {
            $Script:LineStateWidth = 6
            Write-Host '    ' -NoNewLine
        }
        'Dots' {
            $Script:LineStateWidth = 6
            Write-Host '....' -NoNewLine
        }
        default {
            $Script:LineStateWidth = 6
            Write-Host '....' -NoNewLine
        }
    }
    Write-Host ']' -NoNewLine
    if (($PSCmdlet.ParameterSetName -ieq 'Init') -or
        ($OriginalLineStateWith -ne $LineStateWidth)
    ) {
        Write-Host ' ' -NoNewLine
        $ClearLine = $true
    }

    if ($ClearLine) {
        Clear-SLConsoleLine -Return
    }
    else {
        # if our "X" cursor position was right of where we are now, then move back to it
        if ($StartCursorPosX -gt $LineStateWidth) {
            Move-SLConsoleCursor -X $StartCursorPosX
        }
    }
    if ($Next) {
        Write-Host ''
    }
} # end function Write-SLLineState
# ------------------------------------------------------------------------------

<#
.SYNOPSIS
    Write text to the current line, without overflowing to the next line.
    Text that would overflow is replaced with ...
    Will move the cursor to the next line with -End

    Is intended to be used with Write-SLLineState

.EXAMPLE
    Write-SLLineState
    Write-SLLineText 'Performing Task'
    try {
        # Perform task
        Write-SLLineState -OK -Next
    }
    catch {
        Write-SLLineState -Fail -Next
        # Handle error
    }
#>
function Write-SLLineText {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    Param (
        [string]$Text = '',
        [ConsoleColor]$Color = $Host.UI.RawUI.ForegroundColor,
        [switch]$Clear,
        [switch]$End
    )
    # Make sure we are not left of the LineState
    if ($Host.UI.RawUI.CursorPosition.X -le $LineStateWidth) {
        Move-SLConsoleCursor -X ($LineStateWidth + 1)
    }

    # Get the remaining space on the line (allowing 3 chars for the ...)
    [int]$RemainaingWidth = $Host.UI.RawUI.BufferSize.Width - $Host.UI.RawUI.CursorPosition.X - 3
    if ($RemainaingWidth -lt 1) {
        # no space left on line
        $Text = ''
    }
    # cut off $Text if its too long
    [bool]$TextClipped = $false
    if ($Text.Length -gt $RemainaingWidth) {
        $Text = $Text.SubString(0, $RemainaingWidth)
        $Text += '...'
        $TextClipped = $true
    }

    Write-Host $Text -NoNewLine -ForegroundColor $Color
    if ($TextClipped) {
        # if we clipped the text then the cursor will have moved to the start of the next line
        # so move back to the end of the this line
        Move-SLConsoleCursor -Up 1 -Right ($Host.UI.RawUI.BufferSize.Width - 1)
    }
    if ($Clear) {
        Clear-SLConsoleLine -Return
    }
    if ($End) {
        Write-Host ''
    }
} # end function Write-SLLineText
