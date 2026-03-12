# Which developments have unexplained consumption spikes

SELECT Borough, RevenueYear, SUM(consumptionHCF) AS TotalConsumed
FROM waterconsumption w 
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 AND ServiceStartDate IS NOT NULL
GROUP BY Borough, RevenueYear
ORDER BY Borough, RevenueYear DESC;

#Looked at highest consumption, found that manhattan consistently had the most


SELECT Borough, RevenueYear, SUM(consumptionHCF) AS TotalConsumed
FROM waterconsumption w 
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND ServiceStartDate IS NOT NULL AND RevenueYear >= 2021
GROUP BY Borough, RevenueYear
ORDER BY totalconsumed DESC
LIMIT 10;

#Looked at the consumption per month to see the trends within years, found no obvious spikes

SELECT Borough, RevenueYear, RevenueMonthNum, SUM(consumptionHCF) AS TotalConsumed
FROM waterconsumption w 
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND ServiceStartDate IS NOT NULL
GROUP BY Borough, RevenueYear, RevenueMonthNum
ORDER BY Borough, RevenueYear DESC;

#Looked at revenue per consumption, found spikes in 2021-22 across multiple 
#boroughs which is different to the expected stable trend


SELECT Borough, RevenueYear, SUM(CurrentCharges) AS Revenue, SUM(consumptionHCF), 
  ROUND(SUM(CurrentCharges)/NULLIF(SUM(consumptionHCF),0),2) AS RevenuePerHCF
FROM waterconsumption
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND ServiceStartDate IS NOT NULL AND RevenueYear != 2025
GROUP BY Borough, RevenueYear
ORDER BY Borough, RevenueYear DESC;

#Looked further at the spikes, suspected rate class changes could be causing it
#as identified rate class changes around this time previously

SELECT RevenueYear, RevenueMonthNum, 
  ROUND(SUM(CurrentCharges)*1.0/NULLIF(SUM(consumptionHCF),0),2) AS RevenuePerHCF, 
  RateClass, SUM(CurrentCharges) AS Revenue, SUM(consumptionHCF)
FROM waterconsumption
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND ServiceStartDate IS NOT NULL AND (RevenueYear >= 2020 AND RevenueYear <= 2022) 
  AND Borough = 'MANHATTAN'
GROUP BY RevenueYear, RevenueMonthNum, RateClass
ORDER BY RevenueYear DESC, RevenueMonthNum DESC;

#Looked at IsEstimated, found that the spike is caused by estimated bills
#where as actual readings remain stable (which was to be expected)


SELECT RevenueYear, RevenueMonthNum, IsEstimated,
  ROUND(SUM(CurrentCharges)/NULLIF(SUM(consumptionHCF),0),2) AS RevenuePerHCF, 
  RateClass, SUM(CurrentCharges) AS Revenue, SUM(consumptionHCF)
FROM waterconsumption
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND ServiceStartDate IS NOT NULL AND (RevenueYear >= 2020 AND RevenueYear <= 2022) 
  AND Borough = 'MANHATTAN' AND IsEstimated IS NOT NULL
GROUP BY RevenueYear, RevenueMonthNum, RateClass, IsEstimated 
ORDER BY RevenueYear DESC, RevenueMonthNum DESC;

#Looked at the full dataset and looked for highest revenue per consumption, found that
#manhattan one specific development to investigate, TWIN PARKS EAST (SITE 9) development 


SELECT Borough, DevelopmentName, RevenueYear, RevenueMonthNum, IsEstimated,
  ROUND(SUM(CurrentCharges)/NULLIF(SUM(consumptionHCF),0),2) AS RevenuePerHCF, 
  SUM(CurrentCharges) AS Revenue, SUM(consumptionHCF)
FROM waterconsumption
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND ServiceStartDate IS NOT NULL AND IsEstimated IS NOT NULL
GROUP BY RevenueYear, RevenueMonthNum, Borough, DevelopmentName, IsEstimated 
ORDER BY RevenuePerHCF DESC, IsEstimated;

#Found an extreme different in waterandsewer compared to consumption
#high water charge driving the rate spike

SELECT RevenueYear, RevenueMonthNum, CurrentCharges, WaterAndSewer, 
  OtherCharges, w.ConsumptionHCF 
FROM waterconsumption w 
WHERE DevelopmentName = 'TWIN PARKS EAST (SITE 9)' 
  AND RevenueYear = 2023 AND RevenueMonthNum = 3;

#Looked at the full history for this development and found the spike to only be present in certain months


SELECT RevenueYear, RevenueMonthNum, CurrentCharges, WaterAndSewer, 
  OtherCharges, w.ConsumptionHCF 
FROM waterconsumption w 
WHERE DevelopmentName = 'TWIN PARKS EAST (SITE 9)'
ORDER BY RevenueYear ASC, RevenueMonthNum ASC;

#Decided to switch to WaterAndSewer per consumption as currentcharges includes credits, adjustments and penalties which 
#can be very unpredictable


SELECT Borough, RevenueYear, RevenueMonthNum, 
  ROUND(SUM(WaterAndSewer)/NULLIF(SUM(consumptionHCF),0),2) AS WaterPerHCF, 
  SUM(WaterAndSewer) AS WaterAndSewer, SUM(consumptionHCF)
FROM waterconsumption
WHERE DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND ServiceStartDate IS NOT NULL AND RevenueYear != 2025
GROUP BY Borough, RevenueYear, RevenueMonthNum
ORDER BY Borough, RevenueYear DESC, RevenueMonthNum DESC;

#Looked at meter count vs. total consumption to check whether consumption decline
#could be caused by declining meters


SELECT RevenueYear, Borough, COUNT(DISTINCT MeterNumber), SUM(w.ConsumptionHCF)
FROM waterconsumption w
WHERE w.DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  AND w.ConsumptionHCF IS NOT NULL AND RevenueYear != 2025
GROUP BY RevenueYear, Borough
ORDER BY Borough, RevenueYear ASC;

#Calculated consumptino per meter to control for meter count changes, 
#Queen shows a genuine decline but Manhattan remianed stable 


SELECT RevenueYear, Borough, 
  ROUND(AVG(x.totalconsum / x.nummeternum),2) AS ConsumptionPerMeter
FROM (
  SELECT RevenueYear, Borough, 
    COUNT(DISTINCT MeterNumber) AS NumMeterNum, 
    SUM(w.ConsumptionHCF) TotalConsum
  FROM waterconsumption w
  WHERE w.DataQualityFlag = 'OK' AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
    AND w.ConsumptionHCF IS NOT NULL AND RevenueYear != 2025
  GROUP BY RevenueYear, Borough
) x
GROUP BY RevenueYear, Borough
ORDER BY Borough, RevenueYear ASC;

#Looked at meter count by billing type to confirm the 2024 roll out of new meters
#found that active meters doubled in every borough in 2024, decided to exclude from trend analysis


SELECT RevenueYear, 
  CASE WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
    THEN 'Monthly' ELSE 'Annual' END AS BillingType,
  COUNT(DISTINCT MeterNumber)
FROM waterconsumption w 
WHERE w.DataQualityFlag = 'OK' AND w.ConsumptionHCF IS NOT NULL AND RevenueYear != 2025
GROUP BY CASE WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 
  THEN 'Monthly' ELSE 'Annual' END, RevenueYear
ORDER BY RevenueYear DESC;

#Looked at the normal rate range using actual readings, found it to be $10-22 per consumption
#Used this to identify anamalous bills


SELECT Borough, RevenueYear,
  ROUND(AVG(WaterAndSewer / ConsumptionHCF), 2) AS AvgRatePerHCF,
  ROUND(MIN(WaterAndSewer / ConsumptionHCF), 2) AS MinRate,
  ROUND(MAX(WaterAndSewer / ConsumptionHCF), 2) AS MaxRate
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
  AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
  AND IsEstimated = 'N'
  AND ConsumptionHCF > 0
  AND ServiceStartDate IS NOT NULL
GROUP BY Borough, RevenueYear
ORDER BY Borough, RevenueYear;

#Check full data for anomalous bills and high excess charges found UPACA Site 6 Manhattan, July 2021 to have
#an incredibly high excess charge of $312,511, also found that 
#Reid apartments appears frequently for anomalous charges


SELECT 
  w.Borough, w.DevelopmentName, w.RevenueYear, w.RevenueMonthNum,
  ROUND(SUM(w.WaterAndSewer) / NULLIF(SUM(w.ConsumptionHCF), 0), 2) AS EstimatedRatePerHCF,
  ROUND(AVG(b.AvgActualRate), 2) AS NormalBoroughRate,
  ROUND(SUM(w.WaterAndSewer) / NULLIF(SUM(w.ConsumptionHCF), 0) - AVG(b.AvgActualRate), 2) AS ExcessRatePerHCF,
  ROUND((SUM(w.WaterAndSewer) / NULLIF(SUM(w.ConsumptionHCF), 0) - AVG(b.AvgActualRate)) 
    * SUM(w.ConsumptionHCF), 2) AS ExcessChargeTotal
FROM waterconsumption w
JOIN (
  SELECT Borough, RevenueYear,
    ROUND(SUM(WaterAndSewer) / NULLIF(SUM(ConsumptionHCF), 0), 2) AS AvgActualRate
  FROM waterconsumption
  WHERE DataQualityFlag = 'OK'
    AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
    AND IsEstimated = 'N'
    AND ConsumptionHCF > 0
    AND ServiceStartDate IS NOT NULL
  GROUP BY Borough, RevenueYear
) b ON w.Borough = b.Borough AND w.RevenueYear = b.RevenueYear
WHERE w.DataQualityFlag = 'OK'
  AND DATEDIFF(w.ServiceEndDate, w.ServiceStartDate) <= 334
  AND w.IsEstimated = 'Y'
  AND w.ConsumptionHCF > 0
  AND w.ServiceStartDate IS NOT NULL
GROUP BY w.Borough, w.DevelopmentName, w.RevenueYear, w.RevenueMonthNum
HAVING EstimatedRatePerHCF > (NormalBoroughRate * 3)
ORDER BY ExcessChargeTotal DESC;

#Looked at the revenue impact of the 2024 rate class transition
#found Union Avenue top decline by -66% (-$149,298) and top increase West Farms Road 15% (+$53,683)


SELECT
  DevelopmentName, Borough,
  SUM(CASE WHEN RevenueYear = 2023 THEN WaterAndSewer ELSE 0 END) AS Revenue2023,
  SUM(CASE WHEN RevenueYear = 2024 THEN WaterAndSewer ELSE 0 END) AS Revenue2024,
  ROUND(SUM(CASE WHEN RevenueYear = 2024 THEN WaterAndSewer ELSE 0 END) -
    SUM(CASE WHEN RevenueYear = 2023 THEN WaterAndSewer ELSE 0 END), 2) AS RevenueChange,
  ROUND(((SUM(CASE WHEN RevenueYear = 2024 THEN WaterAndSewer ELSE 0 END) -
    SUM(CASE WHEN RevenueYear = 2023 THEN WaterAndSewer ELSE 0 END)) /
    NULLIF(SUM(CASE WHEN RevenueYear = 2023 THEN WaterAndSewer ELSE 0 END), 0)) * 100, 2) AS PctChange,
  MAX(CASE WHEN RevenueYear = 2023 THEN RateClass END) AS RateClass2023,
  MAX(CASE WHEN RevenueYear = 2024 THEN RateClass END) AS RateClass2024
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
  AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
  AND ServiceStartDate IS NOT NULL
  AND RevenueYear IN (2023, 2024)
GROUP BY DevelopmentName, Borough
HAVING Revenue2023 > 0 AND Revenue2024 > 0
ORDER BY RevenueChange ASC;

#Looked at water revenue and rate per consumption, found that Manhattan rose from 
# $14.68 (2014) to $22.46 (2023), 52% increase.


SELECT
  Borough, RevenueYear,
  ROUND(SUM(WaterAndSewer), 2) AS WaterRevenue,
  ROUND(SUM(CurrentCharges), 2) AS TotalRevenue,
  ROUND(SUM(WaterAndSewer) / NULLIF(SUM(ConsumptionHCF), 0), 2) AS WaterRatePerHCF
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
  AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
  AND ServiceStartDate IS NOT NULL
  AND RevenueYear NOT IN (2024, 2025)
  AND Borough NOT IN ('STATEN ISLAND', 'FHA')
GROUP BY Borough, RevenueYear
ORDER BY Borough, RevenueYear;

#Compared actual vs aestimated water rate per consumption found that they can vary wildly,
# Manhattan July 2021, Estimated $718.70/HCF vs Actual $15.29/HCF, a 47x difference

SELECT
  IsEstimated,
  ROUND(SUM(ConsumptionHCF), 2) AS ConsumptionHCF,
  ROUND(SUM(WaterAndSewer), 2) AS WaterRevenue,
  ROUND(SUM(WaterAndSewer) / NULLIF(SUM(ConsumptionHCF), 0), 2) AS RatePerHCF
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
  AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
  AND ServiceStartDate IS NOT NULL
  AND Borough = 'MANHATTAN'
  AND RevenueYear = 2021
  AND RevenueMonthNum = 7
GROUP BY IsEstimated
ORDER BY IsEstimated DESC;

#Looked further at Manhattan July 2021 by development to see which developments are leading in the 
#estimated vs actual billing anomalies, found UPACA Site 6 had the highest estimated rate per consumption
#by a lot


SELECT DevelopmentName, IsEstimated,
  ROUND(SUM(ConsumptionHCF), 2) AS ConsumptionHCF,
  ROUND(SUM(WaterAndSewer), 2) AS WaterRevenue,
  ROUND(SUM(WaterAndSewer) / NULLIF(SUM(ConsumptionHCF), 0), 2) AS RatePerHCF
FROM waterconsumption w 
WHERE DataQualityFlag = 'OK'
  AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334
  AND ServiceStartDate IS NOT NULL
  AND Borough = 'MANHATTAN'
  AND RevenueYear = 2021
  AND RevenueMonthNum = 7
GROUP BY w.Borough, DevelopmentName, w.IsEstimated  
ORDER BY RatePerHCF DESC;