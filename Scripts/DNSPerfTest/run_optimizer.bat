@echo off
title DNS Optimizer
color 0B
echo ===================================
echo      GELISMIS DNS OPTIMIZER
echo ===================================
echo.
echo Script yonetici haklariyla yeni bir pencerede baslatiliyor...
echo Lutfen cikan UAC (Kullanici Hesabi Denetimi) uyarisina EVET deyin.
echo.
echo NOT: Islem bittiginde veya hata verdiginde o pencere acik kalacaktir.
echo.

:: -NoExit parametresi eklendi: Pencerenin işlem bitince kapanmasını önler.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File ""%~dp0dns_benchmark.ps1""' -Verb RunAs}"