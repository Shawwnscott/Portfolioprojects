select * 
from portfolioproject..coviddeaths 
where continent is not null
order by 3, 4

--select * 
--from portfolioproject..covidvaccinations 
--order by 3, 4

-- Select Data To BE Used

select location, date, total_cases, new_cases, total_deaths, population
from portfolioproject..coviddeaths 
where continent is not null
order by 1,2

-- Total Cases vs Total Deaths
-- Illustrates the probability of death if contract covid

select location, date, total_cases, total_deaths,(total_deaths/ total_cases)*100 as DeathPercentage
from portfolioproject..coviddeaths 
where location like '%states%'
order by 1,2

-- Total Case Per Population
-- What percentage of pupulation contracted covid 

select location, date, total_cases, population ,(total_cases/ population)*100 as PercentPopulationInfected
from portfolioproject..coviddeaths 
-- where location like '%states%'
order by 1,2


-- Countries with highest intection rate to population

select location,population, max(total_deaths) as HighestInfectionCount,max((total_cases/ population))*100 as PercentPopulationInfected
from portfolioproject..coviddeaths 
-- where location like '%states%'
group by location, population
order by PercentPopulationInfected desc


--  Highest Death count by country
select location,max(cast(total_deaths as int)) as TotalDeathCount
from portfolioproject..coviddeaths 
-- where location like '%states%'
where continent is not null
group by location
order by TotalDeathCount desc


--  Highest Death count by Continent
select continent,max(cast(total_deaths as int)) as TotalDeathCount
from portfolioproject..coviddeaths 
-- where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc



-- Daily Change in New_Cases , New_Deaths & Death Percentage worldwide

select date, SUM(new_cases) as TotalCasesWorldwide, sum(cast(new_deaths as int)) as NewDeathsWorldwide , sum(cast(new_deaths as int))/SUM(new_cases)*100  as DeathPercentage
from portfolioproject..coviddeaths 
-- where location like '%states%'
where continent is not null
group by date
order by 1,2

--Total Cases , Deaths & Death Percentage Worldwide
select SUM(new_cases) as TotalCasesWorldwide, sum(cast(new_deaths as int)) as NewDeathsWorldwide , sum(cast(new_deaths as int))/SUM(new_cases)*100  as DeathPercentage
from portfolioproject..coviddeaths 
-- where location like '%states%'
where continent is not null
order by 1,2

-- Look Vaccinations accross population
select 
dea.continent, 
dea.location,
dea.date, 
dea.population, 
vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE
with popvsvac (continent,location, date, population, New_vaccination, RollingPeopleVaccinated) as
(select
dea.continent, 
dea.location,
dea.date, 
dea.population, 
vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3
) 
select *, (RollingPeopleVaccinated/population)*100
from popvsvac



--Temp Table
Drop Table if Exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
select
dea.continent, 
dea.location,
dea.date, 
dea.population, 
vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3
select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


-- Creating View

Create View PercentPopulationVaccinated as 
select 
dea.continent, 
dea.location,
dea.date, 
dea.population, 
vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from portfolioproject..CovidDeaths dea
join portfolioproject..CovidVaccinations vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3


Select * 
from PercentPopulationVaccinated
