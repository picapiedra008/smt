@echo off
setlocal

REM Ruta del proyecto
set PROJECT_DIR=H:\ap4\prueba1

echo Creando estructura de carpetas en %PROJECT_DIR%...
echo.

REM --- ASSETS ---
mkdir "%PROJECT_DIR%\assets"
mkdir "%PROJECT_DIR%\assets\images"
mkdir "%PROJECT_DIR%\assets\icons"
mkdir "%PROJECT_DIR%\assets\fonts"
mkdir "%PROJECT_DIR%\assets\animations"
mkdir "%PROJECT_DIR%\assets\videos"
mkdir "%PROJECT_DIR%\assets\audio"

REM --- DATA ---
mkdir "%PROJECT_DIR%\assets\data"
mkdir "%PROJECT_DIR%\assets\data\local"
mkdir "%PROJECT_DIR%\assets\data\mock"
mkdir "%PROJECT_DIR%\assets\data\json"

REM --- DOCS ---
mkdir "%PROJECT_DIR%\docs"
mkdir "%PROJECT_DIR%\docs\manuales"
mkdir "%PROJECT_DIR%\docs\diagramas"

REM --- SRC / LIB ---
mkdir "%PROJECT_DIR%\lib\core"
mkdir "%PROJECT_DIR%\lib\core\config"
mkdir "%PROJECT_DIR%\lib\core\constants"
mkdir "%PROJECT_DIR%\lib\core\utils"
mkdir "%PROJECT_DIR%\lib\core\theme"

mkdir "%PROJECT_DIR%\lib\data"
mkdir "%PROJECT_DIR%\lib\data\models"
mkdir "%PROJECT_DIR%\lib\data\services"
mkdir "%PROJECT_DIR%\lib\data\providers"
mkdir "%PROJECT_DIR%\lib\data\repositories"

mkdir "%PROJECT_DIR%\lib\presentation"
mkdir "%PROJECT_DIR%\lib\presentation\pages"
mkdir "%PROJECT_DIR%\lib\presentation\widgets"
mkdir "%PROJECT_DIR%\lib\presentation\controllers"

mkdir "%PROJECT_DIR%\lib\domain"
mkdir "%PROJECT_DIR%\lib\domain\entities"
mkdir "%PROJECT_DIR%\lib\domain\usecases"

REM --- UTILS / OTHER ---
mkdir "%PROJECT_DIR%\test\unit"
mkdir "%PROJECT_DIR%\test\widget"
mkdir "%PROJECT_DIR%\test\integration"

echo.
echo ✔ Estructura creada correctamente.
pause
