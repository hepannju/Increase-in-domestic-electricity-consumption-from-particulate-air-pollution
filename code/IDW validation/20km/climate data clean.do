clear
capture log close
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"


***********************************daily
************convert GSOD into .dta
clear

import excel "E:\sand storm\data\data\climate\GSOD\GSOD combined.xlsx", sheet("Sheet1") firstrow

foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
}

rename stn usaf

drop if wban=="WBAN" 

gen year=substr(yearmoda,1,4)
gen month=substr(yearmoda,5,2)
gen day=substr(yearmoda,7,2)

keep usaf wban temp dewp stp visib wdsp prcp year month day

destring usaf wban temp dewp stp visib wdsp year month day, replace

replace dewp=. if dewp>=9999.9
replace stp=. if stp>=9999.9
replace visib=. if visib>=999.9
replace wdsp=. if wdsp>=999.9

replace prcp="" if prcp=="99.99"
replace prcp="" if prcp=="0.00I"
replace prcp=substr(prcp,1,4)
destring prcp, replace

replace temp=(temp-32)*5/9 //originally F, convert to C
replace dewp=(dewp-32)*5/9 //originally F, convert to C
replace wdsp=wdsp*0.5144 //knots to tenths, originally knots to tenths, convert to m/s

gen rhmd=100*(exp((17.625*dewp)/(243.04+dewp))/exp((17.625*temp)/(243.04+temp)))


cd "E:\sand storm\data\data\"

save "climate daily raw.dta", replace

use "climate daily raw.dta", clear


************weight of stations to zip code center
clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("zip code") firstrow

rename svc_zip svc_zip_original
rename svc_zip_match svc_zip 

cd "E:\sand storm\data\data\"

save "zip code zone match.dta", replace



clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("climate & zip code") firstrow

drop if DISTANCE>0.2

cd "E:\sand storm\data\data\"

rename ZCTA5CE10 svc_zip

joinby svc_zip using "zip code zone match.dta"

keep svc_zip svc_zip_original usaf wban DISTANCE

joinby usaf wban using "climate daily raw.dta"

foreach var of varlist temp visib wdsp prcp rhmd{
egen m_`var'=wtmean(`var'), weight(1/DISTANCE) by(svc_zip_original year month day)
drop `var'
rename m_`var' `var'
}

keep svc_zip_original year month day temp visib wdsp prcp rhmd

duplicates drop svc_zip_original year month day, force

rename svc_zip_original svc_zip

tostring svc_zip, replace

save "climate daily 20km.dta", replace










/*
clear

import delimited "E:\sand storm\data\data\wind\Wind\id34.csv", clear

keep if peakwinddirection!=.

gen year=substr(date,1,4)
gen month=substr(date,6,2)
gen day=substr(date,9,2)

destring year month day, replace

keep year month day peakwinddirection

gen wind_direction8=0
forvalues i=0/7 {
replace wind_direction8=`i'+1 if peakwinddirection/22.5>=`i'*2+1 & peakwinddirection/22.5<(`i'+1)*2+1
}

replace wind_direction8=0 if wind_direction8==8


gen wind_direction4=0
forvalues i=0/3 {
replace wind_direction4=`i'+1 if peakwinddirection/45>=`i'*2+1 & peakwinddirection/45<(`i'+1)*2+1
}

replace wind_direction4=0 if wind_direction4==4

gen wind_cos=cos((260-peakwinddirection)*_pi/180)

cd "E:\sand storm\data\data\"

save "wind direction final.dta", replace
*/






*************************hourly data
************combine data
cd "E:\sand storm\data\data\air quality and climate hourly\climate"

clear

set more off
local csvfiles: dir . files "*.csv"
foreach file of local csvfiles {
 preserve
 insheet using "`file'", clear
 ** add syntax here to run on each file**
 keep if statename=="Arizona"
 save temp, replace
 restore
 append using temp, force
}

cd "E:\sand storm\data\data\"

save "climate hourly raw.dta", replace


***********climate station

clear

use "climate hourly raw.dta", clear

keep sitenum latitude longitude

duplicates drop sitenum, force

sort sitenum



*************test using just a part
clear

use "climate hourly raw.dta", replace

*keep if svc_zip==85009 | svc_zip==85040 | svc_zip==85256
keep if sitenum==4004 | sitenum==4006 | sitenum==9812 | sitenum==4009 | sitenum==4003 | ///
sitenum==4019 | sitenum==4005 | sitenum==1003 | sitenum==2001 | sitenum==9997 | ///
sitenum==4020 | sitenum==3010 | sitenum==1004 | sitenum==19 | sitenum==3002 | ///
sitenum==3003 | sitenum==1010 | sitenum==4010 | sitenum==4016 | sitenum==4018 | ///
sitenum==2005 | sitenum==9704 | sitenum==4008 | sitenum==9702

save "climate hourly part.dta", replace



*****************************
clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("air pollution hourly & zip code") firstrow

drop if DISTANCE>0.2

cd "E:\sand storm\data\data\"

rename ZCTA5CE10 svc_zip

joinby svc_zip using "zip code zone match.dta"

keep svc_zip svc_zip_original sitenum DISTANCE

*****keep a part
keep if svc_zip==85009 | svc_zip==85040 | svc_zip==85256

joinby sitenum using "climate hourly part.dta"

replace timelocal=substr(timelocal,1,2)

destring timelocal, replace

egen v_=wtmean(samplemeasurement), weight(1/DISTANCE) by(svc_zip_original datelocal timelocal parametername)

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep svc_zip_original year month day timelocal parametername v_

duplicates drop svc_zip_original year month day timelocal parametername, force

drop if parametername=="Wind Direction - Resultant"
replace parametername="temp" if parametername=="Outdoor Temperature"
replace parametername="rhmd" if parametername=="Relative Humidity "
replace parametername="wdsp" if parametername=="Wind Speed - Resultant"

reshape wide v_, i(year month day timelocal svc_zip_original) j(parametername) string

replace v_temp=(v_temp-32)*5/9 //originally F, convert to C
replace v_wdsp=v_wdsp*0.5144 //knots to tenths, originally knots to tenths, convert to m/s

rename svc_zip_original svc_zip

save "climate hourly.dta", replace







*************daily wind direction
cd "E:\sand storm\data\data\"

clear

use "climate hourly raw.dta", clear

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep if parametername=="Wind Direction - Resultant"

gen wind_cos=cos((180-samplemeasurement)*_pi/180)

egen m_wind_cos=mean(wind_cos), by(sitenum year month day)

gen wind_cos_south=cos((90-samplemeasurement)*_pi/90)

egen m_wind_cos_south=mean(wind_cos_south), by(sitenum year month day)

duplicates drop sitenum year month day, force

keep sitenum year month day m_wind_cos m_wind_cos_south

save "wind direction daily raw.dta", replace


************weight of stations to zip code center
clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("zip code") firstrow

rename svc_zip svc_zip_original
rename svc_zip_match svc_zip 

cd "E:\sand storm\data\data\"

save "zip code zone match.dta", replace



clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("climate hourly & zip code") firstrow

drop if DISTANCE>0.2

cd "E:\sand storm\data\data\"

rename ZCTA5CE10 svc_zip

joinby svc_zip using "zip code zone match.dta"

keep svc_zip svc_zip_original sitenum DISTANCE

joinby sitenum using "wind direction daily raw.dta"

egen wind_cos=wtmean(m_wind_cos), weight(1/DISTANCE) by(svc_zip_original year month day)

egen wind_cos_south=wtmean(m_wind_cos_south), weight(1/DISTANCE) by(svc_zip_original year month day)


keep svc_zip_original year month day wind_cos wind_cos_south

duplicates drop svc_zip_original year month day, force

rename svc_zip_original svc_zip

tostring svc_zip, replace

save "wind direction daily 20km.dta", replace




*************************solar radiation
/*
cd "E:\sand storm\data\data\climate\solar irradiance"

clear

use "solar_irradiance data.dta", clear

rename mo month
rename dy day
rename yr year

keep year month day Surfacealbedo_a

duplicates drop year month day, force

cd "E:\sand storm\data\data\"

save "solar irradiance.dta", replace


clear

use "ID_station.dta", clear

joinby s_station using "solar_irradiance data.dta"

rename mo month
rename dy day
rename yr year

cd "E:\sand storm\data\data\"

save "solar irradiance.dta", replace
*/


*************************climate factors
clear

use "stationmatch.dta", clear

rename stationmatch station

merge m:m station using "prcp_station.dta"
drop if _merge!=3
drop _merge

duplicates drop station date, force

gen year=year(date)
gen month=month(date)
gen day=day(date)

egen prcp_mean=mean(prcp), by(date)

duplicates drop date, force

keep year month day prcp_mean

rename prcp_mean prcp

save "prcp record final.dta", replace



clear

import delimited "climate\climate record.csv"

tostring yearmoda, replace

gen year=substr(yearmoda,1,4)
gen month=substr(yearmoda,5,2)
gen day=substr(yearmoda,7,2)

drop mxspd gust max min

save "climate record.dta", replace


clear all

import delimited "climate\climate station zip code.csv"

joinby usaf wban using "climate record.dta"

duplicates drop usaf wban year month day, force

keep temp dewp stp visib wdsp prcp year month day

destring year month day, replace

replace dewp=. if dewp>9999.9
replace stp=. if stp>9999.9
replace visib=. if visib>999.9
replace wdsp=. if wdsp>999.9

replace prcp="" if prcp=="99.99"
replace prcp="" if prcp=="0.00I"
replace prcp=substr(prcp,1,4)
destring prcp, replace

replace temp=(temp-32)*5/9 //originally F, convert to C
replace dewp=(dewp-32)*5/9 //originally F, convert to C
replace wdsp=wdsp*0.5144 //knots to tenths, originally knots to tenths, convert to m/s

gen rhmd=100*(exp((17.625*dewp)/(243.04+dewp))/exp((17.625*temp)/(243.04+temp)))

foreach var of varlist temp dewp stp visib wdsp rhmd prcp {
egen `var'_mean=mean(`var'), by(year month day)
drop `var'
rename `var'_mean `var'
}

duplicates drop year month day, force

save "climate record final.dta", replace


*************wind
cd "E:\sand storm\data\data\wind\Wind"

clear

import delimited "E:\sand storm\data\data\wind\Wind\id34.csv", clear

keep if peakwinddirection!=.

gen year=substr(date,1,4)
gen month=substr(date,6,2)
gen day=substr(date,9,2)

destring year month day, replace

keep year month day peakwinddirection

gen wind_direction8=0
forvalues i=0/7 {
replace wind_direction8=`i'+1 if peakwinddirection/22.5>=`i'*2+1 & peakwinddirection/22.5<(`i'+1)*2+1
}

replace wind_direction8=0 if wind_direction8==8


gen wind_direction4=0
forvalues i=0/3 {
replace wind_direction4=`i'+1 if peakwinddirection/45>=`i'*2+1 & peakwinddirection/45<(`i'+1)*2+1
}

replace wind_direction4=0 if wind_direction4==4

gen wind_cos=cos((260-peakwinddirection)*_pi/180)

cd "E:\sand storm\data\data\"

save "wind direction final.dta", replace






***stations
cd "E:\sand storm\data\data\"

clear

use "air pollution station.dta", clear







***stations
cd "E:\sand storm\data\data\"

clear

import excel "E:\sand storm\data\data\climate\air pollution station zip code.xlsx", sheet("station zipcode") firstrow

save "air pollution station zip code.dta", replace



***combine air pollution data
cd "E:\sand storm\data\data\air quality"

clear

set more off
local csvfiles: dir . files "*.csv"
foreach file of local csvfiles {
 preserve
 insheet using "`file'", clear
 ** add syntax here to run on each file**
 save temp, replace
 restore
 append using temp
}

rm "temp.dta"

gen vartype="CO_max8hour" if dailymax8hourcoconcentration!=.
replace vartype="NO2_max1hour" if dailymax1hourno2concentration!=.
replace vartype="Ozone_max8hour" if dailymax8hourozoneconcentration!=.
replace vartype="Pb_mean" if dailymeanpbconcentration!=.
replace vartype="PM10_mean" if dailymeanpm10concentration!=.
replace vartype="PM25_mean" if dailymeanpm25concentration!=.
replace vartype="SO2_max1hour" if dailymax1hourso2concentration!=.

gen v=dailymax8hourcoconcentration if dailymax8hourcoconcentration!=.
replace v=dailymax1hourno2concentration if dailymax1hourno2concentration!=.
replace v=dailymax8hourozoneconcentration if dailymax8hourozoneconcentration!=.
replace v=dailymeanpbconcentration if dailymeanpbconcentration!=.
replace v=dailymeanpm10concentration if dailymeanpm10concentration!=.
replace v=dailymeanpm25concentration if dailymeanpm25concentration!=.
replace v=dailymax1hourso2concentration if dailymax1hourso2concentration!=.


cd "E:\sand storm\data\data\"

joinby siteid using "air pollution station zip code.dta"

duplicates drop siteid date vartype, force

egen vs=mean(v), by(date vartype)

duplicates drop date vartype, force

keep date vartype vs

reshape wide vs, i(date) j(vartype) string

gen year=substr(date,7,4)
gen month=substr(date,1,2)
gen day=substr(date,4,2)

destring year month day, replace
 
drop vsPb_mean date

save "air pollution final.dta", replace


***********


clear

use "stationmatch.dta", clear

rename stationmatch station

merge m:m station using "prcp_station.dta"

drop if _merge!=3

drop _merge

gen year=year(date)
gen month=month(date)
gen day=day(date)

keep zipcode year month day prcp

save "prcp record final.dta", replace



clear

import delimited "climate\climate record.csv"

tostring yearmoda, replace

gen year=substr(yearmoda,1,4)
gen month=substr(yearmoda,5,2)
gen day=substr(yearmoda,7,2)

drop mxspd gust max min

save "climate record.dta", replace


clear all

import delimited "climate\climate station zip code.csv"

joinby usaf wban using "climate record.dta"

keep zcta5ce10 temp dewp stp visib wdsp year month day

rename zcta5ce10 zipcode

destring year month day, replace

rename temp temp_GSOD

replace dewp=. if dewp>9999.9
replace stp=. if stp>9999.9
replace visib=. if visib>999.9
replace wdsp=. if wdsp>999.9

merge 1:1 zipcode year month day using "prcp record final.dta"

save "climate record final.dta", replace



***************solar irradiance daily
***data source: http://www2.mps.mpg.de/projects/sun-climate/data.html
***data source: http://www2.mps.mpg.de/projects/sun-climate/data/SATIRE-S_TSI_20190621.txt
clear all

import delimited "E:\sand storm\data\data\total solar irradiance\SATIRE-S_TSI_20190621.txt", delimiter(space)

keep v6 v14 v22 v30 v38

keep if v38==4

destring v6, replace

sort v6

gen date = _n + td(29apr2010)
gen year=year(date)
gen month=month(date)
gen day=day(date)

keep year month day v14

rename v14 irradiance_new

save "solar irradiance daily.dta", replace
