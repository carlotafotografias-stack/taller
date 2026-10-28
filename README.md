# Taller

App móvil para descubrir y reservar experiencias creativas y de bienestar en Mendoza: cerámica, pintura, yoga, baños de sonido y fotografía.

Proyecto de Carlota Monteverdi · Licenciatura en Comunicación Digital e Interactiva · UCA · 2026.

## Tecnologías

- **Flutter / Dart** para la app (Android, iOS y web con un solo código).
- **Supabase** como base de datos (PostgreSQL), autenticación de usuarios y reglas de seguridad.

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
├── main.dart              # Arranque, conexión con Supabase y control de sesión
├── config.dart            # URL y clave de Supabase
├── theme.dart             # Colores y tipografías del sistema de diseño
├── models.dart            # Taller, Fecha, Reserva y categorías
├── datos.dart             # Consultas a Supabase
├── utils.dart             # Formato de precios, fechas y mensajes de error
├── widgets/               # Tarjetas, chips e ilustraciones por categoría
└── screens/               # Bienvenida, Inicio, Explorar, Detalle, Reserva,
                           # Confirmación, Mis reservas y Perfil
supabase/
└── schema.sql             # Tablas, reglas de seguridad y datos de ejemplo
```

## Base de datos

| Tabla | Contenido |
|---|---|
| `perfiles` | Nombre e intereses de cada usuario (se crea solo al registrarse) |
| `talleres` | Título, categoría, descripción, lugar, precio, duración, nivel y docente |
| `fechas` | Fecha y hora de cada taller, con cupo total y disponible |
| `reservas` | Quién reservó, qué fecha, cuántos lugares, total y código QR |
| `resenas` | Puntaje de 1 a 5 de cada usuario para cada taller |

La función `reservar` descuenta los cupos dentro de la base, así dos personas no pueden quedarse con el mismo lugar. Las reglas de seguridad (RLS) permiten que cualquiera vea los talleres, pero cada usuario solo ve sus propias reservas.

## Cómo ejecutarla

### 1. Crear la base de datos en Supabase

1. Entrá a [supabase.com](https://supabase.com) y creá una cuenta gratuita (podés ingresar con GitHub).
2. Creá un proyecto nuevo: nombre `taller`, una contraseña para la base y región **South America (São Paulo)**.
3. Cuando termine de crearse, abrí **SQL Editor › New query**, pegá todo el contenido de `supabase/schema.sql` y tocá **Run**.
4. Para probar sin confirmar emails: **Authentication › Sign In / Providers › Email** y desactivá **Confirm email**.
5. En **Project Settings › API** copiá la **Project URL** y la clave **anon public**, y pegalas en `lib/config.dart`.

### 2. Correr la app

1. Instalá Flutter siguiendo [docs.flutter.dev/get-started](https://docs.flutter.dev/get-started/install). Lo más simple es usar VS Code con la extensión de Flutter.
2. Abrí una terminal en la carpeta del proyecto y ejecutá:

```
flutter create . --project-name taller --platforms web,android,ios
flutter pub get
flutter run -d chrome
```

El primer comando genera las carpetas de cada plataforma; solo hace falta la primera vez.

### Opción sin instalar nada: GitHub Pages

El repositorio incluye `.github/workflows/publicar.yml`, que compila la app y la publica en GitHub Pages cada vez que se suben cambios. Para activarlo: **Settings › Pages › Source: GitHub Actions**. La app queda disponible en `https://<usuario>.github.io/taller/`.
