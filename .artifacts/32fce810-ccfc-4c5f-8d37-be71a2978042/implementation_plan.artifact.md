# Plan de Implementación - Overhaul del Monitor de Pedidos (KDS) 📋🍔🥤

El objetivo es transformar el monitor de pedidos en un sistema de "Tickets de Orden", donde cada ticket agrupa todos los productos comprados en una misma transacción, organizados por categorías y con control individual de preparación.

## User Review Required

> [!IMPORTANT]
> - **Evolución de Datos (v13):** Para agrupar los pedidos de forma confiable, añadiré una columna `orderGroupId` a la tabla `OrderItems`. Esto requiere una migración.
> - **Lógica de Entrega:** El botón "Entregado" del ticket solo se activará cuando el empleado haya marcado todos los productos del ticket como listos. Esto garantiza que no se olvide nada.
> - **Categorización:** Los productos dentro del ticket se separarán visualmente (ej: Bebidas arriba, Snacks abajo).

## Cambios Propuestos

### 1. Base de Datos (Evolución)
#### [MODIFY] [tables.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/database/tables.dart)
- Añadir `TextColumn get orderGroupId => text().nullable()();` a `OrderItems`.
- Incrementar `schemaVersion` a `13` en `database.dart`.

#### [MODIFY] [cart_sidebar.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/widgets/cart_sidebar.dart)
- Generar un ID único (Timestamp o UUID) al momento de cobrar y asignarlo a todos los items de la compra.

### 2. Lógica de Negocio (DAO)
#### [MODIFY] [order_dao.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/database/daos/order_dao.dart)
- Añadir `markOrderGroupAsDelivered(String groupId)`: Para finalizar todo el ticket de un solo golpe.

### 3. Interfaz de Usuario (Monitor)
#### [NEW] [order_ticket_widget.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/widgets/order_ticket_widget.dart)
- Crear el widget personalizado con:
    - **Header:** Número de orden (#) grande y hora de pedido.
    - **Body:** Agrupación por categoría con iconos.
    - **Item Row:** Nombre, cantidad y Checkbox interactivo.
    - **Footer:** Botón "Entregado" con lógica de validación (solo activo si todo está checkeado).

#### [MODIFY] [order_monitor_screen.dart](file:///C:/Users/Usuario/StudioProjects/pdv_nexus/lib/screens/order_monitor_screen.dart)
- Cambiar la lista simple por una rejilla (`GridView`) de `OrderTicketWidget`.
- Implementar la lógica de agrupación de la lista plana de la BD en objetos de orden estructurados.

## Plan de Verificación

### Verificación Manual
- Realizar una compra de 2 bebidas y 1 snack.
- Verificar que en el monitor aparezca **un solo ticket** con los 3 items.
- Intentar presionar "Entregado" sin marcar los checkboxes (debe estar deshabilitado).
- Marcar todo, presionar "Entregado" y confirmar que el ticket desaparece.
