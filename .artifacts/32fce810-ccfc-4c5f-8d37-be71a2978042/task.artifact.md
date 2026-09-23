# Tareas - Overhaul del Monitor de Pedidos (KDS) 📋🍔🥤

- [ ] **Evolución de Base de Datos (v13)**
    - [ ] Añadir `orderGroupId` a `OrderItems` en `tables.dart`.
    - [ ] Incrementar `schemaVersion` a 13 y añadir migración en `database.dart`.
- [ ] **Actualización de DAO (`order_dao.dart`)**
    - [ ] Añadir `markOrderGroupAsDelivered(String groupId)`.
- [ ] **Lógica de Captura (`cart_sidebar.dart`)**
    - [ ] Generar un ID de grupo único al momento del cobro.
- [ ] **Interfaz de Usuario (Widgets)**
    - [ ] Crear `lib/widgets/order_ticket_widget.dart`.
- [ ] **Interfaz de Pantalla (`order_monitor_screen.dart`)**
    - [ ] Implementar rejilla de tickets y lógica de agrupación.
- [ ] **Verificación final**
