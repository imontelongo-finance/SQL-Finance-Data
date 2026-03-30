## 📌 Executive Summary
This repository contains a modular SQL-based **Revenue Assurance Pipeline** designed for high-growth marketplace platforms (e.g., Wolt). The system automates the reconciliation between operational "Upstream" events and "Downstream" ERP ledger entries, identifying revenue leakage and SOX compliance risks using deterministic logic.

---

## 🚀 The Problem
In high-volume digital environments, manual reconciliation leads to:
* **Revenue Leakage:** Orders marked as `DELIVERED` in the app but never captured in accounting.
* **Compliance Risk:** Revenue recognized on `REFUNDED` orders.
* **Ghost Entries:** Financial records existing in the ledger without a corresponding operational event.

---

## 🛠️ Technical Architecture
The engine follows a **Three-Tier Architecture** to ensure data integrity:

1. **Upstream (Operational Truth):** Captures raw data events (`upstream_orders`) including gross amounts and varying tax rates (e.g., 7% vs 19% VAT).
2. **Transformation (The Subledger View):** A view (`v_revenue_subledger`) that strips VAT and applies a **20% Commission Logic** to calculate `expected_commission_revenue` per IFRS 15.
3. **Control Layer (Audit Engine):** A bi-directional `UNION` reconciliation that compares `expected` vs. `actual_posted` amounts.

---

## 📊 Key Features & Outputs
The system generates two high-value reports for stakeholders:

### 1. The Executive Integrity Summary
Aggregates risk into actionable buckets for leadership. Based on current mock data, the system identifies:
* **REVENUE LEAKAGE:** Orders delivered but not in the ledger.
* **GHOST ENTRIES (SOX RISK):** Ledger entries with no matching app order.
* **REFUND COMPLIANCE ERROR:** Revenue incorrectly held on refunded items.
* **AMOUNT MISMATCH:** Discrepancies between expected commission and actual posted revenue.

### 2. The Daily Variance Alert
A granular exception report for Revenue Operations. It surfaces the exact `event_id` and `variance` amount (e.g., identifying a €5.88 leak on order `WOLT-DE-004`).

---

## 💻 How to Run
1. Open **MySQL Workbench**.
2. Run the `SQL Wolt Example.sql` script.
3. Inspect **Result Grid 1** for the Strategic Summary and **Result Grid 2** for the detailed Exception List.

---

## 🧠 Strategic Finance Insights
This architecture allows for:
* **Unit Economics:** Analyzing `merchant_payable` (80%) vs. `wolt_commission_revenue` (20%) across different tax jurisdictions.
* **Scalability:** Replacing manual `VLOOKUPs` with a scalable SQL script capable of processing millions of rows.

---
**Author:** Israel  
*Finance Controller | CFA Charterholder | MBA*
