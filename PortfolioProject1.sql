--SELECT *
--FROM PortfolioProject..CovidDeaths
--Where continent is NOT NULL
--order by 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--Order By 3,4

--Select Data that we are going to be using
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
Where continent is NOT NULL
Order By 1,2

--Looking at Total Cases Vs Total Deaths
--Show likelihood of dying if you contract covid in your country
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' and continent is NOT NULL
ORDER BY 1,2

--Looking at Total Cases Vs Population
--Shows what percentage of population got Covid
SELECT location,date,population,total_cases, (total_cases/population)*100 As PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states' and 
WHERE total_cases is NOT NULL
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate Compared to Population
SELECT location,population,MAX(total_cases) AS HightestInfectionCount,
	MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
Group BY location,population
ORDER BY PercentPopulationInfected DESC

--Showing Countries with Highest Death Count per Population
SELECT location,MAX(cast(total_deaths as int)) As TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent is NOT NULL
Group By location
ORDER BY TotalDeathCount desc

--Let's Break Things Down by Continent
Select continent,MAX(total_deaths) As TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
Group by continent
ORDER BY TotalDeathCount desc

--GLOBAL NUMBERS
Select SUM(new_cases) AS Total_NewCases,SUM(new_deaths) AS Total_NewDeaths,
	CASE
		WHEN SUM(new_cases)*100=0
			THEN SUM(new_deaths)
		ELSE
			SUM(new_deaths)/SUM(new_cases)*100
		END DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE new_cases is NOT NULL and new_deaths is NOT NULL
--Group By date
Order By 1,2

ALTER TABLE dbo.CovidVaccinations
ALTER COLUMN new_vaccinations float

--Looking at Total Population Vs Vaccination
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location,
	dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is NOT NULL
order by 2,3

--USE CTE
WITH PopVsVac (continent,location,date,population,new_vaccinations,
				RollingPeopleVaccinated)
as(
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location,
		dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	and dea.date=vac.date
	WHERE dea.continent is NOT NULL
	--order by 2,3
)
SELECT *,(RollingPeopleVaccinated/population)*100
FROM PopVsVac

--Temp Table
DROP TABLE if exists PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date nvarchar(255),
	population nvarchar(255),
	new_vaccinations float,
	RollingPeopleVaccinate float
)
INSERT INTO PercentPopulationVaccinated
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location
	order by dea.location,dea.date)AS RollingPeopleVaccinate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON	dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is NOT NULL

SELECT *,(RollingPeopleVaccinate/population)*100 As Total
FROM PercentPopulationVaccinated

--Creating view to store data for later visualization

Create View PercentPopulationVaccination as
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location,
		dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location
	and dea.date=vac.date
	WHERE dea.continent is NOT NULL
	--order by 2,3

SELECT *
FROM PercentPopulationVaccination