# Exercise: Test Your Tool

Exercise code for the lesson **Exercise: Test Your Tool** in PowerShell in Depth on [ask-codey.com](https://www.ask-codey.com).

`RecipeBox` is the recipe box from *Exercise: A Recipe Box Module*, grown a little: it keeps your recipes in a JSON file, `Get-Recipe` finds them, `Add-Recipe` adds one and `Remove-Recipe` (new) takes one out, with `-WhatIf`. Every command also takes `-Path`, so a test can point it at a copy of the box. It works today. Your job is to make it a proper module, with a manifest, and to write the Pester tests that will tell you, every time you change it from now on, that it still works. A check makes sure your tests are good enough: it breaks RecipeBox in five ways and expects your tests to notice each one.

## What's here

- `RecipeBox\RecipeBox.psm1`: the module, with three commands and two helpers. Ready to use; don't change it.
- `test-data\recipes.json`: five test recipes, two of them Baking and one, Lemon Garlic Pasta, that takes exactly 30 minutes. Ready to use.
- `RecipeBox.Tests.ps1`: your tests. One example test is written; for you to finish.
- `Check.Tests.ps1`: the check. You don't need to change it.

## What to do

Open PowerShell 7 in this folder (the one with `RecipeBox.Tests.ps1` in it).

1. **Make the manifest.** Use `New-ModuleManifest` to make `RecipeBox\RecipeBox.psd1`, beside `RecipeBox.psm1`. Give it `-RootModule RecipeBox.psm1`, a `-ModuleVersion` and `-Description` of your choice, and `-FunctionsToExport` with the three commands: `Get-Recipe`, `Add-Recipe` and `Remove-Recipe`. Leave out the helpers `Read-RecipeFile` and `Save-RecipeFile`. Check it with `Test-ModuleManifest`.
2. **Run the example test.** `Invoke-Pester .\RecipeBox.Tests.ps1 -Output Detailed` should show one green test.
3. **Write five more tests**, one `It` block for each line in `RecipeBox.Tests.ps1`:
   1. `Get-Recipe -Category Baking` returns only the baking recipes.
   2. `Get-Recipe -MaxMinutes 30` includes a recipe that takes exactly 30 minutes.
   3. `Add-Recipe` saves the new recipe, so `Get-Recipe` finds it afterwards.
   4. `Add-Recipe` refuses a name that's already in the box.
   5. `Remove-Recipe -WhatIf` leaves the recipe in the box.

Every RecipeBox command takes `-Path`. Give every call `-Path $box`, so each test works on its own fresh copy of the five test recipes in `TestDrive:`, never on your real recipe box.

## Check your work

The check needs Pester 5 or newer. Install it once, if you haven't already:

```powershell
Install-PSResource Pester
```

Then, from this folder, run your own tests, then the check:

```powershell
Invoke-Pester .\RecipeBox.Tests.ps1 -Output Detailed
Invoke-Pester .\Check.Tests.ps1
```

A plain `Invoke-Pester` runs both files.

At first most of the check's tests fail: that is expected. The manifest turns the first three green. Then the check runs your tests twice over: once on RecipeBox as it is, where every one of your tests must pass, and once on each of five broken copies of RecipeBox, where at least one of your tests must fail. A failing check names the break your tests missed and gives a hint. The check can take up to half a minute, because it starts a fresh PowerShell for each run.

If PowerShell says the check *cannot be loaded* because it *is not digitally signed*, or because *running scripts is disabled*, the folder came from a download that Windows marked as from the internet. Unblock its files once with `Get-ChildItem -Recurse | Unblock-File`, from this folder, and run the check again.

## The rules

- Don't change `RecipeBox.psm1` or `test-data\recipes.json`: the check breaks its own copies of them.
- Keep your tests in `RecipeBox.Tests.ps1`, and keep its first lines: `Import-Module "$PSScriptRoot\RecipeBox\RecipeBox.psd1" -Force` and the `BeforeEach` that copies the test recipes into `TestDrive:`.
- Find files with `$PSScriptRoot`, never a path that starts at your drive, so the tests work wherever the folder is.

## Tips

- Each test needs only a line or two. Run a command at the prompt first (with `-Path .\test-data\recipes.json` for `Get-Recipe`), see what it gives, then write the `Should`.
- `Should -HaveCount 1` checks how many things came down the pipeline, and `Should -Contain 'Lemon Garlic Pasta'` checks that a list has that item.
- `(Get-Recipe -Category Baking -Path $box).Name` gives the name of every recipe it found, and `Should -Be 'Apple Crumble', 'Banana Bread'` checks a whole list, in order.
- To test that a command fails, put it in braces and pipe it to `Should -Throw`: `{ Add-Recipe ... } | Should -Throw`.
- `-WhatIf` prints a `What if:` line while your tests run. That's expected.

## Hand it in

When it works, push your solution to a public repo of your own on GitHub, then paste that repo's address into **Submit your exercise** on the lesson page at [ask-codey.com](https://www.ask-codey.com). That's what completes the lesson. The lesson page shows the Git commands, step by step.
