clear
capture log close
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"


clear
use "commercial solar electricity data.dta", clear

drop temp

gen zipcode=svc_zip

gen pinal=(zipcode==85118 |zipcode==85119 | zipcode==85120 ///
|zipcode==85132 | zipcode==85140 | zipcode==85143 )
gen countyname="pinal" if pinal==1
replace countyname="maricopa" if pinal==0

**********merge data
*naics code
merge m:1 bilacct_k using "naic.dta"
drop if _merge==2
drop _merge

*climate
gen month=month(date)
gen year=year(date)
gen day=day(date)

tostring svc_zip, replace

merge m:1 svc_zip year month day using "climate daily.dta"
drop if _merge==2
drop _merge

***wind direction
merge m:1 svc_zip year month day using "wind direction daily.dta"
drop if _merge==2
drop _merge

*percipitation
*merge m:1 year month day using "prcp record final.dta"
*drop if _merge==2
*drop _merge

*air pollution concentration
destring svc_zip, replace
merge m:1 svc_zip year month day using "air pollution daily.dta", force 
drop if _merge==2
drop _merge

*AQI new
merge m:1 countyname year month day using "AQI final new.dta" 
drop if _merge==2
drop _merge


*sand storm
merge m:1 year month day using "sand storm final.dta"
drop if _merge==2
drop _merge
replace stormevent=0 if stormevent==.


*thermal inversion
merge m:1 date using "therminv.dta"
rename therm_inv inversion
drop if _merge==2
drop _merge

***solar radiation
merge m:1 year month day using "solar irradiance.dta"
drop if _merge==2
drop _merge


gen summer=(month>=5 & month<=10)
rename cons consum
drop if consum<0
gen lnconsum=ln(consum)

rename bilacct_k vmatchbk

*gen solarinv=solar_treat*inversion

gen temp2=temp^2

egen iddate=group(vmatchbk day month)

xtset vmatchbk date

gen naic_2=substr(naic,1,2)

capture drop sector

gen sector="Others"
*replace sector="Agriculture, forestry, fishing and hunting" if naic_2=="11"
*replace sector="Mining, quarrying, and oil and gas extraction" if naic_2=="21"
*replace sector="Utilities" if naic_2=="22"
*replace sector="Construction" if naic_2=="23"
*replace sector="Manufacturing" if naic_2=="31" | naic_2=="32" | naic_2=="33"
*replace sector="Wholesale trade" if naic_2=="42"
replace sector="Retail trade" if naic_2=="44" | naic_2=="45" 
*replace sector="Transportation and warehousing" if naic_2=="48" | naic_2=="49"
*replace sector="Information" if naic_2=="51"
*replace sector="Finance and insurance" if naic_2=="52"
*replace sector="Real estate and rental and leasing" if naic_2=="53"
*replace sector="Professional, scientific, and technical services" if naic_2=="54"
*replace sector="Management of companies and enterprises" if naic_2=="55"
*replace sector="Administrative and support and waste management and remediation services" if naic_2=="56"
*replace sector="Educational services" if naic_2=="61"
*replace sector="Health care and social assistance" if naic_2=="62"
replace sector="Arts, entertainment, and recreation" if naic_2=="71"
replace sector="Accommodation and food services" if naic_2=="72"
replace sector="Other services (except public administration)" if naic_2=="81"
*replace sector="Public administration" if naic_2=="92"

replace sector="Recreation and services" if naic_2=="71" | naic_2=="72" | naic_2=="81"

gen lndcharge=ln(dcharge)
gen lnecharge=ln(echarge)

gen cdd_new=max(temp*1.8+32-65, 0)
gen hdd_new=max(65-temp*1.8-32, 0)

*xtset iddate year

*mkspline temp_range 6 = temp, pctile

egen alwayszero=max(consum), by(vmatchbk)

drop if alwayszero==0

**********************descriptive statistics
gen solar_treat=0
replace solar_treat=1 if solar_date!=.
 
*xttab solar_treat

set more off
tabstat consum v_PM10_mean v_PM25_mean v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd dcharge echarge, statistics( N mean sd min max) save
mat StatTotal=r(StatTotal)'

putexcel set "commercial descriptive statistics.csv",replace // remember to specify the full path
putexcel A1 = matrix(StatTotal,names)

tabstat he_dy, by(solar_treat) statistics( N mean sd min max) save
mat StatTotal=r(StatTotal)'
mat Stat1=r(Stat1)'
mat Stat2=r(Stat2)'

putexcel set "commercial descriptive statistics.csv",modify // remember to specify the full path
putexcel A13 = matrix(StatTotal,names)
putexcel B14 = matrix(Stat1)
putexcel B15 = matrix(Stat2)

tabstat consum v_PM10_mean v_PM25_mean, by(sector) statistics( N mean sd min max) save
mat StatTotal=r(StatTotal)'
mat Stat1=r(Stat1)'
mat Stat2=r(Stat2)'
mat Stat3=r(Stat3)'

putexcel set "commercial descriptive statistics.csv",modify // remember to specify the full path
putexcel A16 = matrix(StatTotal,names)
putexcel B17 = matrix(Stat1)
putexcel B20 = matrix(Stat2)
putexcel B23 = matrix(Stat3)


preserve

duplicates drop vmatchbk, force
set more off
tabstat kw_ac kw_dc, statistics( N mean sd min max) save
mat StatTotal=r(StatTotal)'
mat Stat1=r(Stat1)'
mat Stat2=r(Stat2)'
mat Stat3=r(Stat3)'
mat Stat4=r(Stat4)'

putexcel set "commercial descriptive statistics.csv",modify // remember to specify the full path
putexcel A27 = matrix(StatTotal,names)

restore



**********************main analysis

set more off
xtreg consum v_PM10_mean v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday, fe vce(cluster vmatchbk)
estimates store pm10_gls

set more off
xi: xtivreg2 consum (v_PM10_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday, fe cluster(vmatchbk) first savefirst
estimates store pm10_iv

set more off
xtreg consum v_PM25_mean v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday, fe vce(cluster vmatchbk)
estimates store pm25_gls

set more off
xi: xtivreg2 consum (v_PM25_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday, fe cluster(vmatchbk) first savefirst
estimates store pm25_iv

esttab pm10_gls _xtivreg2_v_PM10_mean pm10_iv pm25_gls _xtivreg2_v_PM25_mean pm25_iv ///
 using "commercial results.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(wind_cos v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 order(wind_cos v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 coeflabels(wind_cos "Wind cosine" v_PM10_mean "PM10 concentration" v_PM25_mean "PM2.5 concentration" v_Ozone_max8hour "Ozone concentration" ///
 hdd_new "Heating degree days" cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" rhmd "Relative humidity" dcharge "Demand charge (log)" echarge "Energy charge (log)" Surfacealbedo_a "Solar irradiance" _cons "Constant") ///
 mtitle("GLS" "IV" "IV" "GLS" "IV" "IV")





**********************main analysis without outlier, 500
set more off
xtreg consum v_PM10_mean v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=500, fe vce(cluster vmatchbk)
estimates store pm10_gls

set more off
xi: xtivreg2 consum (v_PM10_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=500, fe cluster(vmatchbk) first savefirst
estimates store pm10_iv

set more off
xtreg consum v_PM25_mean v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=500, fe vce(cluster vmatchbk)
estimates store pm25_gls

set more off
xi: xtivreg2 consum (v_PM25_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=500, fe cluster(vmatchbk) first savefirst
estimates store pm25_iv

esttab pm10_gls _xtivreg2_v_PM10_mean pm10_iv pm25_gls _xtivreg2_v_PM25_mean pm25_iv ///
 using "commercial results outlier 500.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(wind_cos v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 order(wind_cos v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 coeflabels(wind_cos "Wind cosine" v_PM10_mean "PM10 concentration" v_PM25_mean "PM2.5 concentration" v_Ozone_max8hour "Ozone concentration" ///
 hdd_new "Heating degree days" cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" rhmd "Relative humidity" dcharge "Demand charge (log)" echarge "Energy charge (log)" Surfacealbedo_a "Solar irradiance" _cons "Constant") ///
 mtitle("GLS" "IV" "IV" "GLS" "IV" "IV")



**********************main analysis without outlier, 1000
set more off
xtreg consum v_PM10_mean v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=1000, fe vce(cluster vmatchbk)
estimates store pm10_gls

set more off
xi: xtivreg2 consum (v_PM10_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=1000, fe cluster(vmatchbk) first savefirst
estimates store pm10_iv

set more off
xtreg consum v_PM25_mean v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=1000, fe vce(cluster vmatchbk)
estimates store pm25_gls

set more off
xi: xtivreg2 consum (v_PM25_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if alwayszero<=1000, fe cluster(vmatchbk) first savefirst
estimates store pm25_iv

esttab pm10_gls _xtivreg2_v_PM10_mean pm10_iv pm25_gls _xtivreg2_v_PM25_mean pm25_iv ///
 using "commercial results outlier 1000.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(wind_cos v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 order(wind_cos v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 coeflabels(wind_cos "Wind cosine" v_PM10_mean "PM10 concentration" v_PM25_mean "PM2.5 concentration" v_Ozone_max8hour "Ozone concentration" ///
 hdd_new "Heating degree days" cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" rhmd "Relative humidity" dcharge "Demand charge (log)" echarge "Energy charge (log)" Surfacealbedo_a "Solar irradiance" _cons "Constant") ///
 mtitle("GLS" "IV" "IV" "GLS" "IV" "IV")
 
 
 
***by sector
set more off
xtivreg consum (v_PM10_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if sector=="Retail trade", fe vce(cluster vmatchbk) first
estimates store pm10_retail

set more off
xtivreg consum (v_PM10_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if sector=="Recreation and services", fe vce(cluster vmatchbk) first
estimates store pm10_recreation

set more off
xtivreg consum (v_PM10_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if sector=="Others", fe vce(cluster vmatchbk) first
estimates store pm10_other

set more off
xtivreg consum (v_PM25_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if sector=="Retail trade", fe vce(cluster vmatchbk) first
estimates store pm25_retail

set more off
xtivreg consum (v_PM25_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if sector=="Recreation and services", fe vce(cluster vmatchbk) first
estimates store pm25_recreation

set more off
xtivreg consum (v_PM25_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lndcharge lnecharge i.year i.month weekend holiday if sector=="Others", fe vce(cluster vmatchbk) first
estimates store pm25_other

esttab pm10_retail pm10_recreation pm10_other pm25_retail pm25_recreation pm25_other ///
 using "commercial sector results.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 order(v_PM10_mean v_PM25_mean v_Ozone_max8hour hdd_new cdd_new prcp wdsp rhmd lndcharge lnecharge _cons) ///
 coeflabels(v_PM10_mean "PM10 concentration" v_PM25_mean "PM2.5 concentration" v_Ozone_max8hour "Ozone concentration" ///
 hdd_new "Heating degree days" cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" rhmd "Relative humidity" dcharge "Demand charge (log)" echarge "Energy charge (log)" Surfacealbedo_a "Solar irradiance" _cons "Constant") ///
 mtitle("Retail trade" "Recreation and services" "Others" "Retail trade" "Recreation and services" "Others")


 
***solar 
gen lnhe_dy=ln(he_dy)

set more off
xtreg he_dy v_PM10_mean cdd_new hdd_new prcp wdsp lndcharge lnecharge Surfacealbedo_a i.year weekend holiday, fe vce(cluster vmatchbk)
estimates store pm10_gls_solar

set more off
xi: xtivreg2 he_dy (v_PM10_mean=wind_cos) cdd_new hdd_new prcp wdsp lndcharge lnecharge Surfacealbedo_a i.year weekend holiday, fe cluster(vmatchbk) first savefirst
estimates store pm10_iv_solar

set more off
xtreg he_dy v_PM25_mean cdd_new hdd_new prcp wdsp lndcharge lnecharge Surfacealbedo_a i.year weekend holiday, fe vce(cluster vmatchbk)
estimates store pm25_gls_solar

set more off
xi: xtivreg2 he_dy (v_PM25_mean=wind_cos) cdd_new hdd_new prcp wdsp lndcharge lnecharge Surfacealbedo_a i.year weekend holiday, fe cluster(vmatchbk) first savefirst
estimates store pm25_iv_solar


esttab pm10_gls_solar _xtivreg2_v_PM10_mean pm10_iv_solar pm25_gls_solar _xtivreg2_v_PM25_mean pm25_iv_solar ///
 using "commercial solar results.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) ///
 keep(wind_cos v_PM10_mean v_PM25_mean hdd_new cdd_new prcp wdsp lndcharge lnecharge Surfacealbedo_a _cons) ///
 order(wind_cos v_PM10_mean v_PM25_mean hdd_new cdd_new prcp wdsp lndcharge lnecharge Surfacealbedo_a _cons) ///
 coeflabels(wind_cos "Wind cosine" v_PM10_mean "PM10 concentration" v_PM25_mean "PM2.5 concentration" hdd_new "Heating degree days" ///
 cdd_new "Cooling degree days" prcp "Precipitation"  ///
 wdsp "Wind speed" dcharge "Demand charge (log)" echarge "Energy charge (log)" Surfacealbedo_a "Solar irradiance" _cons "Constant") ///
 mtitle("GLS" "IV" "IV" "GLS" "IV" "IV")

