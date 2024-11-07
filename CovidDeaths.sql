SELECT * 
FROM PortifolioDB..covid_deaths
WHERE continent IS NOT NULL
ORDER BY location,date

--SELECT * FROM PortifolioDB..covid_vaccinations
--ORDER BY 3,4

-- SELECTING DATA
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortifolioDB..covid_deaths
ORDER BY location, date

--1 Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths,
CASE
	WHEN
	total_cases = 0 THEN 0
	ELSE (total_deaths/total_cases) * 100
END AS DeathPercent
FROM PortifolioDB..covid_deaths
ORDER BY location, date

--Showing Details for chances of dying in Tanzania if you contract Covid
SELECT location, date, total_cases, total_deaths,
CASE
	WHEN
	total_cases = 0 THEN 0
	ELSE (total_deaths/total_cases) * 100
END AS DeathPercentage
FROM PortifolioDB..covid_deaths
WHERE location = 'Tanzania'
ORDER BY location, date

--Showing Details for chances of dying in US if you contract Covid
SELECT location, date,population, total_cases, total_deaths,
CASE
	WHEN
	total_cases = 0 THEN 0
	ELSE (total_deaths/population) * 100
END AS DeathPercentage
FROM PortifolioDB..covid_deaths
WHERE location like  '%states'
ORDER BY location, date


--2 TOTAL CASES VS POPULATION
SELECT location, date, population, total_cases,
CASE
	WHEN
	population = 0 THEN 0
	ELSE (total_cases/population) * 100
END AS Percent_population_infected
FROM PortifolioDB..covid_deaths
WHERE location like  '%states%' AND date > '2022-12-31'  AND date < '2023-06-01'
ORDER BY location, date

--Countries with highest infection rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectedCountry, 
CASE
	WHEN
	population = 0 THEN 0
	ELSE MAX((total_cases/population)) * 100
END AS percent_population_infected
FROM PortifolioDB..covid_deaths
GROUP BY location, population
ORDER BY percent_population_infected DESC

--COUNTRIES WITH HGHEST DEATH COUNT PER POPULATION
SELECT Location, MAX(cast(total_deaths as int)) AS total_death_count
FROM PortifolioDB..covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY total_death_count DESC

--BREAK DOWN BY CONTINENT
SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count
FROM PortifolioDB..covid_deaths
WHERE continent IS NULL
GROUP BY continent
ORDER BY total_death_count DESC


--GLOBAL NUMBERS
SELECT date, 
       SUM(COALESCE(new_cases, 0)) AS TotalCases,
       SUM(COALESCE(CAST(new_deaths AS INT), 0)) AS TotalDeaths,
       CASE 
           WHEN SUM(COALESCE(new_cases, 0)) = 0 THEN 0
           ELSE (SUM(COALESCE(CAST(new_deaths AS INT), 0)) / SUM(COALESCE(new_cases, 0))) * 100
       END AS death_percentage
FROM PortifolioDB..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


--Total population
--USE CT
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, vaccinated_people)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.Date) AS vaccinated_people
FROM PortifolioDB..covid_deaths dea
JOIN PortifolioDB..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT * , (vaccinated_people/Population) * 100
FROM PopvsVac



--TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
vaccinated_people NUMERIC
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.Date) AS vaccinated_people
FROM PortifolioDB..covid_deaths dea
JOIN PortifolioDB..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT * , (vaccinated_people/Population) * 100
FROM #PercentPopulationVaccinated


--CREATING VIEW FOR VISUALIZATIONS
DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.Date) AS vaccinated_people
FROM PortifolioDB..covid_deaths dea
JOIN PortifolioDB..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated