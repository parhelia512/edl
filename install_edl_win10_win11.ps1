# --- Privilèges Administrateur ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script nécessite des privilèges d'administrateur. Redémarrage..." -ForegroundColor Yellow
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Vérification Winget ---
while (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget est introuvable. Ouverture du Microsoft Store..." -ForegroundColor Cyan
    Start-Process "ms-windows-store://pdp?hl=en-us&gl=us&productid=9nblggh4nns1"
    Write-Host "Appuyez sur Entrée une fois 'App Installer' mis à jour."
    $null = $host.UI.RawUI.ReadKey()
}

# --- Installation des paquets ---
Write-Host "Mise à jour des sources et installation des outils..." -ForegroundColor Green
winget source update
$packages = @("akeo.ie.Zadig", "Git.Git", "Python.Python.3.9")

foreach ($package in $packages) {
    winget install --id=$package --accept-package-agreements --accept-source-agreements --disable-interactivity --scope machine
}

# --- Détection de Git (Ta logique avec &) ---
$gitcmd = ""
if (Test-Path "${env:ProgramFiles}\Git\cmd\git.exe") {
    $gitcmd = "${env:ProgramFiles}\Git\cmd\git.exe"
} elseif (Get-Command "git" -ErrorAction SilentlyContinue) {
    $gitcmd = "git"
} else {
    Write-Host "Git introuvable, abandon..." -ForegroundColor Red
    exit
}

# --- Clonage du dépôt EDL ---
$targetDir = Join-Path $env:ProgramFiles "edl"
if (-not (Test-Path $targetDir)) {
    Write-Host "Clonage de EDL dans $targetDir..." -ForegroundColor Cyan
    # On force le clonage dans le dossier edl spécifiquement
    & $gitcmd clone --recurse-submodules https://github.com/bkerler/edl.git $targetDir
}

# --- Installation des dépendances Python ---
Write-Host "Installation des dépendances Python..." -ForegroundColor Cyan
# On cherche pip de manière plus flexible au cas où le dossier n'est pas "Python39"
if (Get-Command "pip3" -ErrorAction SilentlyContinue) {
    & pip3 install -r "$targetDir\requirements.txt"
} else {
    & python -m pip install -r "$targetDir\requirements.txt"
}

# --- Ajout au PATH ---
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -split ';' -notcontains $targetDir) {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$targetDir", "Machine")
    Write-Host "EDL ajouté au PATH système." -ForegroundColor Green
}

Write-Host "`nInstallation terminée avec succès !" -ForegroundColor Green
Write-Host "N'oubliez pas de lancer 'Zadig' pour les drivers USB."
Write-Host "Appuyez sur une touche pour quitter..."
$null = $host.UI.RawUI.ReadKey()
