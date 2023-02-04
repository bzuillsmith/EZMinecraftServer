$javaVersionCheckResult = & java --version;
if (-not $?) {
    Write-Host "Java is not installed. Installing jdk from 'https://download.oracle.com/java/19/latest/jdk-19_windows-x64_bin.exe'";
    & Invoke-WebRequest -OutFile "$env:Temp\jdk-19_windows-x64_bin.exe" -Uri https://download.oracle.com/java/19/latest/jdk-19_windows-x64_bin.exe;
    Write-Host "Installing jdk-19_windows-x64_bin.exe..."
    & "$env:Temp\jdk-19_windows-x64_bin.exe" /s # Other possible options: /L=1033 /v"/qn INSTALLDIR=C:\Program Files\Java\jdk-19";
    Write-Host "... complete"
}

$minecraftServerDownloadUrl = "https://piston-data.mojang.com/v1/objects/c9df48efed58511cdd0213c56b9013a7b5c9ac1f/server.jar";
$version = "1.19.3";
$localMinecraftServerPath = "E:\Minecraft\Server";

$currentVersionPath = "$localMinecraftServerPath\$version";
# Create the directory if it doesn't exist
if (-not (Test-Path $currentVersionPath -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $currentVersionPath;
}
$serverJarPath = "$currentVersionPath\server.jar";
$serverJarExists = Test-Path $serverJarPath -PathType Leaf;
if (-not $serverJarExists) {
    Write-Host "Downloading Minecraft server version $version from $minecraftServerDownloadUrl...";
    Invoke-WebRequest -OutFile $serverJarPath -Uri $minecraftServerDownloadUrl;
    Write-Host "... complete";
}
$eulaPath = "$currentVersionPath\eula.txt";
$eulaExists = Test-Path $eulaPath -PathType Leaf;
if (-not $eulaExists)
{
    Write-Output "#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula).`r`n#Sun Mar 27 18:57:27 PDT 2022`r`neula=true" | Out-File $eulaPath;
    Write-Host "Automatically agreed to eula";
}
else
{
    Write-Host "eula exists"
}

Write-Host "Starting Minecraft server version $version";
Write-Host "Press Ctrl+C to stop the server";
Set-Location $currentVersionPath
& java -Xmx1024M -Xms1024M -jar $serverJarPath nogui;