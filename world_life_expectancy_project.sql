-- 1.1 Duplicate Country-Year Check

SELECT Country, Year, CONCAT(Country, Year), COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;

-- 1.2 Identify Duplicate Row_IDs

SELECT * FROM (
    SELECT Row_ID, CONCAT(Country, Year) AS country_year,
           ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num
    FROM world_life_expectancy
) AS Row_Table
WHERE Row_Num > 1;

-- 1.3 Remove Duplicate Rows

DELETE FROM world_life_expectancy
WHERE Row_ID IN (
    SELECT Row_ID FROM (
        SELECT Row_ID, CONCAT(Country, Year),
               ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num
        FROM world_life_expectancy
    ) AS Row_Table
    WHERE Row_Num > 1
);

-- 1.4 Detect Missing Status

SELECT * FROM world_life_expectancy WHERE Status = "";

-- 1.5 Check Valid Status Values

SELECT DISTINCT(Status) FROM world_life_expectancy WHERE Status <> "";

-- 1.6 Countries with 'Developing' Status

SELECT DISTINCT(Country) FROM world_life_expectancy WHERE Status = 'Developing';

-- 1.7 Update Missing Status to 'Developing'

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2 ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = '' AND t2.Status = 'Developing';

-- 1.8 Update Remaining Status to 'Developed'

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2 ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = '' AND t2.Status = 'Developed';

-- 1.9 Check Missing Life Expectancy

SELECT * FROM world_life_expectancy WHERE Life_Expectancy = '';

-- 1.10 Estimate Missing Life Expectancy (interpolation)

SELECT t1.Country, t1.Year, t1.Life_Expectancy,
       t2.Life_Expectancy AS prev_year,
       t3.Life_Expectancy AS next_year,
       ROUND((t2.Life_Expectancy + t3.Life_Expectancy) / 2, 1) AS estimated_life_expectancy
FROM world_life_expectancy t1
JOIN world_life_expectancy t2 ON t1.Country = t2.Country AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3 ON t1.Country = t3.Country AND t1.Year = t3.Year + 1
WHERE t1.Life_Expectancy = '';

-- 1.11 Update Estimated Life Expectancy

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2 ON t1.Country = t2.Country AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3 ON t1.Country = t3.Country AND t1.Year = t3.Year + 1
SET t1.Life_Expectancy = ROUND((t2.Life_Expectancy + t3.Life_Expectancy) / 2, 1)
WHERE t1.Life_Expectancy = '';

-- 2.1 Life Expectancy Growth per Country

SELECT Country, MIN(Life_Expectancy), MAX(Life_Expectancy),
       ROUND(MAX(Life_Expectancy) - MIN(Life_Expectancy), 1) AS Life_Increase_15_Years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(Life_Expectancy) <> 0 AND MAX(Life_Expectancy) <> 0
ORDER BY Life_Increase_15_Years DESC;

-- 2.2 Global Avg Life Expectancy Over Time

SELECT Year, ROUND(AVG(Life_Expectancy), 2)
FROM world_life_expectancy
WHERE Life_Expectancy <> 0
GROUP BY Year
ORDER BY Year;

-- 2.3 Countries with Lowest GDP

SELECT Country, ROUND(AVG(Life_Expectancy), 2) AS Life_Exp, ROUND(AVG(GDP), 2) AS GDP
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0 AND GDP > 0
ORDER BY GDP ASC;

-- 2.4 Countries with Highest GDP

SELECT Country, ROUND(AVG(Life_Expectancy), 2) AS Life_Exp, ROUND(AVG(GDP), 2) AS GDP
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0 AND GDP > 0
ORDER BY GDP DESC;

-- 2.5 GDP Threshold Comparison

SELECT 
  SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
  ROUND(AVG(CASE WHEN GDP >= 1500 THEN Life_Expectancy ELSE NULL END), 2) AS High_GDP_Life_Expectancy,
  SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
  ROUND(AVG(CASE WHEN GDP <= 1500 THEN Life_Expectancy ELSE NULL END), 2) AS Low_GDP_Life_Expectancy
FROM world_life_expectancy;

-- 2.6 Life Expectancy by Status

SELECT Status, COUNT(DISTINCT Country) AS Nr_Countries,
       ROUND(AVG(Life_Expectancy), 1) AS AVG_Life_Expectancy
FROM world_life_expectancy
WHERE Life_Expectancy > 0
GROUP BY Status;