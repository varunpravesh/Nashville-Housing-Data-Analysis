SELECT * FROM [Housing Data].dbo.NashVilleData

 -- Standardize SaleDate

 SELECT SaleDate, CONVERT(Date,SaleDate) FROM [Housing Data].dbo.NashVilleData

 ALTER TABLE [Housing Data].dbo.NashVilleData 
 ALTER COLUMN SaleDate Date; 

 ---------------------------------------------------------------------------------------------------------------------------------

-- Populate Address Data
/*
 WITH DupRecords (ParcelID,PropertyAddress,OwnerName,OwnerAddress) AS

(SELECT A.ParcelID,A.PropertyAddress,A.OwnerName,A.OwnerAddress FROM [Housing Data].dbo.NashVilleData A
JOIN [Housing Data].dbo.NashVilleData B ON 
A.ParcelID = B.ParcelID
WHERE A.[UniqueID ] != B.[UniqueID ])

SELECT * FROM DupRecords
*/

SET IMPLICIT_TRANSACTIONS ON;
UPDATE A
SET A.PropertyAddress = B.PropertyAddress                          
FROM [Housing Data].dbo.NashVilleData A 
JOIN [Housing Data].dbo.NashVilleData B ON							
A.ParcelID = B.ParcelID											
WHERE A.PropertyAddress IS NULL AND A.[UniqueID ] != B.[UniqueID ]
COMMIT TRANSACTION;
ROLLBACK TRANSACTION;

/*Sometimes a property might have two or more entries in the table having the same the parcelId and PropertyAddress. Although the parcelId and proprtyAddress might be same
each entry has a different unique ID. So if we were to fill the NULL values of Propertyaddress we can pull those values from their duplicate counterparts.
In order to do that we'll have filter the table for duplicate ParcelID values.We achieve this by using a self join but we have to make sure that table doesn't join 
itself on the same rows. We do this by ensuring that the table join itself on same parcelID but given that those ParcelID have different uniqueIDs. */


SELECT * FROM [Housing Data].dbo.NashVilleData 

------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns(Address,City,State)

SELECT PropertyAddress,SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,   --The -1 here subtracts 1 from the end position to get rid of the comma
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City							
FROM [Housing Data].dbo.NashVilleData

 ALTER TABLE [Housing Data].dbo.NashVilleData 
 ADD PropertySplitAddress NVARCHAR(200)
 
 ALTER TABLE [Housing Data].dbo.NashVilleData 
 ADD PropertySplitCity NVARCHAR(200)

UPDATE [Housing Data].dbo.NashVilleData 
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) 

UPDATE [Housing Data].dbo.NashVilleData 
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


--Breaking OwnerAddress (Using ParseName function)
 SELECT OwnerAddress,
 PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS OwnerSplitAddress,  --For reasons unkown PARSENAME functions returns values from the right
 PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS OwnerSplitCity,	   
 PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS OwnerSplitState
 FROM [Housing Data].dbo.NashVilleData

 ALTER TABLE [Housing Data].dbo.NashVilleData 
 ADD OwnerSplitAddress NVARCHAR(200)
 
 ALTER TABLE [Housing Data].dbo.NashVilleData 
 ADD OwnerSplitCity NVARCHAR(200)

 ALTER TABLE [Housing Data].dbo.NashVilleData 
 ADD OwnerSplitState NVARCHAR(200)

UPDATE [Housing Data].dbo.NashVilleData 
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE [Housing Data].dbo.NashVilleData 
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE [Housing Data].dbo.NashVilleData 
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT * FROM [Housing Data].dbo.NashVilleData

--------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in the SoldAsVacant field

--SELECT DISTINCT(SoldAsVacant) FROM [Housing Data].dbo.NashVilleData


UPDATE [Housing Data].dbo.NashVilleData
SET SoldAsVacant = REPLACE(SoldAsVacant,'Y','Yes')

UPDATE [Housing Data].dbo.NashVilleData
SET SoldAsVacant = REPLACE(SoldAsVacant,'N','No')


---------------------------------------------------------------------------------------------------------------------------------------------

--Removing Duplicates


WITH PartitionedTable AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY
				ParcelID,
				PropertyAddress,
				SaleDate,
				SalePrice,
				LegalReference
				ORDER BY UniqueID) AS Row_Num
FROM [Housing Data].dbo.NashVilleData
)
/*
DELETE FROM PartitionedTable
WHERE Row_Num > 1
*/
SELECT * FROM PartitionedTable
WHERE Row_Num > 1

----------------------------------------------------------------------------------------------------------------------------------------------

-- Drop Unused Columns

ALTER TABLE [Housing Data].dbo.NashVilleData 
DROP COLUMN OwnerAddress,PropertyAddress,TaxDistrict

SELECT * FROM [Housing Data].dbo.NashVilleData 