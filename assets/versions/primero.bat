@echo off
echo =============================
echo Creando estructura Flutter...
echo =============================

REM Carpetas principales dentro de /lib
mkdir lib\core
mkdir lib\core\config
mkdir lib\core\constants
mkdir lib\core\utils
mkdir lib\core\themes
mkdir lib\core\widgets

mkdir lib\data
mkdir lib\data\models
mkdir lib\data\repositories
mkdir lib\data\local
mkdir lib\data\remote

mkdir lib\domain
mkdir lib\domain\entities
mkdir lib\domain\usecases

mkdir lib\presentation
mkdir lib\presentation\pages
mkdir lib\presentation\widgets
mkdir lib\presentation\controllers
mkdir lib\presentation\state

mkdir lib\routes
mkdir lib\services

REM Carpetas de assets
mkdir assets
mkdir assets\images
mkdir assets\images\logos
mkdir assets\images\icons
mkdir assets\images\illustrations
mkdir assets\images\backgrounds

mkdir assets\media
mkdir assets\media\audio
mkdir assets\media\video

mkdir assets\docs
mkdir assets\docs\pdf
mkdir assets\docs\txt

mkdir assets\data
mkdir assets\data\json
mkdir assets\data\csv

echo =============================
echo Carpetas creadas correctamente.
echo =============================
pause
