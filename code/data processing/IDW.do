set more off
clear all

global Repository "E:\Countyset and Weather Dataset\CountysetAndWeatherData\WeatherData1951-2016"
local varlist "tem_Mean tem_Max tem_Min pre_20_8 pre_8_20 pre_20_20" /*the list of weather variable*/

forvalues unit = 1/2839{ /* 2839 counties, loop over each county */
*foreach unit of local duplist{
cd "$Repository\countyweather"
use countymap_sorted, clear /*This map includes administraitve code and coordinates of centroid of each county*/

gen ones =1
sort ones
gen n=_n /*generate individual identifier n=1,2,...,2839*/
keep if n == `unit'
save temp, replace /*for each county create an individual dataset*/


/*the above code is to restrict the sample to a specific county with its geographical coordinates */

		use weather1980-2016.dta,clear /*this is a file with all station-level weather data*/
		gen ones =1 /* the one here is an identity of each county for joinby-ing or merging */
		sort ones
		joinby one using temp
		
        sort date
   
        local R = 6371 /* radius of the Earth (KM)  */
		local radius = 200 /* radius of the circle */
		
       *Inverse-distance weighting interpolation
        qui gen distance =`R'*acos(sin(centroid_lat *_pi/180)*sin(station_lati*_pi/180)+ ///
		cos(centroid_lat*_pi/180)*cos(station_lati*_pi/180)*cos(station_longi*_pi/180 - centroid_lon*_pi/180))  
		* centroid_lat: county centroid latitude 
		* centroid_lon: county centroid longitude
		* station_lati: station latitude
		* statioin_longi: station longitude
        qui gen weight = (1 / (distance*distance))
        qui replace weight = . if distance > `radius' /* circle radius */
        by date: egen sum_weights = sum(weight) /* calculate for each day */
		
	

		foreach VAR in `varlist'{
               qui gen `VAR'_1 = `VAR'*weight
               qui by date: egen w`VAR' = sum(`VAR'_1) 
	           qui replace w`VAR' = w`VAR'/sum_weights
			   
			   /*distinguish missing and nonmissing: this is important because stata will process missing values as zeros*/
			   qui bysort date (`VAR'_1): gen allmissing_`VAR'=missing(`VAR'_1[1]) 
			   qui replace w`VAR'=. if allmissing_`VAR'==1
               qui replace `VAR' = w`VAR'
               drop `VAR'_1 w`VAR'
        }
			
	    collapse (mean) tem_Mean-pre_20_20 (min)allmissing_tem_Mean-allmissing_pre_20_20, by(date county_id centroid_lon centroid_lat) fast 
		
		
		foreach VAR in `varlist'{
		qui replace `VAR'=. if allmissing_`VAR'==1
		
		}
	
		cd "$Repository\countyweather"	   	   
       /* make sure to create a folder named temp, to store results for each county */

        compress
		*cap erase countyweather_`unit'
	    cap erase countyweatp_`unit'
		
		
		destring,replace
		xtset county_id date
	    tsfill, full
		gen year=year(date)
		gen month=month(date)
		gen day=day(date)
		
		drop allmissing_tem_Mean-allmissing_pre_20_20
		
		order county_id centroid_lon centroid_lat date year month day 

		save countyweatp_`unit', replace
 

}
