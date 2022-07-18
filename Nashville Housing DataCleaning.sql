/* 
----------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Cleaning Data-------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------

*/

------------Standardize Date Format--------------------------
Select * from portfolioproject.dbo.NashvilleHousing

Select SaleDate, convert(date,saledate)
from portfolioproject.dbo.NashvilleHousing

Update NashvilleHousing
Set SaleDate = convert(date,saledate)

Alter Table NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
Set SaleDateConverted = convert(date,saledate)

Select SaleDateConverted
from portfolioproject.dbo.NashvilleHousing

----------------------------------------------------------------------------------
-- -------------------Populate Property Address Data------------------------------

Select * 
From portfolioproject.dbo.NashvilleHousing
Where PropertyAddress is null
order by ParceliD

Select a.ParcelID, a.PropertyAddress, b.PArcelID, b.PropertyAddress, ISNULL(a.propertyaddress,b.propertyAddress)
From portfolioproject.dbo.NashvilleHousing a
Join portfolioproject.dbo.NashvilleHousing b
	on a.ParcelID = b.parcelID
	and a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

Update a
SET propertyAddress = ISNULL(a.propertyaddress,b.propertyAddress)
From portfolioproject.dbo.NashvilleHousing a
Join portfolioproject.dbo.NashvilleHousing b
	on a.ParcelID = b.parcelID
	and a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

----------------------------------------------------------------------------------
-------- Breaking out Address into Individual Columns ( Address, City, State)

Select * 
From portfolioproject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParceliD

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, Len(PropertyAddress)) as Address

From portfolioproject.dbo.NashvilleHousing

Alter Table portfolioproject.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update portfolioproject.dbo.NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) 

Alter Table portfolioproject.dbo.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update portfolioproject.dbo.NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, Len(PropertyAddress))

Select * 
From portfolioproject.dbo.NashvilleHousing


Select OwnerAddress 
From portfolioproject.dbo.NashvilleHousing

Select
PARSENAME(Replace(OwnerAddress,',','.'), 3),
PARSENAME(Replace(OwnerAddress,',','.'), 2),
PARSENAME(Replace(OwnerAddress,',','.'), 1)
From portfolioproject.dbo.NashvilleHousing
----------------------------------------------------------------------
Alter Table portfolioproject.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update portfolioproject.dbo.NashvilleHousing
Set OwnerSplitAddress = PARSENAME(Replace(OwnerAddress,',','.'), 3)
-------------------------------------------------------------------------------
Alter Table portfolioproject.dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update portfolioproject.dbo.NashvilleHousing
Set OwnerSplitCity = PARSENAME(Replace(OwnerAddress,',','.'), 2)
-------------------------------------------------------------------------------------
Alter Table portfolioproject.dbo.NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update portfolioproject.dbo.NashvilleHousing
Set OwnerSplitState =PARSENAME(Replace(OwnerAddress,',','.'), 1)
------------------------------------------------------------------------------------
Select * 
From portfolioproject.dbo.NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------
---- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From portfolioproject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2


Select SoldAsVacant, 
Case When SoldAsVacant = 'Y' Then 'Yes'
	 When SoldAsVacant = 'N' Then 'No'
	 ELSE SoldAsVacant
	 END
From portfolioproject.dbo.NashvilleHousing

Update portfolioproject.dbo.NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
	 When SoldAsVacant = 'N' Then 'No'
	 ELSE SoldAsVacant
	 END

------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------Remove Duplicates-------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
With RowNumCTE As(
Select * ,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			ORDER BY 
			UniqueID
			) as row_num
From portfolioproject.dbo.NashvilleHousing
--Order By ParcelID
)
DELETE
From RowNumCTE
Where row_num >1
Order by PropertyAddress



------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------Delete Unused Columns-------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
Select * 
From portfolioproject.dbo.NashvilleHousing

ALTER TABLE portfolioproject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, Sale_Date
