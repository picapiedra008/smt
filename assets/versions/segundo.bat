@echo off
echo ============================================
echo Creando estructura completa Flutter + archivos...
echo ============================================

REM ====== LIB STRUCTURE ======

mkdir lib\core\config
mkdir lib\core\constants
mkdir lib\core\utils
mkdir lib\core\themes
mkdir lib\core\widgets

mkdir lib\data\models
mkdir lib\data\repositories
mkdir lib\data\local
mkdir lib\data\remote

mkdir lib\domain\entities
mkdir lib\domain\usecases

mkdir lib\presentation\pages
mkdir lib\presentation\widgets
mkdir lib\presentation\controllers
mkdir lib\presentation\state

mkdir lib\routes
mkdir lib\services

REM ====== ASSETS STRUCTURE ======

mkdir assets\images\logos
mkdir assets\images\icons
mkdir assets\images\illustrations
mkdir assets\images\backgrounds

mkdir assets\media\audio
mkdir assets\media\video

mkdir assets\docs\pdf
mkdir assets\docs\txt

mkdir assets\data\json
mkdir assets\data\csv

REM ====== CREATE .dart SAMPLE FILES ======

REM Core
echo // Global app configuration > lib\core\config\app_config.dart
echo const String appTitle = "Prueba1 App"; >> lib\core\config\app_config.dart

echo // Global constants > lib\core\constants\constants.dart
echo class AppConstants {} >> lib\core\constants\constants.dart

echo // Utility functions > lib\core\utils\utils.dart
echo class Utils {} >> lib\core\utils\utils.dart

echo // Theme setup > lib\core\themes\app_theme.dart
echo import 'package:flutter/material.dart'; > lib\core\themes\app_theme.dart
echo class AppTheme { >> lib\core\themes\app_theme.dart
echo   static ThemeData lightTheme = ThemeData.light(); >> lib\core\themes\app_theme.dart
echo } >> lib\core\themes\app_theme.dart

echo // Shared reusable widgets > lib\core\widgets\custom_button.dart
echo import 'package:flutter/material.dart'; > lib\core\widgets\custom_button.dart
echo class CustomButton extends StatelessWidget { >> lib\core\widgets\custom_button.dart
echo   final String text; >> lib\core\widgets\custom_button.dart
echo   const CustomButton({super.key, required this.text}); >> lib\core\widgets\custom_button.dart
echo   @override >> lib\core\widgets\custom_button.dart
echo   Widget build(BuildContext context) { >> lib\core\widgets\custom_button.dart
echo     return ElevatedButton(onPressed: (){}, child: Text(text)); >> lib\core\widgets\custom_button.dart
echo   } >> lib\core\widgets\custom_button.dart
echo } >> lib\core\widgets\custom_button.dart

REM Data layer

echo class UserModel {} > lib\data\models\user_model.dart
echo abstract class UserRepository {} > lib\data\repositories\user_repository.dart
echo class LocalDataSource {} > lib\data\local\local_data_source.dart
echo class RemoteDataSource {} > lib\data\remote\remote_data_source.dart

REM Domain layer

echo class UserEntity {} > lib\domain\entities\user_entity.dart
echo class GetUsersUseCase {} > lib\domain\usecases\get_users_usecase.dart

REM Presentation layer

echo import 'package:flutter/material.dart'; > lib\presentation\pages\home_page.dart
echo class HomePage extends StatelessWidget { >> lib\presentation\pages\home_page.dart
echo   const HomePage({super.key}); >> lib\presentation\pages\home_page.dart
echo   @override >> lib\presentation\pages\home_page.dart
echo   Widget build(BuildContext context) { >> lib\presentation\pages\home_page.dart
echo     return Scaffold(appBar: AppBar(title: Text("Home Page")),body: Center(child: Text("Hola Flutter"))); >> lib\presentation\pages\home_page.dart
echo   } >> lib\presentation\pages\home_page.dart
echo } >> lib\presentation\pages\home_page.dart

echo class HomeController {} > lib\presentation\controllers\home_controller.dart
echo class AppState {} > lib\presentation\state\app_state.dart
echo class CustomCard extends StatelessWidget { >> lib\presentation\widgets\custom_card.dart
echo   const CustomCard({super.key}); >> lib\presentation\widgets\custom_card.dart
echo   @override >> lib\presentation\widgets\custom_card.dart
echo   Widget build(BuildContext context) { >> lib\presentation\widgets\custom_card.dart
echo     return Card(child: Padding(padding: EdgeInsets.all(16),child: Text("Card"))); >> lib\presentation\widgets\custom_card.dart
echo   } >> lib\presentation\widgets\custom_card.dart
echo } >> lib\presentation\widgets\custom_card.dart

REM Routes
echo class AppRoutes {} > lib\routes\app_routes.dart

REM Services
echo class NotificationService {} > lib\services\notification_service.dart

echo ============================================
echo Estructura creada con exito.
echo ============================================
pause
