-- SQL PROJECT #2
-- DATA CLEANING: NASHVILLE HOUSING DATA

-- Data cleaning is one of the most common and important tasks while working in Data Analytics or Data Science,
-- this is why in this project we'll be using a dataset containing housing information from the city of Nashville, 
-- USA, to practice some important data cleaning skills, essential to sucessfully prepare data for future analysis  
-- or visualizations.

-- BEGGINING

-- Let´s give a general look at the data:

SET search_path TO public;

SELECT * FROM nashville_housing
ORDER BY parcel_id;

-- 1. Adjusting 'sale_date' column

-- We can see that 'SaleDate' column is in a text format not suitable for date functions.
-- We should transform this column to the appropiate format:

SELECT sale_date FROM nashville_housing;

UPDATE nashville_housing
SET sale_date = TO_DATE(sale_date, 'Month DD, YYYY');

ALTER TABLE nashville_housing
ALTER COLUMN sale_date TYPE DATE USING sale_date::DATE;

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Populating Property Address Data

SELECT *
FROM nashville_housing
WHERE property_address IS NULL;

-- We can see there are rows from the property_address column that are null.
-- We'll try to fix this and complete this missing information:

-- We'll approach this by updating the rows in the 'nashville_housing' table where property address is NULL,
-- with the corresponding property address value, from rows where 'parcel_id' match, and 'unique_id' are different.
-- This is assuming that equal 'parcel_id' values share the same property address.

--NOTE: we use transaction clauses to first ensure that the changes behave as expected, before fully applying these changes.

BEGIN;
UPDATE nashville_housing a
SET property_address = b.property_address
FROM (
    SELECT DISTINCT ON (parcel_id)
        unique_id, parcel_id, property_address
    FROM nashville_housing
    WHERE property_address IS NOT NULL
) b
WHERE a.parcel_id = b.parcel_id
  AND a.unique_id <> b.unique_id
  AND a.property_address IS NULL;
COMMIT;
--ROLLBACK;

-- Now, we can verify that there are not NULL values for property address.

SELECT *
FROM nashville_housing
WHERE property_address IS NULL;


----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. Breaking out Address information into individual columns (address, ciy, state)

SELECT property_address
FROM nashville_housing;

-- Extracting the address and the city from the property address column:

SELECT 
SUBSTRING( property_address, 1, POSITION(',' IN property_address) - 1 ) AS address,
SUBSTRING( property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address) ) AS city
FROM nashville_housing;

-- Creating two new columns with the data we just extracted:

ALTER TABLE nashville_housing
ADD property_split_address text;

UPDATE nashville_housing
SET property_split_address = SUBSTRING( property_address, 1, POSITION(',' IN property_address) - 1 );

ALTER TABLE nashville_housing
ADD property_split_city text;

UPDATE nashville_housing
SET property_split_city = SUBSTRING( property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address) );

SELECT property_address, property_split_address, property_split_city
FROM nashville_housing;

-- Extracting information from owner address:

SELECT owner_address
FROM nashville_housing;

-- Instead of using SUBSTRING() as in the previous case, we'll use the SPLIT_PART() function,
-- which splits a given string in substrings accorfing to a specified delimiter, a gives us the substring  
-- corresponding to the position, or 'index', we specify. 

SELECT 
SPLIT_PART(owner_address, ',', 1) AS address,
SPLIT_PART(owner_address, ',', 2) AS city,
SPLIT_PART(owner_address, ',', 3) AS state
FROM nashville_housing;

-- Creating  new columns with the data we just extracted:

ALTER TABLE nashville_housing
ADD COLUMN owner_split_address text,
ADD COLUMN owner_split_city text,
ADD COLUMN owner_split_state text;

UPDATE nashville_housing
SET owner_split_address = SPLIT_PART(owner_address, ',', 1),
	owner_split_city = SPLIT_PART(owner_address, ',', 2),
	owner_split_state = SPLIT_PART(owner_address, ',', 3);

SELECT owner_address, owner_split_address, owner_split_city, owner_split_state
FROM nashville_housing;

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. Changing the 'Y' and 'N' values from the 'sold_as_vacant' column to 'Yes' or 'No', respectively:

SELECT DISTINCT sold_as_vacant, COUNT(sold_as_vacant)
FROM nashville_housing
GROUP BY sold_as_vacant
ORDER BY 2;

-- We'll make use of CASE statements: 

SELECT sold_as_vacant, 
CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
	 WHEN sold_as_vacant = 'N' THEN 'No'
	 ELSE sold_as_vacant
	 END
FROM nashville_housing;

-- Let's update the column in the table: 

UPDATE nashville_housing
SET sold_as_vacant = CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
	 					  WHEN sold_as_vacant = 'N' THEN 'No'
						  ELSE sold_as_vacant
						  END;

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5. Removing Duplicates

-- Although it is not an usual practice to remove duplicates directly from an actual database (it's normally done when
-- preparing data in another tool, for example, Power BI), we'll do it here for practicing purposes. 

WITH row_num_cte AS (
SELECT *,
	  ROW_NUMBER() OVER (
	  PARTITION BY parcel_id,
		  		   property_address,
		  		   sale_price,
		  		   sale_date, 
		  		   legal_reference
		  		   ORDER BY unique_id ) as row_num
FROM nashville_housing
-- ORDER BY parcel_id;
)
SELECT *
FROM row_num_cte
WHERE row_num > 1
ORDER BY property_address;

-- The result of this last query is all the duplicated rows we found basing our search on the columns
-- used in the PARTITION BY clause of the window function. Basically, we used the fact that, when using the
-- ROW_NUMBER() function and creating partitions, within each partition, no two rows can have the same row number.

-- Now, we'll delete these duplicated rows: 

WITH row_num_cte AS (
SELECT *,
	  ROW_NUMBER() OVER (
	  PARTITION BY parcel_id,
		  		   property_address,
		  		   sale_price,
		  		   sale_date, 
		  		   legal_reference
		  		   ORDER BY unique_id ) as row_num
FROM nashville_housing
)
DELETE
FROM nashville_housing
WHERE unique_id IN ( SELECT unique_id FROM row_num_cte WHERE row_num > 1 );

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Deleting Unused Columns:

ALTER TABLE nashville_housing
DROP COLUMN owner_address,
DROP COLUMN tax_district,
DROP COLUMN property_address;

ALTER TABLE nashville_housing
DROP COLUMN sale_date;

SELECT * FROM nashville_housing;

-- 7. Renaming Some Columns:

--Let's rename some of the columns we created in the previous steps: 

ALTER TABLE nashville_housing
RENAME COLUMN property_split_address TO property_address;

ALTER TABLE nashville_housing
RENAME COLUMN property_split_city TO property_city;

ALTER TABLE nashville_housing
RENAME COLUMN owner_split_address TO owner_address;

ALTER TABLE nashville_housing
RENAME COLUMN owner_split_city TO owner_city;

ALTER TABLE nashville_housing
RENAME COLUMN owner_split_state TO owner_state;
