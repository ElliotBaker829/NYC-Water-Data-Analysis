#Create the staging table with row number as a column to remove direct duplicates

CREATE TABLE `waterconsumptionstaging3` (
  `DevelopmentName` varchar(50) DEFAULT NULL,
  `Borough` varchar(50) DEFAULT NULL,
  `AccountName` varchar(50) DEFAULT NULL,
  `Location` varchar(50) DEFAULT NULL,
  `MeterAMR` varchar(50) DEFAULT NULL,
  `MeterScope` varchar(50) DEFAULT NULL,
  `TDSNum` varchar(50) DEFAULT NULL,
  `EDP` varchar(50) DEFAULT NULL,
  `RCCode` varchar(50) DEFAULT NULL,
  `FundingSource` varchar(50) DEFAULT NULL,
  `AMPNum` varchar(50) DEFAULT NULL,
  `VendorName` varchar(50) DEFAULT NULL,
  `UMISBILLID` varchar(50) DEFAULT NULL,
  `RevenueMonth` varchar(50) DEFAULT NULL,
  `ServiceStartDate` varchar(50) DEFAULT NULL,
  `ServiceEndDate` varchar(50) DEFAULT NULL,
  `Numdays` varchar(50) DEFAULT NULL,
  `MeterNumber` varchar(50) DEFAULT NULL,
  `Estimated` varchar(50) DEFAULT NULL,
  `CurrentCharges` varchar(50) DEFAULT NULL,
  `RateClass` varchar(50) DEFAULT NULL,
  `BillAnalyzed` varchar(50) DEFAULT NULL,
  `ConsumptionHCF` varchar(50) DEFAULT NULL,
  `WaterAndSewer` varchar(50) DEFAULT NULL,
  `Charges` varchar(50) DEFAULT NULL,
  `OtherCharges` varchar(50) DEFAULT NULL,
  `rn` INTEGER
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

#Insert data from previous staging table

INSERT INTO waterconsumptionstaging3
SELECT *,
ROW_NUMBER() OVER(PARTITION BY 
DevelopmentName	,
Borough	,
AccountName	,
Location	,
MeterAMR	,
MeterScope	,
TDSNum	,
EDP	,
RCCode	,
FundingSource	,
AMPNum,
VendorName,	
UMISBILLID	,
RevenueMonth,	
ServiceStartDate,
ServiceEndDate	,
Numdays	,
MeterNumber,	
Estimated,
CurrentCharges,	
RateClass	,
BillAnalyzed,
ConsumptionHCF,
WaterAndSewer,
Charges,
OtherCharges 
) AS rn
FROM waterconsumptionstaging w;

#Delete exact duplicates

START TRANSACTION;

DELETE
FROM waterconsumptionstaging3 w
WHERE rn >1;

COMMIT;


#Investigating Revenue Month length, nulls, blanks, and testing string conversion and converting string to date

SELECT LENGTH(RevenueMonth), LENGTH(TRIM(RevenueMonth))
FROM waterconsumptionstaging3 w
WHERE Length(TRIM(RevenueMonth)) <> 7

SELECT w.RevenueMonth 
FROM waterconsumptionstaging3 w
WHERE RevenueMonth NOT LIKE '____-%';

SELECT COUNT(*) AS BlankOrNull
FROM waterconsumptionstaging3
WHERE RevenueMonth IS NULL
   OR TRIM(RevenueMonth) = '';

SELECT
    RevenueMonth                                                AS Original,
    STR_TO_DATE(CONCAT(RevenueMonth, '-01'), '%Y-%m-%d')        AS Converted
FROM waterconsumptionstaging3
LIMIT 20;

START TRANSACTION;

UPDATE waterconsumptionstaging3
SET RevenueMonth = STR_TO_DATE(CONCAT(RevenueMonth, '-01'), '%Y-%m-%d');

COMMIT;

#Checking service start / end date and converting string to date

SELECT
    ServiceStartDate                                AS Original,
    STR_TO_DATE(
        NULLIF(TRIM(ServiceStartDate), ''),
        '%m/%d/%Y'
    )                                               AS Converted
FROM waterconsumptionstaging3
ORDER BY Converted;

SELECT 
    ServiceEndDate,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
WHERE ServiceEndDate IS NOT NULL
  AND TRIM(ServiceEndDate) != ''
  AND STR_TO_DATE(
        NULLIF(TRIM(ServiceEndDate), ''),
        '%m/%d/%Y'
      ) IS NULL
GROUP BY ServiceEndDate
ORDER BY Count DESC;

START TRANSACTION;

UPDATE waterconsumptionstaging3
SET
    ServiceStartDate = STR_TO_DATE(NULLIF(TRIM(ServiceStartDate), ''), '%m/%d/%Y'),
    ServiceEndDate   = STR_TO_DATE(NULLIF(TRIM(ServiceEndDate),   ''), '%m/%d/%Y');

COMMIT;


#Testing how many of the string columns contain NULL or blanks 

SELECT
    SUM(CASE WHEN DevelopmentName IS NULL OR TRIM(DevelopmentName) = '' THEN 1 ELSE 0 END) AS Missing_DevelopmentName,
    SUM(CASE WHEN Borough IS NULL OR TRIM(Borough) = '' THEN 1 ELSE 0 END) AS Missing_Borough,
    SUM(CASE WHEN AccountName IS NULL OR TRIM(AccountName) = '' THEN 1 ELSE 0 END) AS Missing_AccountName,
    SUM(CASE WHEN Location IS NULL OR TRIM(Location) = '' THEN 1 ELSE 0 END) AS Missing_Location,
    SUM(CASE WHEN MeterAMR IS NULL OR TRIM(MeterAMR) = '' THEN 1 ELSE 0 END) AS Missing_MeterAMR,
    SUM(CASE WHEN MeterScope IS NULL OR TRIM(MeterScope) = '' THEN 1 ELSE 0 END) AS Missing_MeterScope,
    SUM(CASE WHEN UMISBILLID IS NULL OR TRIM(UMISBILLID) = '' THEN 1 ELSE 0 END) AS Missing_UMISBILLID,
    SUM(CASE WHEN RevenueMonth IS NULL OR TRIM(RevenueMonth) = '' THEN 1 ELSE 0 END) AS Missing_RevenueMonth,
    SUM(CASE WHEN ServiceStartDate IS NULL OR TRIM(ServiceStartDate) = '' THEN 1 ELSE 0 END) AS Missing_ServiceStartDate,
    SUM(CASE WHEN ServiceEndDate IS NULL OR TRIM(ServiceEndDate) = '' THEN 1 ELSE 0 END) AS Missing_ServiceEndDate,
    SUM(CASE WHEN NumDays IS NULL OR TRIM(NumDays) = '' THEN 1 ELSE 0 END) AS Missing_NumDays,
    SUM(CASE WHEN MeterNumber IS NULL OR TRIM(MeterNumber) = '' THEN 1 ELSE 0 END) AS Missing_MeterNumber,
    SUM(CASE WHEN Estimated IS NULL OR TRIM(Estimated) = '' THEN 1 ELSE 0 END) AS Missing_Estimated,
    SUM(CASE WHEN CurrentCharges IS NULL OR TRIM(CurrentCharges) = '' THEN 1 ELSE 0 END) AS Missing_CurrentCharges,
    SUM(CASE WHEN RateClass IS NULL OR TRIM(RateClass) = '' THEN 1 ELSE 0 END) AS Missing_RateClass,
    SUM(CASE WHEN ConsumptionHCF IS NULL OR TRIM(ConsumptionHCF) = '' THEN 1 ELSE 0 END) AS Missing_ConsumptionHCF,
    SUM(CASE WHEN WaterAndSewer IS NULL OR TRIM(WaterAndSewer) = '' THEN 1 ELSE 0 END) AS Missing_WaterAndSewer,
    SUM(CASE WHEN OtherCharges IS NULL OR TRIM(OtherCharges) = '' THEN 1 ELSE 0 END) AS Missing_OtherCharges,
    SUM(CASE WHEN FundingSource IS NULL OR TRIM(FundingSource) = '' THEN 1 ELSE 0 END) AS Missing_FundingSource,
    COUNT(*) AS TotalRows
FROM waterconsumptionstaging3;

#Started to investigate rows with no meter number as this might indicate no reading can take place

SELECT
    UMISBILLID,
    RevenueMonth,
    MeterNumber,
    RateClass,
    CurrentCharges,
    ConsumptionHCF,
    WaterAndSewer,
    OtherCharges,
    ServiceStartDate,
    ServiceEndDate
FROM waterconsumptionstaging3
WHERE MeterNumber IS NULL
   OR TRIM(MeterNumber) = ''
AND UMISBILLID IN (
    SELECT UMISBILLID
    FROM waterconsumptionstaging3
    WHERE MeterNumber IS NULL
       OR TRIM(MeterNumber) = ''
    GROUP BY UMISBILLID, RevenueMonth
    HAVING COUNT(*) > 1
)
ORDER BY UMISBILLID, RevenueMonth;

#Counted the NULL meter duplicates to see whether they have identical charges and consumption 
#across their rows. Found they differed on charges but had the same consumption

SELECT
    UMISBILLID,
    RevenueMonth,
    COUNT(*)                        AS TotalRows,
    COUNT(DISTINCT RateClass)       AS DistinctRateClass,
    COUNT(DISTINCT CurrentCharges)  AS DistinctCharges,
    COUNT(DISTINCT ConsumptionHCF)  AS DistinctConsumption
FROM waterconsumptionstaging3
WHERE MeterNumber IS NULL
   OR TRIM(MeterNumber) = ''
GROUP BY UMISBILLID, RevenueMonth
HAVING COUNT(*) > 1
ORDER BY UMISBILLID, RevenueMonth;

#Looks at rows that do have a meter number but still more than one UMISBILLID,
# found that most had distinct consumption

SELECT
    UMISBILLID,
    MeterNumber,
    RevenueMonth,
    COUNT(*)                        AS TotalRows,
    COUNT(DISTINCT CurrentCharges)  AS DistinctCharges,
    COUNT(DISTINCT ConsumptionHCF)  AS DistinctConsumption,
    COUNT(DISTINCT RateClass)       AS DistinctRateClass,
    COUNT(DISTINCT ServiceStartDate) AS DistinctStartDate,
    COUNT(DISTINCT ServiceEndDate)  AS DistinctEndDate,
    COUNT(DISTINCT NumDays)         AS DistinctNumDays
FROM waterconsumptionstaging3
WHERE MeterNumber IS NOT NULL
  AND TRIM(MeterNumber) != ''
GROUP BY UMISBILLID, MeterNumber, RevenueMonth
HAVING COUNT(*) > 1
ORDER BY UMISBILLID, RevenueMonth;

#Check what differs across rows with a meter number but duplicate UMISBILLs,
# found that W+S and location would differ

SELECT
    UMISBILLID,
    MeterNumber,
    RevenueMonth,
    COUNT(DISTINCT DevelopmentName)     AS DistinctDevName,
    COUNT(DISTINCT Borough)             AS DistinctBorough,
    COUNT(DISTINCT AccountName)         AS DistinctAccount,
    COUNT(DISTINCT Location)            AS DistinctLocation,
    COUNT(DISTINCT MeterAMR)            AS DistinctMeterAMR,
    COUNT(DISTINCT FundingSource)       AS DistinctFunding,
    COUNT(DISTINCT Estimated)           AS DistinctEstimated,
    COUNT(DISTINCT WaterAndSewer)   AS DistinctWSCharges,
    COUNT(DISTINCT OtherCharges)        AS DistinctOther,
    COUNT(DISTINCT RateClass)           AS DistinctRateClass
FROM waterconsumptionstaging3
WHERE MeterNumber IS NOT NULL
  AND TRIM(MeterNumber) != ''
GROUP BY UMISBILLID, MeterNumber, RevenueMonth
HAVING COUNT(*) > 1
ORDER BY UMISBILLID, RevenueMonth;

#shows the list of the duplicates for reference 

SELECT
    UMISBILLID,
    MeterNumber,
    RevenueMonth
FROM waterconsumptionstaging3
WHERE MeterNumber IS NOT NULL
  AND TRIM(MeterNumber) != ''
GROUP BY UMISBILLID, MeterNumber, RevenueMonth
HAVING COUNT(*) > 1;

#investigate a specific development record to get more of an understanding in the differences, 
#found they were the same dates but different consumption and waterandsewer charge
# but the same current charge - suggesting a problem when inputting the data

SELECT *
FROM waterconsumptionstaging3
WHERE UMISBILLID = '13680477'
  AND MeterNumber = 'K15130328'
  AND RevenueMonth = '2024-02-01';

#Investigate water 0 charges 0 but total number?



#Checking if any meter numbers are blank, found none

SELECT *
FROM waterconsumptionstaging3 w 
WHERE TRIM(MeterNumber) = '';

#Checking if numdays has any null, found 27

SELECT *
FROM waterconsumptionstaging3 w 
WHERE NumDays IS NULL;

#Changing the 27 blank num days to null

START TRANSACTION;

UPDATE waterconsumptionstaging3 w2 
SET NumDays = NULL
WHERE NumDays = '';

COMMIT;

#Checking for invalid numdays and evaluating what they are, found 0, negative numbers and some too large

SELECT *
FROM waterconsumptionstaging3 w 
WHERE NumDays < 0;

SELECT
    NumDays,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
WHERE CAST(NumDays AS SIGNED) < 0
GROUP BY NumDays
ORDER BY CAST(NumDays AS SIGNED);

#Double checking the count for blanks or nulls and updating

SELECT COUNT(*) 
FROM waterconsumptionstaging3
WHERE (MeterNumber IS NULL OR TRIM(MeterNumber) = '')
  AND (Estimated IS NULL OR TRIM(Estimated) = '')
  AND (WaterAndSewer IS NULL OR TRIM(WaterAndSewer) = '');

START TRANSACTION;

UPDATE waterconsumptionstaging3
SET MeterNumber = NULL, Estimated = NULL, WaterAndSewer = NULL
WHERE (MeterNumber IS NULL OR TRIM(MeterNumber) = '')
  AND (Estimated IS NULL OR TRIM(Estimated) = '')
  AND (WaterAndSewer IS NULL OR TRIM(WaterAndSewer) = '');

COMMIT;

#Investigating meter scope / location, found that they are mostly the same 
#but meter scope is the larger property with location sometimes specifying which part of that 
#larger property the bill is associated with e.g meter scope: community center location: bld 3, bld 4, etc

SELECT *
FROM waterconsumptionstaging3 w 
WHERE TRIM(MeterScope) != ''

SELECT
    MeterScope,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
GROUP BY MeterScope
ORDER BY Count DESC;

SELECT
    MeterScope,
    Location,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
WHERE MeterScope IS NOT NULL
  AND TRIM(MeterScope) != ''
GROUP BY MeterScope, Location
ORDER BY MeterScope;

#Replace blank values with null

START TRANSACTION; 

UPDATE waterconsumptionstaging3 w
SET MeterScope = NULL
WHERE TRIM(MeterScope) = '';

COMMIT;

#Investigating relationship with location and meter amr, found meter can have two
# different values for NA/Not applicable, so updated to null as well as blanks

SELECT Location, MeterAMR
FROM waterconsumptionstaging3 w 
WHERE Location = '';

SELECT MeterScope
FROM waterconsumptionstaging3 w 
WHERE MeterScope = 'NA' OR MeterScope = 'Not Applicable'

SELECT
    COUNT(*)                                                    AS TotalBlankLocation,
    SUM(CASE WHEN MeterScope IS NULL 
             OR TRIM(MeterScope) = '' THEN 1 ELSE 0 END)       AS AlsoBlankMeterScope,
    SUM(CASE WHEN MeterAMR = 'NOT APPLICABLE' 
             OR MeterAMR = 'N/A' 
             OR MeterAMR = 'NA' THEN 1 ELSE 0 END)            AS MeterAMRNotApplicable,
    SUM(CASE WHEN MeterNumber IS NULL 
             OR TRIM(MeterNumber) = '' THEN 1 ELSE 0 END)       AS AlsoBlankMeterNumber
FROM waterconsumptionstaging3
WHERE Location IS NULL
   OR TRIM(Location) = '';

SELECT
    MeterAMR,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
WHERE Location IS NULL
   OR TRIM(Location) = ''
GROUP BY MeterAMR
ORDER BY Count DESC;

SELECT *
FROM waterconsumptionstaging3
WHERE (Location IS NULL OR TRIM(Location) = '')
  AND MeterAMR = 'AMR';

SELECT *
FROM waterconsumptionstaging3 w 
WHERE AMPNum = 'NY005015300P' AND RCCode = 'B036200'

SELECT *
FROM waterconsumptionstaging3 w 
WHERE AMPNum = 'NY005013090P' AND RCCode = 'M033100'

START TRANSACTION; 

UPDATE waterconsumptionstaging3 w
SET MeterScope = NULL
WHERE MeterScope = 'NA' OR MeterScope = 'Not Applicable';

COMMIT; 

#Found some rows are missing rate classes, looked at specific developments rate classes over time,
# found that the blank rate class is more common is a specifc subset of meters across specific dates

SELECT DISTINCT RateClass, COUNT(*)
FROM waterconsumptionstaging3 w
GROUP BY rateclass;

SELECT
    RateClass,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
GROUP BY RateClass
ORDER BY Count DESC;

SELECT *
FROM waterconsumptionstaging3 w 
WHERE TRIM(RateClass) = '';

SELECT RateClass, Location, MeterNumber, w.RevenueMonth 
FROM waterconsumptionstaging3 w 
WHERE MeterNumber = 'E97172487'
ORDER BY RevenueMonth;

SELECT RateClass, Location, MeterNumber, w.RevenueMonth 
FROM waterconsumptionstaging3 w 
WHERE MeterNumber = 'K16830957'
ORDER BY RevenueMonth;

SELECT
    UMISBILLID,
    MeterNumber,
    MIN(RevenueMonth)   AS EarliestBlank,
    MAX(RevenueMonth)   AS LatestBlank,
    COUNT(*)            AS BlankCount
FROM waterconsumptionstaging3
WHERE RateClass IS NULL
   OR TRIM(RateClass) = ''
GROUP BY UMISBILLID, MeterNumber
ORDER BY UMISBILLID;

SELECT RateClass, Location, MeterNumber, w.RevenueMonth 
FROM waterconsumptionstaging3 w 
WHERE MeterNumber = 'K96779329'
ORDER BY RevenueMonth;

SELECT RateClass, Location, MeterNumber, w.RevenueMonth 
FROM waterconsumptionstaging3 w 
WHERE MeterNumber = 'K99438473'
ORDER BY RevenueMonth;

SELECT RateClass, Location, MeterNumber, w.RevenueMonth 
FROM waterconsumptionstaging3 w 
WHERE MeterNumber = '22031091'
ORDER BY RevenueMonth;

SELECT
    RateClass,
    RevenueMonth,
    CurrentCharges,
    ConsumptionHCF,
    MeterNumber
FROM waterconsumptionstaging3
WHERE MeterNumber IN (
    SELECT MeterNumber
    FROM waterconsumptionstaging3
    WHERE RateClass IS NULL
       OR TRIM(RateClass) = ''
    GROUP BY MeterNumber
    HAVING COUNT(*) = 2
)
ORDER BY MeterNumber, RevenueMonth;

SELECT COUNT(DISTINCT(MeterNumber))
FROM waterconsumptionstaging3 w 
WHERE TRIM(RateClass) = ''

SELECT
    RevenueMonth,
    COUNT(*) AS BlankRateClassRows
FROM waterconsumptionstaging3
WHERE RateClass IS NULL
   OR TRIM(RateClass) = ''
GROUP BY RevenueMonth
ORDER BY RevenueMonth;

SELECT
    MeterNumber,
    COUNT(*) AS BlankMonths,
    MIN(RevenueMonth) AS FirstBlank,
    MAX(RevenueMonth) AS LastBlank
FROM waterconsumptionstaging3
WHERE RateClass IS NULL
   OR TRIM(RateClass) = ''
GROUP BY MeterNumber
ORDER BY BlankMonths DESC
LIMIT 5;

SELECT RateClass, Location, MeterNumber, w.RevenueMonth 
FROM waterconsumptionstaging3 w 
WHERE MeterNumber = 'K96779329'
ORDER BY RevenueMonth;

SELECT
    RateClass,
    RevenueMonth,
    CurrentCharges,
    ConsumptionHCF,
    MeterNumber
FROM waterconsumptionstaging3
WHERE MeterNumber IN ('3000743341001-Sewer', 'ACC 1')
ORDER BY MeterNumber, RevenueMonth;

SELECT
    RateClass,
    RevenueMonth,
    CurrentCharges,
    ConsumptionHCF
FROM waterconsumptionstaging3
WHERE MeterNumber = 'K96779329'
ORDER BY RevenueMonth;

#Found blank consumption and checked what the meter typr was, found that 
#blank consumption with automatic meters were concentrated on annual billings

SELECT *
FROM waterconsumptionstaging3 w 
WHERE (TRIM(w.ConsumptionHCF) = '' OR w.ConsumptionHCF IS NULL) AND Numdays = 366 AND MeterAMR != 'Not Applicable'

SELECT * 
FROM waterconsumptionstaging3 w 
WHERE Numdays > 334 AND Numdays < 367

SELECT DevelopmentName, COUNT(*)
FROM waterconsumptionstaging3 w 
WHERE TRIM(w.ConsumptionHCF) = ''
GROUP BY DevelopmentName

SELECT
    UMISBILLID,
    DevelopmentName,
    MeterNumber,
    RevenueMonth,
    MeterAMR,
    ConsumptionHCF,
    CurrentCharges,
    RateClass,
    NumDays
FROM waterconsumptionstaging3
WHERE (TRIM(ConsumptionHCF) = '' OR ConsumptionHCF IS NULL)
  AND MeterAMR = 'AMR';

SELECT COUNT(*) AS TotalBlankConsumption
FROM waterconsumptionstaging3
WHERE (TRIM(ConsumptionHCF) = '' OR ConsumptionHCF IS NULL);

SELECT COUNT(*) AS BlankConsumptionWithAMR
FROM waterconsumptionstaging3
WHERE (TRIM(ConsumptionHCF) = '' OR ConsumptionHCF IS NULL)
AND MeterAMR = 'AMR';

SELECT
    NumDays,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
WHERE (TRIM(ConsumptionHCF) = '' OR ConsumptionHCF IS NULL)
  AND MeterAMR = 'AMR'
GROUP BY NumDays
ORDER BY Count DESC;

SELECT *
FROM waterconsumptionstaging3 w 
WHERE TRIM(OtherCharges) = ''

#Look at count of funding sources

SELECT
    FundingSource,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
GROUP BY FundingSource
ORDER BY Count DESC;

#find negative values of other charges

SELECT *
FROM waterconsumptionstaging3
WHERE OtherCharges LIKE '%-%'

#look at the history of a specific property with negative charges,
# found that negative charge is likely due to paying extra in other months

SELECT *
FROM waterconsumptionstaging3 w 
WHERE TDSNum = '377' AND Location = 'BLD 45'

#Look at how long a certain development had a blank funding source found for 76 entries

SELECT *
FROM waterconsumptionstaging3 w 
WHERE TRIM(FundingSource) = ''
ORDER BY RevenueMonth ASC

SELECT
    DevelopmentName,
    Location,
    COUNT(*) AS BlankRows,
    MIN(RevenueMonth) AS EarliestMonth,
    MAX(RevenueMonth) AS LatestMonth
FROM waterconsumptionstaging3
WHERE FundingSource IS NULL
   OR TRIM(FundingSource) = ''
GROUP BY DevelopmentName, Location;

#Look more in detail at other fields

SELECT DISTINCT Borough FROM waterconsumptionstaging3 ORDER BY Borough;

SELECT DISTINCT Estimated FROM waterconsumptionstaging3 ORDER BY Estimated;

SELECT DISTINCT MeterAMR FROM waterconsumptionstaging3 ORDER BY MeterAMR;

SELECT DISTINCT FundingSource FROM waterconsumptionstaging3 ORDER BY FundingSource;

SELECT DISTINCT RateClass FROM waterconsumptionstaging3 ORDER BY RateClass;

#Check how many have dollar signs

SELECT DISTINCT
    LEFT(OtherCharges , 1) AS FirstCharacter,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
GROUP BY LEFT(OtherCharges, 1)
ORDER BY Count DESC;

#Check if its possible to convert the values to include a dollar sign


SELECT
    WaterAndSewer  AS Original,
    CAST(
        REPLACE(
            REPLACE(WaterAndSewer , '$', ''),
        ',', '')
    AS DECIMAL(14,2)) AS Converted
FROM waterconsumptionstaging3
WHERE WaterAndSewer  IS NOT NULL
  AND TRIM(WaterAndSewer ) != ''
LIMIT 20;

SELECT
    OtherCharges AS Original,
    CAST(
        REPLACE(
            REPLACE(OtherCharges , '$', ''),
        ',', '')
    AS DECIMAL(14,2)) AS Converted
FROM waterconsumptionstaging3
WHERE OtherCharges  IS NOT NULL
  AND TRIM(OtherCharges ) != ''
LIMIT 20;

#Checking date formats and then finding 94 monthly vs 2 annual charges for blank rate classes

SELECT DISTINCT
    LEFT(RevenueMonth, 7) AS DateFormat,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
GROUP BY LEFT(RevenueMonth, 7)
ORDER BY Count DESC
LIMIT 10;



SELECT
    CASE
        WHEN CAST(NULLIF(TRIM(NumDays), '') AS SIGNED) >= 334
            THEN 'Annual charge'
        ELSE 'Monthly charge'
    END AS BillingType,
    COUNT(*) AS Count
FROM waterconsumptionstaging3
WHERE RateClass IS NULL
   OR TRIM(RateClass) = ''
GROUP BY
    CASE
        WHEN CAST(NULLIF(TRIM(NumDays), '') AS SIGNED) >= 334
            THEN 'Annual charge'
        ELSE 'Monthly charge'
    END;

#Checking again the close relationship between location and meter scope

SELECT MeterScope, Location
FROM waterconsumptionstaging3 w 
WHERE MeterScope LIKE '%Location%'

SELECT MeterScope, Location
FROM waterconsumptionstaging3 w 
WHERE MeterScope != Location

#Checking for valid dates, found some definitely out of range 2022 so double checked it, 
#then set a reasonable date border based on the data and checked

SELECT 
	MIN(ServiceStartDate) AS EarliestStart,
	MAX(ServiceStartDate) AS LatestStart,
	MIN(ServiceEndDate) AS EarliestEnd,
	MAX(ServiceEndDate) AS LatestEnd,
	MIN(RevenueMonth) AS EarliestRev,
	MAX(RevenueMonth) AS LatestRev
FROM waterconsumptionstaging3 w 

SELECT 
	COUNT(*)
FROM waterconsumptionstaging3
WHERE ServiceEndDate < ServiceStartDate

SELECT
    UMISBILLID,
    DevelopmentName,
    RevenueMonth,
    ServiceStartDate,
    ServiceEndDate
FROM waterconsumptionstaging3
WHERE ServiceStartDate = '2202-07-01';

SELECT
    UMISBILLID,
    DevelopmentName,
    RevenueMonth,
    ServiceStartDate,
    ServiceEndDate
FROM waterconsumptionstaging3
WHERE STR_TO_DATE(NULLIF(TRIM(ServiceStartDate), ''), '%Y-%m-%d') > '2026-12-31'
   OR STR_TO_DATE(NULLIF(TRIM(ServiceStartDate), ''), '%Y-%m-%d') < '2008-01-01'
   OR STR_TO_DATE(NULLIF(TRIM(ServiceEndDate), ''), '%Y-%m-%d') > '2026-02-20'
   OR STR_TO_DATE(NULLIF(TRIM(ServiceEndDate), ''), '%Y-%m-%d') < '2008-01-01';

#Looking at the fields that system flagged as problematic decided to also flag tem

SELECT DISTINCT BillAnalyzed, COUNT(*)
FROM waterconsumptionstaging3 w 
GROUP BY BillAnalyzed

SELECT *
FROM waterconsumptionstaging3 w 
WHERE BillAnalyzed = 'Exception'

#Checking for mistakes on references fields 

SELECT DISTINCT TDSNum FROM waterconsumptionstaging3 LIMIT 20;
SELECT DISTINCT EDP FROM waterconsumptionstaging3 LIMIT 20;
SELECT DISTINCT RCCode FROM waterconsumptionstaging3 LIMIT 20;
SELECT DISTINCT AMPNum FROM waterconsumptionstaging3 LIMIT 20;

SELECT COUNT(*)
FROM waterconsumptionstaging3 w 
WHERE TDSNum = '#N/A'

SELECT *
FROM waterconsumptionstaging3 w 
WHERE TDSNum = '#N/A'

SELECT DISTINCT MeterAMR 
FROM waterconsumptionstaging3 w 

#create final table 

CREATE TABLE WaterConsumption (
    SurrogateID         INT             AUTO_INCREMENT PRIMARY KEY,
    UMISBILLID          BIGINT,
    DevelopmentName     VARCHAR(200),
    Borough             VARCHAR(50)     NOT NULL,
    AccountName         VARCHAR(200),
    Location            VARCHAR(200),
    MeterAMR            VARCHAR(20),
    MeterScope          VARCHAR(100),
    MeterNumber         VARCHAR(50),
    TDSNum				INT,
    RevenueMonth        DATE            NOT NULL,
    ServiceStartDate    DATE,
    ServiceEndDate      DATE,
    IsEstimated         VARCHAR(10),
    RateClass           VARCHAR(60),
    ConsumptionHCF      FLOAT,
    CurrentCharges      DECIMAL(14,2)   NOT NULL,
    WaterAndSewer       DECIMAL(14,2),
    OtherCharges        DECIMAL(14,2),
    FundingSource       VARCHAR(50),
    RevenueYear         INT,
    RevenueMonthNum     INT,
    BillAnalyzed		VARCHAR(50),
    DataQualityFlag     VARCHAR(100)
);

#insert data from staging table into real table, creating data flag column and 
#splitting revenue year and revenue month. Also, removing numdays as it can be calculated
# from the service start/end date and contained some errors 

INSERT INTO wateranalysisnycrawdata.waterconsumption (
    UMISBILLID, DevelopmentName, Borough, AccountName,
    Location, MeterAMR, MeterScope, MeterNumber, TDSNum,
    RevenueMonth, ServiceStartDate, ServiceEndDate,
    IsEstimated, RateClass, ConsumptionHCF,
    CurrentCharges, WaterAndSewer, OtherCharges,
    FundingSource, RevenueYear, RevenueMonthNum,
    BillAnalyzed, DataQualityFlag
)
SELECT
    NULLIF(TRIM(UMISBILLID), ''),
    NULLIF(TRIM(DevelopmentName), ''),
    NULLIF(TRIM(Borough), ''),
    NULLIF(TRIM(AccountName), ''),
    NULLIF(TRIM(Location), ''),
    NULLIF(TRIM(MeterAMR), ''),
    NULLIF(NULLIF(TRIM(MeterScope), ''), 'NA'),
    NULLIF(TRIM(MeterNumber), ''),
    CASE
        WHEN TRIM(TDSNum) = '#N/A' THEN NULL
        ELSE NULLIF(TRIM(TDSNum), '')
    END,
    RevenueMonth,
    CASE
        WHEN ServiceStartDate > '2026-12-31'
          OR ServiceStartDate < '2008-01-01'
            THEN NULL
        ELSE ServiceStartDate
    END,
    CASE
        WHEN ServiceEndDate > '2026-12-31'
          OR ServiceEndDate < '2008-01-01'
            THEN NULL
        ELSE ServiceEndDate
    END,
    NULLIF(TRIM(Estimated), ''),
    NULLIF(TRIM(RateClass), ''),
    CAST(NULLIF(TRIM(ConsumptionHCF), '') AS DECIMAL(14,2)),
    CAST(REPLACE(REPLACE(NULLIF(TRIM(CurrentCharges), ''), '$', ''), ',', '') AS DECIMAL(14,2)),
    CAST(REPLACE(REPLACE(NULLIF(TRIM(WaterAndSewer), ''), '$', ''), ',', '') AS DECIMAL(14,2)),
    CAST(REPLACE(REPLACE(NULLIF(TRIM(OtherCharges), ''), '$', ''), ',', '') AS DECIMAL(14,2)),
    NULLIF(TRIM(FundingSource), ''),
    YEAR(RevenueMonth),
    MONTH(RevenueMonth),
    NULLIF(TRIM(BillAnalyzed), ''),
    CASE
        WHEN ServiceStartDate > '2026-12-31'
          OR ServiceStartDate < '2008-01-01'
          OR ServiceEndDate > '2026-12-31'
          OR ServiceEndDate < '2008-01-01'
            THEN 'Invalid date'
        WHEN ServiceEndDate < ServiceStartDate
            THEN 'Negative service days'
        WHEN TRIM(BillAnalyzed) = 'Exception'
            THEN 'Billing exception'
        WHEN (Location IS NULL OR TRIM(Location) = '')
          AND MeterAMR = 'AMR'
            THEN 'Missing location'
        WHEN (RateClass IS NULL OR TRIM(RateClass) = '')
            THEN 'Missing rate class'
        ELSE 'OK'
    END
FROM waterconsumptionstaging3;

#Final data checks to see if it had been inserted properply, checking for nulls, counts and date borders

SELECT COUNT(*) AS StagingRows
FROM waterconsumptionstaging3;

SELECT COUNT(*) AS FinalRows
FROM waterconsumption;

SELECT
    SUM(CASE WHEN Borough IS NULL THEN 1 ELSE 0 END)         AS NullBorough,
    SUM(CASE WHEN RevenueMonth IS NULL THEN 1 ELSE 0 END)    AS NullRevenueMonth,
    SUM(CASE WHEN CurrentCharges IS NULL THEN 1 ELSE 0 END)  AS NullCurrentCharges
FROM waterconsumption;
	
SELECT
    DataQualityFlag,
    COUNT(*) AS Count
FROM waterconsumption
GROUP BY DataQualityFlag
ORDER BY Count DESC;

SELECT
    MIN(CurrentCharges)    AS MinCharge,
    MAX(CurrentCharges)    AS MaxCharge,
    AVG(CurrentCharges)    AS AvgCharge,
    COUNT(*)               AS TotalRows
FROM waterconsumption
WHERE CurrentCharges IS NOT NULL;


SELECT
    MIN(RevenueMonth)       AS EarliestRevenue,
    MAX(RevenueMonth)       AS LatestRevenue,
    MIN(ServiceStartDate)   AS EarliestStart,
    MAX(ServiceStartDate)   AS LatestStart
FROM waterconsumption;

SELECT *
FROM waterconsumption w 
ORDER BY w.CurrentCharges DESC
LIMIT 50;

SELECT
    AVG(CurrentCharges) AS AvgMonthlyCharge
FROM waterconsumption
WHERE ServiceStartDate IS NOT NULL
  AND DATEDIFF(ServiceEndDate, ServiceStartDate) < 334;

SELECT *
FROM waterconsumption w 
ORDER BY w.CurrentCharges ASC
LIMIT 50;

SELECT
    RevenueYear,
    RevenueMonthNum,
    COUNT(*) AS Count
FROM waterconsumption
GROUP BY RevenueYear, RevenueMonthNum
ORDER BY RevenueYear, RevenueMonthNum
LIMIT 10;
