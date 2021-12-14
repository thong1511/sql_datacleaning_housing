/*
	DATA CLEANING
*/

-- 1. Reformat SaleDate

ALTER TABLE housing
ADD SaleDateConverted DATE;
GO

UPDATE housing
SET SaleDateConverted = CONVERT(DATE, SaleDate);

-- 2. Process NULL in PropertyAddress

UPDATE x
SET PropertyAddress = ISNULL(x.PropertyAddress, y.PropertyAddress)
FROM housing x
JOIN housing y
	ON x.ParcelID = y.ParcelID
	AND x.UniqueID <> y.UniqueID
WHERE x.PropertyAddress IS NULL;

-- 3. Split PropertyAddress into 2 columns (Address, City)

ALTER TABLE housing
ADD SplitPropertyAddress NVARCHAR(255);
GO

UPDATE housing
SET SplitPropertyAddress = SUBSTRING(
									PropertyAddress
									,1
									,CHARINDEX(',', PropertyAddress) -1
									);

ALTER TABLE housing
ADD SplitPropertyCity NVARCHAR(255);
GO

UPDATE housing
SET SplitPropertyCity = SUBSTRING(
								PropertyAddress
								,CHARINDEX(',', PropertyAddress) +2
								,LEN(PropertyAddress)
								);

-- 4. Split OwnerAddress into 3 columns (Address, City, State)

----- Method 1: Use SUBSTRING, CHARINDEX

ALTER TABLE housing
ADD SplitOwnerAddress NVARCHAR(255);
GO

UPDATE housing
SET SplitOwnerAddress = SUBSTRING(
								OwnerAddress
								,1
								,CHARINDEX(',', OwnerAddress) -1
								);


ALTER TABLE housing
ADD SplitOwnerCity NVARCHAR(255);
GO

UPDATE housing
SET SplitOwnerCity = SUBSTRING(
							SUBSTRING(
									OwnerAddress
									,CHARINDEX(',', OwnerAddress) +2
									,LEN(OwnerAddress)
									)
							,1
							,CHARINDEX(',', SUBSTRING(
												OwnerAddress
												,CHARINDEX(',', OwnerAddress) +2
												,LEN(OwnerAddress)
											)
									) -1
								);

ALTER TABLE housing
ADD SplitOwnerState NVARCHAR(255);
GO

UPDATE housing
SET SplitOwnerState = SUBSTRING(
							SUBSTRING(
									OwnerAddress
									,CHARINDEX(',', OwnerAddress) +2
									,LEN(OwnerAddress)
									)
							,CHARINDEX(',', SUBSTRING(
												OwnerAddress
												,CHARINDEX(',', OwnerAddress) +2
												,LEN(OwnerAddress)
												)
										) +2
							,LEN(OwnerAddress)
							);
SELECT TOP 5 *
FROM housing;

----- Method 2: Use PARSENAME

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS SplitOwnerAddress
	,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS SplitOwnerCity
	,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS SplitOwnerState
FROM housing;

-- 5. Change Y, N to Yes, No in SoldAsVacant

UPDATE housing
SET SoldAsVacant = CASE
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END;
	
-- 6. Remove duplicated rows

WITH RowNumCTE AS (
	SELECT 
		*
		,ROW_NUMBER() OVER(
		PARTITION BY
				ParcelID
				,PropertyAddress
				,SalePrice
				,SaleDate
				,LegalReference
		ORDER BY UniqueID
		) AS Row_Num
	FROM housing)
DELETE
FROM RowNumCTE
WHERE Row_Num > 1;

-- 7. Drop all unused columns

ALTER TABLE housing
DROP COLUMN 
		PropertyAddress
		,OwnerAddress
		,SaleDate
		,TaxDistrict
;