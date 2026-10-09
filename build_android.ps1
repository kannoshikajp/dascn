param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "pod")]
    [string]$Environment = "dev",

    [Parameter(Mandatory=$false)]
    [ValidateSet("apk", "appbundle")]
    [string]$BuildType = "apk"
)

Write-Host "Starting Android build process..."
Write-Host "Environment: $Environment"
Write-Host "Build Type:  $BuildType"

# Navigate to the Flutter project directory
cd "$PSScriptRoot\joppe_flutter_app"

$mode = if ($Environment -eq "pod") { "--release" } else { "--debug" }

if ($BuildType -eq "apk") {
    Write-Host "Running: flutter build apk $mode"
    flutter build apk $mode
} else {
    Write-Host "Running: flutter build appbundle $mode"
    flutter build appbundle $mode
}

Write-Host "Build completed successfully!"
