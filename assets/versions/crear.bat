@echo off
echo ============================================
echo Creando estructura Flutter (Clean + GoRouter + Riverpod)...
echo ============================================

REM ======= CORE STRUCTURE ========
mkdir lib\core
mkdir lib\core\config
mkdir lib\core\constants
mkdir lib\core\themes
mkdir lib\core\utils
mkdir lib\core\widgets

REM ======= DATA LAYER ========
mkdir lib\data
mkdir lib\data\models
mkdir lib\data\repositories
mkdir lib\data\datasources
mkdir lib\data\datasources\local
mkdir lib\data\datasources\remote

REM ======= DOMAIN LAYER ========
mkdir lib\domain
mkdir lib\domain\entities
mkdir lib\domain\repositories
mkdir lib\domain\usecases

REM ======= PRESENTATION LAYER ========
mkdir lib\presentation
mkdir lib\presentation\pages
mkdir lib\presentation\pages\home
mkdir lib\presentation\pages\login
mkdir lib\presentation\pages\splash
mkdir lib\presentation\widgets
mkdir lib\presentation\controllers

REM ======= ROUTES ========
mkdir lib\routes

REM ======= SERVICES ========
mkdir lib\services

REM ======= ASSETS ========
mkdir assets
mkdir assets\images
mkdir assets\images\logos
mkdir assets\images\icons
mkdir assets\media
mkdir assets\data

REM ======= FILE CREATION ========

REM -------- core/config/app_config.dart --------
echo const appName = "Prueba1 App"; > lib\core\config\app_config.dart

REM -------- core/constants/app_colors.dart --------
echo import 'package:flutter/material.dart'; > lib\core\constants\app_colors.dart
echo class AppColors { >> lib\core\constants\app_colors.dart
echo   static const primary = Colors.blue; >> lib\core\constants\app_colors.dart
echo   static const secondary = Colors.orange; >> lib\core\constants\app_colors.dart
echo } >> lib\core\constants\app_colors.dart

REM -------- core/themes/app_theme.dart --------
echo import 'package:flutter/material.dart'; > lib\core\themes\app_theme.dart
echo class AppTheme { >> lib\core\themes\app_theme.dart
echo   static ThemeData light = ThemeData(primarySwatch: Colors.blue); >> lib\core\themes\app_theme.dart
echo } >> lib\core\themes\app_theme.dart

REM -------- core/utils/logger.dart --------
echo class AppLogger { >> lib\core\utils\logger.dart
echo   static void log(msg) { print("[LOG] $msg"); } >> lib\core\utils\logger.dart
echo } >> lib\core\utils\logger.dart

REM -------- core/widgets/big_button.dart --------
echo import 'package:flutter/material.dart'; > lib\core\widgets\big_button.dart
echo class BigButton extends StatelessWidget { >> lib\core\widgets\big_button.dart
echo   final String text; final VoidCallback onTap; >> lib\core\widgets\big_button.dart
echo   const BigButton({super.key, required this.text, required this.onTap}); >> lib\core\widgets\big_button.dart
echo   @override Widget build(BuildContext context){ >> lib\core\widgets\big_button.dart
echo     return ElevatedButton(style: ElevatedButton.styleFrom(padding: EdgeInsets.all(20)), onPressed: onTap, child: Text(text)); >> lib\core\widgets\big_button.dart
echo   } >> lib\core\widgets\big_button.dart
echo } >> lib\core\widgets\big_button.dart

REM ----------------------------------------------
REM DOMAIN LAYER
REM ----------------------------------------------

echo class UserEntity {final String id; final String name; UserEntity(this.id,this.name);} > lib\domain\entities\user_entity.dart
echo abstract class UserRepository {Future<List<UserEntity>> getUsers();} > lib\domain\repositories\user_repository.dart
echo class GetUsersUseCase {final UserRepository repo; GetUsersUseCase(this.repo); Future call()=>repo.getUsers();} > lib\domain\usecases\get_users_usecase.dart

REM ----------------------------------------------
REM DATA LAYER
REM ----------------------------------------------
echo class UserModel {final String id; final String name; UserModel(this.id,this.name);} > lib\data\models\user_model.dart

REM Fake datasource
echo import '../../domain/entities/user_entity.dart'; > lib\data\datasources\remote\user_remote_datasource.dart
echo class UserRemoteDataSource { >> lib\data\datasources\remote\user_remote_datasource.dart
echo   Future<List<UserEntity>> fetchUsers() async { >> lib\data\datasources\remote\user_remote_datasource.dart
echo     return [UserEntity("1","Juan"),UserEntity("2","Maria")]; >> lib\data\datasources\remote\user_remote_datasource.dart
echo   } >> lib\data\datasources\remote\user_remote_datasource.dart
echo } >> lib\data\datasources\remote\user_remote_datasource.dart

echo import '../../domain/entities/user_entity.dart'; > lib\data\repositories\user_repository_impl.dart
echo import '../datasources/remote/user_remote_datasource.dart'; >> lib\data\repositories\user_repository_impl.dart
echo import '../../domain/repositories/user_repository.dart'; >> lib\data\repositories\user_repository_impl.dart
echo class UserRepositoryImpl implements UserRepository { >> lib\data\repositories\user_repository_impl.dart
echo   final UserRemoteDataSource remote; >> lib\data\repositories\user_repository_impl.dart
echo   UserRepositoryImpl(this.remote); >> lib\data\repositories\user_repository_impl.dart
echo   @override Future<List<UserEntity>> getUsers()=>remote.fetchUsers(); >> lib\data\repositories\user_repository_impl.dart
echo } >> lib\data\repositories\user_repository_impl.dart

REM ----------------------------------------------
REM PRESENTATION (PAGES)
REM ----------------------------------------------

REM Splash page
echo import 'package:flutter/material.dart'; > lib\presentation\pages\splash\splash_page.dart
echo class SplashPage extends StatelessWidget { >> lib\presentation\pages\splash\splash_page.dart
echo   const SplashPage({super.key}); >> lib\presentation\pages\splash\splash_page.dart
echo   @override Widget build(BuildContext context){ >> lib\presentation\pages\splash\splash_page.dart
echo     return const Scaffold(body: Center(child: Text("Cargando..."))); >> lib\presentation\pages\splash\splash_page.dart
echo   } >> lib\presentation\pages\splash\splash_page.dart
echo } >> lib\presentation\pages\splash\splash_page.dart

REM Login page
echo import 'package:flutter/material.dart'; > lib\presentation\pages\login\login_page.dart
echo class LoginPage extends StatelessWidget { >> lib\presentation\pages\login\login_page.dart
echo   const LoginPage({super.key}); >> lib\presentation\pages\login\login_page.dart
echo   @override Widget build(BuildContext context){ >> lib\presentation\pages\login\login_page.dart
echo     return Scaffold(appBar: AppBar(title: Text("Login")),body: Center(child: Text("Pantalla de Login"))); >> lib\presentation\pages\login\login_page.dart
echo   } >> lib\presentation\pages\login\login_page.dart
echo } >> lib\presentation\pages\login\login_page.dart

REM Home page
echo import 'package:flutter/material.dart'; > lib\presentation\pages\home\home_page.dart
echo class HomePage extends StatelessWidget { >> lib\presentation\pages\home\home_page.dart
echo   const HomePage({super.key}); >> lib\presentation\pages\home\home_page.dart
echo   @override Widget build(BuildContext context){ >> lib\presentation\pages\home\home_page.dart
echo     return Scaffold(appBar: AppBar(title: Text("Home")),body: Center(child: Text("Bienvenido a la app"))); >> lib\presentation\pages\home\home_page.dart
echo   } >> lib\presentation\pages\home\home_page.dart
echo } >> lib\presentation\pages\home\home_page.dart

REM ----------------------------------------------
REM ROUTER (GoRouter)
REM ----------------------------------------------

echo import 'package:go_router/go_router.dart'; > lib\routes\app_router.dart
echo import '../presentation/pages/home/home_page.dart'; >> lib\routes\app_router.dart
echo import '../presentation/pages/login/login_page.dart'; >> lib\routes\app_router.dart
echo import '../presentation/pages/splash/splash_page.dart'; >> lib\routes\app_router.dart
echo final appRouter = GoRouter( >> lib\routes\app_router.dart
echo   initialLocation: '/', >> lib\routes\app_router.dart
echo   routes: [ >> lib\routes\app_router.dart
echo     GoRoute(path: '/', builder: (_,__)=>const SplashPage()), >> lib\routes\app_router.dart
echo     GoRoute(path: '/login', builder: (_,__)=>const LoginPage()), >> lib\routes\app_router.dart
echo     GoRoute(path: '/home', builder: (_,__)=>const HomePage()), >> lib\routes\app_router.dart
echo   ], >> lib\routes\app_router.dart
echo ); >> lib\routes\app_router.dart

echo ============================================
echo PROYECTO ESTRUCTURADO EXITOSAMENTE
echo ============================================
pause
