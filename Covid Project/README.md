# Analyzing Worlwide Covid Data with SQL

In this project, we look at a worlwide Covid-19 dataset, with information ranging from January 2020 towards the end 2023. It includes information on daily new cases of covid, daily new deaths due to the virus, daily new vaccinations, total vaccinations, total population, and also, although not covered in this project, patients in hospitalization or ICU due to the virus, and many other interesting indicators. 

We use SQL queries to answer questions like:

- What is the aproximate likelihood of dying from Covid in a particular country?
- What percentage of population got Covid in a given country, on a particular date?
- Which countries had the highest death count per population?
- How was the the evolution in time of new Covid cases and new deaths at a global scale?

And other interesting questions. In some cases, we used some helpful querying tools in the SQL language such as virtual tables (or views) and Common Table Expressions (or CTE).

Here's the link to the data: https://ourworldindata.org/covid-deaths

Some notes:
- The database engine used in this project was PostgreSQL.
- I added a jupyter notebook file ('import_covid_tables_copy') with a brief code to load the csv files into PostgreSQL.
- I divided the file available in the previous link into two tables: covid_deaths, and covid_vaccinations, for ease of use. You can choose to work this way or use the whole table as it comes from the source. 
    
