# Plan de Implementación - Refresco de Estadísticas y Pantalla de Historial Completa 🕒📊

El objetivo es asegurar que las estadísticas se reinicien inmediatamente al generar el reporte PDF y transformar la vista de Historial en una pantalla completa que reemplace la interfaz principal.

## User Review Required

> [!IMPORTANT]
> - **Refresco Automático:** Cambiaremos el panel de estadísticas para que use Streams. Esto hará que en cuanto el PDF se genere y las ventas se "archiven", los números en pantalla bajen a $0.00 sin tener que reiniciar la app.
> - **Historial Full-Screen:** Al tocar "Historial", la app navegará a una nueva pantalla que cubrirá todo el espacio (incluyendo el menú lateral). Tendrá su propio botón de regresar.

## Cambios Propuestos

### 1. Base de Datos (DAO)
#### [MODIFY] [order_dao.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/database/daos/order_dao.dart)
- Crear `watchTodayStats()`: Un Stream que emita el total de ventas y cantidad de items filtrando por `reportId.isNull()`. Esto permitirá que la UI reaccione a cambios en tiempo real.

### 2. Interfaz de Usuario (Widgets)
#### [MODIFY] [stats_panel.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/widgets/stats_panel.dart)
- Reemplazar `FutureBuilder` por `StreamBuilder` conectado a `watchTodayStats()`.

### 3. Pantalla de Historial (Full-Screen)
#### [NEW] [day_preview_screen.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/screens/day_preview_screen.dart)
- Crear una nueva pantalla que muestre:
    - Lista detallada de productos vendidos (agrupados).
    - Resumen de rentas por tipo de consola.
    - Total acumulado.
    - Botón de cerrar/regresar en la parte superior.

#### [MODIFY] [home_screen.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/screens/home_screen.dart)
- Cambiar la lógica del botón "Historial" para que use `Navigator.push` hacia `DayPreviewScreen` en lugar de abrir un diálogo.

## Plan de Verificación

### Verificación Manual
- Realizar una venta y observar cómo el `StatsPanel` se actualiza al instante.
- Generar el PDF y confirmar que el `StatsPanel` vuelve a $0.00 inmediatamente.
- Tocar el botón "Historial" y verificar que la nueva pantalla ocupa el 100% de la tablet.
- Regresar del historial y confirmar que la navegación vuelve al panel de administración.
