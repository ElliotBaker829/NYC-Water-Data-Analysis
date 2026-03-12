# NYC-Water-Data-Analysis
Cleaning and analysing the NYCHA Open Water Data, analyzing problems with the dataset, and trends in revenue and consumption. 

## Project Background

NYC tracks water consumption and cost data from January 2013 to May 2025, covering all five boroughs of New York (Bronx, Brooklyn, Queens, Manhattan, Staten Island). This data breaks down use by specific development and individual meter locations. This project aims to establish estimated vs. actual meter reading accuracy, as well as consumption and revenue trends.

The analysis identified two primary areas of concern: revenue anomalies caused by inaccurate estimated bills and a consumption decline that varies depending on the per-meter control. These findings align with a 2024 meter rollout by the NYCHA.
Analysis was performed on the following topics, by borough, development, and throughout the years. 

* Consumption
* Revenue
* Active meters
* Water rates per consumption 
* Estimated vs actual meter readings 


## Process

### Cleaning 

When the data was imported, a raw table was created with VARCHAR(50) and manually checked for mapping to ensure all columns were imported correctly.
A staging table was used before the data was imported into a new table.
​Evaluating duplicates, standardizing, removing unnecessary columns or rows, and investigating NULL or blank values comprised the cleaning process. Possible reasons for these unclean values were investigated at the same time. If blanks were the result of potential errors, they were marked for data flag creation later. If they were not errors, but just rows with intended blanks, they were updated with NULL.

Strip currency formatting before casting:
```SQL
CAST(REPLACE(REPLACE(NULLIF(TRIM(CurrentCharges), ''), '$', ''), ',', '') AS DECIMAL(14,2))
```
Handle Excel #N/A errors
```SQL
CASE WHEN TRIM(TDSNum) = '#N/A' THEN NULL ELSE NULLIF(TRIM(TDSNum), '') END
```
Replace impossible dates with NULL
```SQL
CASE
   WHEN ServiceStartDate > '2026-12-31' OR ServiceStartDate < '2008-01-01' THEN NULL
   ELSE ServiceStartDate
END
```
A finished table was created, taking more care to correctly identify data types for each column. The staging data was inserted into the new table, with dates or integers being converted from strings at this time. Unnecessary columns (Numdays that could be calculated from existing columns but contained incorrectly calculated values) were removed, and new columns were added (splitting dates into year and month). One such created column was the data flag column, which flagged acceptable values as ‘OK’ and raised errors, such as invalid dates or billing exceptions that were raised in the original data. 
```SQL
CASE
   WHEN ServiceStartDate > '2026-12-31' OR ServiceEndDate < '2008-01-01' THEN 'Invalid date'
   WHEN ServiceEndDate < ServiceStartDate                                 THEN 'Negative service days'
   WHEN TRIM(BillAnalyzed) = 'Exception'                                 THEN 'Billing exception'
   WHEN (Location IS NULL OR TRIM(Location) = '') AND MeterAMR = 'AMR'   THEN 'Missing location'
   WHEN RateClass IS NULL OR TRIM(RateClass) = ''                        THEN 'Missing rate class'
   ELSE 'OK'
END
```

### Analysis

Analysis focused on revenue and consumption, trying to find trends. Total revenue by borough and year was looked at. A noticeable jump was observed in 2021 across all boroughs. Further inspection revealed this was caused by an increase in annual fixed-charge rows (Bills that covered 334-365 days). From this, it was decided to further separate the data into monthly and annual billing, as this distorted trends. 
```SQL
CASE
   WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
   ELSE 'Monthly'
END AS BillingType
````
The water rate per consumption by borough and year  was calculated while filtering for monthly rows. Spikes were seen in 2021-22. Including IsEstimated revealed that in specific months, estimated bills and actual readings showed huge discrepancies in the same borough and time. WaterAndSewer was used throughout, as CurrentCharges would affect the per consumption calculations due to credits and adjustments.
```SQL
SELECT RevenueYear, RevenueMonthNum, IsEstimated,
   ROUND(SUM(WaterAndSewer) / NULLIF(SUM(ConsumptionHCF), 0), 2) AS RatePerHCF
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
 AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
 AND Borough = 'MANHATTAN'
 AND RevenueYear BETWEEN 2020 AND 2022
GROUP BY RevenueYear, RevenueMonthNum, IsEstimated
ORDER BY RevenueYear DESC, RevenueMonthNum DESC;
```

To further investigate the anomaly, each estimated row was compared against a borough-level actual rate to compare the excess.
```SQL
SELECT w.Borough, w.DevelopmentName, w.RevenueYear, w.RevenueMonthNum,
   ROUND(SUM(w.WaterAndSewer) / NULLIF(SUM(w.ConsumptionHCF), 0), 2) AS EstimatedRatePerHCF,
   ROUND(AVG(b.AvgActualRate), 2)                                     AS NormalBoroughRate,
   ROUND((SUM(w.WaterAndSewer) / NULLIF(SUM(w.ConsumptionHCF), 0))
       - AVG(b.AvgActualRate), 2)                                     AS ExcessRatePerHCF,
   ROUND(((SUM(w.WaterAndSewer) / NULLIF(SUM(w.ConsumptionHCF), 0))
       - AVG(b.AvgActualRate)) * SUM(w.ConsumptionHCF), 2)           AS ExcessChargeTotal
FROM waterconsumption w
JOIN (
   SELECT Borough, RevenueYear,
       ROUND(SUM(WaterAndSewer) / NULLIF(SUM(ConsumptionHCF), 0), 2) AS AvgActualRate
   FROM waterconsumption
   WHERE DataQualityFlag = 'OK'
     AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
     AND IsEstimated = 'N' AND ConsumptionHCF > 0
   GROUP BY Borough, RevenueYear
) b ON w.Borough = b.Borough AND w.RevenueYear = b.RevenueYear
WHERE w.IsEstimated = 'Y' AND w.ConsumptionHCF > 0
GROUP BY w.Borough, w.DevelopmentName, w.RevenueYear, w.RevenueMonthNum
HAVING EstimatedRatePerHCF > (NormalBoroughRate * 3)
ORDER BY ExcessChargeTotal DESC;
```
Consumption was investigated by controlling for distinct meter count 
```SQL
SELECT Borough, RevenueYear,
   ROUND(SUM(ConsumptionHCF) / NULLIF(COUNT(DISTINCT MeterNumber), 0), 0) AS HCFPerMeter
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
 AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
 AND RevenueYear NOT IN (2024, 2025)
 AND Borough NOT IN ('STATEN ISLAND', 'FHA')
GROUP BY Borough, RevenueYear
ORDER BY Borough, RevenueYear;
```

## Dataset

The data used is the NYCHA Water Consumption dataset from NYC Open Data, covering January 2023 to May 2025.



### Excluded: 
Annual billing charges (+334 days from service start to service end): predominantly monthly charges, adding annual distortions to consumption and revenue figures.
State Island: insufficient monthly data for trend analysis
FHA: not based on geographic borough, contained hundreds of developments with no clear geographic marker that would have taken a long time to assign.
2025: year not finished at the time of data collection, so could not accurately be used to compare with others




## DASHBOARD

Consumption Trends - Total consumption, active meters, and consumption per meter by borough. 




Billing Anomalies - Estimated vs. actual rate comparison, high charge events, excess charge by development



Revenue & Rates - Water revenue trends, rate per consumption over time with a snapshot comparison of 2014, 2019, 2023 



Consumption by Development - Select developments specifically to see more information on bill history, meter count and rate over time



## Tools

MySQL: Data cleaning and analytical queries.
Power BI + DAX: Four-page interactive dashboard showing consumption trends, billing anomalies, revenue & rate and exploration by development. DAX measures to show rate

## Repository Structure

## How To Run
Download the NYCHA Water Consumption dataset from NYC Open Data and import into MySQL
Run NYCWaterCleaning.sql to create the waterconsumption table
Run NYCWaterRevenueAnalysis.sql and NYCWaterConsumptionAnalysis.sql to check for trends

## Findings

### Estimated billing of up to 47x the actual rate

Manhattan July 2021 showed a 47 times larger estimated rate of $718.70/HCF against an actual rate of $15.29/HCF. One Manhattan development, UPACA, generated $312,511 in excess charges in a single month. The highest total excess charges of any development, Reid Apartments in Brooklyn, were systematically overbilled over 4 consecutive years.

### Revenue remained stable despite falling consumption

Despite falling consumption rates, total revenue remained stable due to increasing rates. The water rate per HCF rose 52% in Manhattan between 2014 and 2023. Rate spikes in 2021-22 can be attributed to estimated billing anomalies. Although consumption declined across all boroughs since 2013, Queens showed the steepest decline per meter.

### January 2024 rate class transition caused redistribution of revenue percentages 

Rate classes were changed from Basic Water and Sewer to new MWW rate classes in January 2024. These changes caused individual developments to fluctuate in revenue. 
Union Avenue (Bronx): -66% (-$149,298)
UPACA Site 5 (Manhattan):  -33% (-$113,318)
West Farms Road Rehab (Bronx):  -15% (-$53,683)

Since the full 2025 year data had not been recorded at this time, the full effects are yet to be observed. 


