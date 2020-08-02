clear
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\storm\dofile\hourly climate and electricity consumption\data"




clear

use "ret.dta", clear

duplicates drop vmatchbk svc_zip rate date, force

reshape long kwh, i(vmatchbk svc_zip rate date) j(timelocal) string

destring timelocal, replace

replace date=date+1 if timelocal==24

replace timelocal=0 if timelocal==24

gen month=month(date)
gen year=year(date)
gen day=day(date)

**********merge data
***household characteristics
merge m:1 vmatchbk year month day using "household characteristics.dta"
drop if _merge==2
drop _merge

gen pinal=(zipcode==85118 |zipcode==85119 | zipcode==85120 ///
|zipcode==85132 | zipcode==85140 | zipcode==85143 )
gen countyname="Pinal" if pinal==1
replace countyname="Maricopa" if pinal==0

egen _holiday=max(holiday), by(year month day)
egen _weekend=max(weekend), by(year month day)

drop holiday weekend

rename _holiday holiday
rename _weekend weekend

***ethnic group
merge m:1 vmatchbk using "household survey.dta"
drop if _merge==2
drop _merge

*climate daily
merge m:1 svc_zip year month day using "climate daily.dta"
drop if _merge==2
drop _merge

*climate hourly
destring svc_zip, replace
merge m:1 svc_zip year month day timelocal using "climate hourly.dta", force
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

***hourly air pollution
merge m:1 svc_zip year month day timelocal using "air pollution hourly.dta", force 
drop if _merge==2
drop _merge

rename kwh consum
drop if consum<0
gen lnconsum=ln(consum)
gen lnprice=ln(price)
gen lnhousehold_income=ln(household_income)

***outage events
gen summer=(month>=5 & month<=10)

gen temp2=temp^2

egen iddate=group(vmatchbk day month)

egen datetime=group(year day month timelocal)

xtset vmatchbk datetime

*xtset iddate year


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


gen cdd_new=max(v_temp*1.8+32-65, 0)
gen hdd_new=max(65-v_temp*1.8-32, 0)



**********************main analysis
preserve
***no price
set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent i.year i.month weekend holiday, fe vce(cluster vmatchbk)
estimates store pm10_gls_noprice

matrix pm10_gls_noprice=e(b)'
svmat pm10_gls_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_gls_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_gls_noprice_u)

matrix test=e(V)
matrix pm10_gls_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_gls_noprice_V

matrix pm10_gls_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_gls_noprice_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent i.year i.month weekend holiday, fe vce(cluster vmatchbk)
estimates store pm25_gls_noprice

matrix pm25_gls_noprice=e(b)'
svmat pm25_gls_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_gls_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_gls_noprice_u)

matrix test=e(V)
matrix pm25_gls_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_gls_noprice_V

matrix pm25_gls_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_gls_noprice_CV


***with price
set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent lnprice i.year i.month weekend holiday, fe vce(cluster vmatchbk)
estimates store pm10_gls_price

matrix pm10_gls_price=e(b)'
svmat pm10_gls_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_gls_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_gls_price_u)

matrix test=e(V)
matrix pm10_gls_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_gls_price_V

matrix pm10_gls_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_gls_price_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent lnprice i.year i.month weekend holiday, fe vce(cluster vmatchbk)
estimates store pm25_gls_price

matrix pm25_gls_price=e(b)'
svmat pm25_gls_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_gls_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_gls_price_u)

matrix test=e(V)
matrix pm25_gls_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_gls_price_V

matrix pm25_gls_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_gls_price_CV

esttab pm10_gls_noprice pm25_gls_noprice pm10_gls_price pm25_gls_price ///
 using "residential results hourly.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) 

drop _est_*

keep pm10_gls* pm25_gls*

gen id=_n

keep if id==1 | (id>26 & id<50)
replace id=0 if id==1
replace id=id-26 if id!=0
 
reshape long pm10_gls pm25_gls, i(id) j(coefficient) string

rename pm10_gls estimationpm10
rename pm25_gls estimationpm25

reshape long estimation, i(id coefficient) j(variable) string

gen coef="c"
replace coef="l" if strpos(coefficient, "_l")>0
replace coef="u" if strpos(coefficient, "_u")>0
replace coef="V" if strpos(coefficient, "_V")>0
replace coef="CV" if strpos(coefficient, "_CV")>0
replace variable="PM10" if variable=="pm10"
replace variable="PM2.5" if variable=="pm25"

gen withprice=""
replace withprice="price controlled" if strpos(coefficient, "_price")>0
replace withprice="price not controlled" if strpos(coefficient, "_noprice")>0

replace estimation=. if id==0 & coef=="CV"
gen _c=estimation if coef=="c"
egen c=max(_c), by(id variable withprice)
gen _V=estimation if coef=="V"
egen V=max(_V), by(id variable withprice)
gen _CV=estimation if coef=="CV"
egen CV=max(_CV), by(id variable withprice)

gen _c0=estimation if coef=="c" & id==0
egen c0=max(_c0), by(variable withprice)
gen _V0=estimation if coef=="V" & id==0
egen V0=max(_V0), by(variable withprice)

gen estimation_new=estimation+c0 if coef=="c" & id!=0
replace estimation_new=estimation+c0+1.96*sqrt(V0+V+2*CV) if coef=="u" & id!=0
replace estimation_new=estimation+c0-1.96*sqrt(V0+V+2*CV) if coef=="l" & id!=0
replace estimation_new=estimation if id==0

drop coefficient _*

save "coefficient R air pollution and hourly residential electricity use.dta", replace

restore 
 
 
 

***by income
preserve
***no price
set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent i.year i.month weekend holiday if incomegroup=="Lower income", fe vce(cluster vmatchbk)
estimates store pm10_Low_noprice

matrix pm10_Low_noprice=e(b)'
svmat pm10_Low_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_Low_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_Low_noprice_u)

matrix test=e(V)
matrix pm10_Low_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_Low_noprice_V

matrix pm10_Low_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_Low_noprice_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent i.year i.month weekend holiday if incomegroup=="Middle income", fe vce(cluster vmatchbk)
estimates store pm10_Middle_noprice

matrix pm10_Middle_noprice=e(b)'
svmat pm10_Middle_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_Middle_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_Middle_noprice_u)

matrix test=e(V)
matrix pm10_Middle_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_Middle_noprice_V

matrix pm10_Middle_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_Middle_noprice_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent i.year i.month weekend holiday if incomegroup=="Upper income", fe vce(cluster vmatchbk)
estimates store pm10_High_noprice

matrix pm10_High_noprice=e(b)'
svmat pm10_High_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_High_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_High_noprice_u)

matrix test=e(V)
matrix pm10_High_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_High_noprice_V

matrix pm10_High_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_High_noprice_CV



set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if incomegroup=="Lower income", fe vce(cluster vmatchbk)
estimates store pm25_Low_noprice

matrix pm25_Low_noprice=e(b)'
svmat pm25_Low_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_Low_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_Low_noprice_u)

matrix test=e(V)
matrix pm25_Low_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_Low_noprice_V

matrix pm25_Low_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_Low_noprice_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if incomegroup=="Middle income", fe vce(cluster vmatchbk)
estimates store pm25_Middle_noprice

matrix pm25_Middle_noprice=e(b)'
svmat pm25_Middle_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_Middle_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_Middle_noprice_u)

matrix test=e(V)
matrix pm25_Middle_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_Middle_noprice_V

matrix pm25_Middle_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_Middle_noprice_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if incomegroup=="Upper income", fe vce(cluster vmatchbk)
estimates store pm25_High_noprice

matrix pm25_High_noprice=e(b)'
svmat pm25_High_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_High_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_High_noprice_u)

matrix test=e(V)
matrix pm25_High_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_High_noprice_V

matrix pm25_High_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_High_noprice_CV


***with price
set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent lnprice i.year i.month weekend holiday if incomegroup=="Lower income", fe vce(cluster vmatchbk)
estimates store pm10_Low_price

matrix pm10_Low_price=e(b)'
svmat pm10_Low_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_Low_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_Low_price_u)

matrix test=e(V)
matrix pm10_Low_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_Low_price_V

matrix pm10_Low_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_Low_price_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent lnprice i.year i.month weekend holiday if incomegroup=="Middle income", fe vce(cluster vmatchbk)
estimates store pm10_Middle_price

matrix pm10_Middle_price=e(b)'
svmat pm10_Middle_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_Middle_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_Middle_price_u)

matrix test=e(V)
matrix pm10_Middle_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_Middle_price_V

matrix pm10_Middle_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_Middle_price_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent lnprice i.year i.month weekend holiday if incomegroup=="Upper income", fe vce(cluster vmatchbk)
estimates store pm10_High_price

matrix pm10_High_price=e(b)'
svmat pm10_High_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_High_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_High_price_u)

matrix test=e(V)
matrix pm10_High_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_High_price_V

matrix pm10_High_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_High_price_CV



set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if incomegroup=="Lower income", fe vce(cluster vmatchbk)
estimates store pm25_Low_price

matrix pm25_Low_price=e(b)'
svmat pm25_Low_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_Low_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_Low_price_u)

matrix test=e(V)
matrix pm25_Low_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_Low_price_V

matrix pm25_Low_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_Low_price_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if incomegroup=="Middle income", fe vce(cluster vmatchbk)
estimates store pm25_Middle_price

matrix pm25_Middle_price=e(b)'
svmat pm25_Middle_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_Middle_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_Middle_price_u)

matrix test=e(V)
matrix pm25_Middle_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_Middle_price_V

matrix pm25_Middle_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_Middle_price_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if incomegroup=="Upper income", fe vce(cluster vmatchbk)
estimates store pm25_High_price

matrix pm25_High_price=e(b)'
svmat pm25_High_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_High_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_High_price_u)

matrix test=e(V)
matrix pm25_High_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_High_price_V

matrix pm25_High_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_High_price_CV


esttab pm10_Low_noprice pm10_Middle_noprice pm10_High_noprice pm25_Low_noprice pm25_Middle_noprice pm25_High_noprice ///
pm10_Low_price pm10_Middle_price pm10_High_price pm25_Low_price pm25_Middle_price pm25_High_price ///
 using "residential income results hourly.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) 


drop _est_*

keep pm10* pm25*

gen id=_n

keep if id==1 | (id>26 & id<50)
replace id=0 if id==1
replace id=id-26 if id!=0
 
reshape long pm10 pm25, i(id) j(coefficient) string

rename pm10 estimationpm10
rename pm25 estimationpm25

reshape long estimation, i(id coefficient) j(variable) string

gen coef="c"
replace coef="l" if strpos(coefficient, "_l")>0
replace coef="u" if strpos(coefficient, "_u")>0
replace coef="V" if strpos(coefficient, "_V")>0
replace coef="CV" if strpos(coefficient, "_CV")>0
replace variable="PM10" if variable=="pm10"
replace variable="PM2.5" if variable=="pm25"

gen withprice=""
replace withprice="price controlled" if strpos(coefficient, "_price")>0
replace withprice="price not controlled" if strpos(coefficient, "_noprice")>0

gen income=""
replace income="Lower income" if strpos(coefficient, "_Low")>0
replace income="Middle income" if strpos(coefficient, "_Middle")>0
replace income="Upper income" if strpos(coefficient, "_High")>0

replace estimation=. if id==0 & coef=="CV"
gen _c=estimation if coef=="c"
egen c=max(_c), by(id variable withprice income)
gen _V=estimation if coef=="V"
egen V=max(_V), by(id variable withprice income)
gen _CV=estimation if coef=="CV"
egen CV=max(_CV), by(id variable withprice income)

gen _c0=estimation if coef=="c" & id==0
egen c0=max(_c0), by(variable withprice income)
gen _V0=estimation if coef=="V" & id==0
egen V0=max(_V0), by(variable withprice income)

gen estimation_new=estimation+c0 if coef=="c" & id!=0
replace estimation_new=estimation+c0+1.96*sqrt(V0+V+2*CV) if coef=="u" & id!=0
replace estimation_new=estimation+c0-1.96*sqrt(V0+V+2*CV) if coef=="l" & id!=0
replace estimation_new=estimation if id==0

drop coefficient _*

save "coefficient R air pollution and hourly residential electricity use income.dta", replace

restore  
 

/* 
use "coefficient R air pollution and hourly residential electricity use income.dta",clear

egen test=max(estimation) if coef=="l" & income=="Lower income", by(id variable withprice income)

gen test1=estimation

replace coef="c" if test==test1 & test!=.
*/
 

***by ethnic group
preserve
***no price
set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="White", fe vce(cluster vmatchbk)
estimates store pm10_white_noprice

matrix pm10_white_noprice=e(b)'
svmat pm10_white_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_white_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_white_noprice_u)

matrix test=e(V)
matrix pm10_white_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_white_noprice_V

matrix pm10_white_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_white_noprice_CV



set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="Hispanic", fe vce(cluster vmatchbk)
estimates store pm10_hispanic_noprice

matrix pm10_hispanic_noprice=e(b)'
svmat pm10_hispanic_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_hispanic_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_hispanic_noprice_u)

matrix test=e(V)
matrix pm10_hispanic_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_hispanic_noprice_V

matrix pm10_hispanic_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_hispanic_noprice_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="Asian", fe vce(cluster vmatchbk)
estimates store pm10_asian_noprice

matrix pm10_asian_noprice=e(b)'
svmat pm10_asian_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_asian_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_asian_noprice_u)

matrix test=e(V)
matrix pm10_asian_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_asian_noprice_V

matrix pm10_asian_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_asian_noprice_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="Other", fe vce(cluster vmatchbk)
estimates store pm10_other_noprice

matrix pm10_other_noprice=e(b)'
svmat pm10_other_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_other_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_other_noprice_u)

matrix test=e(V)
matrix pm10_other_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_other_noprice_V

matrix pm10_other_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_other_noprice_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="White", fe vce(cluster vmatchbk)
estimates store pm25_white_noprice

matrix pm25_white_noprice=e(b)'
svmat pm25_white_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_white_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_white_noprice_u)

matrix test=e(V)
matrix pm25_white_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_white_noprice_V

matrix pm25_white_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_white_noprice_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="Hispanic", fe vce(cluster vmatchbk)
estimates store pm25_hispanic_noprice

matrix pm25_hispanic_noprice=e(b)'
svmat pm25_hispanic_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_hispanic_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_hispanic_noprice_u)

matrix test=e(V)
matrix pm25_hispanic_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_hispanic_noprice_V

matrix pm25_hispanic_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_hispanic_noprice_CV

set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="Asian", fe vce(cluster vmatchbk)
estimates store pm25_asian_noprice

matrix pm25_asian_noprice=e(b)'
svmat pm25_asian_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_asian_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_asian_noprice_u)

matrix test=e(V)
matrix pm25_asian_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_asian_noprice_V

matrix pm25_asian_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_asian_noprice_CV

set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if ethnicgroup=="Other", fe vce(cluster vmatchbk)
estimates store pm25_other_noprice

matrix pm25_other_noprice=e(b)'
svmat pm25_other_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_other_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_other_noprice_u)

matrix test=e(V)
matrix pm25_other_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_other_noprice_V

matrix pm25_other_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_other_noprice_CV


***with price
set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="White", fe vce(cluster vmatchbk)
estimates store pm10_white_price

matrix pm10_white_price=e(b)'
svmat pm10_white_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_white_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_white_price_u)

matrix test=e(V)
matrix pm10_white_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_white_price_V

matrix pm10_white_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_white_price_CV



set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="Hispanic", fe vce(cluster vmatchbk)
estimates store pm10_hispanic_price

matrix pm10_hispanic_price=e(b)'
svmat pm10_hispanic_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_hispanic_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_hispanic_price_u)

matrix test=e(V)
matrix pm10_hispanic_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_hispanic_price_V

matrix pm10_hispanic_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_hispanic_price_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="Asian", fe vce(cluster vmatchbk)
estimates store pm10_asian_price

matrix pm10_asian_price=e(b)'
svmat pm10_asian_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_asian_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_asian_price_u)

matrix test=e(V)
matrix pm10_asian_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_asian_price_V

matrix pm10_asian_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_asian_price_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="Other", fe vce(cluster vmatchbk)
estimates store pm10_other_price

matrix pm10_other_price=e(b)'
svmat pm10_other_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_other_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_other_price_u)

matrix test=e(V)
matrix pm10_other_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_other_price_V

matrix pm10_other_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_other_price_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="White", fe vce(cluster vmatchbk)
estimates store pm25_white_price

matrix pm25_white_price=e(b)'
svmat pm25_white_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_white_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_white_price_u)

matrix test=e(V)
matrix pm25_white_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_white_price_V

matrix pm25_white_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_white_price_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="Hispanic", fe vce(cluster vmatchbk)
estimates store pm25_hispanic_price

matrix pm25_hispanic_price=e(b)'
svmat pm25_hispanic_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_hispanic_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_hispanic_price_u)

matrix test=e(V)
matrix pm25_hispanic_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_hispanic_price_V

matrix pm25_hispanic_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_hispanic_price_CV

set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="Asian", fe vce(cluster vmatchbk)
estimates store pm25_asian_price

matrix pm25_asian_price=e(b)'
svmat pm25_asian_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_asian_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_asian_price_u)

matrix test=e(V)
matrix pm25_asian_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_asian_price_V

matrix pm25_asian_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_asian_price_CV

set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lnprice i.year i.month weekend holiday if ethnicgroup=="Other", fe vce(cluster vmatchbk)
estimates store pm25_other_price

matrix pm25_other_price=e(b)'
svmat pm25_other_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_other_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_other_price_u)

matrix test=e(V)
matrix pm25_other_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_other_price_V

matrix pm25_other_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_other_price_CV


esttab pm10_white_noprice pm10_hispanic_noprice pm10_asian_noprice pm10_other_noprice ///
pm25_gls_white pm25_gls_hispanic pm25_gls_asian pm25_gls_other ///
 using "residential ethnic results hourly.csv", replace ///
 b(%6.3f) se(%6.3f) r2 star(* 0.10 ** 0.05  *** 0.01) 



drop _est_*

keep pm10* pm25*

gen id=_n

keep if id==1 | (id>26 & id<50)
replace id=0 if id==1
replace id=id-26 if id!=0
 
reshape long pm10 pm25, i(id) j(coefficient) string

rename pm10 estimationpm10
rename pm25 estimationpm25

reshape long estimation, i(id coefficient) j(variable) string

gen coef="c"
replace coef="l" if strpos(coefficient, "_l")>0
replace coef="u" if strpos(coefficient, "_u")>0
replace coef="V" if strpos(coefficient, "_V")>0
replace coef="CV" if strpos(coefficient, "_CV")>0
replace variable="PM10" if variable=="pm10"
replace variable="PM2.5" if variable=="pm25"

gen withprice=""
replace withprice="price controlled" if strpos(coefficient, "_price")>0
replace withprice="price not controlled" if strpos(coefficient, "_noprice")>0

gen ethnic=""
replace ethnic="Other" if strpos(coefficient, "_other")>0
replace ethnic="White" if strpos(coefficient, "_white")>0
replace ethnic="Hispanic" if strpos(coefficient, "_hispanic")>0
replace ethnic="Asian" if strpos(coefficient, "_asian")>0


replace estimation=. if id==0 & coef=="CV"
gen _c=estimation if coef=="c"
egen c=max(_c), by(id variable withprice ethnic)
gen _V=estimation if coef=="V"
egen V=max(_V), by(id variable withprice ethnic)
gen _CV=estimation if coef=="CV"
egen CV=max(_CV), by(id variable withprice ethnic)

gen _c0=estimation if coef=="c" & id==0
egen c0=max(_c0), by(variable withprice ethnic)
gen _V0=estimation if coef=="V" & id==0
egen V0=max(_V0), by(variable withprice ethnic)

gen estimation_new=estimation+c0 if coef=="c" & id!=0
replace estimation_new=estimation+c0+1.96*sqrt(V1+V+2*CV) if coef=="u" & id!=0
replace estimation_new=estimation+c0-1.96*sqrt(V1+V+2*CV) if coef=="l" & id!=0
replace estimation_new=estimation if id==0

drop coefficient _*

save "coefficient R air pollution and hourly residential electricity use ethnic.dta", replace

restore 
 
 