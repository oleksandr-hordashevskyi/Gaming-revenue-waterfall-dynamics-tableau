# 🎮 Gaming-revenue-waterfall-dynamics-tableau

[![Tableau Public](https://img.shields.io/badge/Tableau_Public-Live_Dashboard-E97627?style=flat&logo=tableau&logoColor=white)](https://public.tableau.com/app/profile/oleksandr.hordashevskyi/viz/GamingRevenueUserDynamics/GamingRevenueUserDynamics)
[![Database](https://img.shields.io/badge/PostgreSQL-Data_Pipeline-336791?style=flat&logo=postgresql&logoColor=white)](#-technical-architecture--data-pipeline)
[![Domain](https://img.shields.io/badge/SaaS_/_Gaming-Unit_Economics-4CAF50?style=flat)](#-key-metrics-definitions--formulas)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📌 Executive Summary

An end-to-end subscription and gaming monetization intelligence solution designed for product managers and C-level stakeholders to monitor monthly recurring cash flows and decompose underlying revenue volatility.

Built on an analytical dataset from **PostgreSQL (1,392 validated rows)**, the project synthesizes transaction-level gamer telemetry into cohort transitions. The interactive Business Intelligence layer in **Tableau Public** decomposes recurring revenue and user dynamics into opposing expansion, contraction, and churn vectors relative to a zero baseline, providing granular visibility into user base stability, monetization efficiency, and lifecycle value.

* **Live Interactive Dashboard:** [View on Tableau Public](https://public.tableau.com/app/profile/oleksandr.hordashevskyi/viz/GamingRevenueUserDynamics/GamingRevenueUserDynamics)
* **Target Audience:** Product Managers, Monetization Leads, Growth Analysts.
* **Core Business Model:** Recurring in-game purchases and subscriptions across multi-language user cohorts.

---

## 📊 Visualizations & Dashboard Overview

![Gaming Revenue Dashboard Preview](images/01_gaming_revenue_dashboard.png)

The dashboard architecture adheres to executive dashboard design standards and the **5-second cognitive comprehension rule**, structured into three analytical horizons:
1. **High-Level Financial Dynamics (Top-Left):** Dual-axis tracking comparing absolute **Monthly Recurring Revenue (MRR)** volume against **Average Revenue Per Paid User (ARPPU)** efficiency.
2. **Portfolio Risk & Attrition Trajectories (Top-Right):** Synchronized trends comparing **Paid Users Churn Rate** against **Revenue Churn Rate** to detect customer retention vs. revenue dilution divergence.
3. **MoM Growth & Attrition Factors (Center):** Paired zero-baseline waterfall bar charts isolating exact expansion vs. contraction forces:
   * **Revenue Change Factors:** New MRR & Expansion MRR vs. Contraction MRR & Churned Revenue.
   * **Paid Users Change Factors:** New Paid Users & Back-from-Churn Users vs. Churned Users.
4. **Demographic Monetization Segmentation (Bottom):** Horizontal cohort breakdown across age brackets (`< 18`, `18–24`, `25–34`, `35+`) clustered by localization languages (`en`, `ru`, `uk`).

### 1. Data Engineering & Harmonization (PostgreSQL / DBeaver)
* **CTE 1 (Granular User Aggregations):** Aggregated payments into `[user_id, payment_month, SUM(revenue_amount_usd)]`.
* **CTE 2 (Chronological Offsetting):** Engineered temporal window frames using `LAG()` and `LEAD()` over `ORDER BY payment_month` partitioned by `user_id` to establish prior/subsequent payment months and amounts.
* **CTE 3 (Status Categorization):** Implemented conditional branching via `CASE WHEN` to accurately classify customer states:
  * `is_new_user`: Identifies initial purchase events (`previous_payment_month IS NULL`).
  * `is_back_from_churn`: Identifies reactivated players (`payment_month - previous_payment_month > 1`).
  * `expansion_mrr` / `contraction_mrr`: Delta calculation comparing current vs. previous month revenue.
* **Final Join:** Enriched transactional data with demographic dimensions (`age`, `language`, `game_name`) via a `LEFT JOIN` on `project.games_paid_users`. Output precisely matched the benchmark volume of **1,392 rows**.

### 2. Business Intelligence & Table Calculations (Tableau)
* **Temporal Shift Handling:** Solved the churn observation paradox where users who stopped paying generate no transaction records. Engineered directional Table Calculations using `LOOKUP(SUM([churned_revenue]), -1)` and `LOOKUP(SUM([is_churned_user]), -1)` along `Table (across)` to project churn attributes onto the target transition month.
* **Dynamic Churn Rate Modeling:** Built non-additive formulas dividing shifted attrition volumes by previous-period active users:
  $$\text{Paid Users Churn Rate} = \frac{\text{Churned Users (Shifted)}}{\text{LOOKUP}(\text{[Paid Users]}, -1)}$$
* **Interactive Slicing & Dicing:** Configured synchronized multi-select dropdown controls for `Payment Month`, `Language`, and `Age Group`, broadcasting globally across all visual containers (`All Using This Data Source`).

---

## 📐 Key Metrics Definitions & Formulas

| Metric | Definition | Implementation Logic |
| :--- | :--- | :--- |
| **MRR** | Monthly Recurring Revenue from paying players | `SUM([mrr])` |
| **Paid Users** | Distinct paying gamers in a calendar month | `COUNTD([user_id])` |
| **ARPPU** | Average Revenue Per Paid User | `SUM([mrr]) / [Paid Users]` |
| **New MRR** | Revenue generated by first-time payers | `SUM([new_mrr])` |
| **Expansion MRR** | Increase in revenue from upgraded existing payers | `SUM([expansion_mrr])` |
| **Contraction MRR**| Decrease in revenue from existing payers who paid less | `SUM([contraction_mrr])` |
| **Churned Revenue**| Previous month's revenue lost from players who churned | `LOOKUP(SUM([churned_revenue]), -1)` |
| **User Churn Rate**| Percentage of paying users lost MoM | `[Churned Users (Shifted)] / LOOKUP([Paid Users], -1)` |
| **Rev Churn Rate** | Percentage of recurring revenue lost MoM | `[Churned Revenue (Shifted)] / LOOKUP(SUM([mrr]), -1)` |
| **Customer LT** | Projected average customer lifetime (in months) | `1 / [Paid Users Churn Rate]` |
| **Customer LTV**| Projected customer lifetime value | `[ARPPU] * [LT]` |

---

## 📈 Key Business Insights

* **Healthy Top-Line Growth vs. Unit Economics Stability:** Monthly Recurring Revenue expanded rapidly from **$1,491 in March** to a peak of **$9,344 in October**, plateauing at **$8,440 in December**. Throughout this scaling phase, **ARPPU remained remarkably stable ($43–$49)**, proving that top-line revenue expansion was driven predominantly by volume acquisition rather than pricing inflation.
* **Critical Fall Churn Spike:** During October–November, **Paid Users Churn Rate jumped from 25.7% to 35.7%**, driving monthly revenue churn losses above **$2.8K**. This indicates a typical 90–120 day product lifecycle cliff where mid-core players exhaust primary content loops.
* **Demographic Concentration:** The **18–24 age bracket represents the monetization engine**, contributing **>$33K (>52% of total cumulative MRR)**. Within this bracket, English-speaking players (`en`) drove **$22,102**, showing the highest willingness to pay for in-game content. Conversely, players aged **35+** represented less than 3% of revenue ($1.5K).

---

## 💡 Strategic Recommendations

1. **Implement Day 90–120 Re-Engagement Trigger Loops:** Establish automated retention interventions (targeted questlines, VIP battle pass accelerators, or returning player bundles) around the third month of user tenure to blunt the Q4 churn wave.
2. **Reallocate UA Budgets toward Core Demographic Anchors:** Double down performance marketing spend on English-speaking players aged 18–24, where LTV and payment conversion frequencies demonstrate the strongest unit economic margins.
3. **Monetize the Core via Expansion Mechanics:** Introduce premium cosmetic tiers and recurring monthly club subscriptions to boost Expansion MRR, which currently lags behind new user acquisition.

---

## 📁 Project Structure & Deliverables

```text
gaming-revenue-waterfall-dynamics-tableau/
├── LICENSE                                    # MIT Open Source License
├── README.md                                  # Executive business summary & technical docs
├── dashboards/
│   └── Gaming Revenue & User Dynamics.twbx     # Packaged Tableau Workbook
├── sql/
│   └── gaming_revenue_metrics_pipeline.sql     # Multi-stage PostgreSQL ETL extraction query
├── data/
│   └── games_revenue_metrics.csv               # Data dictionary & schema validation notes
└── images/
    └── gaming_revenue_dashboard.png        # High-res dashboard visual asset

```
---
## ✉️ Contact

**Author:** Oleksandr Hordashevskyi

- LinkedIn: [Oleksandr Hordashevskyi](https://www.linkedin.com/in/oleksandr-hordashevskyi)
- Email: [o.hordashevskyi@gmail.com](mailto:o.hordashevskyi@gmail.com)


---

## 🛠 Technical Architecture & Data Pipeline
