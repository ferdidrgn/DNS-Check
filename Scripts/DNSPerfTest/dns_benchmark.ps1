# dns_benchmark.ps1 - Gelişmiş DNS Performans Testi (Yol Düzeltmeli)
# Yazan: Gemini AI

param(
    [string]$DnsListFilename = "dns_servers.txt",
    [string[]]$TestDomains = @("google.com", "microsoft.com", "cloudflare.com")
)

# --- YOL DÜZELTME ---
# Scriptin çalıştığı gerçek klasörü bul
$ScriptPath = $PSScriptRoot
# Eğer PSScriptRoot boş gelirse (bazı eski sürümlerde), alternatif yöntem dene
if ([string]::IsNullOrEmpty($ScriptPath)) {
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}

# Tam dosya yolunu oluştur
$DnsListFile = Join-Path -Path $ScriptPath -ChildPath $DnsListFilename
# --------------------

# Yönetici yetkisi uyarısı
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Daha doğru sonuçlar için bu scripti Yönetici olarak çalıştırmanız önerilir."
}

if (!(Test-Path $DnsListFile)) {
    Write-Error "DNS listesi bulunamadı!"
    Write-Error "Aranan yol: $DnsListFile"
    Write-Error "Lütfen '$DnsListFilename' dosyasının script ile AYNI KLASÖRDE olduğundan emin olun."
    Start-Sleep -Seconds 10
    exit
}

Clear-Host
Write-Host "=== Gelişmiş DNS Benchmark Başlıyor ===" -ForegroundColor Cyan
Write-Host "Çalışma Dizini: $ScriptPath" -ForegroundColor Gray
Write-Host "DNS Listesi   : $DnsListFile" -ForegroundColor Gray
Write-Host "Test edilecek domainler: $($TestDomains -join ', ')" -ForegroundColor Gray
Write-Host "NOT: Bu test biraz zaman alacaktır. Lütfen bekleyin..." -ForegroundColor Yellow
Write-Host ""

# DNS listesini oku ve temizle
$rawDnsList = Get-Content $DnsListFile
$dnsServersToTest = @()
foreach ($line in $rawDnsList) {
    $cleanDns = ($line -split '#')[0].Trim()
    if ($cleanDns -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        $dnsServersToTest += $cleanDns
    }
}

$results = @()
$counter = 0
$totalServers = $dnsServersToTest.Count

foreach ($dns in $dnsServersToTest) {
    $counter++
    $percentComplete = ($counter / $totalServers) * 100
    Write-Progress -Activity "DNS Testi Yapılıyor" -Status "Test ediliyor: $dns ($counter / $totalServers)" -PercentComplete $percentComplete

    $serverTotalTime = 0
    $successfulTests = 0

    foreach ($domain in $TestDomains) {
        try {
            $duration = Measure-Command {
                $result = Resolve-DnsName -Name $domain -Server $dns -Type A -ErrorAction Stop
            }
            if ($result) {
                $serverTotalTime += $duration.TotalMilliseconds
                $successfulTests++
            }
        }
        catch {
            $serverTotalTime += 1000 # Ceza puanı
        }
    }

    if ($successfulTests -gt 0) {
        $avgTime = [math]::Round($serverTotalTime / $TestDomains.Count, 2)
    } else {
        $avgTime = 9999
    }

    $results += [PSCustomObject]@{
        DNS = $dns
        AvgTimeMS = $avgTime
        SuccessRate = "$successfulTests/$($TestDomains.Count)"
    }
}

Write-Progress -Activity "DNS Testi Yapılıyor" -Completed

# Sonuçları göster
Clear-Host
Write-Host "=== BENCHMARK SONUÇLARI (Ortalama Yanıt Süresi) ===" -ForegroundColor Green
$sortedResults = $results | Sort-Object AvgTimeMS
$sortedResults | Where-Object { $_.AvgTimeMS -lt 1000 } | Format-Table -AutoSize

# En iyi 2 taneyi kaydet
$best = $sortedResults[0]
$backup = $sortedResults[1]

if ($best.AvgTimeMS -ge 1000) {
    Write-Error "Hiçbir DNS sunucusu düzgün yanıt vermedi."
    Start-Sleep -Seconds 10
    exit
}

Write-Host "EN HIZLI DNS: $($best.DNS) ($($best.AvgTimeMS) ms)" -ForegroundColor Cyan
Write-Host "YEDEK DNS   : $($backup.DNS) ($($backup.AvgTimeMS) ms)" -ForegroundColor Yellow

# Sonuçları tam yola kaydet
$bestFile = Join-Path -Path $ScriptPath -ChildPath "best_dns.txt"
$backupFile = Join-Path -Path $ScriptPath -ChildPath "backup_dns.txt"

$best.DNS | Out-File $bestFile -Encoding ASCII -Force
$backup.DNS | Out-File $backupFile -Encoding ASCII -Force

Write-Host ""
Write-Host "Sonuçlar kaydedildi:" -ForegroundColor Green
Write-Host " - $bestFile"
Write-Host " - $backupFile"
Write-Host ""

$choice = Read-Host "Bu DNS ayarlarını şimdi uygulamak ister misiniz? (E/H)"
if ($choice -eq 'E' -or $choice -eq 'e') {
    $applyScript = Join-Path -Path $ScriptPath -ChildPath "apply_dns.ps1"
    if (Test-Path $applyScript) {
        PowerShell -NoProfile -ExecutionPolicy Bypass -File $applyScript
    } else {
        Write-Warning "'apply_dns.ps1' bulunamadı: $applyScript"
        Read-Host "Çıkmak için Enter'a basın..."
    }
}