clear
capture log close
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"

******AQI

*************************dust storm
cd "E:\sand storm\data\data\climate\storm event"

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

keep if event_type=="Dust Storm" | event_type=="Dust Devil"

keep if state=="ARIZONA"

keep if strpos(cz_name, "PHOENIX") | strpos(cz_name, "Phoenix") ///
| strpos(cz_name, "MARICOPA") | strpos(cz_name, "PINAL")

keep event_id begin_yearmonth begin_day end_yearmonth end_day

rename begin_yearmonth yearmonth_begin
rename begin_day day_begin
rename end_yearmonth yearmonth_end
rename end_day day_end

reshape long yearmonth day, i(event_id) j(variable) string

duplicates drop yearmonth day, force

gen year=int(yearmonth/100)

gen month=yearmonth-int(yearmonth/100)*100

keep year month day

gen stormevent=1

cd "E:\sand storm\data\data\"

save "sand storm final.dta", replace

use "sand storm final.dta", clear



*************daily air pollution 
cd "E:\sand storm\data\data\air quality"

clear

set more off
local csvfiles: dir . files "*.csv"
foreach file of local csvfiles {
 preserve
 insheet using "`file'", clear
 ** add syntax here to run on each file**
keep if state=="Arizona"
 save temp, replace
 restore
 append using temp
}

rm "temp.dta"

gen vartype="Ozone_max8hour" if dailymax8hourozoneconcentration!=.
replace vartype="NO2_max1hour" if dailymax1hourno2concentration!=.
replace vartype="CO_max8hour" if dailymax8hourcoconcentration!=.
replace vartype="Pb_mean" if dailymeanpbconcentration!=.
replace vartype="PM10_mean" if dailymeanpm10concentration!=.
replace vartype="PM25_mean" if dailymeanpm25concentration!=.
replace vartype="SO2_max1hour" if dailymax1hourso2concentration!=.

gen v=dailymax8hourozoneconcentration if dailymax8hourozoneconcentration!=.
replace v=dailymax1hourno2concentration if dailymax1hourno2concentration!=.
replace v=dailymax8hourcoconcentration if dailymax8hourcoconcentration!=.
replace v=dailymeanpbconcentration if dailymeanpbconcentration!=.
replace v=dailymeanpm10concentration if dailymeanpm10concentration!=.
replace v=dailymeanpm25concentration if dailymeanpm25concentration!=.
replace v=dailymax1hourso2concentration if dailymax1hourso2concentration!=.


cd "E:\sand storm\data\data\"

/*
egen vs=mean(v), by(date vartype county)

duplicates drop date vartype county, force

keep date vartype vs county

reshape wide vs, i(date county) j(vartype) string

gen year=substr(date,7,4)
gen month=substr(date,1,2)
gen day=substr(date,4,2)

destring year month day county, replace
 
drop vsPb_mean date

rename county countyname
*/

preserve
keep siteid site_latitude site_longitude
duplicates drop siteid, force
save "air pollution station.dta", replace
restore

drop if v<0

save "air pollution daily raw.dta", replace

use "air pollution daily raw.dta", clear

************weight of stations to zip code center
clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("zip code") firstrow

rename svc_zip svc_zip_original
rename svc_zip_match svc_zip 

cd "E:\sand storm\data\data\"

save "zip code zone match.dta", replace



clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("air pollution & zip code") firstrow

drop if DISTANCE>0.2

cd "E:\sand storm\data\data\"

rename ZCTA5CE10 svc_zip

joinby svc_zip using "zip code zone match.dta"

keep svc_zip svc_zip_original siteid DISTANCE

joinby siteid using "air pollution daily raw.dta"

egen v_=wtmean(v), weight(1/DISTANCE) by(svc_zip_original date vartype)

keep svc_zip_original date vartype v_

duplicates drop svc_zip_original date vartype, force

reshape wide v_, i(date svc_zip_original) j(vartype) string

gen year=substr(date,7,4)
gen month=substr(date,1,2)
gen day=substr(date,4,2)

destring year month day, replace

drop date

rename svc_zip_original svc_zip

save "air pollution daily 20km.dta", replace


















*************************hourly air pollution 
cd "E:\sand storm\data\data\air quality and climate hourly\air pollution"

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

rm "temp.dta"

cd "E:\sand storm\data\data\"

replace samplemeasurement=arithmeticmean if samplemeasurement==.

drop if parametername=="Acceptable PM2.5 AQI & Speciation Mass"

replace parametername="PM10" if parametername=="PM10 Total 0-10um STP"
replace parametername="PM25" if parametername=="PM2.5 - Local Conditions"

save "air pollution hourly raw.dta", replace



clear

use "air pollution hourly raw.dta", replace

keep sitenum latitude longitude datum

duplicates drop sitenum, force


*************test using just a part
clear

use "air pollution hourly raw.dta", replace

*keep if svc_zip==85009 | svc_zip==85040 | svc_zip==85256
keep if sitenum==4004 | sitenum==4006 | sitenum==9812 | sitenum==4009 | sitenum==4003 | ///
sitenum==4019 | sitenum==4005 | sitenum==1003 | sitenum==2001 | sitenum==9997 | ///
sitenum==4020 | sitenum==3010 | sitenum==1004 | sitenum==19 | sitenum==3002 | ///
sitenum==3003 | sitenum==1010 | sitenum==4010 | sitenum==4016 | sitenum==4018 | ///
sitenum==2005 | sitenum==9704 | sitenum==4008 | sitenum==9702

save "air pollution hourly part.dta", replace


************


clear

import excel "E:\sand storm\data\list of zipcode zone.xlsx", sheet("air pollution hourly & zip code") firstrow

drop if DISTANCE>0.2

cd "E:\sand storm\data\data\"

rename ZCTA5CE10 svc_zip

joinby svc_zip using "zip code zone match.dta"

keep svc_zip svc_zip_original sitenum DISTANCE

*****keep a part
keep if svc_zip==85009 | svc_zip==85040 | svc_zip==85256

joinby sitenum using "air pollution hourly part.dta"

replace timelocal=substr(timelocal,1,2)

destring timelocal, replace

egen v_=wtmean(samplemeasurement), weight(1/DISTANCE) by(svc_zip_original datelocal timelocal parametername)

gen year=substr(datelocal,1,4)
gen month=substr(datelocal,6,2)
gen day=substr(datelocal,9,2)

destring year month day, replace

keep svc_zip_original year month day timelocal parametername v_

duplicates drop svc_zip_original year month day timelocal parametername, force

reshape wide v_, i(year month day timelocal svc_zip_original) j(parametername) string

rename svc_zip_original svc_zip

save "air pollution hourly.dta", replace
