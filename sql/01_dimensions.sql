-- =========================================================
-- 01 · DIMENSIONES (modelo estrella)
-- Origen: bakehouse_raw (CSV exportados desde Databricks silver)
--         y bakehouse_model.stg_transactions (ver 00_staging.sql)
-- Destino: bakehouse_model
-- Ejecutar completo en el editor de consultas de BigQuery
-- =========================================================

-- ---------------------------------------------------------
-- dim_franchise: franquicias (dato de referencia)
-- ---------------------------------------------------------
CREATE OR REPLACE TABLE bakehouse_model.dim_franchise
OPTIONS (description = 'Dimensión de franquicias: nombre y ubicación')
AS
SELECT
  franchise_id,
  franchise_name,
  city    AS franchise_city,
  country AS franchise_country
FROM bakehouse_raw.franchises;

-- ---------------------------------------------------------
-- dim_customer: clientes (versión vigente desde el SCD2 de Databricks)
-- ---------------------------------------------------------
CREATE OR REPLACE TABLE bakehouse_model.dim_customer
OPTIONS (description = 'Dimensión de clientes: atributos vigentes, sin datos personales sensibles')
AS
SELECT
  customer_id,
  first_name,
  gender,
  city    AS customer_city,
  country AS customer_country,
  continent
FROM bakehouse_raw.customers;

-- ---------------------------------------------------------
-- dim_product: productos con clave surrogada determinística
-- FARM_FINGERPRINT genera un INT64 estable a partir del nombre,
-- así la clave no cambia entre recargas.
-- ---------------------------------------------------------
CREATE OR REPLACE TABLE bakehouse_model.dim_product
OPTIONS (description = 'Dimensión de productos con clave surrogada (FARM_FINGERPRINT)')
AS
SELECT
  FARM_FINGERPRINT(product) AS product_key,
  product                   AS product_name
FROM (
  SELECT DISTINCT product
  FROM bakehouse_model.stg_transactions
  WHERE product IS NOT NULL
);

-- ---------------------------------------------------------
-- dim_date: calendario generado para el rango de ventas
-- GENERATE_DATE_ARRAY + UNNEST crea una fila por día,
-- incluso días sin ventas (útil para detectar huecos).
-- ---------------------------------------------------------
CREATE OR REPLACE TABLE bakehouse_model.dim_date
OPTIONS (description = 'Dimensión calendario: una fila por día del rango de ventas')
AS
WITH bounds AS (
  SELECT MIN(transaction_date) AS min_d, MAX(transaction_date) AS max_d
  FROM bakehouse_model.stg_transactions
)
SELECT
  d                                    AS date,
  EXTRACT(YEAR      FROM d)            AS year,
  EXTRACT(MONTH     FROM d)            AS month,
  EXTRACT(DAY       FROM d)            AS day,
  EXTRACT(ISOWEEK   FROM d)            AS iso_week,
  FORMAT_DATE('%A', d)                 AS day_name,
  EXTRACT(DAYOFWEEK FROM d) IN (1, 7)  AS is_weekend
FROM bounds, UNNEST(GENERATE_DATE_ARRAY(min_d, max_d)) AS d;
