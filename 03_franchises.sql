-- =========================================================
-- EXPORT · Franquicias (dato de referencia) desde Databricks
-- Ejecutar en el SQL Editor de Databricks y descargar como CSV
-- Archivo de salida: franchises.csv
-- =========================================================

SELECT
  franchiseID AS franchise_id,
  name        AS franchise_name,
  city,
  country
FROM samples.bakehouse.sales_franchises;
