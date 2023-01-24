---------------------------------------- Data-Cleaning of Housing Dataset ----------------------------------------- 

--Skills used: CTEs, Windows Functions, Aggregate Functions, CASE Statement, 
--			   Functions - CONVERT, ISNULL, SUBSTRING,  CHARINDEX, PARSENAME, REPLACE 
----------------------------------------------------------------------------------------------------------

SELECT *
FROM HousingData.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------
-- SaleDate column - Standardizing the Date Format (Removing the time information)


SELECT saleDate, CONVERT(Date,SaleDate)
FROM HousingData.dbo.NashvilleHousing;

--Create new column : SaleDateConverted

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

--Fill data to new column : SaleDateConverted

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------
-- PropertyAddress column - Populating Property Address data (where null)

SELECT *
FROM HousingData.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL;


SELECT *
FROM HousingData.dbo.NashvilleHousing
ORDER BY ParcelID;


SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, 
		ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM HousingData.dbo.NashvilleHousing as A
INNER JOIN HousingData.dbo.NashvilleHousing as B
	ON A.ParcelID = B.ParcelID
	AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL;


UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM HousingData.dbo.NashvilleHousing as A
JOIN HousingData.dbo.NashvilleHousing as B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL;


--------------------------------------------------------------------------------------------------------------------------
-- Splitting PropertyAddress into Individual Columns (Address, City)


SELECT PropertyAddress
FROM HousingData.dbo.NashvilleHousing;

SELECT PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM HousingData.dbo.NashvilleHousing;

--Create new column : PropertySplitAddress
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

--Create new column : PropertySplitCity
ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);



--Fill data to new column : PropertySplitAddress
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

--Fill data to new column : PropertySplitCity
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


--------------------------------------------------------------------------------------------------------------------------
-- Splitting OwnerAddress into Individual Columns (Address, City, State)

SELECT OwnerAddress
FROM HousingData.dbo.NashvilleHousing;

--Displaying the owner's Address, City and State separately
SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) as Address
   ,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) as City
   ,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) as State
FROM HousingData.dbo.NashvilleHousing;


--Create new columns : OwnerSplitAddress, OwnerSplitCity, OwnerSplitState

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);


--Fill data to new columns : OwnerSplitAddress, OwnerSplitCity, OwnerSplitState

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);


--------------------------------------------------------------------------------------------------------------------------
-- SoldAsVacant - Changing 'Y' and 'N' to 'Yes' and 'No'


SELECT DISTINCT(SoldAsVacant), 
		COUNT(SoldAsVacant)
FROM HousingData.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END  
FROM HousingData.dbo.NashvilleHousing;


UPDATE HousingData.dbo.NashvilleHousing 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END;


-------------------------------------------------------------------------------
-- Removing Duplicates

--Displaying the duplicates
WITH repeated_data as (
					SELECT *,
						ROW_NUMBER() OVER(
						PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
						ORDER BY UniqueID) as row_num	
					FROM HousingData.dbo.NashvilleHousing
				)
SELECT * 
FROM repeated_data
WHERE row_num > 1
ORDER BY PropertyAddress;


--Deleting the duplicates
WITH repeated_data as (
					SELECT *,
						ROW_NUMBER() OVER(
						PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
						ORDER BY UniqueID) as row_num	
					FROM HousingData.dbo.NashvilleHousing
				)
DELETE	 
FROM repeated_data
WHERE row_num > 1;


-----------------------------------------------------------------------------------------
-- Deleting unrequired columns

ALTER TABLE HousingData.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE HousingData.dbo.NashvilleHousing
DROP COLUMN SaleDate;

-----------------------------End of Document------------------------------------------------------------
