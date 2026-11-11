<#
.SYNOPSIS
    Деплой сайта «Формула Жизни» на GitHub Pages.

.DESCRIPTION
    Прописывает remote и пушит ветку main в ваш репозиторий GitHub.
    Перед запуском создайте ПУСТОЙ репозиторий: https://github.com/new
      - имя: formula-zhizni
      - Public (Pages бесплатен только для публичных)
      - без README, без .gitignore, без лицензии

.EXAMPLE
    .\deploy-github.ps1 -User "my-login"

.EXAMPLE
    .\deploy-github.ps1 -User "my-login" -Repo "formula-zhizni"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Ваш логин на GitHub")]
    [string]$User,

    [string]$Repo = "formula-zhizni",

    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

function Write-Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }
function Write-Ok($text)   { Write-Host "    $text" -ForegroundColor Green }
function Write-Note($text) { Write-Host "    $text" -ForegroundColor Yellow }

# --- 1. git на месте? ---
Write-Step "Проверяю git"
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { throw "git не найден в PATH. Установите Git for Windows." }
Write-Ok (& git --version)

# --- 2. мы в репозитории? ---
Write-Step "Проверяю репозиторий"
if (-not (Test-Path (Join-Path $PSScriptRoot ".git"))) {
    throw "В папке $PSScriptRoot нет .git. Запускайте скрипт из папки gh-pages."
}

Push-Location $PSScriptRoot
try {
    $current = (& git branch --show-current).Trim()
    if ($current -ne $Branch) {
        Write-Note "Текущая ветка '$current', переключаю на '$Branch'"
        & git branch -M $Branch
    }
    Write-Ok "Ветка: $Branch"

    $dirty = (& git status --porcelain)
    if ($dirty) {
        Write-Note "Есть незакоммиченные изменения:"
        $dirty | ForEach-Object { Write-Note "  $_" }
        $answer = Read-Host "Закоммитить их перед отправкой? (y/n)"
        if ($answer -eq "y") {
            & git add -A
            & git commit -m "Обновление сайта"
            Write-Ok "Изменения закоммичены"
        }
    } else {
        Write-Ok "Рабочее дерево чистое"
    }

    # --- 3. remote ---
    Write-Step "Настраиваю remote"
    $url = "https://github.com/$User/$Repo.git"
    & git remote get-url origin 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        & git remote set-url origin $url
        Write-Ok "origin обновлён -> $url"
    } else {
        & git remote add origin $url
        Write-Ok "origin добавлен -> $url"
    }

    # --- 4. push ---
    Write-Step "Отправляю на GitHub"
    Write-Note "Если попросит пароль — вводите Personal Access Token, не пароль аккаунта."
    Write-Note "Создать токен: https://github.com/settings/tokens (права: repo)"
    Write-Host ""
    & git push -u origin $Branch
    if ($LASTEXITCODE -ne 0) {
        throw "git push завершился с ошибкой. Проверьте логин, имя репозитория и токен."
    }
    Write-Ok "Код отправлен"

    # --- 5. что дальше ---
    $pagesUrl = "https://github.com/$User/$Repo/settings/pages"
    $siteUrl  = "https://$User.github.io/$Repo/"
    Write-Host ""
    Write-Host "Готово. Осталось включить Pages:" -ForegroundColor Green
    Write-Host "  1. Откройте $pagesUrl"
    Write-Host "  2. Source: Deploy from a branch"
    Write-Host "  3. Branch: $Branch   /   Folder: / (root)"
    Write-Host "  4. Save"
    Write-Host ""
    Write-Host "Через 1-2 минуты сайт будет доступен:" -ForegroundColor Green
    Write-Host "  $siteUrl" -ForegroundColor Green
}
finally {
    Pop-Location
}
