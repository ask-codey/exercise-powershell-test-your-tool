# Your tests for the RecipeBox module. Run them from this folder with: Invoke-Pester .\RecipeBox.Tests.ps1

BeforeAll {
    Import-Module "$PSScriptRoot\RecipeBox\RecipeBox.psd1" -Force
}

Describe 'RecipeBox' {
    BeforeEach {
        # A fresh copy of the five test recipes for every test, in Pester's throwaway TestDrive: folder.
        $box = Join-Path $TestDrive 'recipes.json'
        Copy-Item -Path "$PSScriptRoot\test-data\recipes.json" -Destination $box
    }

    It 'Get-Recipe returns every recipe in the box' {
        Get-Recipe -Path $box | Should -HaveCount 5
    }

    # Write a test for each line below, in an It block of its own. Give every RecipeBox command -Path $box,
    # so your tests use the copy in TestDrive:, never your real recipe box.
    # 2) Get-Recipe -Category Baking returns only the baking recipes
    # 3) Get-Recipe -MaxMinutes 30 includes a recipe that takes exactly 30 minutes
    # 4) Add-Recipe saves the new recipe, so Get-Recipe finds it afterwards
    # 5) Add-Recipe refuses a name that's already in the box
    # 6) Remove-Recipe -WhatIf leaves the recipe in the box
}
