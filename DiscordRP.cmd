@echo off
chcp 65001 >nul
title Discord Rich Presence
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0drp.ps1"
