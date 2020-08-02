clear
capture log close
set more off
cd "E:\sand storm\storm\dofile\hourly climate and electricity consumption\data"


*************************hourly air pollution 

clear

import excel "list of zipcode zone.xlsx", sheet("air pollution hourly & zip code") firstrow

drop if DISTANCE>0.5

rename ZCTA5CE10 svc_zip

joinby svc_zip using "zip code zone match.dta"

keep svc_zip svc_zip_original sitenum DISTANCE

joinby sitenum using "air pollution hourly raw.dta"

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






***********************hourly climate
clear

import excel "list of zipcode zone.xlsx", sheet("air pollution hourly & zip code") firstrow

drop if DISTANCE>0.5

rename ZCTA5CE10 svc_zip

joinby svc_zip using "zip code zone match.dta"

keep svc_zip svc_zip_original sitenum DISTANCE

joinby sitenum using "climate hourly raw.dta"

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


