@echo off
title Intel AX200 Wi-Fi Ping Optimizasyon Aracı
color 0A

echo --------------------------------------------
echo  Intel Wi-Fi 6 AX200 için Ping Optimizasyonu
echo --------------------------------------------
echo.
echo [1/6] Ağ önbellekleri temizleniyor...

ipconfig /flushdns
ipconfig /release
ipconfig /renew
netsh winsock reset
netsh int ip reset

echo [2/6] IPv6 devre dışı bırakılıyor...
netsh interface ipv6 set teredo disabled
netsh interface ipv6 set privacy disabled
netsh interface ipv6 set global randomizeidentifiers=disabled
netsh interface ipv6 set global reassemblylimit=0
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 255 /f

echo [3/6] TCP performans ayarları uygulanıyor...

netsh int tcp set global autotuninglevel=normal
netsh int tcp set global rss=enabled
netsh int tcp set global chimney=enabled
netsh int tcp set global dca=enabled
netsh int tcp set global ecncapability=disabled
netsh int tcp set global timestamps=disabled
netsh int tcp set global netdma=enabled
netsh int tcp set heuristics disabled

echo [4/6] MTU ayarlanıyor...
netsh interface ipv4 set subinterface "Wi-Fi" mtu=1492 store=persistent

echo [5/6] DNS önbelleği temizleniyor...
ipconfig /flushdns

echo [6/6] Güç yönetimi kontrolü...
echo Güç tasarrufu özelliğini manuel olarak kapatmak için:
echo Aygıt Yöneticisi > Ağ Bağdaştırıcıları > Intel Wi-Fi 6 AX200 > Güç Yönetimi sekmesi > "Güç tasarrufu için bu aygıtı kapat" kutusunu kaldırın.
echo.

echo ✅ Optimizasyon tamamlandı!
echo Lütfen bilgisayarınızı yeniden başlatın.
pause
exit
