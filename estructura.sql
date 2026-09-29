-- ============================================================
-- CAPSTONE: Análisis Exploratorio de Datos (EDA) - E-commerce
-- Archivo: estructura.sql
-- Contiene: creación de la BD, tablas, tipos de datos y carga
-- de un dataset sintético de e-commerce con nulos intencionales
-- (simulan errores reales de carga: precios y fechas faltantes).
-- ============================================================

-- 1) Creación de la base de datos
-- Ejecutar esta línea por separado (psql no permite CREATE DATABASE
-- dentro de una transacción junto con otros comandos).
CREATE DATABASE capstone_project;

-- Conectarse a la base recién creada antes de seguir:
-- \c capstone_project

-- ============================================================
-- 2) Limpieza de objetos previos (para poder re-ejecutar el script)
-- ============================================================
DROP VIEW IF EXISTS pedidos_limpios;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

-- ============================================================
-- 3) Definición de tablas
-- Los tipos se eligen a propósito: DATE para fechas (no texto,
-- para poder usar funciones de fecha en el análisis) y NUMERIC
-- para montos (evita errores de redondeo de FLOAT en dinero).
-- ============================================================

CREATE TABLE clientes (
    cliente_id      SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(150),
    ciudad          VARCHAR(100),
    fecha_registro  DATE NOT NULL
);

CREATE TABLE productos (
    producto_id     SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(100) NOT NULL,
    categoria       VARCHAR(50) NOT NULL,
    precio          NUMERIC(10,2) NOT NULL
);

CREATE TABLE pedidos (
    pedido_id        SERIAL PRIMARY KEY,
    cliente_id       INTEGER REFERENCES clientes(cliente_id),
    producto_id      INTEGER REFERENCES productos(producto_id),
    fecha_pedido     DATE,              -- puede venir nula (error de carga)
    cantidad         INTEGER NOT NULL,
    precio_unitario  NUMERIC(10,2),     -- puede venir nulo (error de carga)
    descuento        NUMERIC(5,2)       -- NULL = no se registró descuento aplicado
);

-- ============================================================
-- 4) Carga de datos: clientes
-- ============================================================
INSERT INTO clientes (nombre, email, ciudad, fecha_registro) VALUES
('Lucía Fernández',   'lucia.fernandez@mail.com',  'Buenos Aires', '2023-11-02'),
('Martín Rodríguez',  'martin.rodriguez@mail.com', 'Córdoba',      '2023-12-15'),
('Sofía Gómez',       'sofia.gomez@mail.com',      'Rosario',      '2024-01-05'),
('Juan Pérez',        'juan.perez@mail.com',       'Mendoza',      '2024-01-20'),
('Valentina Díaz',    'valentina.diaz@mail.com',   'La Plata',     '2024-02-01'),
('Nicolás Torres',    'nicolas.torres@mail.com',   'Buenos Aires', '2024-02-10'),
('Camila Suárez',     'camila.suarez@mail.com',    'Córdoba',      '2024-03-01'),
('Tomás Álvarez',     'tomas.alvarez@mail.com',    'Rosario',      '2024-03-18'),
('Agustina Romero',   'agustina.romero@mail.com',  'Mendoza',      '2024-04-02'),
('Federico Molina',   'federico.molina@mail.com',  'La Plata',     '2024-04-25');

-- ============================================================
-- 5) Carga de datos: productos (4 categorías)
-- ============================================================
INSERT INTO productos (nombre_producto, categoria, precio) VALUES
('Auriculares Bluetooth', 'Electrónica', 45.00),
('Notebook Gamer',        'Electrónica', 1200.00),
('Mouse Inalámbrico',     'Electrónica', 25.00),
('Cafetera Eléctrica',    'Hogar',       60.00),
('Set de Sábanas',        'Hogar',       35.00),
('Licuadora',             'Hogar',       50.00),
('Campera Impermeable',   'Ropa',        80.00),
('Zapatillas Running',    'Ropa',        70.00),
('Mochila Deportiva',     'Deportes',    40.00),
('Pelota de Fútbol',      'Deportes',    20.00);

-- ============================================================
-- 6) Carga de datos: pedidos
-- Nota: se dejan NULL a propósito en precio_unitario (pedido 11),
-- en fecha_pedido (pedido 15) y en la mayoría de los descuentos,
-- para poder demostrar la limpieza con COALESCE en analisis.sql.
-- ============================================================
INSERT INTO pedidos (cliente_id, producto_id, fecha_pedido, cantidad, precio_unitario, descuento) VALUES
(1,  2, '2024-01-15', 1, 1200.00, 0.10),
(1,  3, '2024-01-15', 2, 25.00,   NULL),
(2,  2, '2024-02-10', 1, 1200.00, NULL),
(2,  1, '2024-02-10', 3, 45.00,   0.05),
(3,  4, '2024-01-20', 1, 60.00,   NULL),
(3,  5, '2024-01-20', 4, 35.00,   NULL),
(4,  7, '2024-03-05', 1, 80.00,   NULL),
(4,  8, '2024-03-05', 1, 70.00,   0.15),
(5,  9, '2024-02-18', 2, 40.00,   NULL),
(5, 10, '2024-02-18', 5, 20.00,   NULL),
(6,  1, '2024-04-01', 2, NULL,    NULL),   -- precio_unitario faltante
(6,  6, '2024-04-01', 1, 50.00,   NULL),
(7,  2, '2024-04-22', 1, 1200.00, 0.20),
(7,  3, '2024-04-22', 1, 25.00,   NULL),
(8,  7, NULL,         2, 80.00,   NULL),   -- fecha_pedido faltante
(8,  9, '2024-05-14', 1, 40.00,   NULL),
(9, 10, '2024-05-30', 10, 20.00,  0.10),
(9,  5, '2024-05-30', 2, 35.00,   NULL),
(10, 4, '2024-06-11', 1, 60.00,   NULL),
(10, 6, '2024-06-11', 1, 50.00,   NULL),
(1,  9, '2024-06-19', 1, 40.00,   NULL),
(2, 10, '2024-07-02', 3, 20.00,   NULL),
(3,  1, '2024-07-15', 1, 45.00,   NULL),
(4,  3, '2024-07-15', 2, 25.00,   NULL),
(5,  2, '2024-08-08', 1, 1200.00, 0.05),
(6,  7, '2024-08-08', 1, 80.00,   NULL),
(7,  8, '2024-08-21', 1, 70.00,   NULL),
(8,  5, '2024-09-01', 3, 35.00,   NULL),
(9,  1, '2024-09-01', 2, 45.00,   NULL),
(10, 2, '2024-09-17', 1, 1200.00, 0.10),
(1,  4, '2024-10-05', 1, 60.00,   NULL),
(2,  6, '2024-10-05', 2, 50.00,   NULL),
(3,  8, '2024-10-19', 1, 70.00,   NULL),
(4,  9, '2024-11-02', 1, 40.00,   NULL),
(5, 10, '2024-11-02', 4, 20.00,   NULL),
(10,10, '2024-11-20', 1, 20.00,   NULL);

-- ============================================================
-- 7) Vista de datos limpios
-- La creamos acá (capa de datos) para que analisis.sql no tenga
-- que repetir la lógica de limpieza en cada consulta.
--
-- Reglas de negocio para los nulos:
--  - precio_unitario nulo: no se registró el precio al momento de
--    la venta -> se aproxima con el precio actual del catálogo
--    (mejor estimar que perder la fila completa).
--  - descuento nulo: si no quedó registrado un descuento, la regla
--    del negocio es asumir que no se aplicó ninguno (0%).
--  - fecha_pedido nula: se conserva NULL a propósito (no se inventa
--    una fecha) y se filtra explícitamente en los análisis por mes,
--    dejando constancia de cuántos pedidos quedan fuera por este motivo.
-- ============================================================
CREATE VIEW pedidos_limpios AS
SELECT
    p.pedido_id,
    p.cliente_id,
    p.producto_id,
    p.fecha_pedido,
    p.cantidad,
    COALESCE(p.precio_unitario, pr.precio) AS precio_unitario,
    COALESCE(p.descuento, 0)               AS descuento,
    pr.nombre_producto,
    pr.categoria,
    -- monto final ya limpio, listo para sumar en el análisis
    ROUND(p.cantidad * COALESCE(p.precio_unitario, pr.precio)
          * (1 - COALESCE(p.descuento, 0)), 2) AS monto_total
FROM pedidos p
JOIN productos pr ON pr.producto_id = p.producto_id;
