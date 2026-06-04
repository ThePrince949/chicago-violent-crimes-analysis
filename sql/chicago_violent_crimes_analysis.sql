

----------------------------------------------------------- Chicago Crime Data - Violent Crime Analysis --------------------------------------------------
-- Project: Chicago Violent Crimes Analysis
-- Purpose: SQL analysis supporting Power BI dashboard and R visualizations
-- Tools: SQL Server, R, Bpower BI
-- Dataset: Chicago crime recordeds filtered to violent crime categories
-- Types of crime included (violent crime):
	-- Assault
	-- Battery
	-- Homicide
	-- Robbery
	-- Weapons Violation
-- Time Period
	-- 01/01/2025 - 05/15/2026






----------------------------------------------- Database Creation -----------------------------------------------

CREATE DATABASE chicago_crimes;

USE chicago_crimes;


----------------------------------------------- Database Analysis -----------------------------------------------
--#######
--#######
--#######
----------------------------------------------- Temporal Analysis -----------------------------------------------

-- Total violent crime (from 2025/01/01 - 2026/05/15)
SELECT 
	COUNT(*) AS [Total Crimes Committed]
FROM dbo.chicago_crime_data;


-- Violent crime level per month
SELECT
	YEAR(Date) AS [Year],
	MONTH(Date) AS [Month],
	COUNT(*) AS [Total Crimes Committed]
FROM dbo.chicago_crime_data
GROUP BY
	YEAR(Date),
	MONTH(Date)
ORDER BY
	YEAR(Date),
	MONTH(Date);


-- Violent crime level per day of month (i.e. 15th of Jan, 15th of Feb, etc.)
SELECT
	YEAR(Date) AS [Year],
	MONTH(Date) AS [Month],
	DAY(Date) AS [Day of Month],
	COUNT(*) AS [Total Crimes Committed]
FROM dbo.chicago_crime_data
GROUP BY
	YEAR(Date),
	MONTH(Date),
	DAY(Date)
ORDER BY 
	YEAR(Date) ASC,
	MONTH(Date) ASC,
	DAY(Date) ASC;  


-- Violent crime level per hour
WITH CrimeCountPerHour AS (                                                       --- Extract hour of crime and count of crime per hour
	SELECT
		Date AS [Date],
		DATEPART(hour, Time) AS [Hour of Crime],
		COUNT(*) AS [Total Count of Crimes]
	FROM dbo.chicago_crime_data
	GROUP BY 
		Date,
		DATEPART(hour, Time)
),

HourClass AS (                                                                    --- Create "time bucket" for each hour 
	SELECT
		[Hour of Crime],
		[Total Count of Crimes],
		CASE 
			 WHEN [Hour of Crime] = 0 THEN '00:00 - 00:59'
			 WHEN [Hour of Crime] = 1 THEN '01:00 - 01:59'
			 WHEN [Hour of Crime] = 2 THEN '02:00 - 02:59'
			 WHEN [Hour of Crime] = 3 THEN '03:00 - 03:59'
			 WHEN [Hour of Crime] = 4 THEN '04:00 - 04:59'
			 WHEN [Hour of Crime] = 5 THEN '05:00 - 05:59'
			 WHEN [Hour of Crime] = 6 THEN '06:00 - 06:59'
			 WHEN [Hour of Crime] = 7 THEN '07:00 - 07:59'
			 WHEN [Hour of Crime] = 8 THEN '08:00 - 08:59'
			 WHEN [Hour of Crime] = 9 THEN '09:00 - 09:59'
			 WHEN [Hour of Crime] = 10 THEN '10:00 - 10:59'
			 WHEN [Hour of Crime] = 11 THEN '11:00 - 11:59'
			 WHEN [Hour of Crime] = 12 THEN '12:00 - 12:59'
			 WHEN [Hour of Crime] = 13 THEN '13:00 - 13:59'
			 WHEN [Hour of Crime] = 14 THEN '14:00 - 14:59'
			 WHEN [Hour of Crime] = 15 THEN '15:00 - 15:59'
			 WHEN [Hour of Crime] = 16 THEN '16:00 - 16:59'
			 WHEN [Hour of Crime] = 17 THEN '17:00 - 17:59'
			 WHEN [Hour of Crime] = 18 THEN '18:00 - 18:59'
			 WHEN [Hour of Crime] = 19 THEN '19:00 - 19:59'
			 WHEN [Hour of Crime] = 20 THEN '20:00 - 20:59'
			 WHEN [Hour of Crime] = 21 THEN '21:00 - 21:59'
			 WHEN [Hour of Crime] = 22 THEN '22:00 - 22:59'
			 WHEN [Hour of Crime] = 23 THEN '23:00 - 23:59'
		END AS [Time Interval]
	FROM CrimeCountPerHour
)

SELECT
	[Time Interval],
	SUM([Total Count of Crimes]) AS [Count of Crimes]
FROM HourClass
GROUP BY [Time Interval]
ORDER BY [Time Interval] ASC;


-- Violent crime level per day of the week
WITH CrimeLevelPerDayofWeek AS (                                -- extract day of week from date
	SELECT
		Date AS [Date],
		DATEPART(weekday, Date) AS [Day of Week],
		COUNT(*) AS [Total Count of Crimes]
	FROM dbo.chicago_crime_data
	GROUP BY 
		Date,
		DATEPART(WEEKDAY, Date)
),

WeekdayClass AS (                                              -- create day of week titles 
	SELECT
		[Day of Week],
		[Total Count of Crimes],
		CASE 
			WHEN [Day of Week] = 1 THEN 'Sunday'
			WHEN [Day of Week] = 2 THEN 'Monday'
			WHEN [Day of Week] = 3 THEN 'Tuesday'
			WHEN [Day of Week] = 4 THEN 'Wednesday'
			WHEN [Day of Week] = 5 THEN 'Thursday'
			WHEN [Day of Week] = 6 THEN 'Friday'
			WHEN [Day of Week] = 7 THEN 'Saturday'
		END AS [Weekday Name]
	FROM CrimeLevelPerDayofWeek
)

SELECT
	[Day of Week],
	[Weekday Name],
	SUM([Total Count of Crimes]) AS [Count of Crime]
FROM WeekdayClass
GROUP BY 
	[Day of Week],
	[Weekday Name]
ORDER BY [Day of Week] ASC;



----------------------------------------------- Hotspot Analysis -----------------------------------------------

-- Blocks with the highest amount of homicides
SELECT
	Block AS [Block],
	COUNT(*) AS [Total Homicides]
FROM dbo.chicago_crime_data
WHERE Primary_Type = 'Homicide'
GROUP BY [Block]
ORDER BY [Total Homicides] DESC;


-- Rank the blocks relative to the total amount of violent crime offences
SELECT
	Block AS [Block],
	COUNT(*) AS [Total Violent Crimes],
	RANK() OVER (
		ORDER BY COUNT(*) DESC 
		) [RANK]
FROM dbo.chicago_crime_data
GROUP BY [Block]
ORDER BY [Total Violent Crimes] DESC;


-- Which type of violent crime is most common in the top 5 blocks with the most violent crime offences
WITH TopFiveBlocks AS (                                                  -- Query top five blocks
	SELECT TOP 5
		Block AS [Block],
		COUNT(*) AS [Count of Violent Crimes],
		RANK() OVER (
		ORDER BY COUNT(*) DESC 
		) [RANK]
	FROM dbo.chicago_crime_data
	GROUP BY [Block]
	ORDER BY [Count of Violent Crimes] DESC
),

MostCommonViolentCrime AS (                                              -- Find counts of violent crimes
	SELECT 
		Block AS [Block],
		Primary_Type AS [Primary Type],
		COUNT(*) AS [Count of Primary Type]
	FROM dbo.chicago_crime_data
	WHERE Block IN (                                                     -- Filter so that only blocks in the TopFiveBlocks query are present
		SELECT 
			Block
		FROM TopFiveBlocks)
	GROUP BY 
		Block,
		Primary_Type
)

SELECT
	[Block],
	[Primary Type],
	[Count of Primary Type],
	RANK() OVER (
		PARTITION BY Block
		ORDER BY [Count of Primary Type] DESC
		) [RANK]
FROM MostCommonViolentCrime
ORDER BY 
	[Block] ASC,
	[Count of Primary Type] DESC;


-- Rank the community areas relative to the total amount of violent crime offences 
SELECT
	Community_Area AS [CommunityArea],                             -- Kept as camelcase for R integration 
	COUNT(*) AS [CountofViolentCrimes],
	RANK() OVER (
		ORDER BY COUNT(*) DESC 
		) AS [Rank]
FROM dbo.chicago_crime_data
GROUP BY [Community_Area]
ORDER BY [CountofViolentCrimes] DESC;


-- Which type of violent crime is most common in the top 5 community areas with the most violent crime offences
WITH TopFiveCommunityAreas AS (                                                  -- Query top five community areas
	SELECT TOP 5
		Community_Area AS [Community Area],
		COUNT(*) AS [Count of Violent Crimes],
		RANK() OVER (
		ORDER BY COUNT(*) DESC 
		) [RANK]
	FROM dbo.chicago_crime_data
	GROUP BY [Community_Area]
	ORDER BY [Count of Violent Crimes] DESC
),

MostCommonViolentCrime AS (                                                       -- Find counts of violent crimes
	SELECT 
		Community_Area AS [Community Area],
		Primary_Type AS [Primary Type],
		COUNT(*) AS [Count of Primary Type]
	FROM dbo.chicago_crime_data
	WHERE Community_Area IN (                                                     -- Filter so that only blocks in the TopFiveCommunityAreas query are present
		SELECT 
			[Community Area]
		FROM TopFiveCommunityAreas)
	GROUP BY 
		Community_Area,
		Primary_Type
)

SELECT
	[Community Area],
	[Primary Type],
	[Count of Primary Type],
	RANK() OVER (
		PARTITION BY [Community Area]
		ORDER BY [Count of Primary Type] DESC
		) [RANK]
FROM MostCommonViolentCrime
ORDER BY 
	[Community Area] ASC,
	[Count of Primary Type] DESC;



----------------------------------------------- Trend Acceleration Analysis -----------------------------------------------

-- Increase of overall crime rate (month-over-month)
WITH CrimeRateMoM AS (
	SELECT
		YEAR(Date) as [Year],
		MONTH(Date) AS [Month],
		COUNT(*) AS [Count of Violent Crimes],
		LAG(COUNT(*)) OVER (
			ORDER BY 
				YEAR(Date),
				MONTH(Date)
			) AS Previous_Month_Crime_Count
	FROM dbo.chicago_crime_data
	GROUP BY
		YEAR(Date),
		MONTH(Date)
),

MoMCalculated AS (
	SELECT
		[Year],
		[Month],
		[Count of Violent Crimes],
		[Previous_Month_Crime_Count],
		ROUND(
			(([Count of Violent Crimes] - Previous_Month_Crime_Count) / NULLIF(CAST(Previous_Month_Crime_Count AS FLOAT),0)) * 100, 3) AS MoM_Percent_Change
	FROM CrimeRateMoM
	WHERE Previous_Month_Crime_Count IS NOT NULL
)

SELECT
	[Year],
	[Month],
	[Count of Violent Crimes],
	Previous_Month_Crime_Count,
	MoM_Percent_Change
FROM MoMCalculated
ORDER BY
	[Year] ASC,
	[Month] ASC;


-- Crime acceleration per Block MoM
WITH BlockCrimeRateMoM AS (
	SELECT
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		Block AS [Block],
		COUNT(*) AS [Count of Violent Crime Per Block]
	FROM dbo.chicago_crime_data
	GROUP BY 
		YEAR(Date),
		MONTH(Date),
		Block
),

PreviousBlockCrimeCount AS (
	SELECT
		[Year],
		[Month],
		[Block],
		[Count of Violent Crime Per Block],
		LAG ([Count of Violent Crime Per Block]) OVER (
			PARTITION BY [Block]
			ORDER BY
				[Year],
				[Month]
			) AS Previous_Month_Block_Crime_Count
	FROM BlockCrimeRateMoM
),

MoMBlockCalculated AS (
	SELECT
		[Year],
		[Month],
		[Block],
		[Count of Violent Crime Per Block],
		Previous_Month_Block_Crime_Count,
		ROUND(
			(([Count of Violent Crime Per Block] - Previous_Month_Block_Crime_Count) / NULLIF(CAST(Previous_Month_Block_Crime_Count AS FLOAT)
			,0)) * 100, 3) AS MoM_Block_Percent_Change
		FROM PreviousBlockCrimeCount
		WHERE 
			Previous_Month_Block_Crime_Count IS NOT NULL
			AND Previous_Month_Block_Crime_Count >= 3                                     -- To make more analytically sound -- some blocks with 0 and 1 counts were causing sever outliers
)

SELECT
	[Year],
	[Month],
	[Block],
	[Count of Violent Crime Per Block],
	Previous_Month_Block_Crime_Count,
	MoM_Block_Percent_Change
FROM MoMBlockCalculated
ORDER BY
	[Year] ASC,
	[Month] ASC,
	MoM_Block_Percent_Change DESC;


-- Type of crime growth MoM
WITH CountOfTypes AS (
	SELECT
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		Primary_Type AS [Primary Type],
		COUNT(*) AS [Count of Primary Type]
	FROM dbo.chicago_crime_data
	GROUP BY
		YEAR(Date),
		MONTH(Date),
		Primary_Type
),

PreviousCountofTypes AS (
	SELECT
		[Year],
		[Month],
		[Primary Type],
		[Count of Primary Type],
		LAG([Count of Primary Type]) OVER (
			PARTITION BY [Primary Type]
			ORDER BY
				[Year],
				[Month]
		) AS Previous_Month_Count_Of_Crime_Types
	FROM CountofTypes
),

MoMCalculated AS (
	SELECT
		[Year],
		[Month],
		[Primary Type],
		[Count of Primary Type],
		Previous_Month_Count_Of_Crime_Types,
		ROUND(
		(([Count of Primary Type] - Previous_Month_Count_Of_Crime_Types) / NULLIF(CAST(Previous_Month_Count_Of_Crime_Types AS FLOAT)
		,0)) * 100, 3) AS MoM_Crime_Type_Percent_Change
	FROM PreviousCountofTypes
	WHERE Previous_Month_Count_Of_Crime_Types IS NOT NULL
)

SELECT
	[Year],
	[Month],
	CONCAT([Year], '-', RIGHT('00' + CAST([Month] AS VARCHAR(2)),2)) AS [MonthYear],
	[Primary Type],
	[Count of Primary Type],
	Previous_Month_Count_Of_Crime_Types,
	MoM_Crime_Type_Percent_Change
FROM MoMCalculated
ORDER BY
	[Year] ASC,
	[Month] ASC;


----------------------------------------------- Rolling Averages/Smoothing -----------------------------------------------

-- Is overall violence trending upward despite short-term fluctuations (i.e. calc rolling average to "cancel out noise")
WITH TotalViolentCrimeCount AS (
	SELECT
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		COUNT(*) AS [Total Violent Crime]
	FROM dbo.chicago_crime_data
	GROUP BY
		YEAR(Date),
		MONTH(Date)
),

RollingAverage AS (
	SELECT
		[Year],
		[Month],
		[Total Violent Crime],
		AVG(CAST([Total Violent Crime] AS FLOAT)) OVER (
			ORDER BY
				[Year],
				[Month]
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW                          -- Create a 3-row moving window (this row, and the 2 before it)
		) AS [Rolling Average]                                                -- January/February use fewer than 3 months because there aren't enough months yet (Jan uses 1 month, Feb uses 2)
	FROM TotalViolentCrimeCount
)

SELECT
	[Year],
	[Month],
	[Total Violent Crime],
	[Rolling Average]
FROM RollingAverage
WHERE NOT (
	([Year] = 2025 AND [Month] IN (1,2))                                       -- This excludes Jan/Feb 2025 (lack of prior data for 3-row moving average)
	OR
	([Year] = 2026 AND [Month] = 5)                                            -- This excludes May 2026 (don't have full month of data - skews average/creates outlier)
	)
ORDER BY
	[Year],
	[Month];


-- Which violent crime categories are persistently rising?
WITH TotalCrimeTypeCount AS (
	SELECT
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		Primary_Type AS [Primary Type],
		COUNT(*) AS [Count of Primary Type]
	FROM dbo.chicago_crime_data
	GROUP BY
		YEAR(Date),
		MONTH(Date),
		Primary_Type
),

RollingAverage AS (
	SELECT
		[Year],
		[Month],
		[Primary Type],
		[Count of Primary Type],
		AVG(CAST([Count of Primary Type] AS FLOAT)) OVER (
			PARTITION BY [Primary Type]
			ORDER BY
				[Year],
				[Month]
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		) AS [Rolling Average]
	FROM TotalCrimeTypeCount
)

SELECT
	[Year],
	[Month],
	[Primary Type],
	[Count of Primary Type],
	[Rolling Average]
FROM RollingAverage
WHERE NOT (
	([Year] = 2025 AND [Month] IN (1,2))                                         -- This excludes Jan/Feb 2025 (lack of prior data for 3-row moving average)
	OR
	([Year] = 2026 AND [Month] = 5)                                              -- This excludes May 2026 (don't have full month of data - skews average/creates outlier)
	)
ORDER BY
	[Year],
	[Month];


----------------------------------------------- Comparative Analysis -----------------------------------------------

-- Community area's share of total city violent crime
WITH TotalCityCrime AS (
	SELECT
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		COUNT(*) AS [Total Crimes]
	FROM dbo.chicago_crime_data
	GROUP BY
		YEAR(Date),
		MONTH(Date)
),

CommunityAreaCrime AS (
	SELECT
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		Community_Area AS [Community Area],
		COUNT(*) AS [Count of Crimes]
	FROM dbo.chicago_crime_data
	GROUP BY
		YEAR(Date),
		MONTH(Date),
		Community_Area
),

ProportionalCrime AS (
	SELECT
		tcc.[Year],
		tcc.[Month],
		cac.[Community Area],
		cac.[Count of Crimes],
		tcc.[Total Crimes],
		ROUND(
		(cac.[Count of Crimes] / NULLIF(CAST(tcc.[Total Crimes] AS FLOAT),0)) * 100, 3) AS [% Share of Crime]
	FROM TotalCityCrime AS tcc
	INNER JOIN CommunityAreaCrime AS cac
		ON tcc.Year = cac.Year 
		AND tcc.Month = cac.Month
)

SELECT
	[Year],
	[Month],
	[Community Area],
	[Count of Crimes],
	[Total Crimes],
	[% Share of Crime]
FROM ProportionalCrime
ORDER BY
	[Year],
	[Month],[% Share of Crime] DESC;


----------------------------------------------- Queries for Clustering in R -----------------------------------------------

-- Community Area Clustering
WITH CommunityCrime AS (
	SELECT
		Community_Area AS [Community Area],
		Date AS [Date],
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		Primary_Type AS [Primary Type]
	FROM dbo.chicago_crime_data
	WHERE NOT (YEAR(Date) = 2026 AND MONTH(Date) = 5)
),

MonthlyCommunityCrime AS (
	SELECT
		Community_Area AS [Community Area],
		YEAR(Date) AS [Year],
		MONTH(Date) AS [Month],
		COUNT(*) AS [Total Violent Crimes]
	FROM dbo.chicago_crime_data
	WHERE NOT (YEAR(Date) = 2026 AND MONTH(Date) = 5)
	GROUP BY
		Community_Area,
		YEAR(Date),
		MONTH(Date)
),

CrimeByArea AS (
	SELECT
		[Community Area],
		SUM([Total Violent Crimes]) AS [Total Violent Crimes]
	FROM MonthlyCommunityCrime
	GROUP BY [Community Area]
),

CrimeByType AS (
	SELECT
		[Community Area],
		SUM(CASE WHEN [Primary Type] = 'Homicide' THEN 1 ELSE 0 END) AS [Homicides],
		SUM(CASE WHEN [Primary Type] = 'Robbery' THEN 1 ELSE 0 END) AS [Robberies],
		SUM(CASE WHEN [Primary Type] = 'Assault' THEN 1 ELSE 0 END) AS [Assaults],
		SUM(CASE WHEN [Primary Type] = 'Weapons Violation' THEN 1 ELSE 0 END) AS [Weapons Violations],
		SUM(CASE WHEN [Primary Type] = 'Battery' THEN 1 ELSE 0 END) AS [Batteries]
	FROM CommunityCrime
	GROUP BY[Community Area]
),

AverageMonthlyCrime AS (
	SELECT
		[Community Area],
		AVG([Total Violent Crimes]) AS [Average Monthly Crime]
	FROM MonthlyCommunityCrime
	GROUP BY [Community Area]
),

RecentGrowth AS (
    SELECT
        [Community Area],

        AVG(CASE 
				WHEN ([Year] = 2025)
				OR ([Year] = 2026 AND [Month] = 1)
				THEN CAST([Total Violent Crimes] AS FLOAT)
			END) AS BaselineAvg,

        AVG(CASE 
				WHEN [Year] = 2026 AND [Month] IN (2, 3, 4)
				THEN CAST([Total Violent Crimes] AS FLOAT)
			END) AS Recent3MonthAvg,

        (
        AVG(CASE 
				WHEN [Year] = 2026 AND [Month] IN (2, 3, 4)
				THEN CAST([Total Violent Crimes] AS FLOAT)
			END)
            -
        AVG(CASE 
                WHEN ([Year] = 2025)
                  OR ([Year] = 2026 AND [Month] = 1)
                THEN CAST([Total Violent Crimes] AS FLOAT)
            END)
        )
        /
        NULLIF(
        AVG(CASE 
                WHEN ([Year] = 2025)
                  OR ([Year] = 2026 AND [Month] = 1)
                THEN CAST([Total Violent Crimes] AS FLOAT)
            END),
            0
        ) AS RecentGrowth

    FROM MonthlyCommunityCrime
    GROUP BY [Community Area]
)

SELECT
	cba.[Community Area] AS [CommunityArea],
	cba.[Total Violent Crimes] AS [TotalViolentCrimes],
	cbt.[Homicides],
	cbt.[Robberies],
	cbt.[Assaults],
	cbt.[Weapons Violations] AS [WeaponsViolations],
	cbt.[Batteries],
	amc.[Average Monthly Crime] AS [AverageMonthlyCrime],
	rg.BaselineAvg,
	rg.Recent3MonthAvg,
	rg.RecentGrowth
FROM CrimeByArea AS cba
JOIN CrimeByType AS cbt
	ON cba.[Community Area] = cbt.[Community Area]
JOIN AverageMonthlyCrime AS amc
	ON cba.[Community Area] = amc.[Community Area]
JOIN RecentGrowth AS rg
	ON cba.[Community Area] = rg.[Community Area]
ORDER BY cba.[Total Violent Crimes] DESC;




