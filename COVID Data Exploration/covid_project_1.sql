-- SQL PROJECT - EXPLORATION OF WORLWIDE COVID DATA

SELECT * FROM covid_deaths
WHERE continent IS NOT NULL
LIMIT 50;

SELECT * FROM covid_vaccinations
WHERE continent IS NOT NULL
LIMIT 50;

-- We filtered the rows where continent is NULL since these correspond to groups in location, like 'World', or 'North America'
-- and, for now, we want to see only countries.

-- We can see that the data type of the 'date' column in both tables is text. Let's change it to a date type

ALTER TABLE covid_deaths
ALTER COLUMN date TYPE DATE USING date::date;

ALTER TABLE covid_vaccinations
ALTER COLUMN date TYPE DATE USING date::date;

-- PART 1 - COVID DEATHS TABLE

-- Selecting the data that will be used from 'deaths' table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Looking at Total cases vs Total deaths (death rate)
-- What is the aproximate likelihood of dying from covid in a particular country?

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- In Brazil

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM covid_deaths
WHERE location like 'Brazil'
ORDER BY 1, 2;

-- What was the highest death rate in Brazil, and when?

WITH max_death_rate AS (
SELECT MAX((total_deaths/total_cases)*100) as max_death_rate
FROM covid_deaths
WHERE location like 'Brazil' )

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM covid_deaths, max_death_rate
WHERE (total_deaths/total_cases)*100 = max_death_rate
AND location like 'Brazil';

-- Looking at Total cases vs Population (infection rate)
-- What percentage of population got Covid in Brazil?

SELECT location, date, total_cases, population, (total_cases/population)*100 as infection_rate
FROM covid_deaths
WHERE location like 'Brazil'
ORDER BY 1, 2;

-- Which country had the highest infection rate compared to population?

SELECT location, MAX(total_cases) as max_infection_count, population, MAX((total_cases/population)*100) as infection_rate
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_rate DESC NULLS LAST;

-- Which countries had the highest death count per population?

SELECT location, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST;

-- Which countries had the highest death rate per population?

SELECT location, MAX((total_deaths/population)*100) as death_rate
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY death_rate DESC NULLS LAST;

-- ANALYZING BY CONTINENT

-- Total death count by continent

SELECT location, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST;

-- In this last query we used the location column where continet is NULL, instead of using the continent column,
-- because the total deaths numbers aren't correct in the continent column, and they are correct in 
-- in the location column.

-- Let's see the results if we use the 'continent' column in the query

SELECT continent, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC NULLS LAST;

-- Looking at Global Totals by Date

SELECT date, 
	   SUM(new_cases) AS new_cases_global, 
	   SUM(new_deaths) as new_deaths_global
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

-- This query allows to follow the evolution of new Covid cases and new deaths at the global scale by date

SELECT date, 
	   SUM(total_cases) AS total_cases_global, 
	   SUM(total_deaths) AS total_deaths_global,
	   SUM(total_deaths)/SUM(total_cases)*100 AS global_death_rate
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

-- This query allows to follow the evolution of total Covid cases and total deaths at the global scale by date
-- as well as the global death rate. For example, by January 25th 2020, around 2.93% of the infected global population 
-- has died from Covid

-- PART 2 - USING THE COVID VACCINATIONS TABLE

-- Joining the two tables

SELECT *
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;

-- Let's look at Total population vs Vaccinations - How many people was vaccinated worlwide?

SELECT dea.continent, dea.location, dea.date, dea.population, vac.total_vaccinations
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- We can get the same number of total vaccinations, at a particular date, calculating the rolling count of New vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- With this 'total vaccinations', we can calculate the percentage of vaccinated people in a given country

-- A. Using Common Table Expressions (CTE)

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, total_vaccinations)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3
)
SELECT *, (total_vaccinations/population)*100 AS vaccination_rate
FROM pop_vs_vac;

-- NOTE: when looking at these results, we see that, in some countries from a certain date onwards, 
-- the vaccination rate surpasses 100%, or, in other words, the total vaccinations are greater than the total population of a country.
-- Let's consider that the total vaccionations count takes into account the second, third or more doses of a vaccine applied
-- to a same person, otherwise these results wouldn't make sense.

-- B. Using a Temporary (temp) Table

DROP TABLE IF EXISTS population_vaccinated;

CREATE TEMPORARY TABLE population_vaccinated (
continent text,
location text,
date date,
population bigint,
new_vaccinations double precision,
total_vaccinations double precision
);

INSERT INTO population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

SELECT *, (total_vaccinations/population)*100 AS vaccination_rate
FROM population_vaccinated;

-- C. Creating a View (Virtual Table)
-- *it can be used, for example, for doing visualizations

CREATE VIEW population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

SELECT *
FROM population_vaccinated;