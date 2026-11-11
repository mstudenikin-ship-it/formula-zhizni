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

# Вызов git без падения на stderr (git пишет туда и обычные сообщения)
function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & git @Args 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
    return [pscustomobject]@{ Output = $out; Code = $code }
}

# --- 1. git на месте? ---
Write-Step "Проверяю git"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git не найден в PATH. Установите Git for Windows."
}
Write-Ok ((Invoke-Git --version).Output -join " ")

# --- 2. мы в репозитории? ---
Write-Step "Проверяю репозиторий"
if (-not (Test-Path (Join-Path $PSScriptRoot ".git"))) {
    throw "В папке $PSScriptRoot нет .git. Запускайте скрипт из папки gh-pages."
}

Push-Location $PSScriptRoot
try {
    $cur = Invoke-Git branch --show-current
    $current = ($cur.Output -join "").Trim()
    if ($current -ne $Branch) {
        Write-Note "Текущая ветка '$current', переключаю на '$Branch'"
        [void](Invoke-Git branch -M $Branch)
    }
    Write-Ok "Ветка: $Branch"

    $st = Invoke-Git status --porcelain
    $dirty = @($st.Output | Where-Object { $_ -and $_.Trim() -ne "" })
    if ($dirty.Count -gt 0) {
        Write-Note "Есть незакоммиченные изменения:"
        $dirty | ForEach-Object { Write-Note "  $_" }
        $answer = Read-Host "Закоммитить их перед отправкой? (y/n)"
        if ($answer -eq "y") {
            [void](Invoke-Git add -A)
            $c = Invoke-Git commit -m "Обновление сайта"
            if ($c.Code -ne 0) { throw "Не удалось закоммитить изменения." }
            Write-Ok "Изменения закоммичены"
        }
    }
    else {
        Write-Ok "Рабочее дерево чистое"
    }

    # --- 3. remote ---
    Write-Step "Настраиваю remote"
    $url = "https://github.com/$User/$Repo.git"
    $hasOrigin = (Invoke-Git remote).Output -contains "origin"
    if ($hasOrigin) {
        [void](Invoke-Git remote set-url origin $url)
        Write-Ok "origin обновлён -> $url"
    }
    else {
        [void](Invoke-Git remote add origin $url)
        Write-Ok "origin добавлен -> $url"
    }

    # --- 4. push ---
    Write-Step "Отправляю на GitHub"
    Write-Note "Если попросит пароль — вводите Personal Access Token, не пароль аккаунта."
    Write-Note "Создать токен: https://github.com/settings/tokens (права: repo)"
    Write-Host ""

    $push = Invoke-Git push -u origin $Branch
    $push.Output | ForEach-Object { Write-Host "    $_" }
    if ($push.Code -ne 0) {
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
