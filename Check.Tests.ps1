# Checks your manifest and your tests.
# For the tests, it runs your RecipeBox.Tests.ps1 in a second PowerShell: once on RecipeBox as it is, where every
# test should pass, and once on each of five broken copies of RecipeBox, where at least one test should fail.
# The copies live in a throwaway folder that Pester makes and removes (TestDrive), and every run gets a pretend
# app-data folder of its own, so nothing here touches your real recipe box.
# Run it from this folder with: Invoke-Pester .\Check.Tests.ps1   (plain Invoke-Pester runs your tests too)
# You don't need to change this file.

BeforeAll {
    $script:manifest = Join-Path $PSScriptRoot 'RecipeBox\RecipeBox.psd1'
    $script:tests = Join-Path $PSScriptRoot 'RecipeBox.Tests.ps1'
    $script:pwsh = [System.Environment]::ProcessPath
    $script:pester = Join-Path (Get-Module Pester).ModuleBase 'Pester.psd1'

    # Runs RecipeBox.Tests.ps1 from a folder in a second PowerShell, and says how it went.
    function Invoke-YourTest([string] $Folder) {
        $appData = Join-Path $TestDrive ('appdata-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        New-Item -ItemType Directory -Path $appData | Out-Null
        $run = & $pwsh -NoProfile -NonInteractive -Command {
            param($Folder, $Pester, $AppData)
            $env:LOCALAPPDATA = $AppData
            Import-Module $Pester
            $result = Invoke-Pester -Path (Join-Path $Folder 'RecipeBox.Tests.ps1') -PassThru -Output None
            [pscustomobject]@{
                Passed = $result.PassedCount
                Failed = $result.FailedCount
                Names  = @($result.Failed | ForEach-Object { $_.ExpandedName }) -join '; '
            }
        } -args $Folder, $pester, $appData
        [pscustomobject]@{
            Passed      = [int] $run.Passed
            Failed      = [int] $run.Failed
            Names       = $run.Names
            TouchedData = @(Get-ChildItem -Path $appData -Recurse -Force).Count -gt 0
        }
    }

    # Copies RecipeBox, your tests and the test data into TestDrive, breaks RecipeBox.psm1 by changing each line
    # named in $Change into its broken version, and runs your tests on the broken copy.
    function Invoke-BrokenCopy([System.Collections.Specialized.OrderedDictionary] $Change) {
        $copy = Join-Path $TestDrive ('broken-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        New-Item -ItemType Directory -Path $copy | Out-Null
        Copy-Item -Path (Join-Path $PSScriptRoot 'RecipeBox'), (Join-Path $PSScriptRoot 'test-data'), $tests -Destination $copy -Recurse
        $psm1 = Join-Path $copy 'RecipeBox\RecipeBox.psm1'
        $text = Get-Content -Path $psm1 -Raw
        foreach ($line in $Change.Keys) {
            $text.Contains($line) | Should -BeTrue -Because "RecipeBox.psm1 should still have the line '$($line.Trim())'. Get a fresh copy of RecipeBox.psm1 from the exercise repo"
            $text = $text.Replace($line, $Change[$line])
        }
        Set-Content -Path $psm1 -Value $text -NoNewline
        Invoke-YourTest -Folder $copy
    }

    $script:yours = $null
    if ((Test-Path -LiteralPath $tests) -and (Test-Path -LiteralPath $manifest)) {
        $script:yours = Invoke-YourTest -Folder $PSScriptRoot
    }

    function Assert-YoursPass {
        $yours | Should -Not -BeNullOrEmpty -Because 'your tests run only once RecipeBox.Tests.ps1 and RecipeBox\RecipeBox.psd1 are both here'
        $yours.Failed | Should -Be 0 -Because "your tests should all pass on RecipeBox as it is, before they can catch a broken copy. Failing: $($yours.Names)"
    }
}

Describe 'Exercise: Test Your Tool' {

    Context 'The manifest' {

        It 'RecipeBox\RecipeBox.psd1 is here and PowerShell accepts it' {
            Test-Path -LiteralPath $manifest | Should -BeTrue -Because 'the manifest goes in the RecipeBox folder, beside RecipeBox.psm1. Make it with New-ModuleManifest'
            { Test-ModuleManifest -Path $manifest -ErrorAction Stop } | Should -Not -Throw -Because 'Test-ModuleManifest should accept the manifest'
        }

        It 'the manifest names RecipeBox.psm1 as its root module' {
            Test-Path -LiteralPath $manifest | Should -BeTrue -Because 'there is no RecipeBox\RecipeBox.psd1 yet. Make it with New-ModuleManifest'
            $data = Import-PowerShellDataFile -Path $manifest
            $data.RootModule | Should -Be 'RecipeBox.psm1' -Because 'without -RootModule RecipeBox.psm1, the manifest loads no commands at all'
        }

        It 'the manifest shares the three commands, and not the helpers' {
            Test-Path -LiteralPath $manifest | Should -BeTrue -Because 'there is no RecipeBox\RecipeBox.psd1 yet. Make it with New-ModuleManifest'
            $data = Import-PowerShellDataFile -Path $manifest
            @($data.FunctionsToExport | Sort-Object) | Should -Be @('Add-Recipe', 'Get-Recipe', 'Remove-Recipe') -Because 'give New-ModuleManifest -FunctionsToExport Get-Recipe, Add-Recipe, Remove-Recipe. Read-RecipeFile and Save-RecipeFile are for the module''s own use'
        }
    }

    Context 'Your tests' {

        It 'RecipeBox.Tests.ps1 is here' {
            Test-Path -LiteralPath $tests -PathType Leaf | Should -BeTrue -Because 'your tests go in RecipeBox.Tests.ps1, in this folder. Did it get moved or renamed?'
        }

        It 'there are at least six tests, and they all pass on RecipeBox as it is' {
            Assert-YoursPass
            $yours.Passed | Should -BeGreaterOrEqual 6 -Because 'the example test and one test for each of the five lines in RecipeBox.Tests.ps1 make six'
        }

        It 'your tests use TestDrive: and leave the real recipe box alone' {
            Assert-YoursPass
            Get-Content -Path $tests -Raw | Should -Match 'TestDrive' -Because 'the tests should work on a copy of the recipes in TestDrive:'
            $yours.TouchedData | Should -BeFalse -Because 'a test wrote to the real recipe box. Give every RecipeBox command -Path $box'
        }
    }

    Context 'Your tests catch a broken RecipeBox' {

        It '2) when Get-Recipe ignores -Category' {
            Assert-YoursPass
            $run = Invoke-BrokenCopy ([ordered]@{ '        $recipes = $recipes | Where-Object Category -eq $Category' = '        $recipes = $recipes' })
            $run.Failed | Should -BeGreaterThan 0 -Because 'in this copy, Get-Recipe -Category Baking returns every recipe, and no test noticed. Check that it returns exactly the two baking recipes'
        }

        It '3) when Get-Recipe -MaxMinutes leaves out a recipe that takes exactly that long' {
            Assert-YoursPass
            $run = Invoke-BrokenCopy ([ordered]@{ 'Where-Object Minutes -le $MaxMinutes' = 'Where-Object Minutes -lt $MaxMinutes' })
            $run.Failed | Should -BeGreaterThan 0 -Because 'in this copy, Get-Recipe -MaxMinutes 30 leaves out Lemon Garlic Pasta, which takes 30 minutes, and no test noticed. Check that the names it returns contain Lemon Garlic Pasta'
        }

        It '4) when Add-Recipe forgets to save' {
            Assert-YoursPass
            $run = Invoke-BrokenCopy ([ordered]@{ 'Save-RecipeFile -Path $Path -Recipe ($recipes + $recipe)' = 'Save-RecipeFile -Path $Path -Recipe $recipes' })
            $run.Failed | Should -BeGreaterThan 0 -Because 'in this copy, Add-Recipe returns the new recipe but never saves it, and no test noticed. After Add-Recipe, look for the recipe with Get-Recipe'
        }

        It '5) when Add-Recipe lets a second recipe with the same name in' {
            Assert-YoursPass
            $run = Invoke-BrokenCopy ([ordered]@{ 'if ($recipes.Name -contains $Name) {' = 'if ($false) {' })
            $run.Failed | Should -BeGreaterThan 0 -Because 'in this copy, Add-Recipe adds a second Tomato Soup without a word, and no test noticed. Put the Add-Recipe call in { } and pipe it to Should -Throw'
        }

        It '6) when Remove-Recipe -WhatIf removes the recipe anyway' {
            Assert-YoursPass
            # Skips the question -WhatIf answers, and saves with .NET, which never rehearses.
            $run = Invoke-BrokenCopy ([ordered]@{
                'if ($PSCmdlet.ShouldProcess($Path, "Remove the recipe ''$Name''")) {' = 'if ($true) {'
                'ConvertTo-Json -InputObject @($Recipe) | Set-Content -Path $Path' = '[System.IO.File]::WriteAllText($Path, (ConvertTo-Json -InputObject @($Recipe)))'
            })
            $run.Failed | Should -BeGreaterThan 0 -Because 'in this copy, Remove-Recipe -WhatIf really removes the recipe, and no test noticed. After Remove-Recipe -WhatIf, check that Get-Recipe still finds it'
        }
    }
}
