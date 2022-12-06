create table coviddeaths (
	iso_code text,
	continent text,
	location text,
	date text,
	population bigint,
	total_cases int,
	new_cases int,
	new_cases_smoothed float,
	total_deaths int,
	new_deaths int,
	new_deaths_smoothed float,
	total_cases_per_million	float,
	new_cases_per_million float,
	new_cases_smoothed_per_million float,
	total_deaths_per_million float,
	new_deaths_per_million float,
	new_deaths_smoothed_per_million	float,
	reproduction_rate float,
	icu_patients int,
	icu_patients_per_million float,
	hosp_patients int,
	hosp_patients_per_million float,
	weekly_icu_admissions float,
	weekly_icu_admissions_per_million float,
	weekly_hosp_admissions float,
	weekly_hosp_admissions_per_million float);

	
create table covidvaccination (iso_code text,
			  continent text,
			  location text,
			  date text,
			  new_tests int,
			  total_tests int,
			  total_tests_per_thousand float,
			  new_tests_per_thousand float,
			  new_tests_smoothed int,
			  new_tests_smoothed_per_thousand float,
			  positive_rate	float,
			  tests_per_case float,
			  tests_units text,
			  total_vaccinations int,
			  people_vaccinated int,
			  people_fully_vaccinated int,
			  new_vaccinations int,
			  new_vaccinations_smoothed	int,
			  total_vaccinations_per_hundred float,
			  people_vaccinated_per_hundred float,
			  people_fully_vaccinated_per_hundred float,
			  new_vaccinations_smoothed_per_million float,
			  stringency_index float,
			  population_density float,
			  median_age float,
			  aged_65_older float,
			  aged_70_older float,
			  gdp_per_capita float,
			  extreme_poverty float,
			  cardiovasc_death_rate float,
			  diabetes_prevalence float,
			  female_smokers float,
			  male_smokers float,
			  handwashing_facilities float,
			  hospital_beds_per_thousand float,
			  life_expectancy float,
			  human_development_index float);

select * from coviddeaths
where continent is not null;
select * from covidvaccination;


-- selecting data
select location, date, total_cases, new_cases, total_cases, population
from coviddeaths;

-- looking at total cases vs total deaths
-- shows likelyhood of dying if u concract covid in ur country
alter table coviddeaths
alter column total_deaths type float;

select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
from coviddeaths
where location like '%India%';

-- looking at total_cases vs population
-- shows what percentage of population has gt covid
select location, date, total_cases, population,  
(total_cases/population)*100 as percentagecases
from coviddeaths;

--looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as highestinfectioncount,  
max(coalesce((total_cases/population)*100,0)) as percentpopulationinfected
from coviddeaths
group by location, population
order by percentpopulationinfected desc;

--showing countries with highest Death count per population

select location, max(coalesce(total_deaths, 0)) as TotalDeathcount
from coviddeaths
where continent is not null
group by location
order by TotalDeathcount desc;

-- Lets break things down by continent

select location, max(coalesce(total_deaths, 0)) as TotalDeathcount
from coviddeaths
where continent is null
group by location
order by TotalDeathcount desc;




-- showing the continents with the highest deathcounts

select continent, max(coalesce(total_deaths, 0)) as TotalDeathcount
from coviddeaths
where continent is not null
group by continent
order by TotalDeathcount desc;

alter table coviddeaths
alter column date type date using date::date;

-- global numbers
select date,sum(new_cases) as total_cases, sum(new_deaths) as total_deaths,--, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
sum(cast(new_deaths as float))/sum(new_cases)*100 as DeathPercentage
from coviddeaths
-- where location like '%India%';
where continent is not null
group by date
order by date;

select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths,
sum(cast(new_cases as float))/sum(new_deaths)*100 as deathpercentage
from coviddeaths
where continent is not null;

--

select cd.continent, cd.location, cd.date, population, cv.new_vaccinations,
sum(new_vaccinations) over(partition by cd.location order by cd.location, cd.date ) as cum_sum_vaccination
from coviddeaths cd
join covidvaccination cv on cd.location = cv.location and cd.date = cv.date 
where cd.continent is not null
order by 2,3;

alter table covidvaccination
alter column date type date using date::date;

-- Use CTE

with popvsvac as(
select cd.continent, cd.location, cd.date, population, cv.new_vaccinations,
sum(new_vaccinations) over(partition by cd.location order by cd.location, cd.date ) as cum_sum_vaccination
from coviddeaths cd
join covidvaccination cv on cd.location = cv.location and cd.date = cv.date 
where cd.continent is not null
order by 2,3)
select *, cast(cum_sum_vaccination as float)/population*100
from popvsvac;

-- temp table


drop table if exists percentPopulationVaccinated
create table percentPopulationVaccinated
(continent text,
location text,
 Date date,
 population int,
 new_vaccinations int,
 cum_sum_vaccination bigint
);

insert into percentPopulationVaccinated
select cd.continent, cd.location, cd.date, population, cv.new_vaccinations,
sum(new_vaccinations) over(partition by cd.location order by cd.location, cd.date ) as cum_sum_vaccination
from coviddeaths cd
join covidvaccination cv on cd.location = cv.location and cd.date = cv.date 
where cd.continent is not null
order by 2,3;

select , cast(cum_sum_vaccination as float)/population*100 as percentvaccinated_perday
from percentPopulationVaccinated;

-- creating view to store data for visualizations

create view percentPopulationVaccinatedview as
select cd.continent, cd.location, cd.date, population, cv.new_vaccinations,
sum(new_vaccinations) over(partition by cd.location order by cd.location, cd.date ) as cum_sum_vaccination
from coviddeaths cd
join covidvaccination cv on cd.location = cv.location and cd.date = cv.date 
where cd.continent is not null
order by 2,3;

select * from percentPopulationVaccinatedview;