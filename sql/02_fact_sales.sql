-- =========================================================
-- 02 · TABLA DE HECHOS: fact_sales
-- Origen: bakehouse_model.stg_transactions + dim_product
-- Destino: bakehouse_model.fact_sales
--
-- Decisiones de diseño:
-- - Grano: una fila por transacción.
-- - PARTITION BY transaction_date: las consultas filtradas por fecha
--   leen solo las particiones necesarias (menos bytes = menor costo).
-- - CLUSTER BY franchise_id, product_key: dentro de cada partición,
--   los datos quedan ordenados por las columnas más usadas en filtros
--   y joins, lo que reduce aún más los bytes leídos.
-- - Montos como NUMERIC (no FLOAT) para evitar errores de redondeo.
-- - Las dimensiones se referencian por clave (customer_id,
--   franchise_id, product_key); los atributos viven en las dim_*.
-- =========================================================

CREATE OR REPLACE TABLE bakehouse_model.fact_sales
PARTITION BY transaction_date
CLUSTER BY franchise_id, product_key
OPTIONS (description = 'Hechos de ventas: una fila por transacción, particionada por fecha y con clustering por franquicia y producto')
AS
SELECT
  t.transaction_id,
  t.transaction_ts,
  t.transaction_date,
  t.customer_id,
  t.franchise_id,
  p.product_key,
  t.quantity,
  CAST(t.unit_price  AS NUMERIC) AS unit_price,
  CAST(t.total_price AS NUMERIC) AS total_price,
  t.payment_method
FROM bakehouse_model.stg_transactions t
LEFT JOIN bakehouse_model.dim_product p
  ON t.product = p.product_name;
