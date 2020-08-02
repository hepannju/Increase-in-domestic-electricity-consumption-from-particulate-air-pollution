clear
capture log close
set more off
cd "E:\sand storm\storm\dofile\hourly climate and electricity consumption\data"


clear
use "random_panel8.dta", clear

******select a part
rename zip svc_zip

gen zipcode=svc_zip

destring zipcode, replace

gen pinal=(zipcode==85118 |zipcode==85119 | zipcode==85120 ///
|zipcode==85132 | zipcode==85140 | zipcode==85143 )
gen countyname="pinal" if pinal==1
replace countyname="maricopa" if pinal==0

**********merge data
rename hr timelocal

replace date=date+1 if timelocal==24

replace timelocal=0 if timelocal==24

gen month=month(date)
gen year=year(date)
gen day=day(date)


*naics code
merge m:1 bilacct_k using "naic.dta"
drop if _merge==2
drop _merge

***commercial characteristics
rename bilacct_k vmatchbk
merge m:1 vmatchbk year month day using "commercial characteristics.dta"
drop if _merge==2
drop _merge

egen _holiday=max(holiday), by(year month day)
egen _weekend=max(weekend), by(year month day)

drop holiday weekend

rename _holiday holiday
rename _weekend weekend

*climate daily
merge m:1 svc_zip year month day using "climate daily.dta"
drop if _merge==2
drop _merge

*air pollution concentration
destring svc_zip, replace
merge m:1 svc_zip year month day timelocal using "air pollution hourly.dta", force 
drop if _merge==2
drop _merge

*climate hourly
merge m:1 svc_zip year month day timelocal using "climate hourly.dta", force
drop if _merge==2
drop _merge

*air pollution concentration
destring svc_zip, replace
merge m:1 svc_zip year month day using "air pollution daily.dta", force 
drop if _merge==2
drop _merge

*sand storm
merge m:1 year month day using "sand storm final.dta"
drop if _merge==2
drop _merge
replace stormevent=0 if stormevent==.



gen summer=(month>=5 & month<=10)
rename col1 consum
drop if consum<0
gen lnconsum=ln(consum)



*gen solarinv=solar_treat*inversion

gen temp2=temp^2

egen iddate=group(vmatchbk day month)

egen datetime=group(year day month timelocal)

xtset vmatchbk datetime


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

gen cdd_new=max(v_temp*1.8+32-65, 0)
gen hdd_new=max(65-v_temp*1.8-32, 0)

*xtset iddate year

*mkspline temp_range 6 = temp, pctile

egen alwayszero=max(consum), by(vmatchbk)

drop if alwayszero==0

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
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday, fe vce(cluster vmatchbk)
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
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp v_wdsp v_rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday, fe vce(cluster vmatchbk)
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


esttab pm10_gls_noprice pm25_gls_noprice pm10_gls_price pm25_gls_price  ///
 using "commercial results hourly.csv", replace ///
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

save "coefficient R air pollution and hourly commercial electricity use.dta", replace
 
restore
 
 
  
***by sector
preserve
***no price
set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if sector=="Retail trade", fe vce(cluster vmatchbk)
estimates store pm10_rtl_noprice

matrix pm10_rtl_noprice=e(b)'
svmat pm10_rtl_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_rtl_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_rtl_noprice_u)

matrix test=e(V)
matrix pm10_rtl_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_rtl_noprice_V

matrix pm10_rtl_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_rtl_noprice_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if sector=="Recreation and services", fe vce(cluster vmatchbk)
estimates store pm10_rcr_noprice

matrix pm10_rcr_noprice=e(b)'
svmat pm10_rcr_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_rcr_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_rcr_noprice_u)

matrix test=e(V)
matrix pm10_rcr_noprice_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_rcr_noprice_V

matrix pm10_rcr_noprice_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_rcr_noprice_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if sector=="Others", fe vce(cluster vmatchbk)
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
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if sector=="Retail trade", fe vce(cluster vmatchbk)
estimates store pm25_rtl_noprice

matrix pm25_rtl_noprice=e(b)'
svmat pm25_rtl_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_rtl_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_rtl_noprice_u)

matrix test=e(V)
matrix pm25_rtl_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_rtl_noprice_V

matrix pm25_rtl_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_rtl_noprice_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if sector=="Recreation and services", fe vce(cluster vmatchbk)
estimates store pm25_rcr_noprice

matrix pm25_rcr_noprice=e(b)'
svmat pm25_rcr_noprice

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_rcr_noprice_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_rcr_noprice_u)

matrix test=e(V)
matrix pm25_rcr_noprice_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_rcr_noprice_V

matrix pm25_rcr_noprice_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_rcr_noprice_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent i.year i.month weekend holiday if sector=="Others", fe vce(cluster vmatchbk)
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
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday if sector=="Retail trade", fe vce(cluster vmatchbk)
estimates store pm10_rtl_price

matrix pm10_rtl_price=e(b)'
svmat pm10_rtl_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_rtl_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_rtl_price_u)

matrix test=e(V)
matrix pm10_rtl_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_rtl_price_V

matrix pm10_rtl_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_rtl_price_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday if sector=="Recreation and services", fe vce(cluster vmatchbk)
estimates store pm10_rcr_price

matrix pm10_rcr_price=e(b)'
svmat pm10_rcr_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm10_rcr_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm10_rcr_price_u)

matrix test=e(V)
matrix pm10_rcr_price_V=vecdiag(test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10".."23.timelocal#cL.v_PM10"])'
svmat pm10_rcr_price_V

matrix pm10_rcr_price_CV=test["L.v_PM10".."23.timelocal#cL.v_PM10","L.v_PM10"]
svmat pm10_rcr_price_CV


set more off
xtreg consum c.l.v_PM10##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday if sector=="Others", fe vce(cluster vmatchbk)
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
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday if sector=="Retail trade", fe vce(cluster vmatchbk)
estimates store pm25_rtl_price

matrix pm25_rtl_price=e(b)'
svmat pm25_rtl_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_rtl_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_rtl_price_u)

matrix test=e(V)
matrix pm25_rtl_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_rtl_price_V

matrix pm25_rtl_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_rtl_price_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday if sector=="Recreation and services", fe vce(cluster vmatchbk)
estimates store pm25_rcr_price

matrix pm25_rcr_price=e(b)'
svmat pm25_rcr_price

mat r=r(table)
matrix ll=r["ll",....]'
svmat ll,names(pm25_rcr_price_l)

matrix ul=r["ul",....]'
svmat ul,names(pm25_rcr_price_u)

matrix test=e(V)
matrix pm25_rcr_price_V=vecdiag(test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25".."23.timelocal#cL.v_PM25"])'
svmat pm25_rcr_price_V

matrix pm25_rcr_price_CV=test["L.v_PM25".."23.timelocal#cL.v_PM25","L.v_PM25"]
svmat pm25_rcr_price_CV


set more off
xtreg consum c.l.v_PM25##i.timelocal l.v_Ozone cdd_new hdd_new prcp wdsp rhmd stormevent lndcharge lnecharge i.year i.month weekend holiday if sector=="Others", fe vce(cluster vmatchbk)
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

 
drop _est_*

keep pm10_* pm25_*

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

gen sector=""
replace sector="Others" if strpos(coefficient, "_other")>0
replace sector="Recreation and services" if strpos(coefficient, "_rcr")>0
replace sector="Retail trade" if strpos(coefficient, "_rtl")>0


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

save "coefficient R air pollution and hourly commercial electricity use sector.dta", replace

restore
