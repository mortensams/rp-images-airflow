# Local build script for Airflow container image (PowerShell)

param(
    [string]$Name = "airflow-custom",
    [string]$Tag = "latest",
    [string]$Registry = "",
    [switch]$Push,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\build.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Name NAME       Image name (default: airflow-custom)"
    Write-Host "  -Tag TAG         Image tag (default: latest)"
    Write-Host "  -Registry REG    Registry prefix (e.g., ghcr.io/username)"
    Write-Host "  -Push            Push image after building"
    Write-Host "  -Help            Show this help message"
    exit 0
}

# Build full image reference
if ($Registry) {
    $FullImage = "${Registry}/${Name}:${Tag}"
} else {
    $FullImage = "${Name}:${Tag}"
}

Write-Host "Building image: $FullImage"

# Build the image
docker build -t $FullImage .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

Write-Host "Build complete: $FullImage"

# Push if requested
if ($Push) {
    Write-Host "Pushing image: $FullImage"
    docker push $FullImage

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Push failed"
        exit 1
    }

    Write-Host "Push complete"
}
