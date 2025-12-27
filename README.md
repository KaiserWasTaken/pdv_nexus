# 🎮 GamerCafe POS & Manager

Sistema de gestión integral para cafetería y centro de rentas de videojuegos.
Aplicación nativa Android desarrollada en **Flutter**, diseñada con arquitectura **Offline-First** (funciona sin internet) y respaldo diferido en la nube.

---

## 🎯 Objetivo del Proyecto
Proveer una herramienta unificada que permita a los dueños y empleados:
1.  Vender productos de cafetería.
2.  Gestionar tiempos y costos de renta de consolas.
3.  **Controlar la entrega de pedidos en barra** (Estatus "Por Entregar" / "Entregado").
4.  Generar reportes financieros diarios automáticamente en PDF.
5.  Respaldar la información en Google Drive sin intervención manual.

---

## 🛠 Tech Stack
* **Framework:** Flutter (Dart).
* **Plataforma:** Android Tablet (Soporte potencial para iPad/Desktop).
* **Base de Datos Local:** SQLite (vía `drift`).
* **Reportes:** `pdf`, `printing`.
* **Nube:** `googleapis` (Google Drive API) + `google_sign_in`.
* **Arquitectura:** MVVM (Model-View-ViewModel) o similar.

---

## 🗂 Estructura de Base de Datos (Drift)
El sistema utiliza SQLite local. Tablas principales planificadas:

1.  **Products:** Catálogo (Nombre, Precio, Categoría, Stock).
2.  **Rentals:** Control de consolas (Hora inicio, Hora fin, Costo, Mesa).
3.  **OrderItems (NUEVO):** Registro individual de items vendidos en una orden.
    * *Propósito:* Control de barra/cocina.
    * *Campos clave:* `product_name`, `quantity`, `status` ('pending', 'delivered'), `timestamp`.
4.  **DailyReports:** Historial de cierres de caja y rutas de PDFs generados.

---

## ✅ TODO LIST (Hoja de Ruta)

### FASE 1: Configuración y Base (🏁 COMPLETADO)
- [x] Instalación de Flutter y Android Studio.
- [x] Configuración de variables de entorno.
- [x] Creación del proyecto `pdv_nexus`.
- [x] Instalación de dependencias (`drift`, `pdf`, `googleapis`, etc.).
- [x] Definición inicial de tablas en `database.dart`.

### FASE 2: Backend Local (Base de Datos)
- [ ] **ACTUALIZACIÓN:** Agregar tabla `OrderItems` para el control de pedidos pendientes (Bubble Tea).
- [ ] Crear repositorios (DAOs) para insertar y leer datos de forma sencilla.
- [ ] Probar la persistencia de datos (guardar y recuperar).

### FASE 3: Interfaz de Usuario (UI) - Cafetería
- [ ] **Pantalla POS:** Grid de productos con fotos/iconos.
- [ ] **Carrito de Compras:** Lista lateral con suma total.
- [ ] **Monitor de Pedidos (Cocina/Barra):**
    - [ ] Lista de items con estatus "Pendiente".
    - [ ] Funcionalidad "Swipe" o botón para marcar como "Entregado".

### FASE 4: Interfaz de Usuario (UI) - Videojuegos
- [ ] **Dashboard de Consolas:** Visualización de mesas (Libre/Ocupada).
- [ ] **Lógica de Cronómetro:** Iniciar, Pausar, Detener.
- [ ] **Cálculo de Tarifas:** Algoritmo de costo por minuto/hora.s

### FASE 5: Reportes y Nube
- [ ] **Generador PDF:** Diseño del ticket/reporte diario (Ventas + Rentas).
- [ ] **Lógica de Cierre de Caja:** Botón que finaliza el día y resetea contadores.
- [ ] **Servicio Google Drive:**
    - [ ] Autenticación silenciosa.
    - [ ] Subida de archivos PDF.
    - [ ] Cola de sincronización (Sync Queue) para cuando regrese el internet.

---

## 📝 Notas de Desarrollo
* **Offline-First:** La app nunca debe bloquearse si no hay red.
* **Impresión:** Preparar el código para futura integración con impresoras térmicas Bluetooth (Fase futura).