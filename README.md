# LEGO: Valuable for Collectors and Resellers?
**BUS32120: Data Analysis with Python & SQL — Final Project**
Kharla Loayza & Sruthi Pasupuleti | Winter 2026

---

## Overview

This project analyzes what makes a LEGO set a good investment. Using data from **Rebrickable** and **BrickLink**, we combine physical set characteristics with secondary market pricing to understand which features — if any — predict price appreciation after a set is retired.

**Target audience:** LEGO collectors and secondary market investors looking to identify which sets to buy before retirement.

**Key question:** Can a LEGO set's physical characteristics predict its price appreciation in the secondary market?

---

## Repository Contents

| File | Description |
|------|-------------|
| `Final_vFF.ipynb` | Main Jupyter notebook — full analysis including EDA, feature engineering, SQL, and modeling |
| `lego_sql_queries.sql` | All 10 SQL queries as a standalone script with comments |
| `README.md` | This file |
| `Lego_ Valuable for Collectors & Resellers` | Presentation |

### Data Files (not included — download links below)
| File | Source |
|------|--------|
| `sets.csv` | Rebrickable |
| `themes.csv` | Rebrickable |
| `colors.csv` | Rebrickable |
| `inventories.csv` | Rebrickable |
| `inventory_parts.csv` | Rebrickable |
| `minifigs.csv` | Rebrickable |
| `inventory_minifigs.csv` | Rebrickable |
| `lego_additional_info.csv` | BrickLink (secondary market pricing) |

---

## Engineered Features

| Variable | Description |
|----------|-------------|
| `price_appreciation` | `(pop_price - retire_price) / retire_price` — % gain/loss one year after retirement |
| `good_investment` | Binary: 1 if `price_appreciation > 20%`, else 0 |
| `is_licensed` | Binary: 1 if the set belongs to a licensed theme (e.g. Star Wars, Batman) |
| `parts_per_minifig` | `num_parts / minifig_count` — complexity ratio; uses `num_parts` if no minifigs |
| `color_diversity` | Number of unique colors per set, extracted from `inventory_parts` via `inventories` |
| `minifig_count` | Total minifigures per set, extracted from `inventory_minifigs` via `inventories` |
| `parent_theme_name` | Top-level theme (e.g. "Star Wars" instead of "Clone Wars") |

---

## SQL Queries Summary

| Query | Type | Description |
|-------|------|-------------|
| 1 | GROUP BY | Sets released per year, licensed vs non-licensed split |
| 2 | GROUP BY | Top themes by number of sets |
| 3 | GROUP BY + CASE WHEN | Licensed vs non-licensed comparison |
| 4 | INNER JOIN | Join set features with pricing data |
| 5 | JOIN + GROUP BY + HAVING | Average price appreciation by theme |
| 6 | JOIN + GROUP BY + HAVING | Share of good investments by theme |
| 7 | JOIN + Subquery | Themes above overall average appreciation |
| 8 | JOIN + Window Function (RANK) | Best-performing set per theme |
| 9 | JOIN + Window Function (AVG) | Each set vs. its theme average |
| 10 | JOIN + Double Subquery | Sets that beat both theme and overall average |

---

## Models

### Linear Regression
- **Target:** `price_appreciation` (continuous)
- **Features:** `num_parts`, `minifig_count`, `color_diversity`, `is_licensed`, `parts_per_minifig`
- **Results:** R² = -0.007, RMSE = 26% — model underperforms baseline

### Logistic Regression
- **Target:** `good_investment` (binary)
- **Features:** Same 5 features
- **Results:** Accuracy = 68.1%, Precision = 1.0, Recall = 3.7%, ROC-AUC = 0.519

Both models confirm that physical set characteristics alone are insufficient to predict investment performance.

---

## Key Findings

1. **Most LEGO sets don't appreciate** — the majority cluster around 0% appreciation and some lose value after retirement
2. **Niche themes outperform iconic franchises** — Elves, Architecture, and Brickheadz have higher investment rates than Star Wars and Harry Potter
3. **Scarcity > brand recognition** — themes with fewer total sets tend to produce better investment returns
4. **Individual set selection matters** — even within good themes, there is wide variability between sets
5. **Physical features don't predict returns** — neither model performed well, suggesting missing variables like scarcity data and social media signals are more important

---

## Future Work

- Incorporate scarcity data (print run size, retirement timing)
- Add BrickLink watchlist counts as a demand signal
- Include social media sentiment and community engagement data
- Explore tree-based models (Random Forest, XGBoost) to capture non-linear relationships
- Add StandardScaler normalization before modeling
