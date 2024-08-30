param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    [string]$FolderToBackup,

    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    [string]$ArchiveFolder,

    [Parameter()]
    [int]$RetentionDays = 14
)

# Create backup and archive folders if they don't exist
if (-not (Test-Path $FolderToBackup)) {
    Write-Error "Folder to backup does not exist: $FolderToBackup"
    exit 1
}

if (-not (Test-Path $ArchiveFolder)) {
    New-Item -Path $ArchiveFolder -ItemType 'Directory' | Out-Null
}

# Generate a unique backup name based on current date and time
$BackupName = 'Backup_{0:yyyyMMdd_HHmmss}' -f (Get-Date)

# Create a new zip archive for the backup
$ZipPath = Join-Path -Path $ArchiveFolder -ChildPath "$BackupName.zip"
$ZipFile = [System.IO.Compression.ZipFile]::Open($ZipPath, 'Create')

try {
    # Copy all files from the folder to backup into the zip archive
    Get-ChildItem -Path $FolderToBackup -Recurse -File | ForEach-Object {
        $RelativePath = $_.FullName.Substring($FolderToBackup.Length + 1)
        $Entry = $ZipFile.CreateEntry($RelativePath)
        $EntryStream = $Entry.Open()
        $FileStream = $_.OpenRead()

        try {
            $FileStream.CopyTo($EntryStream)
        }
        finally {
            $FileStream.Close()
            $EntryStream.Close()
        }
    }
}
finally {
    $ZipFile.Dispose()
}

# Move the zip file to the archive folder
$ZipFile.MoveTo($ArchiveFolder)

# Delete archives older than the retention period
$OldArchives = Get-ChildItem -Path $ArchiveFolder -File | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays)
}

$OldArchives | Remove-Item -Force