-- =========================================================
-- EXPORT · Transacciones limpias desde Databricks (silver)
-- Ejecutar en el SQL Editor de Databricks y descargar como CSV
-- Archivo de salida: transactions.csv
-- =========================================================

SELECT
  transaction_id,
  customer_id,
  franchise_id,
  transaction_ts,
  transaction_date,
  product,
  quantity,
  unit_price,
  total_price,
  payment_method
FROM workspace.silver.transactions;
