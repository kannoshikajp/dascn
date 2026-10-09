Write-Host "Starting Spring Boot backend build process..."

# Navigate to the Spring Boot project directory
cd "$PSScriptRoot\joppe_spring_backend"

Write-Host "Running: .\gradlew bootJar"
# Execute the Gradle wrapper to build the executable JAR
.\gradlew bootJar

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "The JAR file is located in: joppe_spring_backend\build\libs\" -ForegroundColor Yellow
} else {
    Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
