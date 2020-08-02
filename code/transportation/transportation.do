clear
capture log close
set more off
global path E:\sand storm\data\data transportation\
cd "E:\sand storm\data\data transportation\"



*************************data to dta format
*****county data
clear

import delimited "County.csv", clear

rename ctfips geoid

gen day=substr(date,4,2)
gen month=substr(date,1,2)
gen year=substr(date,7,4)

destring year, replace
destring month, replace
destring day, replace

keep if month<3

save "County.dta", replace



*****GSOD
clear

import delimited "GSOD.csv", clear

keep stnid name ctry state latitude longitude elevation year month day temp stp dewp visib wdsp prcp

keep if month<3

replace dewp="" if dewp=="NA"
replace stp="" if stp=="NA"
replace visib="" if visib=="NA"
replace prcp="" if prcp=="NA"

destring temp dewp stp visib wdsp prcp, replace

gen rhmd=100*(exp((17.625*dewp)/(243.04+dewp))/exp((17.625*temp)/(243.04+temp)))

save "GSOD.dta", replace



*****hourly wind
clear

import delimited "hourly_WIND_2020\hourly_WIND_2020.csv", clear

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep if month<3

keep statecode countycode sitenum latitude longitude datum year month day timelocal samplemeasurement

egen wind_median=median(samplemeasurement), by(sitenum)

gen wind_cos=cos((wind_median-samplemeasurement)*_pi/180)

egen m_wind_cos=mean(wind_cos), by(sitenum year month day)

duplicates drop sitenum year month day, force

keep statecode countycode sitenum latitude longitude datum year month day m_wind_cos

save "daily wind direction.dta", replace



*****PM10
clear

import delimited "daily_81102_2020\daily_81102_2020.csv", clear

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep if month<3

keep statecode countycode sitenum latitude longitude datum year month day arithmeticmean

save "PM10.dta", replace


*****PM2.5 FRM/FEM Mass
clear

import delimited "daily_88101_2020\daily_88101_2020.csv", clear

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep if month<3

keep statecode countycode sitenum latitude longitude datum year month day arithmeticmean

save "PM2.5 FRM FEM Mass.dta", replace


*****PM2.5 non FRM/FEM Mass
clear

import delimited "daily_88502_2020\daily_88502_2020.csv", clear

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep if month<3

keep statecode countycode sitenum latitude longitude datum year month day arithmeticmean

save "PM2.5 non FRM FEM Mass.dta", replace


*****PM2.5
clear

use "PM2.5 FRM FEM Mass.dta", clear

append using "PM2.5 non FRM FEM Mass.dta"

save "PM2.5.dta", replace



*****Ozone
clear

import delimited "daily_44201_2020\daily_44201_2020.csv", clear

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep if month<3

keep statecode countycode sitenum latitude longitude datum year month day arithmeticmean

save "Ozone.dta", replace




****************************data merge and processing
*****climate
clear

import delimited "GIS data\GSOD_county_center_distance.txt", clear

keep geoid distance stnid name ctry state latitude longitude

joinby stnid name ctry state latitude longitude using "GSOD.dta"

egen temp_=wtmean(temp), weight(1/distance) by(year month day geoid)

egen prcp_=wtmean(prcp), weight(1/distance) by(year month day geoid)

egen wdsp_=wtmean(wdsp), weight(1/distance) by(year month day geoid)

egen rhmd_=wtmean(rhmd), weight(1/distance) by(year month day geoid)

duplicates drop year month day geoid, force

keep year month day geoid state temp_ prcp_ wdsp_ rhmd_

rename temp_ temp
rename prcp_ prcp
rename wdsp_ wdsp
rename rhmd_ rhmd

save "climate.dta", replace



*****wind direction
clear

import delimited "GIS data\hourly_wind_county_center_distance.txt", clear

keep geoid distance state_code county_cod site_num latitude longitude datum

rename state_code statecode
rename county_cod countycode
rename site_num sitenum

joinby statecode countycode sitenum latitude longitude datum using "daily wind direction.dta"

egen wind_cos=wtmean(m_wind_cos), weight(1/distance) by(year month day geoid)

duplicates drop year month day geoid, force

keep year month day geoid wind_cos

save "daily wind direction final.dta", replace




*****air pollution
*PM10
clear

import delimited "GIS data\air_pollution_county_center_distance.txt", clear

keep geoid distance state_code county_cod site_num latitude longitude datum

rename state_code statecode
rename county_cod countycode
rename site_num sitenum

joinby statecode countycode sitenum latitude longitude datum using "PM10.dta"

egen PM10=wtmean(arithmeticmean), weight(1/distance) by(year month day geoid)

duplicates drop year month day geoid, force

keep year month day geoid PM10

save "PM10 final.dta", replace



*PM2.5
clear

import delimited "GIS data\air_pollution_county_center_distance.txt", clear

keep geoid distance state_code county_cod site_num latitude longitude datum

rename state_code statecode
rename county_cod countycode
rename site_num sitenum

joinby statecode countycode sitenum latitude longitude datum using "PM2.5.dta"

egen PM25=wtmean(arithmeticmean), weight(1/distance) by(year month day geoid)

duplicates drop year month day geoid, force

keep year month day geoid PM25

save "PM2.5 final.dta", replace



*Ozone
clear

import delimited "GIS data\air_pollution_county_center_distance.txt", clear

keep geoid distance state_code county_cod site_num latitude longitude datum

rename state_code statecode
rename county_cod countycode
rename site_num sitenum

joinby statecode countycode sitenum latitude longitude datum using "Ozone.dta"

egen Ozone=wtmean(arithmeticmean), weight(1/distance) by(year month day geoid)

duplicates drop year month day geoid, force

keep year month day geoid Ozone

save "Ozone final.dta", replace


*****************************merge all the data
clear

use "County.dta", clear

merge 1:1 year month day geoid using "climate.dta"
keep if _merge!=2
drop _merge

merge 1:1 year month day geoid using "daily wind direction final.dta"
keep if _merge!=2
drop _merge

merge 1:1 year month day geoid using "PM10 final.dta"
keep if _merge!=2
drop _merge

merge 1:1 year month day geoid using "Ozone final.dta"
keep if _merge!=2
drop _merge

merge 1:1 year month day geoid using "PM2.5 final.dta"
keep if _merge!=2
drop _merge

drop date

gen date=mdy(month,day,year)
gen dow=dow(date)

gen cdd_new=max(temp*1.8+32-65, 0)
gen hdd_new=max(65-temp*1.8-32, 0)

xtset geoid date

set more off

xtreg tripsperson PM10 Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust
estimates store pm10_gls

xi: xtivreg2 tripsperson (PM10=wind_cos) Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust first savefirst
estimates store pm10_iv

xtreg tripsperson PM25 Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust
estimates store pm25_gls

xi: xtivreg2 tripsperson (PM25=wind_cos) Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust first savefirst
estimates store pm25_iv


esttab pm10_gls _xtivreg2_PM10 pm10_iv pm25_gls _xtivreg2_PM25 pm25_iv ///
 using "tripsperson results.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(wind_cos PM10 PM25 Ozone hdd_new cdd_new prcp wdsp rhmd _cons) ///
 order(wind_cos PM10 PM25 Ozone hdd_new cdd_new prcp wdsp rhmd _cons) ///
 coeflabels(wind_cos "Wind cosine" PM10 "PM10 concentration" PM25 "PM2.5 concentration"  Ozone "Ozone concentration" ///
 hdd_new "Heating degree days" cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" rhmd "Relative humidity" _cons "Constant") ///
 mtitle("GLS" "IV" "IV" "GLS" "IV" "IV")


set more off

xtreg worktripsperson PM10 Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust
estimates store work_pm10_gls

xi: xtivreg2 worktripsperson (PM10=wind_cos) Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust first savefirst
estimates store work_pm10_iv

xtreg worktripsperson PM25 Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust
estimates store work_pm25_gls

xi: xtivreg2 worktripsperson (PM25=wind_cos) Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust first savefirst
estimates store work_pm25_iv

esttab work_pm10_gls _xtivreg2_PM10 work_pm10_iv work_pm25_gls _xtivreg2_PM25 work_pm25_iv ///
 using "worktrip results.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(wind_cos PM10 PM25 Ozone hdd_new cdd_new prcp wdsp rhmd _cons) ///
 order(wind_cos PM10 PM25 Ozone hdd_new cdd_new prcp wdsp rhmd _cons) ///
 coeflabels(wind_cos "Wind cosine" PM10 "PM10 concentration" PM25 "PM2.5 concentration"  Ozone "Ozone concentration" ///
 hdd_new "Heating degree days" cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" rhmd "Relative humidity" _cons "Constant") ///
 mtitle("GLS" "IV" "IV" "GLS" "IV" "IV")


set more off

xtreg nonworktripsperson PM10 Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust
estimates store nonwork_pm10_gls

xi: xtivreg2 nonworktripsperson (PM10=wind_cos) Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust first savefirst
estimates store nonwork_pm10_iv

xtreg nonworktripsperson PM25 Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust
estimates store nonwork_pm25_gls

xi: xtivreg2 nonworktripsperson (PM25=wind_cos) Ozone cdd_new hdd_new prcp wdsp rhmd i.month i.dow, fe robust first savefirst
estimates store nonwork_pm25_iv

esttab nonwork_pm10_gls _xtivreg2_PM10 nonwork_pm10_iv nonwork_pm25_gls _xtivreg2_PM25 nonwork_pm25_iv ///
 using "nonworktrip results.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(wind_cos PM10 PM25 Ozone hdd_new cdd_new prcp wdsp rhmd _cons) ///
 order(wind_cos PM10 PM25 Ozone hdd_new cdd_new prcp wdsp rhmd _cons) ///
 coeflabels(wind_cos "Wind cosine" PM10 "PM10 concentration" PM25 "PM2.5 concentration"  Ozone "Ozone concentration" ///
 hdd_new "Heating degree days" cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" rhmd "Relative humidity" _cons "Constant") ///
 mtitle("GLS" "IV" "IV" "GLS" "IV" "IV")
