## 📌 Executive Summary
This repository contains a modular SQL-based **Revenue Assurance Pipeline** designed for high-growth marketplace platforms (e.g., Wolt, UberEats). The system automates the reconciliation between operational "App" events and the General Ledger, identifying revenue leakage and SOX compliance risks in real-time.

---

## 🚀 The Problem
In high-volume digital environments, manual reconciliation in Excel leads to:
* **Revenue Leakage:** Orders delivered but never captured in accounting.
* **Compliance Risk:** Revenue recognized on cancelled or refunded orders.
* **Insolvability:** Lack of a granular audit trail from the GL back to the Transaction ID.

---

## 🛠️ Technical Architecture
The engine follows a **Three-Tier Architecture** to ensure data integrity and scalability:

1. **Ingestion Layer (Upstream):** Captures raw event data (Gross Amount, VAT, Status) using high-precision `DECIMAL(10,2)` types.
2. **Transformation Layer (Subledger Logic):** A deterministic **SQL View** that applies IFRS 15 Revenue Recognition rules (Net vs. Gross) automatically.
3. **Control Layer (Audit Engine):** A bi-directional `UNION` logic that performs a 360-degree check between the App and the Ledger.

---

## 📊 Key Features & Outputs
The system generates two high-value reports for stakeholders:

### 1. The Executive Risk Summary
Categorizes financial exposure into actionable buckets for the Finance Director.

| Audit Result | Incident Count | Total Variance Exposure |
| :--- | :--- | :--- |
| **MATCHED** | 2 | €0.00 |
| **REVENUE LEAKAGE** | 1 | €5.88 |
| **GHOST ENTRIES** | 1 | €15.00 |
| **REFUND ERROR** | 1 | €10.08 |

### 2. The Daily Exception Alert
A granular "to-do list" for Revenue Operations to fix specific Order IDs.

---

## 💻 How to Use
1. Clone the repository.
2. Run `src/full_pipeline.sql` in MySQL Workbench.
3. View the **Result Grid** for immediate variance analysis.

---

## 🧠 Strategic Finance Insights
Beyond accounting, this subledger allows for:
* **Unit Economics Analysis:** Identifying net take-rates by merchant segment (e.g., Fast Food vs. Fine Dining).
* **Tax Sensitivity Modeling:** Simulating the bottom-line impact of VAT changes across global markets.
* **Cohort Profitability:** Tracking long-term commission value by customer acquisition source.

---
**Author:** Israel  
*Finance Professional | CFA Charterholder | MBA*
