-- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidAnalysis..Covid_deaths
--Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- likelihood of dying if contracted covid in your country
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidAnalysis..Covid_deaths
Where location like '%india%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidAnalysis..Covid_deaths
--Where location like '%india%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidAnalysis..Covid_deaths
--Where location like '%india%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Continents with Highest Death Count per Population
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidAnalysis..Covid_deaths
Where continent is null 
Group by location
order by TotalDeathCount desc


-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidAnalysis..Covid_deaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- global numbers
select  sum(new_cases) as totalCases, sum(new_deaths) as totalDeaths,
sum(new_deaths)/sum(new_cases)*100 as DeathPrcent --, date
from CovidAnalysis..Covid_deaths
where continent is not null and new_cases != 0
--group by date
order by 1,2


-- total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, 
dea.date) as rollingPeopleVaccinated
from CovidAnalysis..Covid_deaths dea
join CovidAnalysis..Covid_vaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3


--CTE
with PopvsVac (continent, date, location, population, new_vaccinations,
rollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, 
dea.date) as rollingPeopleVaccinated
from CovidAnalysis..Covid_deaths dea
join CovidAnalysis..Covid_vaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
)
select *, (rollingPeopleVaccinated/population)*100
from PopvsVac


--temp table
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, 
dea.date) as rollingPeopleVaccinated
from CovidAnalysis..Covid_deaths dea
join CovidAnalysis..Covid_vaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null

select *, (rollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


--views to store data
create view 
PopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, 
dea.date) as rollingPeopleVaccinated
from CovidAnalysis..Covid_deaths dea
join CovidAnalysis..Covid_vaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null

select *
from PopulationVaccinated


--percentage of people vaccinated in India
select vac.location, vac.date, vac.people_vaccinated, dea.population, (vac.people_vaccinated/dea.population)*100 as percentVaccinated
from CovidAnalysis..Covid_vaccinations vac
join CovidAnalysis..Covid_deaths dea
on vac.location = dea.location and vac.date = dea.date
where vac.location like '%india%' and vac.people_vaccinated is not null
order by 1,2


--percentage of people fully vaccinated in India
select vac.location, vac.date, vac.people_fully_vaccinated, dea.population, (vac.people_fully_vaccinated/dea.population)*100 as percentVaccinated
from CovidAnalysis..Covid_vaccinations vac
join CovidAnalysis..Covid_deaths dea
on vac.location = dea.location and vac.date = dea.date
where vac.location like '%india%' and vac.people_fully_vaccinated is not null
order by 1,2


-- 7-day rolling average for new cases and new deaths:
select location, date,
       avg(new_cases) OVER(PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_new_cases,
       avg(new_deaths) OVER(PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_new_deaths
from CovidAnalysis..Covid_deaths

