# 🎌 AnimeApp

Una aplicación moderna de descubrimiento y seguimiento de anime construida con **Flutter**, **Clean Architecture** y **Material Design 3**. Permite explorar los animes más populares del momento, buscar tus series favoritas, consultar sus detalles y gestionar una biblioteca personal con persistencia local. La app es responsiva y se adapta elegantemente a Android, Web y Desktop (Linux/Windows/macOS).

---

## ✨ Funcionalidades

| Funcionalidad | Descripción |
|---|---|
| 🔥 **Top Anime** | Explora el ranking global de los animes más populares con scroll infinito. |
| 🔍 **Búsqueda Avanzada** | Busca animes por nombre con *debounce* y carga paginada integrada fluidamente. |
| 📋 **Detalles Adaptativos** | Consulta información detallada de cada anime (año, episodios, miembros). En móviles se muestra como un *Bottom Sheet*, y en Desktop/Web como un *Modal Dialog* inmersivo. |
| ❤️ **Favoritos** | Guarda y elimina animes de tu biblioteca personal con un solo toque. |
| 📊 **Estadísticas** | Panel de KPIs con el total de episodios y miembros de tu colección de favoritos. |
| 🌗 **Tema Claro / Oscuro** | Cambia entre modo claro y oscuro con un toggle reactivo en tiempo real. |
| 🏠 **Home con Carrusel** | Pantalla de inicio con carrusel de animes destacados (con scroll de ratón en PC) y vista rápida de favoritos recientes. |
| 💾 **Persistencia Local** | Los favoritos se almacenan persistiendo en SQLite o `shared_preferences` según la plataforma. |
| 🖼️ **Caché de Imágenes** | Las imágenes se cachean localmente para una experiencia fluida sin recargas excesivas. |

---

## 🛠️ Stack Tecnológico

| Categoría | Tecnología |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.5.4) |
| **Diseño** | Material Design 3 (`useMaterial3: true`) |
| **State Management** | [Provider](https://pub.dev/packages/provider) ^6.1.5 |
| **Arquitectura** | Clean Architecture estricta con soporte para [fpdart](https://pub.dev/packages/fpdart) (patrón `Either`) |
| **API** | [Jikan API v4](https://jikan.moe/) (MyAnimeList no oficial) |
| **Base de datos** | SQLite / `shared_preferences` (Soporte Multiplataforma) |
| **HTTP Client** | [http](https://pub.dev/packages/http) ^1.6.0 |
| **Tipografía** | [Google Fonts](https://pub.dev/packages/google_fonts) — Plus Jakarta Sans |
| **Imágenes** | [cached_network_image](https://pub.dev/packages/cached_network_image) ^3.4.1 |

---

## 🏗️ Arquitectura (Clean Architecture)

El proyecto sigue **Clean Architecture** separada por capas (Domain → Data → Presentation) garantizando independencia del framework y librerías externas.

```
lib/
├── core/                                    # Configuración transversal
│   ├── constants/api_constants.dart         # URLs y endpoints de la API
│   ├── di/injection_container.dart          # Inyección de dependencias centralizada
│   ├── errors/failure.dart                  # Tipado de errores (ServerFailure, CacheFailure)
│   ├── theme/app_theme.dart                 # Sistema de diseño, Dark/Light mode
│   └── utils/number_formatter.dart          # Utilidades visuales (1.2M, 340K)
│
├── feature/
│   ├── anime_list/                          # Feature Principal
│   │   ├── data/                            # ── DATOS ──
│   │   │   ├── datasources/                 # APIs, BD Local, Preferencias
│   │   │   ├── models/                      # Modelos serializables JSON/BD
│   │   │   └── repositories/                # Implementación de repositorios
│   │   ├── domain/                          # ── DOMINIO (Reglas de negocio) ──
│   │   │   ├── repositories/                # Interfaces del repositorio
│   │   │   └── usecases/                    # Casos de uso específicos (GetTopAnime, SearchAnime)
│   │   └── presentation/                    # ── PRESENTACIÓN ──
│   │       ├── provider/anime_provider.dart # Estado gestionado por Provider
│   │       ├── screens/                     # Explore y Favorites screens
│   │       ├── utils/anime_detail_helper.dart # Lógica para diálogos adaptativos
│   │       └── widgets/                     # Tarjetas, modales, etc.
│   │
│   └── home/                                # Tab/Dashboard
│       └── presentation/                    # NavigationBar, carruseles, layout
│
├── shared/                                  # Compartidos entre features
│   ├── database/database_helper.dart        # Helper de base de datos
│   ├── domain/entities/anime_entity.dart    # Entidad principal de negocio
│   └── preferences/preferences_helper.dart  # Gestión multiplataforma de config
│
└── main.dart                                # Punto de entrada e inicialización
```

### Principios Respetados

- **Inyección de Dependencias**: La capa `core/di` expone las clases preconstruidas a `main.dart`.
- **Patrón Either (fpdart)**: La capa de Domain retorna estructuras `Either<Failure, T>` para manejar exitosamente los errores sin arrojar excepciones incontroladas a la vista.
- **Entidades Globales**: Modelos core como `AnimeEntity` radican en `shared/domain` para permitir inter-conexión limpia entre features (`home` y `anime_list`).

---

## 🚀 Primeros Pasos

### Prerrequisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.5.4
- Android Studio / VS Code
- Emulador, Dispositivo Android o navegador web (Chrome).

### Instalación

```bash
# 1. Clonar el repositorio y entrar
git clone <repository-url>
cd animeapp

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la aplicación
flutter run -d chrome # o linux, android, etc.
```

---

## 🌐 API

La app consume la [Jikan API v4](https://docs.api.jikan.moe/).

| Endpoint | Uso |
|---|---|
| `GET /v4/top/anime?page={n}` | Obtiene el ranking top con paginación. |
| `GET /v4/anime?q={query}&page={n}` | Búsqueda avanzada de animes paginada. |

---

## 📱 Plataformas Soportadas

- ✅ **Android** (Teléfonos y Tablets)
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Linux** (Nativo con soporte de ratón y ventanas modales)

*La interfaz responde activamente al ancho de la ventana, transformando carruseles, layouts de lista (List vs Grid), y los diálogos informativos.*
