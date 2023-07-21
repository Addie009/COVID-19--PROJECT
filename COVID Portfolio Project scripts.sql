--select all data from the coviddeaths table
SELECT*
FROM CovidDeaths
ORDER BY 3,4

--select all data from the covidvaccinations table
SELECT*
FROM CovidVaccinations
ORDER BY 3,4

--select the data to be used
SELECT location, date, total_cases, total_deaths, new_cases, population
FROM CovidDeaths
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths,( total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
ORDER BY 1,2

--Looking at total cases vs population(shows what percentage of the population got covid
SELECT location, date, total_cases, population, ( total_cases/population)*100 as populationPercentage
FROM CovidDeaths
where location like '%europe%'
ORDER BY 1,2


--looking at countries with the highest infection rate compared to the population
SELECT location, population, max(total_cases) as highestinfectioncount, max(( total_cases/population))*100 as infectionpercentage
FROM CovidDeaths
GROUP BY location, population
ORDER BY infectionpercentage desc

--countries with the highest death count per population
SELECT location, max(total_deaths) as totaldeathcount
FROM CovidDeaths
where continent is not null
GROUP BY location
ORDER BY max(total_deaths) desc

--showing the continents with the highest death count per population
SELECT continent, max(total_deaths) as totaldeathcount
FROM CovidDeaths
where continent is not null
GROUP BY continent
ORDER BY totaldeathcount desc

--find out the global number of covid new cases and new death group by only date
SELECT SUM(new_cases) as newCase,SUM(new_deaths) as NewDeath, SUM(new_cases)/ SUM(new_deaths)*100 as totalpercentage
FROM CovidDeaths
where continent is not null
--GROUP BY date
ORDER BY 1,2

--lets join our two tables together
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths as dea
join CovidVaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using ETC
WITH PopvsVac (continent, date, location, population, new_vaccinations, rollingpeoplevaccinated)
as
(
select dea.continent, dea.date, dea.location, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
from CovidDeaths as dea
join CovidVaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3
)
select*, (rollingpeoplevaccinated/population)*100 as percentagevac
from PopvsVac
 
--find the continent with the highest number of vaccination
select dea.continent, dea.date,dea.location, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as rollingpeoplevaccinated,
MAX(convert(float,vac.new_vaccinations)) OVER(PARTITION BY dea.location) as highestvaccinated 
from CovidDeaths as dea
join CovidVaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null and dea.continent = 'europe'
order by 2,3

--create temp table for future use
--TEMP TABLE
DROP TABLE IF EXISTS  #Percentpopulationvaccinated
CREATE TABLE #Percentpopulationvaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population Numeric,
New_vaccinations Numeric,
RollingPeopleVaccinated numeric
)

insert into #Percentpopulationvaccinated
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
from CovidDeaths as dea
join CovidVaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null
order by 2,3

select*, (rollingpeoplevaccinated/population)*100 as percentagevac
from  #Percentpopulationvaccinated

--Creating views to store data for later visualizations on Tableau

create view Percentpopulationvaccinated as 
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
from CovidDeaths as dea
join CovidVaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

create view continenthighestvaccinated as
select dea.continent, dea.date,dea.location, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as rollingpeoplevaccinated,
MAX(convert(float,vac.new_vaccinations)) OVER(PARTITION BY dea.location) as highestvaccinated 
from CovidDeaths as dea
join CovidVaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

create view newcasesandnewdatepercent as
SELECT SUM(new_cases) as newCase,SUM(new_deaths) as NewDeath, SUM(new_cases)/ SUM(new_deaths)*100 as totalpercentage
FROM CovidDeaths
where continent is not null
GROUP BY date

create view totalcasesanddeath as
SELECT location, date, total_cases, total_deaths,( total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths

create view popoftotalcases as
SELECT location, date, total_cases, population, ( total_cases/population)*100 as populationPercentage
FROM CovidDeaths
where location like '%europe%'


create view highestinfectedperpop as
SELECT location, population, max(total_cases) as highestinfectioncount, max(( total_cases/population))*100 as infectionpercentage
FROM CovidDeaths
GROUP BY location, population

create view highestdeathperpop as
SELECT location, max(total_deaths) as totaldeathcount
FROM CovidDeaths
where continent is not null
GROUP BY location

create view deathpoppercontinents as
SELECT continent, max(total_deaths) as totaldeathcount
FROM CovidDeaths
where continent is not null
GROUP BY continent










