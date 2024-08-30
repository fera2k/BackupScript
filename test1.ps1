param (
    [Parameter(Mandatory=$true)]
    [string]$sourceFolder,
    
    [Parameter(Mandatory=$true)]
    [string]$destinationFolder,
    
    [int]$retentionDays = 14
)

# Verifica se a pasta de origem existe
if (-not (Test-Path $sourceFolder)) {
    Write-Host "A pasta de origem não existe."
    exit
}

# Verifica se a pasta de destino existe, caso contrário, cria-a
if (-not (Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}

# Cria o nome do arquivo zip baseado na data atual
$zipFileName = "Backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".zip"
$zipFilePath = Join-Path -Path $destinationFolder -ChildPath $zipFileName

# Cria o arquivo zip
Add-Type -A 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::CreateFromDirectory($sourceFolder, $zipFilePath)

# Exclui os arquivos mais antigos do que o tempo de retenção
$cutOffDate = (Get-Date).AddDays(-$retentionDays)
Get-ChildItem $destinationFolder -File | Where-Object { $_.LastWriteTime -lt $cutOffDate } | Remove-Item -Force

Write-Host "Arquivo zip criado em: $zipFilePath"
Write-Host "Arquivos mais antigos do que $retentionDays dias foram excluídos."

