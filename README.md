# E-Commerce Sales & Customer Analytics

## Project Overview
Analysis of 1M+ retail transactions from a UK-based online store 
to uncover sales trends, customer behavior, and product performance 
insights using MySQL.

This project demonstrates end-to-end data analyst skills including 
data cleaning, exploratory analysis, customer segmentation, and 
advanced SQL techniques.

---

## Tools & Technologies
- **Database:** MySQL 8.0
- **Dataset:** Online Retail II — UCI Machine Learning Repository
- **Concepts Used:** CTEs, Window Functions, RFM Analysis, 
  Cohort Analysis, Subqueries, Aggregations

---

## Dataset Details
| Property | Value |
|---|---|
| Source | UCI Machine Learning Repository |
| Raw Rows | 1,067,371 |
| Clean Rows | 1,007,895 |
| Time Period | December 2009 — December 2011 |
| Columns | Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country |

---

## Data Cleaning Summary
| Issue Found | Count | Action Taken |
|---|---|---|
| Empty Customer IDs | 243,007 | Converted to NULL — excluded from customer analysis |
| Duplicate Rows | 32,909 | Removed using DISTINCT |
| Cancellation Invoices | 19,494 | Excluded (invoices starting with 'C') |
| Negative Quantities | 22,950 | Excluded |
| Zero/Negative Prices | 6,225 | Excluded |
| Empty Descriptions | 4,382 | Excluded |
| **Final Clean Dataset** | **1,007,895** | **Used for all analysis** |

---

## Key Business Findings

### 1. Overall Performance
- Store generated **£20.4M revenue** over 2 years
- **40,077 orders** from **5,878 unique customers**
- Average order value of **£20.32**
- Average revenue per customer of **£3,483**

### 2. Sales Trends
- **November** is consistently the peak revenue month both years
- **Q4 (Sep-Dec) Golden Quarter** generates 46% of annual revenue
- February is consistently the lowest revenue month
- Revenue remained stable at ~£9.8M in both 2010 and 2011

### 3. Product Insights
- **White Hanging Heart T-Light Holder** is the hero product —
  appears in both top revenue and top quantity lists
- High volume products don't always mean high revenue —
  World War 2 Gliders sold 106K units but generated only £24K
- Non-product entries (postage, manual adjustments) found
  in top revenue list — flagged for business review

### 4. Customer Insights
- **72.39%** of customers made repeat purchases
- Only **27.61%** were one-time buyers
- Top 10 customers account for **16% of total revenue**
- Customer 18102 (UK) is the highest value customer at **£580,987**

### 5. RFM Segmentation
| Segment | Customers | % | Avg Spend | Total Revenue |
|---|---|---|---|---|
| Champions | 1,310 | 22.29% | £9,707 | £12,716,165 |
| Loyal Customers | 1,368 | 23.27% | £2,102 | £2,875,867 |
| Potential Loyalists | 1,455 | 24.75% | £862 | £1,255,186 |
| At Risk Customers | 1,301 | 22.13% | £355 | £461,933 |
| Lost Customers | 444 | 7.55% | £147 | £65,650 |

- **Champions (22% of customers) generate 62% of revenue**
- 1,455 Potential Loyalists represent biggest re-engagement opportunity

### 6. Geographic Insights
- **UK dominates with 85% of revenue** (£17.4M)
- Netherlands has highest average order value at **£108.96**
- Australia and Denmark also show high average order values
  suggesting wholesale buying behavior

---

## Business Recommendations
1. **Retain Champions** — implement loyalty rewards for top 1,310
   customers who generate 62% of revenue
2. **Re-engage Potential Loyalists** — 1,455 customers haven't bought
   in 198 days — targeted email campaign recommended
3. **Expand internationally** — Netherlands and Australia show high
   average order values suggesting untapped wholesale opportunity
4. **Prepare for Golden Quarter** — ramp up inventory and staffing
   from September every year
5. **Investigate non-product revenue** — postage and manual entries
   appearing in top revenue list needs business review

---
## SQL Sections
| Section | Description |
|---|---|
| Section 1 | Database Setup |
| Section 2 | Table Creation |
| Section 3 | Data Import |
| Section 4 | Data Cleaning |
| Section 5 | Exploratory Data Analysis |
| Section 6 | Customer & RFM Analysis |
| Section 7 | Advanced Analysis (CTEs + Window Functions) |
| Section 8 | Business Insights Summary |

---

## Advanced SQL Techniques Used
| Technique | Where Used |
|---|---|
| CTE (Common Table Expressions) | RFM Analysis, Cohort Analysis, Rankings |
| LAG() | Month over Month Revenue Growth |
| SUM() OVER() | Running Total Revenue |
| RANK() / DENSE_RANK() | Customer Revenue Ranking |
| NTILE() | RFM Scoring, Customer Quartiles |
| FIRST_VALUE() | Cohort Retention Rate |
| CASE WHEN | Customer Segmentation, RFM Segments |
| DATEDIFF() | Recency Calculation |
| NULLIF() | Empty String Handling |
| STR_TO_DATE() | Date Format Conversion |

---

*Dataset Source: https://archive.ics.uci.edu/dataset/502/online+retail+ii*
---

## Author
**Siyara Sathar**
- 💼 LinkedIn: www.linkedin.com/in/siyara-sathar
- 📧 Email: siyarasathar18@gmail.com
- 🐙 GitHub: https://github.com/siyaraaa18

---
*This project was built as part of my Data Analyst portfolio*
