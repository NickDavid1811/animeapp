# 🎌 AnimeApp

Una aplicación moderna de descubrimiento, seguimiento y gestión de anime construida con **Flutter**, **Clean Architecture** y **Material Design 3**. Permite explorar los animes más populares del momento, buscar series con autocompletado resiliente, ver tráilers oficiales de YouTube, consultar sinopsis y géneros detallados, y gestionar una biblioteca personal de favoritos con filtros dinámicos, ordenamiento y persistencia local. 

La app es 100% responsiva y se adapta con una experiencia inmersiva a Android, Web y Desktop (Linux/Windows/macOS).

---

## ✨ Funcionalidades

| Funcionalidad | Descripción |
|---|---|
| 🔥 **Top Anime** | Explora el ranking global de los animes más populares de MyAnimeList con scroll infinito y paginación reactiva. |
| 🔍 **Búsqueda Avanzada** | Búsqueda en vivo con debounce, paginación y fallback resiliente en memoria ante errores o caídas temporales de la API pública. |
| 🎬 **Tráilers Oficiales** | Visualización directa y apertura del tráiler oficial en YouTube mediante `url_launcher` con extracción inteligente de IDs desde `youtube_id`, `embed_url` y URLs directas. |
| ⛩️ **Títulos Bilingües** | Visualización del título principal junto al título original en japonés (`title_japanese`) como subtítulo decorativo y contextual. |
| ⭐ **Scores y Géneros** | Badges de puntuación de la crítica (ej. `★ 9.34`) y chips de géneros dinámicos (Acción, Aventura, Fantasía, etc.). |
| 📖 **Sinopsis Inmersiva** | Lectura de la trama completa con scroll independiente en la vista de detalle adaptativa. |
| 📋 **Detalles Adaptativos** | Experiencia adaptativa según la pantalla: *Bottom Sheet* fluido en móviles y *Dialog modal centrado* en Desktop y Web. |
| ❤️ **Gestión de Favoritos** | Guarda y elimina animes de tu biblioteca personal con actualización reactiva instantánea. |
| 🎯 **Filtros y Búsqueda en Favoritos** | Barra de búsqueda instantánea interna y selector de chips interactivo por géneros para filtrar tu colección al vuelo. |
| 🔃 **Ordenamiento Flexible** | Ordena tus favoritos por: **Más reciente**, **Mejor puntuación (★)** o **Alfabéticamente (A-Z)**. |
| 🔄 **Sincronización Automática** | Reconciliación transparente en caché y enriquecimiento bajo demanda (*Lazy Detail Fetch*) para favoritos antiguos, además de soporte para *Pull-to-refresh*. |
| 🌗 **Tema Claro / Oscuro** | Modo claro y oscuro con transiciones suaves y persistencia de preferencias de usuario. |
| 🏠 **Home con Carrusel** | Portada con carrusel interactivo de animes destacados (soporte para rueda de ratón en PC) y vista rápida de guardados recientes. |
| 💾 **Persistencia Local** | Almacenamiento local multiplataforma rápido y confiable respaldado en `shared_preferences`. |
| 🖼️ **Caché Inteligente de Imágenes** | Caché optimizado de portadas en red para fluidez total y ahorro de datos. |

---

## 🛠️ Stack Tecnológico

| Categoría | Tecnología |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.5.4) |
| **Diseño** | Material Design 3 (`useMaterial3: true`) con paleta de colores tonal y adaptativa |
| **State Management** | [Provider](https://pub.dev/packages/provider) ^6.1.5 |
| **Arquitectura** | Clean Architecture estricta con soporte para programación funcional [fpdart](https://pub.dev/packages/fpdart) (patrón `Either`) |
| **API** | [Jikan API v4](https://jikan.moe/) (REST API oficial no oficial de MyAnimeList) |
| **Lanzador de URLs** | [url_launcher](https://pub.dev/packages/url_launcher) ^6.3.2 (Apertura de tráilers de YouTube) |
| **Persistencia Local** | `shared_preferences` con adaptador `DatabaseHelper` multiplataforma |
| **HTTP Client** | [http](https://pub.dev/packages/http) ^1.6.0 con manejo de timeouts y códigos de estado (502, 503, 504) |
| **Tipografía** | [Google Fonts](https://pub.dev/packages/google_fonts) — Plus Jakarta Sans |
| **Imágenes** | [cached_network_image](https://pub.dev/packages/cached_network_image) ^3.4.1 |

---

## 🏗️ Arquitectura (Clean Architecture)

El proyecto implementa los principios de **Clean Architecture** y **SOLID**, separando estrictamente la lógica en capas desacopladas:

```
lib/
├── core/                                    # Configuración transversal e infraestructura base
│   ├── constants/api_constants.dart         # URLs base y endpoints de la API
│   ├── di/injection_container.dart          # Inyección de dependencias centralizada (Service Locator)
│   ├── errors/failure.dart                  # Tipado de errores (ServerFailure, DatabaseFailure, etc.)
│   ├── theme/app_theme.dart                 # Sistema de diseño, temas Light y Dark con persistencia
│   └── utils/number_formatter.dart          # Formateador numérico abreviado (ej. 1.2M, 340K)
│
├── feature/
│   ├── anime_list/                          # Feature de Lista, Exploración y Favoritos
│   │   ├── data/                            # ── CAPA DATA ──
│   │   │   ├── datasources/                 # Fuentes de datos remotas (Jikan) y locales (DB)
│   │   │   ├── models/                      # AnimeModel (API) y AnimeDbModel (Local DB)
│   │   │   └── repositories/                # AnimeRepositoryImpl (Caché, fallbacks y orquestación)
│   │   │
│   │   ├── domain/                          # ── CAPA DOMAIN (Reglas de Negocio Puras) ──
│   │   │   ├── repositories/                # AnimeRepositoryInterface (Contratos)
│   │   │   └── usecases/                    # Casos de uso atómicos (SRP):
│   │   │       ├── get_top_anime_usecase.dart
│   │   │       ├── search_anime_usecase.dart
│   │   │       ├── get_anime_details_usecase.dart
│   │   │       ├── get_favorite_animes_usecase.dart
│   │   │       ├── toggle_favorite_usecase.dart
│   │   │       └── get_favorite_totals_usecase.dart
│   │   │
│   │   └── presentation/                    # ── CAPA PRESENTATION ──
│   │       ├── provider/anime_provider.dart # ChangeNotifier reactivo
│   │       ├── screens/                     # ExploreScreen y FavoritesScreen
│   │       ├── utils/anime_detail_helper.dart # Despliegue responsivo (Dialog vs BottomSheet)
│   │       └── widgets/                     # Componentes visuales (AnimeCard unificado, modales, etc.)
│   │
│   └── home/                                # Tab / Dashboard Principal
│       └── presentation/                    # HomeScreen, NavigationBar y carruseles
│
├── shared/                                  # Componentes globales compartidos
│   ├── database/database_helper.dart        # Motor de persistencia local JSON seguro
│   ├── domain/entities/anime_entity.dart    # Entidad pura de Anime del Dominio
│   └── preferences/preferences_helper.dart  # Gestión de configuraciones del usuario
│
└── main.dart                                # Inicialización asíncrona y arranque de la App
```

### Principios de Diseño Destacados

1. **Segregación de Casos de Uso (Single Responsibility Principle):**
   Cada acción del usuario (obtener ranking, buscar, alternar favorito, obtener detalles) es un caso de uso independiente con el método ejecutable `call(...)`, permitiendo pruebas unitarias limpias e inyección desacoplada.
2. **Componente de Tarjeta Unificado (`AnimeCard`):**
   Un único componente reutilizable para listas exploratorias, resultados de búsqueda y favoritos, parametrizando acciones y estados con animaciones de elevación al pasar el ratón (*hover effects*).
3. **Manejo Funcional de Errores con `fpdart`:**
   Uso de `Either<Failure, T>` en el dominio y repositorio para garantizar que las excepciones no se propaguen descontroladamente a la interfaz de usuario.
4. **Resiliencia ante Fallos de Red:**
   El repositorio cuenta con caché de páginas en memoria y un fallback que permite buscar localmente en animes ya cargados si la API pública presenta intermitencias o errores 504.

---

## 🌐 Endpoints de la API

La app consume la [Jikan REST API v4](https://docs.api.jikan.moe/):

| Método | Endpoint | Propósito |
|---|---|---|
| `GET` | `/v4/top/anime?page={n}` | Ranking global de animes con paginación. |
| `GET` | `/v4/anime?q={query}&page={n}` | Búsqueda por término de texto con paginación. |
| `GET` | `/v4/anime/{id}` | Detalles individuales completos de un anime para enriquecimiento bajo demanda. |

---

## 🚀 Primeros Pasos

### Prerrequisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.5.4
- Android Studio / VS Code con extensiones de Flutter y Dart.
- Para Desktop en Linux: dependencias de desarrollo de GTK (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`).

### Instalación y Ejecución

```bash
# 1. Clonar el repositorio
git clone git@github.com:NickDavid1811/animeapp.git
cd animeapp

# 2. Obtener las dependencias
flutter pub get

# 3. Analizar la calidad del código
flutter analyze

# 4. Ejecutar la aplicación en tu plataforma preferida
flutter run -d linux   # Ejecución nativa en Linux Desktop
flutter run -d chrome  # Ejecución en Navegador Web
flutter run -d android # Ejecución en Dispositivo / Emulador Android
```

---

## 📱 Plataformas Soportadas

- ✅ **Linux** (Nativo con soporte de ratón, hover animations, scroll horizontal y diálogos modales)
- ✅ **Android** (Teléfonos y Tablets con *Bottom Sheets* gestuales y *pull-to-refresh*)
- ✅ **Web** (Chrome, Firefox, Safari con layout adaptable)
- ✅ **Windows / macOS** (Compatible con el pipeline multiplataforma de Flutter)

---

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta el archivo `LICENSE` si deseas más información.
