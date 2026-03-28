[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $true)]
    [string]$Pwd,

    [string]$Target = ".",
    [string]$DownloadsDir = "$HOME\Downloads",
    [int]$TimeoutMinutes = 30,
    [int]$PollSeconds = 3,
    [switch]$NoOpenBrowser,
    [switch]$NoClipboard,
    [switch]$NoExtract
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-AbsolutePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    $item = New-Item -ItemType Directory -Path $Path -Force
    return $item.FullName
}

function Get-CandidateItems {
    param(
        [datetime]$Since,
        [string]$Directory
    )

    $tempExtensions = @(".crdownload", ".download", ".part", ".tmp")
    Get-ChildItem -LiteralPath $Directory -Force |
        Where-Object {
            $_.LastWriteTime -ge $Since -and
            $tempExtensions -notcontains $_.Extension.ToLowerInvariant()
        } |
        Sort-Object LastWriteTime -Descending
}

function Get-ItemFingerprint {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item
    )

    if ($Item.PSIsContainer) {
        $children = @(Get-ChildItem -LiteralPath $Item.FullName -Force -Recurse -ErrorAction SilentlyContinue)
        return "{0}|{1}|{2}" -f $Item.LastWriteTimeUtc.Ticks, $children.Count, $Item.Name
    }

    return "{0}|{1}|{2}" -f $Item.Length, $Item.LastWriteTimeUtc.Ticks, $Item.Name
}

function Wait-ForStableDownload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        [Parameter(Mandatory = $true)]
        [datetime]$Since,
        [int]$PollIntervalSeconds,
        [int]$TimeoutInMinutes
    )

    $deadline = (Get-Date).AddMinutes($TimeoutInMinutes)
    $stableCount = @{}

    while ((Get-Date) -lt $deadline) {
        $candidates = @(Get-CandidateItems -Since $Since -Directory $Directory)
        foreach ($candidate in $candidates) {
            $fingerprint = Get-ItemFingerprint -Item $candidate
            if ($stableCount.ContainsKey($candidate.FullName)) {
                if ($stableCount[$candidate.FullName].Fingerprint -eq $fingerprint) {
                    $stableCount[$candidate.FullName].Count += 1
                } else {
                    $stableCount[$candidate.FullName] = @{
                        Fingerprint = $fingerprint
                        Count = 1
                    }
                }
            } else {
                $stableCount[$candidate.FullName] = @{
                    Fingerprint = $fingerprint
                    Count = 1
                }
            }

            if ($stableCount[$candidate.FullName].Count -ge 3) {
                return Get-Item -LiteralPath $candidate.FullName -Force
            }
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }

    throw "未在 $TimeoutInMinutes 分钟内检测到稳定完成的下载文件。"
}

function Get-UniqueDestinationPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory,
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item
    )

    $candidatePath = Join-Path $TargetDirectory $Item.Name
    if (-not (Test-Path -LiteralPath $candidatePath)) {
        return $candidatePath
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Item.Name)
    $extension = [System.IO.Path]::GetExtension($Item.Name)
    $index = 1

    while ($true) {
        $newName = "{0}-{1}{2}" -f $baseName, $index, $extension
        $candidatePath = Join-Path $TargetDirectory $newName
        if (-not (Test-Path -LiteralPath $candidatePath)) {
            return $candidatePath
        }
        $index += 1
    }
}

function Expand-IfPossible {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    $archiveExtensions = @(".zip", ".7z", ".rar")
    if ($archiveExtensions -notcontains $extension) {
        return $null
    }

    $extractDirName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $extractDir = Join-Path $TargetDirectory $extractDirName
    if (Test-Path -LiteralPath $extractDir) {
        $suffix = 1
        while (Test-Path -LiteralPath ("{0}-{1}" -f $extractDir, $suffix)) {
            $suffix += 1
        }
        $extractDir = "{0}-{1}" -f $extractDir, $suffix
    }

    if ($extension -eq ".zip") {
        Expand-Archive -LiteralPath $FilePath -DestinationPath $extractDir -Force
        return $extractDir
    }

    $sevenZip = Get-Command 7z -ErrorAction SilentlyContinue
    if ($null -eq $sevenZip) {
        return $null
    }

    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    & $sevenZip.Source x $FilePath "-o$extractDir" -y | Out-Null
    return $extractDir
}

$targetDir = Resolve-AbsolutePath -Path $Target
$downloadDir = Resolve-AbsolutePath -Path $DownloadsDir
$startTime = Get-Date

Write-Host "分享链接: $Url"
Write-Host "提取码: $Pwd"
Write-Host "下载目录: $downloadDir"
Write-Host "目标目录: $targetDir"

if (-not $NoClipboard) {
    try {
        Set-Clipboard -Value $Pwd
        Write-Host "提取码已复制到剪贴板。"
    } catch {
        Write-Warning "复制提取码到剪贴板失败，请手动复制。"
    }
}

if (-not $NoOpenBrowser) {
    try {
        Start-Process $Url | Out-Null
        Write-Host "已打开百度网盘分享链接，请完成提取码输入并开始下载。"
    } catch {
        Write-Warning "自动打开浏览器失败，请手动打开链接。"
    }
}

Write-Host "开始监听下载目录，等待下载完成..."
$downloadedItem = Wait-ForStableDownload -Directory $downloadDir -Since $startTime -PollIntervalSeconds $PollSeconds -TimeoutInMinutes $TimeoutMinutes
$destinationPath = Get-UniqueDestinationPath -TargetDirectory $targetDir -Item $downloadedItem

Move-Item -LiteralPath $downloadedItem.FullName -Destination $destinationPath
Write-Host "已移动到目标目录: $destinationPath"

if (-not $NoExtract -and -not (Get-Item -LiteralPath $destinationPath).PSIsContainer) {
    try {
        $extractPath = Expand-IfPossible -FilePath $destinationPath -TargetDirectory $targetDir
        if ($extractPath) {
            Write-Host "已自动解压到: $extractPath"
        } else {
            Write-Host "未自动解压: 当前文件不是支持的压缩包，或未检测到 7z。"
        }
    } catch {
        Write-Warning "自动解压失败: $($_.Exception.Message)"
    }
}
