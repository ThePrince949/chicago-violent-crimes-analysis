
# ----------------------------------------------------------------------------


# Chicago Crime - Violent Crime Analysis
# Name: Harrison Doan
# Date: May 26th, 2026


# ----------------------------------------------------------------------------

# Required packages: DBI, odbc, tidyverse, scales, cluster, zoo

library(DBI)
library(odbc)
library(tidyverse)
library(scales)
library(cluster)
library(zoo)

# ----------------------------------------------------------------------------

# Connecting to SQL
con <- dbConnect(
  odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "YOUR_SERVER_NAME",
  Database = "YOUR_DATABASE_NAME",
  Trusted_Connection = "Yes"
)



# --------------------------------- Visuals -----------------------------------


# --------------- Visual #1 - Total Crime Count by Month ----------------------


# Pull data with SQL query
TotalViolentCrime <- dbGetQuery(con, '
  SELECT
    YEAR(Date) AS [Year],
    MONTH(Date) AS [Month],
    COUNT(*) AS [TotalCrimeCount]
  FROM dbo.chicago_crime_data
  GROUP BY
	  YEAR(Date),
	  MONTH(Date)
  ORDER BY
	  YEAR(Date),
	  MONTH(Date);
')


# Adding a "Date" column for R to identify as separate distinct month
TotalViolentCrime$Date <- as.Date(
  paste(TotalViolentCrime$Year,
        TotalViolentCrime$Month,
        "1",
        sep = "-")
)


# Filtering out May 2026 - insufficient data
TotalViolentCrimePlot <- TotalViolentCrime |>
  filter(Date < '2026-05-01')


# Add rolling average
TotalViolentCrimePlot <- TotalViolentCrimePlot |>
  mutate(RollingAvg3Month = rollmean(TotalCrimeCount, k = 3, fill = NA))


# Object for plotting rolling avg
multi_line <- TotalViolentCrimePlot |>
  select(Date, TotalCrimeCount, RollingAvg3Month)


# Create plot
ggplot(multi_line, aes(x = Date)) +
  geom_line(aes(x = Date, y = TotalCrimeCount, color = "Total Crime")) +
  geom_line(aes(x = Date, y = RollingAvg3Month, color = "Rolling Avg"), linewidth = 1.10) +
  geom_point(aes(x = Date, y = TotalCrimeCount), color = "darkblue", size = 1.35) +
  scale_x_date(date_breaks = "month", date_labels = "%b") +
  labs(
    title = "Chicago Violent Crime Count by Month",
    subtitle = "Monthly violent crime incidents with 3-month rolling average",
    color = "",
    x = "Date (Months)",
    y = "Total Violent Crimes Committed"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20, face = "bold"),
    plot.subtitle = element_text(size = 16),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13),
    plot.margin = margin(10,10,10,10),
    legend.position = "bottom"
  ) +
  scale_color_manual(
    values = c(
      "Total Crime" = "darkblue",
      "Rolling Avg" = "lightgrey"
    )
  )




# -------------------- Visual #2 - Growth of crime type -----------------------


# Alter data frame for desired specs
TypeOfCrime <- dbGetQuery(con, '
  SELECT
	  YEAR(Date) AS [Year],
	  MONTH(Date) AS [Month],
	  Primary_Type AS [PrimaryType],
	  COUNT(*) AS [PrimaryTypeCount]
  FROM dbo.chicago_crime_data
  GROUP BY
	  YEAR(Date),
	  MONTH(Date),
	  Primary_Type
	ORDER BY
	  YEAR(Date),
	  MONTH(Date)
')


# Adding a "Date" column for R to identify as separate distinct month
TypeOfCrime$Date <- as.Date(
  paste(TypeOfCrime$Year,
        TypeOfCrime$Month,
        "1",
        sep = "-")
)


# Filtering out May 2026 - insufficient data
TypeOfCrimePlot <- TypeOfCrime |>
  filter(Date < '2026-05-01')


# Create plot
ggplot(TypeOfCrimePlot, aes(x = Date, y = PrimaryTypeCount, color = PrimaryType)) +
  geom_line() +
  facet_wrap(~PrimaryType, scales = "free_y") +
  scale_x_date(date_labels = "%b") +
  labs(
    title = "Type of Violent Crime per Month",
    subtitle = "Monthly trends across major violent crime categories",
    x = "Date (Months)",
    y = "Total Violent Crimes Committed by Type"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(legend.position = "none") +
  theme(
    plot.title = element_text(size = 20, face = "bold"),
    plot.subtitle = element_text(size = 16),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )



# ------------ Visual #3 - Top community areas by violent crime ---------------


# Pull query from SQL
TopCommunityAreas <- dbGetQuery(con, '
  SELECT
	  Community_Area AS [CommunityArea],
	  COUNT(*) AS [CountofViolentCrimes],
	  RANK() OVER (
		  ORDER BY COUNT(*) DESC 
		  ) AS [Rank]
  FROM dbo.chicago_crime_data
  GROUP BY [Community_Area]
  ORDER BY [CountofViolentCrimes] DESC;
')


# Filter for data I want
TopCommunityAreas <- TopCommunityAreas |>
  select(CommunityArea, CountofViolentCrimes) |>
  filter(CountofViolentCrimes > 2000)


# Turn community area to a factor
TopCommunityAreas$CommunityArea <- as.factor(TopCommunityAreas$CommunityArea)

# Reorder factors for the plot (to recognize DESC)
TopCommunityAreas <- TopCommunityAreas |>
  mutate(CommunityArea = fct_reorder(CommunityArea, CountofViolentCrimes))

# Plot the edited df
ggplot(TopCommunityAreas, aes(x = CommunityArea, y = CountofViolentCrimes)) +
  geom_bar(stat = "identity", fill = "darkblue", color = "white") +
  coord_flip() +
  geom_text(aes(label = scales::comma(CountofViolentCrimes), stat = "count"), color = "white", nudge_y = -190) +
  labs(
    title = "Top 15 Community Areas by Violent Crime Incidents",
    subtitle = "Community areas reporting the highest violent crime volumes",
    x = "Community Area (#)",
    y = "Count of Violent Crimes"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 20, face = "bold"),
    plot.subtitle = element_text(size = 16),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )



# --------------------------- Visual #4 - Clustering --------------------------


# Get data from SQL
crime_cluster <- dbGetQuery(con, "

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
") 

# These variables were selected to capture both crime volume and recent trend change by community area


# Remove community area 
crime_cluster <- subset(crime_cluster, select = -CommunityArea)

# Standardize clusters
cluster_scaled <- scale(crime_cluster)

# Set seed
set.seed(123)

# Run cluster
k_model <- kmeans(cluster_scaled, centers = 4, nstart = 25)
crime_cluster$Cluster <- k_model$cluster

# Summarize clusters
crime_cluster |>
  group_by(Cluster) |>
  summarise(across(where(is.numeric), mean))


# Plot clusters
ggplot(crime_cluster, aes(x = TotalViolentCrimes, y = RecentGrowth, color = factor(Cluster))) +
  geom_point(linewidth = 1.85) +
  labs(
    title = "Violent Crime Risk Profiles by Community Area",
    subtitle = "Clusters of community areas based on violent crime characteristics",
    x = "Total Crime Incidents",
    y = "Recent Growth Rate (%)"
  ) +
  geom_hline(yintercept = 0.00, color = "black", linetype = 2, size = 1) +
  theme_minimal() +
  theme(
    legend.position = "bottom"
  ) +
  scale_color_manual(name = "Clusters",
       values = c("red", "blue", "darkgreen", "orange"),
       labels = c("Emerging Risk Areas", "High Crime Hotspots", "Low Activity Areas", "Consistent Crime Activity Areas")
  ) +
  theme(
    plot.title = element_text(size = 18, face = "bold"),
    plot.subtitle = element_text(size = 15),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12)
  )



dbDisconnect(con)








