# Capstone: Análisis Exploratorio de Datos (EDA) en PostgreSQL

Proyecto final del curso de SQL de Coderhouse. Simula el trabajo de un/a
analista de datos para una tienda de e-commerce: limpiar un dataset con
errores de carga, analizarlo y presentar hallazgos accionables para un
equipo directivo.

## 1. Problema de negocio

DataCorp (tienda de e-commerce ficticia) tiene un registro de pedidos con
huecos típicos de sistemas operativos reales: pedidos sin precio cargado,
pedidos sin fecha y descuentos que no siempre quedan registrados. El
equipo de dirección necesita responder tres preguntas antes de definir el
presupuesto de marketing y de compras del próximo trimestre:

1. ¿A qué clientes conviene dirigir un programa de fidelización?
2. ¿En qué meses se concentran las ventas, para anticipar stock y campañas?
3. ¿Qué productos no están rotando y son candidatos a liquidación?

Como estas preguntas dependen de sumar montos de dinero, primero hay que
decidir qué hacer con los datos faltantes: si se ignoran las filas con
nulos se pierde información real de ventas, y si se inventan valores sin
criterio se puede sobre o subestimar la facturación.

## 2. Estructura del repositorio

| Archivo         | Contenido                                                          |
|-----------------|---------------------------------------------------------------------|
| `estructura.sql`| Creación de la base `capstone_project`, tablas `clientes`, `productos`, `pedidos`, carga de datos y vista `pedidos_limpios` |
| `analisis.sql`  | Diagnóstico de calidad de datos + 4 consultas de análisis comentadas |
| `README.md`     | Este documento |

### Modelo de datos
- **clientes**: `cliente_id`, `nombre`, `email`, `ciudad`, `fecha_registro (DATE)`
- **productos**: `producto_id`, `nombre_producto`, `categoria`, `precio (NUMERIC)`
- **pedidos**: `pedido_id`, `cliente_id`, `producto_id`, `fecha_pedido (DATE)`, `cantidad`, `precio_unitario (NUMERIC)`, `descuento (NUMERIC)`

El dataset es sintético pero fue diseñado con nulos intencionales en
`precio_unitario` y `fecha_pedido` (y descuentos mayormente sin informar)
para poder demostrar una limpieza real con `COALESCE`, en vez de trabajar
sobre datos ya perfectos.

## 3. Cómo ejecutar el código

1. Tener PostgreSQL instalado (se probó con la versión 14+).
2. Ejecutar `estructura.sql`. La primera línea (`CREATE DATABASE`) se debe
   correr por separado, y luego conectarse a la base antes de seguir:
   ```bash
   psql -U postgres -c "CREATE DATABASE capstone_project;"
   psql -U postgres -d capstone_project -f estructura.sql
   ```
3. Ejecutar `analisis.sql` contra la misma base:
   ```bash
   psql -U postgres -d capstone_project -f analisis.sql
   ```
4. Revisar la salida de cada consulta en la terminal o en el cliente
   SQL que prefieras (pgAdmin, DBeaver, etc.).

## 4. Limpieza de datos

- `precio_unitario` nulo → `COALESCE(precio_unitario, precio_del_catalogo)`.
  Se decidió no descartar la fila: perder un pedido completo distorsiona
  más el análisis que aproximar su precio con el valor de catálogo actual.
- `descuento` nulo → `COALESCE(descuento, 0)`. Para el negocio, que no
  haya un descuento registrado equivale a que no se aplicó ninguno.
- `fecha_pedido` nula → se mantiene NULL a propósito y se **excluye**
  explícitamente del análisis de ventas por mes (`WHERE fecha_pedido IS
  NOT NULL`). Inventar una fecha con COALESCE hubiera alterado la
  estacionalidad real, que es justamente lo que esa consulta busca medir.

Sobre el dataset de ejemplo, el diagnóstico inicial detecta **1 pedido sin
precio** y **1 pedido sin fecha** sobre 35 pedidos totales, además de
descuentos no informados en la mayoría de las filas.

## 5. Principales hallazgos

### Top 5 clientes por gasto total
Los cinco primeros puestos son: Martín Rodríguez (~$1.488), Valentina Díaz
(~$1.400), Lucía Fernández (~$1.230), Federico Molina (~$1.210) y Camila
Suárez (~$1.055). **Los cinco compraron al menos una Notebook Gamer**, el
producto de mayor precio unitario del catálogo. Esto indica que el
ranking de clientes top no refleja necesariamente lealtad o frecuencia de
compra, sino el hecho puntual de haber comprado un artículo caro. Antes de
armar un programa de fidelización basado solo en este ranking, conviene
cruzarlo con la frecuencia de compra para no premiar una compra aislada
como si fuera un cliente recurrente.

### Ventas totales por mes
Los meses en que se vendió al menos una Notebook Gamer (enero, febrero,
abril, agosto y septiembre) muestran picos claros de facturación frente
al resto. Esto confirma que el ticket promedio mensual depende
fuertemente de la venta de un único producto de electrónica de alto
valor, más que de un crecimiento sostenido en el volumen de pedidos. Es
un riesgo de concentración: si ese producto se agota o deja de venderse,
la facturación mensual puede caer de forma abrupta aunque el resto del
negocio funcione igual.

### Productos menos vendidos
Cafetera Eléctrica y Zapatillas Running quedan últimas en unidades
vendidas, seguidas de cerca por Licuadora y Campera Impermeable. Ninguna
pertenece a Electrónica ni a Deportes, las categorías con mejor
rotación en este dataset. Son candidatas a liquidación de stock o a una
revisión de precio/posicionamiento antes de reponer inventario.

### Ranking de pedidos por categoría (RANK)
Dentro de Electrónica, los pedidos que incluyen la Notebook Gamer ocupan
sistemáticamente el primer puesto del ranking, mientras que Mouse
Inalámbrico y Auriculares Bluetooth quedan relegados a las últimas
posiciones pese a tener más unidades vendidas. Esto sugiere una
oportunidad de **venta cruzada**: ofrecer estos accesorios como combo al
momento de comprar la notebook podría subir el ticket promedio de
productos que hoy se venden mucho pero aportan poco monto individual.

## 6. Conclusiones y recomendaciones

1. **No fiarse del ranking de clientes por gasto total sin ver frecuencia
   de compra**: el top actual está sesgado por una sola compra cara, no
   por lealtad.
2. **La dependencia de un solo producto de alto valor (Notebook Gamer)
   para explicar los picos mensuales es un riesgo de concentración** que
   conviene monitorear con más historial de datos.
3. **Cafetera Eléctrica y Zapatillas Running son candidatas a revisión de
   catálogo** (precio, descripción o directamente liquidación de stock).
4. **Hay oportunidad de combos** entre productos de electrónica de alto
   valor y sus accesorios de bajo ticket, para subir la facturación de
   estos últimos sin depender de nuevos clientes.

