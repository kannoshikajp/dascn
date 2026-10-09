# Joppe Project - Development Summary

This document outlines the foundational work and features implemented across the Joppe ecosystem (Flutter App & Spring Boot Backend) during this development session.

## 1. Source Control Setup
* **Git Repository**: Initialized the local Git repository for the entire workspace.
* **Branching Strategy**: Set up `main` and `dev` branches, with active development tracked on `dev`.

## 2. Frontend: Flutter App (`joppe_flutter_app`)
* **Project Initialization**: Created a clean Flutter project supporting **Web** (Chrome/Edge) and **Android**.
* **UI/UX Foundation**: Configured Google **Material 3** design guidelines as the primary theme.
* **Core Screens & Models**:
  * `HomeScreen`: Displays a grid of products.
  * `ProductDetailsScreen`: Includes Hero animations and detailed layouts.
  * `CartScreen`: Base placeholder for shopping cart interactions.
  * `Product` model & `mock_data.dart` built to drive the initial UI.
* **Android Build Optimization**: Disabled Kotlin incremental compilation in `gradle.properties` to fix local build errors.
* **Build Automation**: Created flexible build scripts (`build_android.ps1`, `build_android_dev.bat`, `build_android_pod.bat`) to quickly compile debug `apk` and release `appbundle` targets.

## 3. Backend: Spring Boot API (`joppe_spring_backend`)
* **Database Schema Analysis**: Parsed and processed the `db_schema.pdf` (18 tables across 6 domains) to ensure exact compliance with UUIDs, INT primary keys, and relations.
* **JPA Entity Mapping**: 
  * Implemented core entities: `User`, `Role`, `Category`, `Brand`, and `Product`.
* **Dynamic RBAC (Role-Based Access Control)**:
  * Restructured security to use a fully dynamic database-driven RBAC model.
  * Created `PermissionGroup` and `Permission` entities, relating them seamlessly to the `Role` entity via Many-To-Many mapping.
* **Authentication System (HMAC + JWT)**:
  * Integrated JJWT dependencies and configured a fully stateless authentication layer.
  * Built `JwtService`, `JwtAuthenticationFilter`, and `SecurityConfig`.
  * Exposed `/api/v1/auth/login` and `/api/v1/auth/register` via `AuthenticationController`.
* **Google OAuth Login Integration**:
  * Implemented secure Google ID token verification (`com.google.api-client`).
  * Created a `/api/v1/auth/google` endpoint that automatically registers new users (with random secure passwords and linked avatars) or logs in existing users, issuing them a standard JWT.
* **Environment Configuration (.env)**:
  * Integrated `spring-dotenv` to securely manage secrets.
  * Replaced hardcoded properties with `.env` variables (`DB_URL`, `JWT_SECRET_KEY`, `GOOGLE_CLIENT_ID`, etc.).
  * Updated `.gitignore` to prevent secret leakage.
* **Build Automation**: Created Windows build scripts (`build_backend.ps1` and `.bat`) for seamless compilation to executable `.jar` files.
