@echo off
title Ping Optimizasyon Geri Alma Aracı
color 0C

echo --------------------------------------------
echo  Ağ ve TCP Ayarlarını Varsayılana Döndürme
echo --------------------------------------------
echo.

echo [1/4] TCP ayarları sıfırlanıyor...
netsh int tcp set global autotuninglevel=normal
netsh int tcp set global rss=default
netsh int tcp set global chimney=default
netsh int tcp set global dca=disabled
netsh int tcp set global ecncapability=default
netsh int tcp set global timestamps=default
netsh int tcp set global netdma=disabled
netsh int tcp set heuristics enabled

echo [2/4] IPv6 yeniden etkinleştiriliyor...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 0 /f
netsh interface ipv6 set teredo default
netsh interface ipv6 set privacy enabled
netsh interface ipv6 set global randomizeidentifiers=enabled

echo [3/4] MTU değeri varsayılana alınıyor...
netsh interface ipv4 set subinterface "Wi-Fi" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent

echo [4/4] Ağ yapılandırması sıfırlanıyor...
ipconfig /flushdns
netsh winsock reset
netsh int ip reset

echo.
echo ✅ Tüm ayarlar varsayılana döndürüldü.
echo Lütfen bilgisayarınızı yeniden başlatın.
pause
exit
