clear
set more off
global path E:\sand storm\data\data\
cd "E:\sand storm\data\data\"


clear

use "residential solar electricity data.dta", clear

gen sample_count=1

egen sample_size=sum(sample_count), by(vmatchbk)

keep vmatchbk sample_size

duplicates drop vmatchbk, force

drop if sample_size<365*3

save "statsby sample size.dta", replace




clear all

use "residents_PM10.dta", clear

duplicates drop vmatchbk, force

merge 1:m vmatchbk using "residents_PM25.dta"
drop _merge

merge 1:1 vmatchbk using "household survey.dta"
drop if _merge==2
drop _merge

merge 1:1 vmatchbk using "statsby sample size.dta"
drop if _merge!=3
drop _merge

merge 1:m vmatchbk using "residential solar electricity data.dta"
drop if _merge==2
drop _merge

duplicates drop vmatchbk, force

gen t_PM10=b_v_PM10_mean/se_v_PM10_mean*sqrt(873)
gen t_PM25=b_v_PM10_mean/se_v_PM25_mean*sqrt(873)

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

gen incomegroupn=.
replace incomegroupn=1 if incomegroup=="Lower income"
replace incomegroupn=2 if incomegroup=="Middle income"
replace incomegroupn=3 if incomegroup=="Upper income"

gen ethnicgroupn=.
replace ethnicgroupn=0 if ethnicgroup=="White"
replace ethnicgroupn=1 if ethnicgroup=="Asian"
replace ethnicgroupn=2 if ethnicgroup=="Hispanic"
*replace ethnicgroupn=3 if ethnicgroup=="Black"
replace ethnicgroupn=4 if ethnicgroup=="Other"

destring squarefeet, replace

gen b_v_PM10=b_v_PM10_mean
gen b_v_PM25=b_v_PM25_mean
replace b_v_PM10=0 if t_PM10>-1.96 & t_PM10<1.96  
replace b_v_PM25=0 if t_PM25>-1.96 & t_PM25<1.96

*drop if b_v_PM10_mean<-10

egen rank_PM10=rank(b_v_PM10_mean)
egen rank_PM25=rank(b_v_PM25_mean)

gen CI_l_PM10=b_v_PM10_mean-1.96*se_v_PM10_mean
gen CI_u_PM10=b_v_PM10_mean+1.96*se_v_PM10_mean
gen CI_l_PM25=b_v_PM25_mean-1.96*se_v_PM25_mean
gen CI_u_PM25=b_v_PM25_mean+1.96*se_v_PM25_mean

save "residential statsby.dta", replace  

set more off
tabstat b_v_PM10_mean, by(incomegroup) statistics(N mean sd min max) save
mat StatTotal=r(StatTotal)'
mat Stat1=r(Stat1)'
mat Stat2=r(Stat2)'
mat Stat3=r(Stat3)'

putexcel set "residential descriptive statistics statsby.csv", modify // remember to specify the full path
putexcel A1 = matrix(StatTotal,names)
putexcel B2 = matrix(Stat1)
putexcel B3 = matrix(Stat2)
putexcel B4 = matrix(Stat3)

tabstat b_v_PM25_mean, by(incomegroup) statistics(N mean sd min max) save
mat Stat1=r(Stat1)'
mat Stat2=r(Stat2)'
mat Stat3=r(Stat3)'

putexcel set "residential descriptive statistics statsby.csv", modify // remember to specify the full path
putexcel B5 = matrix(Stat1)
putexcel B6 = matrix(Stat2)
putexcel B7 = matrix(Stat3)

set more off
tabstat b_v_PM10_mean, by(ethnicgroup) statistics(N mean sd min max) save
mat Stat1=r(Stat4)'
mat Stat2=r(Stat1)'
mat Stat3=r(Stat2)'
mat Stat4=r(Stat3)'

putexcel set "residential descriptive statistics statsby.csv", modify // remember to specify the full path
putexcel B8 = matrix(Stat1)
putexcel B9 = matrix(Stat2)
putexcel B10 = matrix(Stat3)
putexcel B11 = matrix(Stat4)

tabstat b_v_PM25_mean, by(ethnicgroup) statistics(N mean sd min max) save
mat Stat1=r(Stat4)'
mat Stat2=r(Stat1)'
mat Stat3=r(Stat2)'
mat Stat4=r(Stat3)'

putexcel set "residential descriptive statistics statsby.csv", modify // remember to specify the full path
putexcel B12 = matrix(Stat1)
putexcel B13 = matrix(Stat2)
putexcel B14 = matrix(Stat3)
putexcel B15 = matrix(Stat4)

bysort ethnicgroup: sum squarefeet

table ethnicgroup banner1ageofresidenceyears


bysort incomegroup: sum squarefeet

bysort incomegroup: sum b_v_PM10_mean b_v_PM25_mean

bysort ethnicgroup: sum b_v_PM10_mean b_v_PM25_mean

reg b_v_PM10_mean i.incomegroupn i.ethnicgroupn squarefeet

reg b_v_PM25_mean i.incomegroupn i.ethnicgroupn squarefeet

anova b_v_PM10_mean i.incomegroupn i.ethnicgroupn
anova b_v_PM25_mean i.incomegroupn i.ethnicgroupn
