# Деплой сайта «Формула Жизни» на GitHub Pages
# Запуск:  .\deploy-github.ps1 -User "ваш-логин" -Repo "formula-zhizni"
#
# Перед запуском создайте ПУСТОЙ репозиторий на https://github.com/new
#   - имя: formula-zhizni
#   - Public (для бесплатного GitHub Pages)
#   - БЕЗ README, без .gitignore, без лицензии

param(
    [Parameter(Mandatory = $true)][string]$User,
    [string]$Repo = "formula-zhizni"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "==> Проверяю репозиторий" -ForegroundColor Cyan
if (-not (Test-Path ".git")) { throw "Запустите скрипт из папки gh-pages (там должен быть .git)" }

$branch = git branch --show-current
if ($branch -ne "main") { git branch -M main }

Write-Host "==> Настраиваю remote" -ForegroundColor Cyan
$url = "https://github.com/$User/$Repo.git"
$existing = git remote get-url origin 2>$null
if ($existing) { git remote set-url origin $url } else { git remote add origin $url }
Write-Host "    origin -> $url"

Write-Host "==> Отправляю на GitHub" -ForegroundColor Cyan
Write-Host "    При запросе пароля введите Personal Access Token (не пароль от аккаунта)" -ForegroundColor Yellow
git push -u origin main

Write-Host ""
Write-Host "==> Готово. Осталось включить Pages:" -ForegroundColor Green
Write-Host "    1. Откройте https://github.com/$User/$Repo/settings/pages"
Write-Host "    2. Source: Deploy from a branch"
Write-Host "    3. Branch: main   /   Folder: / (root)"
Write-Host "    4. Save"
Write-Host ""
Write-Host "    Через 1-2 минуты сайт будет доступен:" -ForegroundColor Green
Write-Host "    https://$User.github.io/$Repo/" -ForegroundColor Green
