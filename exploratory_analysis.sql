/* rename tables */
alter table table0
    rename to covid_deaths;
alter table table1
    rename to covid_vaccinations;

/*
Covid 19 Data Exploration
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- test data
select *
from covid_deaths
where continent is not null
order by 3, 4 desc;

-- Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths
where continent is not null
order by 1, 2;

-- Total Cases vs Total Deaths

select location,date,population,total_cases, round(((total_deaths/total_cases)*100)::numeric,3) as death_percentage
from covid_deaths
where continent is not null
and lower(location) like '%states%'
order by 1,2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select location,date,population,total_cases, round(((total_cases/covid_deaths.population)*100)::numeric,3) as Percent_population_infected
from covid_deaths
where continent is not null
and lower(location) like '%states%'
order by 1,2;

-- Countries with Highest Infection Rate compared to Population

select location,population,max(total_cases),round(max(((total_cases/covid_deaths.population)*100)::numeric),3) as Percent_population_infected
from covid_deaths
where continent is not null
group by location, population
order by Percent_population_infected desc;

-- Countries with Highest Death rate compared to Population

select location,population,max(total_deaths) as max_deaths,round(max(((covid_deaths.total_deaths/covid_deaths.population)*100)::numeric),3) as Death_percentage
from covid_deaths
where continent is not null
group by location, population
order by Death_percentage desc;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

select continent, max(total_deaths) as Total_deaths_count
from covid_deaths
where continent is not null
group by continent
order by Total_deaths_count desc;

-- GLOBAL NUMBERS per country

select location,sum(new_cases) as total_cases, sum(new_deaths) as total_deaths,(sum(new_deaths)/sum(new_cases))*100 as death_percentage
from covid_deaths
where continent is not null
group by location
having  sum(new_cases) is not null;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select cd.iso_code,cd.continent,cd.location,cd.date,cd.population,cv.total_vaccinations,cv.people_vaccinated,
cv.new_vaccinations,(sum(cv.new_vaccinations) over (partition by cd.location order by cd.location,cd.date)) as rolling_peopole_vaccinated,
(rolling_peopole_vaccinated/cd.population)*100 as vaccination_percentage
from covid_deaths  cd
join covid_vaccinations cv
on cd.location=cv.location
and cd.date=cv.date
where cv.total_vaccinations is not null
order by cd.iso_code,cd.continent,cd.date;

-- Using CTE to simplify vaccination_percentage Calculation

with POPvsVAC (continent, location, date, population,new_vaccinations, rolling_peopole_vaccinated)
         as
         (
         select cd.continent,
                 cd.location,
                 cd.date,
                 cd.population,
                 cv.new_vaccinations,
                 (sum(cv.new_vaccinations)
                  over (partition by cd.location order by cd.location,cd.date)) as rolling_peopole_vaccinated
          from covid_deaths cd
                   join covid_vaccinations cv
                        on cd.location = cv.location
                            and cd.date = cv.date
          where cv.total_vaccinations is not null
          order by cd.iso_code, cd.continent, cd.date
          )
select *,round(((rolling_peopole_vaccinated/population)*100)::numeric,3) as vaccination_percentage from POPvsVAC;

-- create a temps table

DROP TABLE IF EXISTS  PercentPopulationVaccinated;

CREATE table PercentPopulationVaccinated (
    continent varchar(255),
location varchar(255),
date date,
population numeric,
new_vaccination numeric,
rolling_people_vaccinated numeric
);

insert into percentpopulationvaccinated
select cd.continent,
                 cd.location,
                 cd.date,
                 cd.population,
                 cv.new_vaccinations,
                 (sum(cv.new_vaccinations)
                  over (partition by cd.location order by cd.location,cd.date)) as rolling_peopole_vaccinated
          from covid_deaths cd
                   join covid_vaccinations cv
                        on cd.location = cv.location
                            and cd.date = cv.date
          where cv.total_vaccinations is not null
          order by cd.iso_code, cd.continent, cd.date;

select * , (rolling_people_vaccinated/population)*100
from percentpopulationvaccinated;

--
create view PercentPopulationVaccinated
as select cd.continent,
                 cd.location,
                 cd.date,
                 cd.population,
                 cv.new_vaccinations,
                 (sum(cv.new_vaccinations)
                  over (partition by cd.location order by cd.location,cd.date)) as rolling_peopole_vaccinated
          from covid_deaths cd
                   join covid_vaccinations cv
                        on cd.location = cv.location
                            and cd.date = cv.date
          where cv.total_vaccinations is not null
          order by cd.iso_code, cd.continent, cd.date;