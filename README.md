# Taller

App móvil para descubrir y reservar experiencias creativas y de bienestar en Mendoza: cerámica, pintura, yoga, baños de sonido y fotografía.

Proyecto de Carlota Monteverdi · Licenciatura en Comunicación Digital e Interactiva · UCA · 2026.

**App publicada:** https://carlotafotografias-stack.github.io/taller/

## Tecnologías

- **Figma** para la investigación UX, el sistema de diseño y el prototipo.
- **Flutter / Dart** para la app (Android, iOS y web con un solo código).
- **Firebase** para el backend: Authentication (usuarios) y Cloud Firestore (base de datos), con reglas de seguridad.
- **GitHub Actions + GitHub Pages** para compilar y publicar la app automáticamente.

## Funcionalidades

- Registro e inicio de sesión con email, eligiendo intereses.
- Inicio con talleres destacados y próximas fechas.
- Explorar con buscador y filtros por categoría, fecha y precio.
- Detalle de cada taller con duración, nivel, docente y reseñas.
- Reserva de fecha y cantidad de lugares, con descuento automático de cupos.
- Confirmación con código QR para presentar en el taller.
- Mis reservas (próximas y pasadas) y reseñas con estrellas.
- Perfil con intereses editables.

## Estructura

```
lib/
├── main.dart              # Arranque, conexión con Firebase y control de sesión
├── config.dart            # Datos de conexión del proyecto de Firebase
├── theme.dart             # Colores y tipografías del sistema de diseño
├── models.dart            # Taller, Fecha, Reserva y categorías
├── datos.dart             # Lecturas y escrituras en Firestore y Authentication
├── utils.dart             # Formato de precios, fechas y mensajes de error
├── widgets/               # Tarjetas, chips e ilustraciones por categoría
└── screens/               # Bienvenida, Inicio, Explorar, Detalle, Reserva,
                           # Confirmación, Mis reservas y Perfil
firebase/
└── firestore.rules        # Reglas de seguridad de la base de datos
```

## Base de datos (Cloud Firestore)

| Colección | Contenido |
|---|---|
| `perfiles` | Nombre e intereses de cada usuario (uno por cuenta) |
| `talleres` | Título, categoría, descripción, lugar, precio, duración, nivel y docente |
| `fechas` | Fecha y hora de cada taller, con cupo total y disponible |
| `reservas` | Quién reservó, qué fecha, cuántos lugares, total y código QR |
| `resenas` | Puntaje de 1 a 5 de cada usuario para cada taller |

Al reservar, la app usa una **transacción**: revisa el cupo, lo descuenta y crea la reserva en un solo paso, así dos personas no pueden quedarse con el mismo lugar. Las **reglas de seguridad** permiten que cualquiera vea los talleres, pero cada usuario solo ve sus propias reservas, y el cupo solo puede bajar, nunca quedar negativo.

La primera vez que alguien inicia sesión, la app carga sola los 6 talleres de ejemplo con 6 fechas semanales cada uno.

## Cómo configurarla

### 1. Crear el proyecto en Firebase

1. Entrá a [console.firebase.google.com](https://console.firebase.google.com) y creá un proyecto llamado `taller`.
2. **Authentication › Sign-in method:** activá **Correo electrónico/contraseña**. En **Configuración › Dominios autorizados** agregá el dominio donde se publica la app (por ejemplo `usuario.github.io`).
3. **Firestore Database:** creá la base en modo producción (región `southamerica-east1`). En la pestaña **Reglas** pegá el contenido de `firebase/firestore.rules` y tocá **Publicar**.
4. **Configuración del proyecto › Tus apps:** registrá una app web y copiá sus datos (`apiKey`, `projectId`, etc.) en `lib/config.dart`.

### 2. Correr la app en tu computadora (opcional)

1. Instalá Flutter siguiendo [docs.flutter.dev/get-started](https://docs.flutter.dev/get-started/install).
2. En una terminal, dentro de la carpeta del proyecto:

```
flutter create . --project-name taller --platforms web,android,ios
flutter pub get
flutter run -d chrome
```

### 3. Publicación automática

`.github/workflows/publicar.yml` compila la app y la publica en GitHub Pages cada vez que se suben cambios a `main` (activarlo en **Settings › Pages › Source: GitHub Actions**). `.github/workflows/verificar.yml` revisa que compilen los cambios de otras ramas, sin publicarlos.
