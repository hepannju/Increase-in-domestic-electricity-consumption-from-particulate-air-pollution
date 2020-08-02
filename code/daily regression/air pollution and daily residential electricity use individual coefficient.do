clear
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"



clear

use "residential solar electricity data.dta", clear

******select a part
keep if svc_zip=="85009" | svc_zip=="85040" | svc_zip=="85256"

/*
tempname uniform
gen `uniform' = uniform()
bysort vmatchbk: replace `uniform' = `uniform'[1]
keep if `uniform' <0.01
*/


rename temp temp_old

gen pinal=(zipcode==85118 |zipcode==85119 | zipcode==85120 ///
|zipcode==85132 | zipcode==85140 | zipcode==85143 )
gen countyname="Pinal" if pinal==1
replace countyname="Maricopa" if pinal==0


rename DATE date
**********merge data
***ethnic group
merge m:1 vmatchbk using "household survey.dta"
drop if _merge==2
drop _merge

*climate
rename mo month
rename yr year
rename dy day

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

drop if consum<0
gen lnconsum=ln(consum)
gen lnprice=ln(price)
gen lnhousehold_income=ln(household_income)

***outage events
gen summer=(month>=5 & month<=10)

*gen solarinv=solar_treat*inversion

gen temp2=temp^2

gen rhmd2=rhmd^2

egen iddate=group(vmatchbk day month)

xtset vmatchbk date

*xtset iddate year

gen overallaqivalue_white=overallaqivalue*white

gen overallaqivalue_solar=overallaqivalue*solar_treat

*income group: https://www.pewsocialtrends.org/2016/05/11/americas-shrinking-middle-class-a-close-look-at-changes-within-metropolitan-areas/st_2016-05-12_middle-class-geo-03/

gen incomegroup="Lower income" if householdn!=. & household_income!=.
replace incomegroup="Middle income" if householdn==1.5 & household_income>(24.042+34)/2
replace incomegroup="Middle income" if householdn==3.5 & household_income>(41.641+48.083)/2
replace incomegroup="Middle income" if householdn==5 & household_income>53.759
replace incomegroup="Upper income" if householdn==1.5 & household_income>(72.126+103.001)/2 
replace incomegroup="Upper income" if householdn==3.5 & household_income>(124.925+144.251)/2  
replace incomegroup="Upper income" if householdn==5 & household_income>161.277 

gen ethnicgroup="Other" if ethnic!=""
replace ethnicgroup="White" if ethnic=="White/Caucasian"
replace ethnicgroup="Hispanic" if ethnic=="Hispanic"
*replace ethnicgroup="Black" if ethnic=="Black or African American"
replace ethnicgroup="Asian" if ethnic=="Asian"

gen cdd_new=max(temp*1.8+32-65, 0)
gen hdd_new=max(65-temp*1.8-32, 0)

*mkspline cdd_range 5 = cdd_new, pctile
*mkspline hdd_range 5 = hdd_new, pctile

*mkspline temp_range 6 = temp, pctile

*mkspline temp_old_range 6 = temp_old, pctile
capture rm "residents_PM10.dta"
capture rm "residents_PM25.dta"

**********************main analysis
statsby b_v_PM10_mean=_b[v_PM10_mean] se_v_PM10_mean=_se[v_PM10_mean], by(vmatchbk) nodots saving(residents_PM10.dta) : ///
ivreg2 consum (v_PM10_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lnprice i.year i.month weekend holiday

statsby b_v_PM25_mean=_b[v_PM25_mean] se_v_PM25_mean=_se[v_PM25_mean], by(vmatchbk) nodots saving(residents_PM25.dta) : ///
ivreg2 consum (v_PM25_mean=wind_cos) v_Ozone_max8hour cdd_new hdd_new prcp wdsp rhmd lnprice i.year i.month weekend holiday



/*
twoway histogram solar_generation, color(*.5) || kdensity solar_generation*
sort solar_generation
gen id=_n
gen lc20=solar_generation-1.96*se_he
gen hc20=solar_generation+1.96*se_he
twoway line hc20 id, lpattern(dash) lcolor(grey) || ///
       line lc20 id, lpattern(dash) lcolor(grey) || ///
       line solar_generation id, lpattern(solid) lcolor(blue)  ///
       legend(off)  ///
       name(line, replace) xtitle("Households") ytitle("Change in daily electricity consumption (kWh)")
*/ 

