# apply_dns.ps1 - DNS Ayarlarını Otomatik Uygulayıcı (Yol Düzeltmeli)
# Yazan: Gemini AI

# --- YOL DÜZELTME ---
$ScriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptPath)) {
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
$BestDnsFile = Join-Path -Path $ScriptPath -ChildPath "best_dns.txt"
$BackupDnsFile = Join-Path -Path $ScriptPath -ChildPath "backup_dns.txt"
# --------------------

# Yönetici hakları kontrolü
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "HATA: Bu script Yönetici hakları gerektirir!" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit
}

# Dosya kontrolleri (Tam yol ile)
if (!(Test-Path $BestDnsFile) -or !(Test-Path $BackupDnsFile)) {
    Write-Error "DNS dosyaları bulunamadı!"
    Write-Error "Aranan yer: $ScriptPath"
    Write-Error "Lütfen önce benchmark scriptini çalıştırın."
    Read-Host "Çıkmak için Enter'a basın..."
    exit
}

$bestDns = (Get-Content $BestDnsFile).Trim()
$backupDns = (Get-Content $BackupDnsFile).Trim()

Write-Host "Aktif ağ bağdaştırıcısı aranıyor..." -ForegroundColor Cyan
try {
    $activeAdapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Sort-Object -Descending LinkSpeed | Select-Object -First 1
    if (!$activeAdapter) { throw "Aktif bir ağ bağdaştırıcısı bulunamadı!" }
    $InterfaceName = $activeAdapter.Name
    Write-Host "Bulunan adaptör: $InterfaceName ($($activeAdapter.InterfaceDescription))" -ForegroundColor Green
}
catch {
    Write-Error "Adaptör tespit hatası: $_"
    Get-NetAdapter | Format-Table Name, Status, LinkSpeed
    $InterfaceName = Read-Host "Lütfen listeden adaptör adını (Name) yazın"
}

Write-Host "`nUygulanacak Ayarlar:" -ForegroundColor Yellow
Write-Host "Adaptör  : $InterfaceName"
Write-Host "DNS 1    : $bestDns"
Write-Host "DNS 2    : $backupDns`n"

try {
    Write-Host "DNS ayarları uygulanıyor..." -ForegroundColor Cyan
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceName -ServerAddresses ($bestDns, $backupDns) -ErrorAction Stop
    Write-Host "DNS önbelleği temizleniyor..." -ForegroundColor Cyan
    Clear-DnsClientCache
    Write-Host "`nBAŞARILI! Yeni DNS ayarları uygulandı." -ForegroundColor Green

    Write-Host "`nGüncel DNS Yapılandırması:" -ForegroundColor Gray
    Get-DnsClientServerAddress -InterfaceAlias $InterfaceName | Select-Object InterfaceAlias, ServerAddresses | Format-List
}
catch {
    Write-Error "Ayarlar uygulanırken bir hata oluştu: $_"
}

Write-Host "`nÇıkmak için Enter'a basın..."
Read-Host