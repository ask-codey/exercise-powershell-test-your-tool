# RecipeBox.psm1: a recipe box, saved as a JSON file in your app-data folder.
# Get-Recipe, Add-Recipe and Remove-Recipe are the box's commands; Read-RecipeFile and Save-RecipeFile are helpers
# for the module's own use. Every command takes -Path, so a test can point it at a copy of the box instead of yours.
# You don't need to change this file.

$dataFolder = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
$script:DefaultPath = Join-Path $dataFolder 'RecipeBox\recipes.json'

function Read-RecipeFile {
    param([string] $Path)
    if (Test-Path -Path $Path) {
        Get-Content -Path $Path -Raw | ConvertFrom-Json
    }
}

function Save-RecipeFile {
    param([string] $Path, [object[]] $Recipe)
    $folder = Split-Path -Path $Path -Parent
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    ConvertTo-Json -InputObject @($Recipe) | Set-Content -Path $Path
}

function Get-Recipe {
    [CmdletBinding()]
    param(
        [string] $Name = '*',

        [ValidateSet('Breakfast', 'Lunch', 'Dinner', 'Baking', 'Snack')]
        [string] $Category,

        [ValidateRange(1, 1440)]
        [int] $MaxMinutes,

        [string] $Path = $script:DefaultPath
    )
    $recipes = Read-RecipeFile -Path $Path | Where-Object Name -like $Name
    if ($Category) {
        $recipes = $recipes | Where-Object Category -eq $Category
    }
    if ($MaxMinutes) {
        $recipes = $recipes | Where-Object Minutes -le $MaxMinutes
    }
    $recipes
}

function Add-Recipe {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateRange(1, 1440)]
        [int] $Minutes,

        [Parameter(Mandatory)]
        [ValidateSet('Breakfast', 'Lunch', 'Dinner', 'Baking', 'Snack')]
        [string] $Category,

        [string] $Path = $script:DefaultPath
    )
    $recipes = @(Read-RecipeFile -Path $Path)
    if ($recipes.Name -contains $Name) {
        throw "A recipe named '$Name' is already in the box."
    }
    $recipe = [PSCustomObject]@{ Name = $Name; Minutes = $Minutes; Category = $Category }
    if ($PSCmdlet.ShouldProcess($Path, "Add the recipe '$Name'")) {
        Save-RecipeFile -Path $Path -Recipe ($recipes + $recipe)
        $recipe
    }
}

function Remove-Recipe {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [string] $Path = $script:DefaultPath
    )
    $recipes = @(Read-RecipeFile -Path $Path)
    $keep = @($recipes | Where-Object Name -ne $Name)
    if ($keep.Count -eq $recipes.Count) {
        Write-Error "There's no recipe named '$Name' in the box."
        return
    }
    if ($PSCmdlet.ShouldProcess($Path, "Remove the recipe '$Name'")) {
        Save-RecipeFile -Path $Path -Recipe $keep
    }
}
