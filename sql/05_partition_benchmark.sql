-- =========================================================
-- 05 · BENCHMARK de particionamiento
-- Objetivo: medir cuántos bytes ahorra la partición por fecha.
--
-- Se compara la misma consulta sobre:
--   A) fact_sales               → particionada por fecha + clustering
--   B) fact_sales_unpartitioned → copia idéntica, sin partición ni clustering
--
-- Cómo medir: ejecutar cada consulta POR SEPARADO y revisar
-- "Bytes procesados" en la pestaña "Información del trabajo".
-- (También se ve antes de ejecutar, arriba a la derecha del editor:
--  "Esta consulta procesará X KB al ejecutarse".)
--
-- Nota: BigQuery factura un mínimo de 10 MB por consulta, así que con
-- este volumen los "bytes facturados" son iguales en ambas; lo que se
-- compara son los "bytes procesados", que escalan igual con datos grandes.
-- =========================================================

-- ---------------------------------------------------------
-- PASO 1: crear la copia sin particionar (ejecutar una vez)
-- ---------------------------------------------------------
CREATE OR REPLACE TABLE bakehouse_model.fact_sales_unpartitioned
OPTIONS (description = 'Copia de fact_sales SIN partición ni clustering, solo para benchmark')
AS
SELECT * FROM bakehouse_model.fact_sales;


-- ---------------------------------------------------------
-- PASO 2A: consulta sobre la tabla PARTICIONADA
-- (filtra un solo día → BigQuery lee solo esa partición)
--
-- Importante: el filtro usa una fecha LITERAL. Si el filtro dependiera
-- de una subconsulta (ej. WHERE fecha = (SELECT MAX(...))), BigQuery
-- no puede saber de antemano qué partición leer y no aplica el
-- "partition pruning". Ajustar la fecha al último día de dim_date.
-- ---------------------------------------------------------
SELECT
  franchise_id,
  SUM(total_price) AS revenue
FROM bakehouse_model.fact_sales
WHERE transaction_date = DATE '2026-10-04'
GROUP BY franchise_id;


-- ---------------------------------------------------------
-- PASO 2B: la MISMA consulta sobre la tabla SIN particionar
-- (debe leer la tabla completa aunque filtre un solo día)
-- ---------------------------------------------------------
SELECT
  franchise_id,
  SUM(total_price) AS revenue
FROM bakehouse_model.fact_sales_unpartitioned
WHERE transaction_date = DATE '2026-10-04'
GROUP BY franchise_id;
