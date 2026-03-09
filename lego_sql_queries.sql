-- ============================================================
-- LEGO Investment Analysis — SQL Queries
-- BUS32120: Data Analysis with Python & SQL
-- Kharla Loayza & Sruthi Pasupuleti | Winter 2026
-- ============================================================
-- Tables used:
--   sets_clean   — all LEGO sets with features and engineered variables
--   sets_priced  — subset of sets_clean with pricing data from BrickLink
--
-- Key variables:
--   price_appreciation = (pop_price - retire_price) / retire_price
--   good_investment    = 1 if price_appreciation > 20%, else 0
--   is_licensed        = 1 if set belongs to a licensed theme, else 0
--   parts_per_minifig  = num_parts / minifig_count (complexity ratio)
-- ============================================================


-- ============================================================
-- QUERY 1: Sets Released Per Year
-- ============================================================
-- What it does:
--   Shows the number of LEGO sets released each year, split by
--   licensed and non-licensed.
-- How it works:
--   Groups rows by year and counts sets in each group.
--   SUM(is_licensed) works because is_licensed is binary (0/1).
-- Why it matters:
--   Identifies whether LEGO's product output grew over time and
--   how the licensed/non-licensed mix evolved.
-- Output: ~1 row per year
-- ============================================================

SELECT
    year,
    COUNT(*) AS total_sets,
    SUM(is_licensed) AS licensed_sets,
    COUNT(*) - SUM(is_licensed) AS non_licensed_sets
FROM sets_clean
GROUP BY year
ORDER BY year;


-- ============================================================
-- QUERY 2: Top LEGO Themes by Number of Sets
-- ============================================================
-- What it does:
--   Finds the parent themes with the most LEGO sets.
-- How it works:
--   Groups rows by parent_theme_name and counts sets per theme.
-- Why it matters:
--   Identifies LEGO's dominant product categories and shows
--   whether licensed or core themes lead in volume.
-- Output: Top 10 themes by set count
-- ============================================================

SELECT
    parent_theme_name,
    COUNT(*) AS total_sets
FROM sets_clean
GROUP BY parent_theme_name
ORDER BY total_sets DESC
LIMIT 10;


-- ============================================================
-- QUERY 3: Licensed vs. Non-Licensed Sets Comparison
-- ============================================================
-- What it does:
--   Compares structural characteristics between licensed and
--   non-licensed sets.
-- How it works:
--   Uses CASE WHEN to label the is_licensed flag, then groups
--   by license type and calculates averages for each group.
-- Why it matters:
--   Tests whether licensed sets are systematically different
--   in size, complexity, and rating.
-- Output: 2 rows (Licensed, Non-Licensed) with avg characteristics
-- ============================================================

SELECT
    CASE
        WHEN is_licensed = 1 THEN 'Licensed'
        ELSE 'Non-Licensed'
    END AS license_type,
    COUNT(*) AS total_sets,
    AVG(num_parts) AS avg_num_parts,
    AVG(minifig_count) AS avg_minifigs,
    AVG(color_diversity) AS avg_color_diversity,
    AVG(set_rating) AS avg_rating
FROM sets_clean
GROUP BY is_licensed;


-- ============================================================
-- QUERY 4: Join Set Features with Pricing Data
-- ============================================================
-- What it does:
--   Combines structural set characteristics with secondary
--   market pricing data into one view.
-- How it works:
--   Joins sets_clean and sets_priced on set_num (unique set ID).
--   Uses INNER JOIN so only sets with pricing data are returned.
-- Why it matters:
--   Creates the base needed to analyze how product features
--   relate to investment outcomes.
-- Output: Sample of 20 priced sets with all key variables
-- ============================================================

SELECT
    s.set_num,
    s.name,
    s.year,
    s.parent_theme_name,
    s.num_parts,
    s.minifig_count,
    s.color_diversity,
    p.retire_price,
    p.pop_price,
    p.price_appreciation,
    p.good_investment
FROM sets_clean s
INNER JOIN sets_priced p
    ON s.set_num = p.set_num
LIMIT 20;


-- ============================================================
-- QUERY 5: Average Price Appreciation by Theme
-- ============================================================
-- What it does:
--   Calculates the average secondary market appreciation
--   for each parent theme.
-- How it works:
--   Joins the two tables, groups by theme, and computes the
--   average price_appreciation. HAVING filters to themes with
--   at least 10 priced sets to ensure statistical reliability.
-- Why it matters:
--   Identifies which themes produce the highest average returns —
--   not just the most frequent good investments.
-- Output: Themes ranked by average price appreciation (min 10 sets)
-- ============================================================

SELECT
    s.parent_theme_name,
    COUNT(*) AS priced_sets,
    AVG(p.price_appreciation) AS avg_price_appreciation
FROM sets_clean s
INNER JOIN sets_priced p
    ON s.set_num = p.set_num
GROUP BY s.parent_theme_name
HAVING COUNT(*) >= 10
ORDER BY avg_price_appreciation DESC;


-- ============================================================
-- QUERY 6: Share of Good Investments by Theme
-- ============================================================
-- What it does:
--   Measures how often sets in each theme are classified as
--   good investments (appreciated > 20%).
-- How it works:
--   AVG(good_investment) works because good_investment is binary
--   (0/1) — the average gives the share of 1s (good investments).
--   HAVING filters to themes with at least 10 priced sets.
-- Why it matters:
--   Shows investment consistency by theme, and reveals that
--   niche themes outperform major franchises like Star Wars.
-- Output: Themes ranked by % of sets that are good investments
-- ============================================================

SELECT
    s.parent_theme_name,
    COUNT(*) AS priced_sets,
    AVG(p.good_investment) AS percentage_good_investment
FROM sets_clean s
INNER JOIN sets_priced p
    ON s.set_num = p.set_num
GROUP BY s.parent_theme_name
HAVING COUNT(*) >= 10
ORDER BY percentage_good_investment DESC;


-- ============================================================
-- QUERY 7: Themes Above Overall Average Appreciation (Subquery)
-- ============================================================
-- What it does:
--   Identifies themes whose average appreciation beats the
--   overall dataset average.
-- How it works:
--   The subquery computes the overall average price_appreciation
--   across all priced sets. The outer query then filters to
--   themes where the theme average exceeds that benchmark.
-- Why it matters:
--   Provides a stronger benchmark than just ranking themes —
--   only themes that are genuinely above average are returned.
-- Output: Themes that outperform the overall average
-- ============================================================

SELECT
    s.parent_theme_name,
    AVG(p.price_appreciation) AS avg_price_appreciation
FROM sets_clean s
INNER JOIN sets_priced p
    ON s.set_num = p.set_num
GROUP BY s.parent_theme_name
HAVING AVG(p.price_appreciation) > (
    SELECT AVG(price_appreciation)
    FROM sets_priced
)
ORDER BY avg_price_appreciation DESC;


-- ============================================================
-- QUERY 8: Best Set Per Theme — Window Function (RANK)
-- ============================================================
-- What it does:
--   Ranks every priced set within its own theme by price
--   appreciation, then returns the top-ranked set per theme.
-- How it works:
--   RANK() OVER (PARTITION BY parent_theme_name ORDER BY
--   price_appreciation DESC) assigns a rank to each set
--   relative to other sets in the same theme, without
--   collapsing rows like GROUP BY would.
--   The outer query filters to rank = 1 (best per theme).
-- Why it matters:
--   Shows that within each theme, one set massively
--   outperforms the rest — individual set selection matters.
-- Output: 1 row per theme showing the best-performing set
-- ============================================================

SELECT *
FROM (
    SELECT
        s.set_num,
        s.name,
        s.parent_theme_name,
        p.price_appreciation,
        RANK() OVER (
            PARTITION BY s.parent_theme_name
            ORDER BY p.price_appreciation DESC
        ) AS rank_within_theme
    FROM sets_clean s
    INNER JOIN sets_priced p
        ON s.set_num = p.set_num
) ranked
WHERE rank_within_theme = 1
ORDER BY price_appreciation DESC;


-- ============================================================
-- QUERY 9: Sets vs. Their Theme Average — Window Function (AVG)
-- ============================================================
-- What it does:
--   Shows how much each set outperforms or underperforms
--   its own theme's average appreciation.
-- How it works:
--   AVG(price_appreciation) OVER (PARTITION BY parent_theme_name)
--   computes the theme average alongside each individual row,
--   without collapsing the data. The outer query filters to
--   only sets that beat their theme average (vs_theme_avg > 0).
-- Why it matters:
--   Identifies standout sets even within poorly performing
--   themes. Individual sets can beat the theme average by
--   a large margin.
-- Output: Sets that outperform their own theme average
-- ============================================================

SELECT *
FROM (
    SELECT
        s.set_num,
        s.name,
        s.parent_theme_name,
        p.price_appreciation,
        AVG(p.price_appreciation) OVER (
            PARTITION BY s.parent_theme_name
        ) AS theme_avg_appreciation,
        p.price_appreciation - AVG(p.price_appreciation) OVER (
            PARTITION BY s.parent_theme_name
        ) AS vs_theme_avg
    FROM sets_clean s
    INNER JOIN sets_priced p
        ON s.set_num = p.set_num
) themed
WHERE vs_theme_avg > 0
ORDER BY vs_theme_avg DESC;


-- ============================================================
-- QUERY 10: Sets That Beat Both Theme Average AND Overall Average
--           (Double Subquery)
-- ============================================================
-- What it does:
--   Finds sets that simultaneously outperform two benchmarks:
--   the overall average across all sets, and their own theme's
--   average.
-- How it works:
--   The first subquery computes the overall average.
--   The second subquery computes each theme's average on the fly
--   for each row in the outer query.
--   Both conditions must be true (AND).
-- Why it matters:
--   These are the strongest investment candidates — sets that
--   are exceptional both globally and within their category.
-- Output: Sets that beat both benchmarks, ranked by appreciation
-- ============================================================

SELECT
    s.set_num,
    s.name,
    s.parent_theme_name,
    p.price_appreciation
FROM sets_clean s
INNER JOIN sets_priced p
    ON s.set_num = p.set_num
WHERE p.price_appreciation > (
    SELECT AVG(price_appreciation)
    FROM sets_priced
)
AND p.price_appreciation > (
    SELECT AVG(p2.price_appreciation)
    FROM sets_clean s2
    INNER JOIN sets_priced p2
        ON s2.set_num = p2.set_num
    WHERE s2.parent_theme_name = s.parent_theme_name
)
ORDER BY p.price_appreciation DESC;
