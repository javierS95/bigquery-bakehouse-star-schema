-- =========================================================
-- EXPORT · Clientes vigentes desde Databricks (silver SCD2)
-- Solo la versión actual de cada cliente (__END_AT IS NULL)
-- Se excluyen datos personales sensibles (email, dirección, teléfono)
-- Ejecutar en el SQL Editor de Databricks y descargar como CSV
-- Archivo de salida: customers.csv
-- =========================================================

SELECT
  customerID AS customer_id,
  first_name,
  gender,
  city,
  country,
  continent
FROM workspace.silver.customers_scd2
WHERE __END_AT IS NULL;
