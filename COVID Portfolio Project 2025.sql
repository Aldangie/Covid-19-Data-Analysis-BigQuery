SELECT* 
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
ORDER BY location,date;

-- Retrieving the initial dataset for analysis

SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
Where continent is not null
ORDER BY location, date;

-- Exploring total cases versus total deaths in Germany to determine mortality percentage
-- Indicates the probability of death upon contracting Covid in a given country

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths/total_cases)*100 as Dead_Percentage
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE LOWER (location) LIKE '%germany%' and continent IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
ORDER BY location, date;

-- Analyzing Total Cases in relation to Population size
-- Calculates the percentage of the population infected with Covid

SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    (total_cases/population)*100 as Percentage_Population_Infected
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
Where continent is not null and population is not null and total_cases is not NULL
--AND LOWER (location) LIKE '%germany%'
ORDER BY location, date;

-- Identifying countries with the highest infection rates relative to their population

SELECT 
    location, 
    population, 
    MAX(total_cases) as Highest_Infection_Count, 
    MAX((total_cases/population))*100 as Percentage_Population_Infected
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY location, population
ORDER BY Percentage_Population_Infected DESC;

-- Ranking countries by Covid death percentage relative to population size

SELECT 
    location, 
    population, 
    MAX(cast(total_deaths as int)) as Highest_Death_Count, 
    MAX((CAST(total_deaths AS INT) / population) * 100) AS Percentage_Deaths
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY location, population
ORDER BY Percentage_Deaths DESC;


-- Listing countries with the highest total number of Covid-related deaths

SELECT 
    location, 
    MAX(cast(total_deaths as int)) as Total_Death_Count
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Summarizing Covid impact by continent
-- Comparing total deaths across continents

SELECT 
    continent, 
    MAX(cast(total_deaths as int)) as Total_Death_Count
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- Aggregate global numbers (new cases and deaths)

SELECT 
    SUM(new_cases) as total_cases, 
    SUM(new_deaths) as total_deaths, 
    SUM (new_deaths) / SUM (new_cases)*100 as death_percentage
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
--WHERE location like '%germany%'
WHERE continent IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
ORDER BY total_cases, total_deaths;

-- Analyzing Total Population vs Vaccinations (Cumulative Vaccinated Individuals)
-- Displays the Percentage of the Population That Has Received at Least One Dose of the Covid Vaccine

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location 
ORDER BY dea.date
) as Rolling_People_Vaccinated
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data` as dea
JOIN `covid-deaths-portfolio-455713.covid_deaths.covid_vaccinations` as vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location, date;


-- Using a Common Table Expression (CTE) to Track Rolling Vaccinations and Identify the Top 10 Countries by Vaccination Percentage

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) as Rolling_People_Vaccinated
    FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data` as dea
    JOIN `covid-deaths-portfolio-455713.covid_deaths.covid_vaccinations` as vac
         ON dea.location = vac.location
         AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
),

LatestVaccinationData AS (
    SELECT 
        location,
        population,
        Rolling_People_Vaccinated,
        (Rolling_People_Vaccinated / population) * 100 AS Vaccination_Percentage,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY date DESC) AS rn
    FROM PopvsVac
)

SELECT 
    location,
    population,
    Rolling_People_Vaccinated,
    ROUND(Vaccination_Percentage, 2) AS Vaccination_Percentage
FROM LatestVaccinationData
WHERE rn = 1
ORDER BY Vaccination_Percentage DESC
LIMIT 10;

-- Creating a View to Store Data for Future Visualizations (Vaccination Percentage by Population)

CREATE VIEW covid_deaths.Percent_Population_Vaccinated AS
WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS Rolling_People_Vaccinated
    FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data` AS dea
    JOIN `covid-deaths-portfolio-455713.covid_deaths.covid_vaccinations` AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
),
LatestVaccinationData AS (
    SELECT 
        location,
        population,
        Rolling_People_Vaccinated,
        (Rolling_People_Vaccinated / population) * 100 AS Vaccination_Percentage,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY date DESC) AS rn
    FROM PopvsVac
)

SELECT 
    location,
    population,
    Rolling_People_Vaccinated,
    ROUND(Vaccination_Percentage, 2) AS Vaccination_Percentage
FROM LatestVaccinationData
WHERE rn = 1;