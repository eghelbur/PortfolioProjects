SELECT *
FROM [Project 1]..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM [Project 1]..CovidVacinations
--ORDER BY 3,4


SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Project 1]..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


--Looking at Total Cases vs. Total Deaths

SELECT Location, date, 
       CAST(total_cases AS float) as total_cases, 
       CAST(total_deaths AS float) as total_deaths, 
       (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 as mortality_rate
FROM [Project 1]..CovidDeaths
WHERE location like '%Moldova%' AND continent is not null
ORDER BY 1,2

--Looking at the Total Cases vs. Population

SELECT Location, date,
	   CAST(population AS float) as population, 
       CAST(total_cases AS float) as total_cases, 
       (CAST(total_cases AS float) / CAST(population AS float))*100 as_percent_of_population_got_covid
FROM [Project 1]..CovidDeaths
--WHERE location like '%Moldova%'
ORDER BY 1,2

--Looking at the Countries with the Highest infection Rate compared to Population

SELECT Location,
	   CAST(population AS float) as population, 
       CAST(total_cases AS float) as total_cases, 
	   MAX(CAST(total_cases AS float)) OVER (PARTITION BY Location) as HighestInfectionCount,
       (CAST(total_cases AS float) / CAST(population AS float))*100 as_percent_of_population_got_covid
FROM [Project 1]..CovidDeaths
--WHERE location like '%Moldova%'
GROUP BY Location, population, total_cases
ORDER BY as_percent_of_population_got_covid desc

-- Showing Conthies with the highest death count per population

SELECT Location,
       MAX(CAST(total_deaths AS float)) as TotalDeathCount
-- WHERE Location like '%Moldova%'
FROM [Project 1]..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT

SELECT continent,
       MAX(CAST(total_deaths AS float)) as TotalDeathCount
-- WHERE Location like '%Moldova%'
FROM [Project 1]..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--Showing the continent with the highest death count

SELECT continent,
       MAX(CAST(total_deaths AS float)) as TotalDeathCount
-- WHERE Location like '%Moldova%'
FROM [Project 1]..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- GLOBAL NUMBERS

SELECT 
  SUM(new_cases) as total_cases,
  SUM(CAST(new_deaths AS INT)) as total_deaths,
  SUM(CAST(new_deaths AS INT))/NULLIF(SUM(New_Cases), 0)*100 AS DeathPercentage
FROM 
  [Project 1]..CovidDeaths
WHERE 
  --location LIKE '%Moldova%' 
  continent IS NOT NULL 
--GROUP BY 
  --date
HAVING
  SUM(new_cases) > 0 AND SUM(CAST(new_deaths AS INT)) > 0
ORDER BY 
  1,2

-- Looking at total Population vs Vaccinations


SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
FROM 
  [Project 1]..CovidDeaths dea
JOIN
  [Project 1]..CovidVacinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE vac.new_vaccinations is not null
	AND dea.continent is not null
	--AND dea.location like '%Moldova%'
ORDER BY 
  2,3

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
FROM 
  [Project 1]..CovidDeaths dea
JOIN
  [Project 1]..CovidVacinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE vac.new_vaccinations is not null
	AND dea.continent is not null
	--AND dea.location like '%Moldova%'
--ORDER BY 
  --2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
FROM 
  [Project 1]..CovidDeaths dea
JOIN
  [Project 1]..CovidVacinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE vac.new_vaccinations is not null
	AND dea.continent is not null
	--AND dea.location like '%Moldova%'
ORDER BY 
  2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Cereating View for store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
FROM 
  [Project 1]..CovidDeaths dea
JOIN
  [Project 1]..CovidVacinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE vac.new_vaccinations is not null
	AND dea.continent is not null
	--AND dea.location like '%Moldova%'
--ORDER BY 
  --2,3

SELECT *
FROM PercentPopulationVaccinated
