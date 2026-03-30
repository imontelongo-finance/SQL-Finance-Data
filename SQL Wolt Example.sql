/* Project: Revenue & Refund Audit Pipeline
   Author: Israel (Finance Professional)
   Target: Wolt Strategic Finance / Finance Manager Role
*/

-- ==========================================
-- 1. ENVIRONMENT SETUP
-- ==========================================
CREATE SCHEMA IF NOT EXISTS wolt_finance_audit;
USE wolt_finance_audit;

-- ==========================================
-- 2. UPSTREAM: Operational "Ground Truth"
-- ==========================================
-- Represents raw event data from Snowflake/BigQuery
CREATE TABLE IF NOT EXISTS upstream_orders (
    event_id VARCHAR(50) PRIMARY KEY,
    customer_id INT,
    order_timestamp DATETIME,
    gross_amount_eur DECIMAL(10, 2),
    tax_rate DECIMAL(4, 2), -- e.g., 0.19 for Germany
    order_status VARCHAR(20) -- DELIVERED, CANCELLED, REFUNDED
);

-- Reset and Insert Sample Events (including edge cases)
TRUNCATE TABLE upstream_orders;
INSERT INTO upstream_orders VALUES 
('WOLT-DE-001', 5001, '2026-03-29 18:30:00', 45.00, 0.19, 'DELIVERED'),
('WOLT-DE-002', 5002, '2026-03-29 19:15:00', 25.00, 0.07, 'DELIVERED'),
('WOLT-DE-003', 5003, '2026-03-29 20:05:00', 60.00, 0.19, 'REFUNDED'),
('WOLT-DE-004', 5004, '2026-03-29 21:00:00', 35.00, 0.19, 'DELIVERED'), -- Tests Leakage
('WOLT-DE-005', 5005, '2026-03-29 22:00:00', 50.00, 0.19, 'DELIVERED'); -- Tests Amount Mismatch


-- ==========================================
-- 3. DOWNSTREAM: Accounting Ledger Data
-- ==========================================
-- Represents actual entries currently sitting in the ERP (NetSuite)
CREATE TABLE IF NOT EXISTS subledger_entries (
    order_id VARCHAR(50) PRIMARY KEY,
    recognized_revenue DECIMAL(10, 2),
    entry_date DATE,
    accounting_period VARCHAR(20)
);

-- Reset and Insert Recorded Entries
TRUNCATE TABLE subledger_entries;
INSERT INTO subledger_entries VALUES 
('WOLT-DE-001', 7.56, '2026-03-29', '2026-03'),  -- Matches logic
('WOLT-DE-002', 4.67, '2026-03-29', '2026-03'),  -- Matches logic
('WOLT-DE-003', 10.08, '2026-03-29', '2026-03'), -- Error: Revenue on Refund
('WOLT-DE-005', 12.00, '2026-03-29', '2026-03'), -- Error: Incorrect amount
('GHOST-999', 15.00, '2026-03-29', '2026-03');   -- Ghost Entry (Audit Test)


-- ==========================================
-- 4. TRANSFORMATION: IFRS 15 Subledger View
-- ==========================================
-- This view acts as the 'Deterministic Brain' of the system
CREATE OR REPLACE VIEW v_revenue_subledger AS
SELECT 
    event_id,
    order_status,
    gross_amount_eur,
    -- Step 1: Strip VAT to find Net Sales
    ROUND(gross_amount_eur / (1 + tax_rate), 2) AS net_sales_value,
    -- Step 2: Recognition Logic (20% Commission on Delivered)
    CASE 
        WHEN order_status = 'DELIVERED' THEN ROUND((gross_amount_eur / (1 + tax_rate)) * 0.20, 2)
        ELSE 0 
    END AS expected_commission_revenue,
    -- Step 3: Liability (80% to Merchant)
    CASE 
        WHEN order_status = 'DELIVERED' THEN ROUND((gross_amount_eur / (1 + tax_rate)) * 0.80, 2)
        ELSE 0 
    END AS merchant_payable
FROM upstream_orders;


-- ==========================================
-- 5. AUDIT ENGINE: Integrity & SOX Controls
-- ==========================================
-- Comprehensive reconciliation of App vs. Ledger
SELECT 
    audit_result,
    COUNT(*) AS incident_count,
    SUM(ABS(expected - actual_posted)) AS total_variance_exposure
FROM (
    SELECT 
        o.event_id,
        v.expected_commission_revenue AS expected,
        COALESCE(s.recognized_revenue, 0) AS actual_posted,
        CASE 
            WHEN s.order_id IS NULL AND o.order_status = 'DELIVERED' THEN 'REVENUE LEAKAGE'
            WHEN o.event_id IS NULL AND s.order_id IS NOT NULL THEN 'GHOST ENTRIES (SOX RISK)'
            WHEN o.order_status = 'REFUNDED' AND s.recognized_revenue > 0 THEN 'REFUND COMPLIANCE ERROR'
            WHEN v.expected_commission_revenue != s.recognized_revenue THEN 'AMOUNT MISMATCH'
            ELSE 'MATCHED'
        END AS audit_result
    FROM upstream_orders o
    JOIN v_revenue_subledger v ON o.event_id = v.event_id
    LEFT JOIN subledger_entries s ON o.event_id = s.order_id
    
    UNION
    
    SELECT s.order_id, 0, s.recognized_revenue, 'GHOST ENTRIES (SOX RISK)'
    FROM subledger_entries s
    LEFT JOIN upstream_orders o ON s.order_id = o.event_id
    WHERE o.event_id IS NULL
) AS combined_audit
GROUP BY audit_result;


-- ==========================================
-- 6. EXCEPTION ALERT: Daily Variance Report
-- ==========================================
-- This provides granular detail for the Finance team to investigate
SELECT 
    event_id,
    expected_commission_revenue AS expected,
    actual AS actual_posted,
    variance
FROM (
    SELECT 
        o.event_id,
        v.expected_commission_revenue,
        COALESCE(s.recognized_revenue, 0) AS actual,
        ROUND(v.expected_commission_revenue - COALESCE(s.recognized_revenue, 0), 2) AS variance
    FROM upstream_orders o
    JOIN v_revenue_subledger v ON o.event_id = v.event_id
    LEFT JOIN subledger_entries s ON o.event_id = s.order_id
) AS variance_check
WHERE variance != 0;
