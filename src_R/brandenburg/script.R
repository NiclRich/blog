# Load necessary libaries ++++++++++++++++++++++++++++++++++++++++++++++++++++++
library(readr)
library(sf)
library(dplyr)
library(ggplot2)
library(lubridate)
library(rdwd)
library(ggtext)

# Define the constants +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
climate_normal_start <- ymd(19700101)
climate_normal_end <- ymd(19991231)
start_recent_period <- ymd(20150101)
# Load the data ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Read the Stations in Germany
stations_germany <- read_table("https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/monthly/kl/historical/KL_Monatswerte_Beschreibung_Stationen.txt", 
                               col_types = cols(Stationshoehe = col_skip(), 
                                                Stationsname = col_skip()))

# The file path has to be adjusted if you want to run it on another computer
sf_germany <- st_read("/home/niclas/Documents/GitHub/blog/src_R/brandenburg/data/gadm41_DEU_2.json")

# select the state Brandenburg of Germany from the shapefile
sf_brandenburg <- filter(sf_germany, NAME_1 == "Brandenburg")

# select the stations in Brandenburg
stations_brandenburg <- stations_germany %>%
  mutate(von_datum = ymd(von_datum), bis_datum = ymd(bis_datum)) %>%
  filter(Bundesland == "Brandenburg" & von_datum <= climate_normal_start & bis_datum >= climate_normal_end)


# The weather station's coordinates are given with the longitude and latitude
# and subdistricts have the columns geometry which contains the boundary of the
# district as a polygon. Since the districts are a partition of Brandenburg's
# surface, we can check whether the station's location is within the described
# polygon using the function st_contains.
# This results in the temporary file stations_subdivisions which maps the 
# weather stations's id to the district.
stations_subdivisions <- tibble(station_id = character(), subdivision = character())
for (i in 1:nrow(stations_brandenburg)) {
  point <- st_point(c(stations_brandenburg$geoLaenge[[i]], stations_brandenburg$geoBreite[[i]]))
  selected_indices <- st_contains(sf_brandenburg, point) %>% lengths > 0
  
  subdivision_of_point <- sf_brandenburg[selected_indices, ]
  stations_subdivisions <- add_row(stations_subdivisions,
                                   station_id = stations_brandenburg$Stations_id[i],
                                   subdivision = subdivision_of_point$NAME_2)
}
# Cast the station to an integer, since upcoming join between the meteorological
# data and the geographical data requires the same data type.
stations_subdivisions <- stations_subdivisions %>%
  mutate(station_id = as.integer(station_id))

# Download the meteorological data
urls <- selectDWD(id=stations_subdivisions$station_id, 
                  res = "monthly", 
                  var = "kl",
                  per = "hr")
meteo_data_raw <- dataDWD(urls)

# combine the many individual data frames into a single data frame
# with the precipitation
meteo_data <- bind_rows(meteo_data_raw) %>%
  mutate(month_measurement = as_date(MESS_DATUM), precipitation = MO_RR) %>%
  select(STATIONS_ID, month_measurement, precipitation) %>%
  rename(station_id = STATIONS_ID) 

# Make a left join, such that each station has the corresponding district
meteo_data <- left_join(meteo_data, stations_subdivisions)

# Computations +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Compute the climate normals for each month and subdivision. We compute the mean,
# the standard error of the mean, and the number of stations for each district.
climate_normals <- meteo_data %>%
  filter(month_measurement >= climate_normal_start & month_measurement <= climate_normal_end) %>%
  mutate(month = month(month_measurement)) %>%
  group_by(month, subdivision) %>%
  summarise(mean_precipitation = mean(precipitation, na.rm = TRUE),
            se_precipitation = sd(precipitation, na.rm = TRUE) / sqrt(n()),
            number_stations = n(),
            )

# Compute the mean for the 
recent_data <- meteo_data %>%
  filter(month_measurement >= start_recent_period) %>%
  mutate(month = month(month_measurement),
         year = year(month_measurement)) %>%
  group_by(month, year, subdivision) %>%
  summarise(recent_mean = mean(precipitation, na.rm = TRUE), n = n())

# compute the precipitation ratios
scores_subdivisions <- left_join(recent_data, climate_normals) %>%
  ungroup() %>%
  mutate(relative_precipitation = round(recent_mean / mean_precipitation , 1),
         month = make_date(year, month, 1)) %>%
  select(subdivision,month,  relative_precipitation)

# Create the frames for the final gif ++++++++++++++++++++++++++++++++++++++++++
end_recent_period <- max(scores_subdivisions$month)
relative_precipitation_min <- min(scores_subdivisions$relative_precipitation,
                                  na.rm = TRUE)
relative_precipitation_max <- max(scores_subdivisions$relative_precipitation,
                                  na.rm = TRUE)

# Use a temporary key to make a copy of the shape file for each month
sf_brandenburg_plot <- sf_brandenburg %>%
  mutate(temp_id = 1) %>%
  full_join(expand.grid(temp_id = 1, month = seq(start_recent_period, end_recent_period, by = "month"))) %>%
  left_join(scores_subdivisions, by = c("NAME_2" = "subdivision", "month" = "month")) %>%
  select(-temp_id)

# create a frame for each month
for (m in unique(sf_brandenburg_plot$month)) {
  p <- sf_brandenburg_plot %>%
    filter(month == m) %>%
    ggplot() + 
    geom_sf(aes(fill=relative_precipitation)) +
    scale_fill_gradient2(low = "red", high = "darkblue", mid = "green", midpoint = 1, na.value = "grey", 
                        limits = c(relative_precipitation_min, relative_precipitation_max),
                        name = "relative precipitation") + 
    theme_bw() +
    labs(title="Deviation of the precipitation from the mean of 1970 - 1999 \n in Brandenburg, Germany") +
    annotate(geom="label", x = 11.9, y = 51.8, label = paste("Month:", strftime(as_date(m), "%b %Y")), fill="white") +
    xlab("") + 
    ylab("")
  
  ggsave(paste0("/home/niclas/Documents/GitHub/blog/R/brandenburg/frames/frame-", strftime(as_date(m), "%Y-%m"), ".png"), p)

}
