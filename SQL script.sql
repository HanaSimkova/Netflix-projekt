-- vytvoření pomocné tabulky rating
CREATE TABLE rating (
	shortcut VARCHAR (255),
	rating VARCHAR (255),
	PRIMARY KEY(shortcut)
);

INSERT INTO rating (shortcut, rating) VALUES 
('G', 'Kids (All)'),
('NC-17', 'Adults only (17+)'),
('NR', 'Adults (17+) NotRated'),
('PG', 'Older kids (7+) Parental Guidance Suggested'),
('PG-13', 'Teens (13+)'),
('R', 'Adults only (17+)'),
('TV-14', 'Young adults (14+)'),
('TV-G ', 'Kids (All)'),
('TV-MA', 'Adults only (17+)'),
('TV-PG', 'Older Kids (7+) Parental Guidance Suggested'),
('TV-Y ', 'Kids (All)'),
('TV-Y7', 'Older Kids (7+)'),
('TV-Y7-FV', 'Older Kids (7+) programming with fantasy violence'),
('UR', 'Unrated');

-- zjištění, jaké údaje obsahuje tabulka netflix ve sloupci rating
SELECT rating 
FROM netflix n
GROUP BY rating;

-- nahrazení chybných dat
UPDATE netflix
SET rating = 'UR'
WHERE rating = '66 min'
	OR rating = '74 min'
	OR rating = '84 min'
	OR rating = ' ';

-- ověření, že každá hodnota v tabulce netflix bude mít přiřazenou hodnotu z tabulky rating
SELECT DISTINCT rating 
FROM netflix n 
WHERE rating NOT IN (
	SELECT shortcut 
	FROM rating
);

-- přiřazení foreign key sloupci ‚rating‘ v tabulce netflix
ALTER TABLE netflix 
ADD FOREIGN KEY (rating) REFERENCES rating (shortcut);

-- spojení tabulek rating a netflix, vytvoření pohledu
CREATE VIEW v_netflix AS
	SELECT 
	n.show_id,
	n.type,
	n.title,
	n.director,
	n.cast,
	n.country,
	n.date_added,
	n.release_year,
	r.rating,
	n.duration,
	n.listed_in,
	n.description
	FROM netflix n
	LEFT JOIN rating r 
		ON n.rating = r.shortcut;

-- 1. Která země má největší zastoupení ve vydaných pořadech na Netflixu?
SELECT 
	country, 
	COUNT (*) AS count 	
FROM v_netflix vn
GROUP BY country 
ORDER BY count DESC;

-- 2. Jaké typy pořadů se objevují na Netflixu a který typ pořadů se na Netflixu vydává nejčastěji? (procentuální zastoupení)
SELECT `type` 
FROM v_netflix vn
GROUP BY `type`;

-- procenta
WITH TotalCounts AS (
    SELECT COUNT (*) AS total_count
    FROM v_netflix
),
TypeCounts AS (
    SELECT 
    	type,
    	COUNT(*) AS type_count
    FROM v_netflix
    GROUP BY type
)
SELECT 
    type,
    type_count,
    total_count,
    ROUND((type_count / total_count) * 100, 2) AS percentage
FROM TypeCounts
JOIN TotalCounts
ON TRUE;

-- 3. Do jakého časového období je dataset zasazen (datum přidání pořadu)?
SELECT 
    MIN(YEAR(STR_TO_DATE(`date_added`, '%M %d, %Y'))) AS first_year,
    MAX(YEAR(STR_TO_DATE(`date_added`, '%M %d, %Y'))) AS last_year
FROM v_netflix vn
WHERE `date_added` IS NOT NULL 
    AND `date_added` <> '';

-- 4. Který žánr se vydává na Netflixu nejčastěji?
SELECT 
	listed_in, 
	COUNT (*) AS count   
FROM v_netflix vn
GROUP BY listed_in
ORDER BY count DESC;

-- 5. Top 10 režisérů s nejvíce pořady na Netflixu?
SELECT 
	director, 
	COUNT (*) AS count
FROM v_netflix vn
WHERE director <> ''
GROUP BY director 
ORDER BY count DESC
LIMIT 10;

-- 6. Jaký byl počet vydaných pořadů v roce 2020 a v roce předchozím a jaký byl mezi těmito lety procentuální pokles nebo nárůst?
WITH YearlyShowCounts AS (
	SELECT 
        release_year,
        COUNT(*) AS show_count
    FROM v_netflix
    GROUP BY release_year
)
SELECT
	shows_2019,
	shows_2020,
	(shows_2020 - shows_2019) AS difference,
    ROUND(((shows_2020 - shows_2019) / GREATEST(shows_2019, 1)) * 100, 2) AS percentage_change
FROM (
	SELECT
    	SUM(CASE WHEN release_year = 2019 THEN show_count ELSE 0 END) AS shows_2019,
    	SUM(CASE WHEN release_year = 2020 THEN show_count ELSE 0 END) AS shows_2020
	FROM YearlyShowCounts
) AS show_data;

-- 7. Jaký je počet všech pořadů pro každou kategorii přístupnosti (rating)?
SELECT 
	rating,
	COUNT (*) AS count
FROM v_netflix vn 
GROUP BY rating 
ORDER BY count DESC;

-- 8. Jací herci se objevili ve více než 10 pořadech?
SELECT 
	TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor, 
	COUNT(*) AS count
FROM v_netflix vn 
WHERE cast IS NOT NULL
	AND TRIM(cast) <> ''
GROUP BY actor
HAVING count > 10
ORDER BY count DESC;

-- 9. Ve kterém měsíci bylo přidáno nejvíce pořadů?
WITH MonthlyCounts AS (
    SELECT 
        MONTH(STR_TO_DATE(`date_added`, '%M %d, %Y')) AS release_month,
        COUNT(*) AS release_count  
    FROM v_netflix
    WHERE `date_added` IS NOT NULL
        AND `date_added` <> ''
    GROUP BY release_month  
)
SELECT 
    release_month,  
    release_count  
FROM MonthlyCounts
ORDER BY release_count DESC;

-- 10. Z jakých zemí jsou nejčastěji přidávané pořady?
SELECT 
	country,
	COUNT (*) AS count   
FROM v_netflix vn
WHERE country <> ' '
GROUP BY country 
ORDER BY count DESC;
