$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe 'SLMenu Module' {
    It 'Should import without error' {
        {Import-Module "$here\SLMenu.psd1"} | Should not throw
    }

    It 'Should not have any PSScriptAnalyzer warnings' {
        $ScriptWarnings = @(Invoke-ScriptAnalyzer -Path $here)
        $ScriptWarnings.Length | Should be 0
    }
}
