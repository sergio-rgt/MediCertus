@echo off
cd /d C:\PrjFlutter\medicertus_app

echo ==========================
echo VALIDANDO CODIGO FLUTTER
echo ==========================
call flutter analyze

if errorlevel 1 goto error

echo ==========================
echo EJECUTANDO PRUEBAS
echo ==========================
call flutter test

if errorlevel 1 goto error

echo.
echo VALIDACION COMPLETADA CORRECTAMENTE
goto fin

:error
echo.
echo ERROR EN LA VALIDACION

:fin
pause
cls