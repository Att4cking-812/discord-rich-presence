param(
    [string]$ClientId = '',
    [string]$Details = 'Вайбкодит',
    [string]$State = 'Процесс : отрицательный',
    [string]$LargeImage = '',
    [string]$LargeText = 'Goober',
    [int]$RefreshSeconds = 60
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()

$root = $PSScriptRoot
$idFile = Join-Path $root 'client_id.txt'

if (-not $ClientId -and (Test-Path -LiteralPath $idFile)) {
    $ClientId = (Get-Content -LiteralPath $idFile -Raw).Trim()
}

if (-not $ClientId) {
    Clear-Host
    Write-Host ''
    Write-Host '  Discord Rich Presence: нужен Application ID' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  1. Открой https://discord.com/developers/applications'
    Write-Host '  2. New Application -> введи любое имя (например, DeepSeek PC)'
    Write-Host '  3. Скопируй Application ID (длинное число)'
    Write-Host '  4. Вставь его в файл client_id.txt в этой папке и запусти снова.'
    Write-Host ''
    Write-Host '  Картинки (по желанию): в приложении -> Rich Presence -> Art Assets,'
    Write-Host '  загрузи картинку и укажи её ключ в параметре -LargeImage.'
    Write-Host ''
    Read-Host '  Enter, чтобы закрыть'
    exit
}

$appName = ''
try {
    $meta = Invoke-RestMethod -Uri ("https://discord.com/api/v10/applications/{0}/rpc" -f $ClientId) -TimeoutSec 8
    if ($meta.name) { $appName = [string]$meta.name }
} catch { }

function Connect-Discord {
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $pipe = New-Object System.IO.Pipes.NamedPipeClientStream('.', "discord-ipc-$i", [System.IO.Pipes.PipeDirection]::InOut)
            $pipe.Connect(300)
            if ($pipe.IsConnected) { return $pipe }
        } catch { }
    }
    return $null
}

function Send-Packet($pipe, [int]$op, [string]$json) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $bw = New-Object System.IO.BinaryWriter($pipe)
    $bw.Write([int32]$op)
    $bw.Write([int32]$bytes.Length)
    $bw.Write($bytes)
    $bw.Flush()
}

function Read-Packet($pipe) {
    $br = New-Object System.IO.BinaryReader($pipe)
    $op = $br.ReadInt32()
    $len = $br.ReadInt32()
    $buf = $br.ReadBytes($len)
    return [pscustomobject]@{ Op = $op; Json = [Text.Encoding]::UTF8.GetString($buf) }
}

function Set-Activity($pipe, $activity) {
    $payload = @{
        cmd = 'SET_ACTIVITY'
        args = @{ pid = $PID; activity = $activity }
        nonce = [guid]::NewGuid().ToString()
    } | ConvertTo-Json -Depth 8 -Compress
    Send-Packet $pipe 1 $payload
    Start-Sleep -Milliseconds 250
    try { Read-Packet $pipe | Out-Null } catch { }
}

Clear-Host
Write-Host ''
Write-Host '  Discord Rich Presence' -ForegroundColor Cyan
Write-Host '  ---------------------------------------------'

$pipe = Connect-Discord
if (-not $pipe) {
    Write-Host '  Discord не найден. Запусти Discord и повтори.' -ForegroundColor Red
    Read-Host '  Enter, чтобы закрыть'
    exit
}

Send-Packet $pipe 0 (@{ v = 1; client_id = $ClientId } | ConvertTo-Json -Compress)
Start-Sleep -Milliseconds 400
try {
    $ready = Read-Packet $pipe
    if ($ready.Op -eq 1) {
        $obj = $ready.Json | ConvertFrom-Json
        Write-Host ("  Подключено как: {0}" -f $obj.data.user.username) -ForegroundColor Green
    } else {
        Write-Host ("  Ответ Discord: {0}" -f $ready.Json) -ForegroundColor Yellow
    }
} catch {
    Write-Host '  Не удалось прочитать handshake.' -ForegroundColor Yellow
}

Write-Host ''
if ($appName) {
    Write-Host ("  Приложение: {0}" -f $appName) -ForegroundColor DarkGray
}
Write-Host ("  Статус: {0} — {1}" -f $Details, $State) -ForegroundColor Green
Write-Host '  Ctrl+C — остановить.' -ForegroundColor DarkGray
Write-Host ''

function New-Activity {
    $a = @{
        details = $Details
        state = $State
        timestamps = @{ start = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
        instance = $true
    }
    if ($LargeImage) {
        $a.assets = @{ large_image = $LargeImage; large_text = $LargeText }
    }
    return $a
}

# Сбрасываем прошлый статус этого приложения, чтобы Discord не показывал старый.
Set-Activity $pipe $null
Set-Activity $pipe (New-Activity)

try {
    while ($true) {
        Start-Sleep -Seconds $RefreshSeconds
        Set-Activity $pipe (New-Activity)
    }
} catch {
    Write-Host ''
    Write-Host '  Соединение с Discord закрыто.' -ForegroundColor DarkGray
}
