-- ============================================================
-- CAPSTONE: Análisis Exploratorio de Datos (EDA) - E-commerce
-- Archivo: analisis.sql
-- Requiere haber corrido estructura.sql antes (crea las tablas,
-- carga los datos y define la vista pedidos_limpios).
-- ============================================================


-- ============================================================
-- 0) DIAGNÓSTICO DE CALIDAD DE DATOS
-- La corremos primero porque antes de sacar cualquier conclusión
-- de negocio necesitamos saber cuánto de la información es
-- confiable y cuánto viene con huecos que podrían distorsionar
-- los totales de facturación.
-- ============================================================
SELECT
    COUNT(*) FILTER (WHERE precio_unitario IS NULL) AS pedidos_sin_precio,
    COUNT(*) FILTER (WHERE fecha_pedido IS NULL)    AS pedidos_sin_fecha,
    COUNT(*) FILTER (WHERE descuento IS NULL)       AS pedidos_sin_descuento_informado
FROM pedidos;
-- Resultado esperado sobre el dataset de ejemplo: 1 pedido sin precio,
-- 1 sin fecha y la mayoría sin descuento informado. Este último caso
-- no es un error: para este negocio, "sin dato" equivale a "sin
-- descuento aplicado", por eso se resuelve con COALESCE(descuento, 0)
-- en la vista pedidos_limpios en vez de descartar la fila.


-- ============================================================
-- 1) TOP 5 CLIENTES POR GASTO TOTAL
-- Objetivo de negocio: identificar a quién dirigir un programa de
-- fidelización o beneficios VIP, porque retener a estos clientes
-- pesa más en la facturación que conseguir clientes nuevos.
-- ============================================================
SELECT
    c.cliente_id,
    c.nombre,
    SUM(pl.monto_total) AS gasto_total
FROM pedidos_limpios pl
JOIN clientes c ON c.cliente_id = pl.cliente_id
GROUP BY c.cliente_id, c.nombre
ORDER BY gasto_total DESC
LIMIT 5;


-- ============================================================
-- 2) VENTAS TOTALES POR MES
-- Objetivo de negocio: detectar estacionalidad para planificar
-- stock y campañas de marketing con anticipación, en vez de
-- reaccionar cuando ya se perdió una oportunidad de venta.
-- Se excluyen explícitamente los pedidos sin fecha (en vez de
-- inventarles una fecha con COALESCE) para no distorsionar la
-- tendencia mensual real; quedan contabilizados aparte en el
-- diagnóstico de calidad de datos (punto 0).
-- ============================================================
SELECT
    DATE_TRUNC('month', fecha_pedido)::DATE AS mes,
    SUM(monto_total)                        AS ventas_del_mes,
    COUNT(*)                                AS cantidad_pedidos
FROM pedidos_limpios
WHERE fecha_pedido IS NOT NULL
GROUP BY DATE_TRUNC('month', fecha_pedido)
ORDER BY mes;


-- ============================================================
-- 3) TOP 3 PRODUCTOS MENOS VENDIDOS (por unidades)
-- Objetivo de negocio: son candidatos a liquidación, a sacar del
-- catálogo, o a revisar de precio/foto/descripción antes de seguir
-- comprando stock de algo que no está rotando.
-- Usamos LEFT JOIN desde productos (no desde pedidos) para que un
-- producto que nunca se vendió también aparezca con 0 unidades,
-- en vez de quedar invisible en el análisis.
-- ============================================================
SELECT
    pr.producto_id,
    pr.nombre_producto,
    pr.categoria,
    COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas
FROM productos pr
LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
GROUP BY pr.producto_id, pr.nombre_producto, pr.categoria
ORDER BY unidades_vendidas ASC
LIMIT 3;


-- ============================================================
-- 4) RANKING DE PEDIDOS POR CATEGORÍA (Window Function)
-- Objetivo de negocio: dentro de cada categoría, ver qué pedidos
-- concentran más facturación. Sirve para detectar qué combinación
-- cliente-producto conviene usar como caso de éxito en marketing,
-- o para armar promociones cruzadas con los productos de la misma
-- categoría que quedan relegados al final del ranking.
-- RANK() (y no ROW_NUMBER()) porque interesa que dos pedidos con el
-- mismo monto compartan el mismo puesto en vez de desempatar
-- arbitrariamente.
-- ============================================================
SELECT
    categoria,
    pedido_id,
    nombre_producto,
    monto_total,
    RANK() OVER (PARTITION BY categoria ORDER BY monto_total DESC) AS ranking_en_categoria
FROM pedidos_limpios
ORDER BY categoria, ranking_en_categoria;
