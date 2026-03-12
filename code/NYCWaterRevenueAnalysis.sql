#Total revenue billed per borough per year, Found a huge jump in 2021 across most boroughs. Investigated this, based on the fact that there was a huge increase in charges based on annual 

SELECT
   Borough,
   RevenueYear,
   SUM(CurrentCharges)     AS TotalRevenue,
   COUNT(*)                AS BillingRows,
   AVG(CurrentCharges)     AS AvgBillPerRow
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
GROUP BY Borough, RevenueYear
ORDER BY Borough, RevenueYear;

#This shows that in 2021, there is a huge addition of annual bills that account for the increase in charges. Therefore, need to separate the monthly/annual billing type when comparing revenue across the 2020/21 barrier. 

SELECT
   RevenueYear,
   CASE
       WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334
           THEN 'Annual'
       ELSE 'Monthly'
   END AS BillingType,
   COUNT(*) AS RowCount,
   SUM(CurrentCharges) AS TotalRevenue
FROM waterconsumption
WHERE DataQualityFlag = 'OK'
 AND ServiceStartDate IS NOT NULL
GROUP BY RevenueYear,
   CASE
       WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334
           THEN 'Annual'
       ELSE 'Monthly'
   END
ORDER BY RevenueYear, BillingType;

#Saw that monthly is decreasing, while annual is increasing. Negative for staten island

SELECT Borough, RevenueYear, CASE
	WHEN DATEDIFF(ServiceEndDate, w.ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END AS BillingType, SUM(CurrentCharges) AS TotalReveue
FROM waterconsumption w
WHERE w.DataQualityFlag = 'OK' AND ServiceStartDate IS NOT NULL AND RevenueYear != 2025
GROUP BY Borough, RevenueYear,
	CASE
	WHEN DATEDIFF(ServiceEndDate, w.ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END
ORDER BY BillingType, Borough, RevenueYear ASC;

#looked at it further

SELECT *
FROM waterconsumption w
WHERE Location LIKE '%BLD 07%' AND Borough ='STATEN ISLAND' AND w.RevenueYear = 2023
ORDER BY RevenueMonthNum DESC;

#Which developments generate the most revenue annually? saw than Manhattan dominated

SELECT DevelopmentName, Borough, CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END AS BillingType, SUM(CurrentCharges) AS Revenue
FROM waterconsumption w
WHERE w.RevenueYear >= 2021 AND DataQualityFlag = 'OK'
GROUP BY CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END,
DevelopmentName, Borough
ORDER BY SUM(CurrentCharges) DESC
LIMIT 10;

#Looked at monthly only, found that south jamaica was number 1 by quite a large margin so investigated further, more even distribution but manhattan still dominates


SELECT DevelopmentName, Borough, CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END AS BillingType, SUM(CurrentCharges) AS Revenue
FROM waterconsumption w
WHERE w.RevenueYear >= 2021 AND DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 AND DataQualityFlag = 'OK'
GROUP BY CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END,
DevelopmentName, Borough
ORDER BY SUM(CurrentCharges) DESC
LIMIT 10;

# Checked the history for south jamaica II in more detail, seen a slight decline in revenue in 2024

SELECT RevenueYear, CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END AS BillingType, SUM(CurrentCharges) AS Revenue
FROM waterconsumption w
WHERE w.DevelopmentName = 'SOUTH JAMAICA II'
GROUP BY CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END ,RevenueYear
ORDER BY RevenueYear DESC;

#Thought this decline in revenue might be caused by an decrease in meters but actually saw an increase in meters which wasnt expected so investigated further

SELECT RevenueYear, CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END AS BillingType, COUNT(DISTINCT MeterNumber)
FROM waterconsumption w
WHERE w.DevelopmentName = 'SOUTH JAMAICA II'
GROUP BY CASE
	WHEN DATEDIFF(ServiceEndDate, ServiceStartDate) >= 334 THEN 'Annual'
	ELSE 'Monthly'
END, RevenueYear
ORDER BY RevenueYear DESC;

#Saw a change in rateclass over this period, which could explain the decrease in revenue 

SELECT RevenueYear, RateClass, COUNT(*)
FROM waterconsumption w
WHERE w.DevelopmentName = 'SOUTH JAMAICA II'
GROUP BY w.DevelopmentName, RateClass, RevenueYear
ORDER BY RevenueYear DESC;

#What is the average monthly per development and how does it differ per borough? Saw that manhattan dominates 

SELECT x.Borough, x.DevelopmentName, AVG(x.MonthlyTotal)
FROM (SELECT Borough, DevelopmentName, SUM(CurrentCharges) AS MonthlyTotal
		FROM waterconsumption w
		WHERE DATEDIFF(ServiceEndDate, ServiceStartDate) <= 334 AND DataQualityFlag = 'OK' AND RevenueYear >= 2021
		GROUP BY DevelopmentName, Borough, RevenueMonthNum) x
GROUP BY x.borough, x.developmentname
ORDER BY Borough, AVG(MonthlyTotal) DESC
