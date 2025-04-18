# Covid-19 Data Exploration (2020–2021)

This project is a deep dive into global Covid-19 data from 2020 to 2021. I analyzed key indicators such as total cases, deaths, vaccination rates, and population data to understand the impact of the pandemic across different countries and continents. Through structured SQL queries, I uncovered meaningful patterns and trends to tell the story behind the numbers.

---

## Skills and Tools Used

- **SQL (BigQuery)**: Extracted, cleaned, transformed, and aggregated data for in-depth analysis.
- **Google BigQuery**: Worked with large-scale datasets to perform efficient and complex data operations.
- **Data Analysis**: Analyzed how the pandemic unfolded across countries by comparing infection and death rates.
- **Data Preparation for Visualization**: Prepared datasets for visualization tools like Tableau or Google Data Studio.
- **GitHub**: Shared queries and tracked progress using GitHub to manage versions, collaborate, and document key insights.

---

## Key Findings from My Analysis

### 1. Total Cases vs Total Deaths in Germany

```sql
SELECT
   location,
   date,
   total_cases,
   total_deaths,
   (total_deaths/total_cases)*100 as Dead_Percentage
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE LOWER (location) LIKE '%germany%' and continent IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
ORDER BY location, date;
```

- **March 9, 2020**: 1,176 cases and 2 deaths (0.17% death rate)  
- **April 30, 2021**: 3,405,365 cases and 83,097 deaths (2.44% death rate)

This progression shows how quickly the situation evolved. Initially, the death rate was relatively low, but as infections surged and more severe cases emerged, the strain on the healthcare system grew significantly. The increase in mortality rate highlights how crucial early intervention and health system preparedness are during a pandemic.

---

### 2. Total Cases vs Population

This analysis helped me understand the **relative impact** of Covid-19 by comparing the number of confirmed cases to each country’s population size:

```sql
SELECT
   location,
   date,
   population,
   total_cases,
   (total_cases/population)*100 as Percentage_Population_Infected
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
Where continent is not null and population is not null and total_cases is not NULL
ORDER BY location, date;
```

- **United States**: 9.77% of the population infected
- **Germany**: 4.06% infected
- **China**: 0.0071% infected

While the absolute number of cases was high in countries like the U.S., the infection rate per capita shows how deeply the virus spread. In contrast, China maintained a remarkably low case-per-population ratio, suggesting strong containment strategies or underreporting.

---

### 3. Countries with the Highest Infection Rate

As of April 2021, smaller countries topped the list in terms of population infection rates.

```sql
SELECT
   location,
   population,
   MAX(total_cases) as Highest_Infection_Count,
   MAX((total_cases/population))*100 as Percentage_Population_Infected
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY location, population
ORDER BY Percentage_Population_Infected DESC;
```

- **San Marino**: 14.93%
- **Slovenia**: 11.56%
- **Luxembourg**: 10.74%

This finding shows that smaller populations with dense urban centers or limited healthcare capacity may be more vulnerable to rapid viral spread, especially in early waves.

---

### 4. Countries with the Highest Covid Death Rate Relative to Population

When comparing **deaths per capita**, I found that:
- **Bosnia and Herzegovina**, **Montenegro**, and **Bulgaria** had the highest death rates

```sql
SELECT
   location,
   population,
   MAX(cast(total_deaths as int)) as Highest_Death_Count,
   MAX((CAST(total_deaths AS INT) / population) * 100) AS Percentage_Deaths
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY location, population
ORDER BY Percentage_Deaths DESC;
```

These numbers may reflect several overlapping factors: healthcare capacity, population age, economic resilience, and timing/strictness of containment measures.

---

### 5. Countries with the Highest Total Number of Covid-Related Deaths

In terms of raw numbers

```sql
SELECT
   location,
   MAX(cast(total_deaths as int)) as Total_Death_Count
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;
```

- **United Kingdom**: 127,775 deaths
- **Italy**: 120,807 deaths
- **Russia**: 108,290 deaths

These figures highlight how developed nations with aging populations and early outbreaks were especially hard-hit in the first two waves.

---

### 6. Continental Overview: Total Deaths by Region

This breakdown gave me a global perspective on how different continents were affected

```sql
SELECT
   continent,
   MAX(cast(total_deaths as int)) as Total_Death_Count
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
WHERE continent is not NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC;
```

- **North America**: 576,232 deaths
- **South America**: 403,781 deaths
- **Asia**: 211,853 deaths

Despite having the largest population, Asia reported fewer deaths than the Americas. This could suggest differences in response strategies, testing/reporting practices, or demographic factors.

---

### 7. Global Totals and Death Percentage

I calculated the total number of reported Covid-19 cases and deaths worldwide between 2020 and 2021. This helped provide a high-level overview of the global impact of the pandemic.

```sql
SELECT 
    SUM(new_cases) as total_cases, 
    SUM(new_deaths) as total_deaths, 
    SUM (new_deaths) / SUM (new_cases)*100 as death_percentage
FROM `covid-deaths-portfolio-455713.covid_deaths.deaths_data`
--WHERE location like '%germany%'
WHERE continent IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
ORDER BY total_cases, total_deaths;
```

- **Total cases**: 150,543,658
- **Total deaths**: 3,180,205
- **Global death rate**: 2.11%

This shows that, globally, around 2 out of every 100 reported Covid-19 cases resulted in death during that period.

---

### 8. Vaccination Rates

As of April 2021, some countries had made significant progress in vaccinating their populations

```sql
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
```

- **Gibraltar**: 182.12%
- **Israel**: 121.28%
- **United Arab Emirates**: 95.8%

Some countries exceeded 100% due to the inclusion of second doses, boosters, and vaccination of non-residents. This highlights how smaller or well-organized nations were often quicker and more efficient in their vaccine rollout.

---

## Queries

This project includes multiple SQL queries developed and tested in BigQuery. Some key queries addressed:
- **Death Percentages Over Time**: Monitoring how fatality rates changed as case numbers increased.
- **Infection and Death Rate Rankings**: Identifying the most severely impacted countries.
- **Vaccination Progress Tracking**: Using rolling sums to visualize how quickly countries vaccinated their populations.

All SQL scripts are shared in this repository, organized by topic.

---

## Conclusion

This project gave me the opportunity to work with real-world data to build a comprehensive analysis of the Covid-19 pandemic. Using **SQL** and **BigQuery**, I handled a large dataset, structured complex queries, and extracted insights that reflect both global patterns and country-level nuances.

By using **GitHub**, I documented my thought process and created a foundation that others can explore or build upon. The project also serves as a stepping stone toward future visualization work and deeper policy-based analyses.
