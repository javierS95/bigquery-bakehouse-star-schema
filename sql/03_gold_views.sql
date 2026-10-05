-- =========================================================
-- 03 · GOLD: vistas de negocio sobre el modelo estrella
-- Origen: bakehouse_model (fact_sales + dim_*)
-- Destino: bakehouse_gold
--
-- Replican los modelos gold del proyecto en Databricks, pero
-- construidos sobre un modelo dimensional: la tabla de hechos
-- tiene solo claves y métricas, y los atributos vienen de las
-- dimensiones vía JOIN.
-- Son VISTAS (no tablas): no duplican datos y siempre reflejan
-- el estado actual de fact_sales.
-- =========================================================

-- ---------------------------------------------------------
-- Ventas diarias por franquicia
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW bakehouse_gold.daily_sales_by_franchise
OPTIONS (description = 'Ventas diarias por franquicia: transacciones, unidades, ingresos y ticket promedio')
AS
SELECT
  f.transaction_date,
  d.day_name,
  d.is_weekend,
  f.franchise_id,
  df.franchise_name,
  df.franchise_city,
  df.franchise_country,
  COUNT(*)                                        AS n_transactions,
  SUM(f.quantity)                                 AS units_sold,
  SUM(f.total_price)                              AS revenue,
  ROUND(SAFE_DIVIDE(SUM(f.total_price), COUNT(*)), 2) AS avg_ticket
FROM bakehouse_model.fact_sales f
JOIN bakehouse_model.dim_date d
  ON f.transaction_date = d.date
LEFT JOIN bakehouse_model.dim_franchise df
  ON f.franchise_id = df.franchise_id
GROUP BY 1, 2, 3, 4, 5, 6, 7;

-- ---------------------------------------------------------
-- Desempeño por producto
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW bakehouse_gold.product_performance
OPTIONS (description = 'Desempeño por producto: unidades, ingresos y participación sobre el total (escala 0-100)')
AS
SELECT
  p.product_name,
  COUNT(*)                                                         AS n_transactions,
  SUM(f.quantity)                                                  AS units_sold,
  SUM(f.total_price)                                               AS revenue,
  ROUND(100 * SUM(f.total_price) / SUM(SUM(f.total_price)) OVER (), 2) AS revenue_share_pct
FROM bakehouse_model.fact_sales f
JOIN bakehouse_model.dim_product p
  ON f.product_key = p.product_key
GROUP BY 1;

-- ---------------------------------------------------------
-- Métricas por cliente
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW bakehouse_gold.customer_metrics
OPTIONS (description = 'Métricas por cliente: frecuencia, gasto total, ticket promedio y ubicación vigente')
AS
SELECT
  f.customer_id,
  c.first_name,
  c.customer_city,
  c.customer_country,
  MIN(f.transaction_date)                         AS first_purchase,
  MAX(f.transaction_date)                         AS last_purchase,
  COUNT(*)                                        AS n_transactions,
  SUM(f.total_price)                              AS total_spent,
  ROUND(SAFE_DIVIDE(SUM(f.total_price), COUNT(*)), 2) AS avg_ticket
FROM bakehouse_model.fact_sales f
LEFT JOIN bakehouse_model.dim_customer c
  ON f.customer_id = c.customer_id
GROUP BY 1, 2, 3, 4;

-- ---------------------------------------------------------
-- NUEVA (no existe en Databricks): ventas por día de la semana
-- Aprovecha dim_date, algo que el modelo agregado de Databricks
-- no tenía: muestra el valor de modelar un calendario.
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW bakehouse_gold.sales_by_weekday
OPTIONS (description = 'Ventas por día de la semana: promedio diario de ingresos y transacciones')
AS
SELECT
  d.day_name,
  d.is_weekend,
  COUNT(DISTINCT f.transaction_date)                                   AS days_observed,
  COUNT(*)                                                             AS n_transactions,
  SUM(f.total_price)                                                   AS revenue,
  ROUND(SAFE_DIVIDE(SUM(f.total_price), COUNT(DISTINCT f.transaction_date)), 2) AS avg_daily_revenue
FROM bakehouse_model.fact_sales f
JOIN bakehouse_model.dim_date d
  ON f.transaction_date = d.date
GROUP BY 1, 2;
