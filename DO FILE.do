describe
 keep b1 b2 b3 b4 b21 b20 b17 hw1 hw2 hw3 hw70 hw71 hw72 hw73 v005 v021 v022  v106 v190

. rename b1 Month_of_birth

. rename b2 Year_of_birth

. rename b3 dob

. rename b4 gender

. rename b21 Duration_of_pregnancy

. rename b20 Duration_of_pregnancy_months

. rename b17 Day_of_birth

. rename hw1 age_in_months

. rename hw2 weight_kg

. rename hw3 height_cm

. rename hw70 haz

. rename hw71 waz

. rename hw72 whz 

. rename hw73 BMI_standard_deviation

. rename v005 sample_weight

. rename v021 cluster

. rename v022 strata
 rename v106 mother_edu

. rename v190 wealth_index

# missing variables
misstable summarize
# RECODE DHS MISSING / FLAGGED VALUES
foreach var in weight_kg height_cm haz waz whz BMI_standard {
    replace `var' = . if inlist(`var', 9994, 9995, 9996, 9997, 9998, 9999)
}
#Rescale height and weight

replace height_cm = height_cm/10
replace weight_kg = weight_kg/10

#Rescale Z-scores
replace haz = haz/100
replace waz = waz/100
replace whz = whz/100
replace bmiz = bmiz/100

#drops values out of range
drop if height_cm < 45 | height_cm > 120
drop if weight_kg < 2 | weight_kg > 40

drop if haz < -6 | haz > 6
drop if waz < -6 | waz > 5
drop if whz < -5 | whz > 5
drop if BMI_standard_deviation < -5 | BMI_standard_deviation > 5

summ height_cm weight_kg haz waz whz

# CREATE MALNUTRITION INDICATORS
gen stunted = haz < -2 if !missing(haz)
gen underweight = waz < -2 if !missing(waz)
gen wasted = whz < -2 if !missing(whz)

#Define a “yes/no” label
label define yesno 0 "No" 1 "Yes"
#Apply the label to your indicators
label values stunted underweight wasted yesno

**Convert DHS sampling weight
gen sw = sample_weight/1000000

**Define survey design
svyset cluster [pweight=sw], strata(strata)

* Weighted prevalence estimates
svy: mean stunted wasted underweight

* Optional: stratified prevalence by sex
svy: mean stunted underweight wasted, over(gender)

label define sexlbl 1 "Male" 2 "Female"
label values gender sexlbl

svy: mean stunted wasted underweight, over(gender)


* Optional: stratified prevalence by age group
gen age_group = .
replace age_group = 0 if age_in_months < 6
replace age_group = 1 if inrange(age_in_months,6,11)
replace age_group = 2 if inrange(age_in_months,12,23)
replace age_group = 3 if inrange(age_in_months,24,35)
replace age_group = 4 if inrange(age_in_months,36,47)
replace age_group = 5 if inrange(age_in_months,48,59)

svy: mean stunted underweight wasted, over(age_group)


svy: mean stunted wasted underweight
estimates store national

graph bar (mean) stunted [pweight=sw], ///
    over(age_group) ///
    title("Stunting Prevalence by Age Group") ///
    ytitle("Proportion")
	**Identify hotspots (regional / county targeting
	svy: mean stunted wasted underweight, over(region)
	
describe
misstable summarize
summ
svy: mean stunted wasted underweight
summ height_cm weight_kg haz waz whz
svy: mean stunted underweight wasted, over(gender)
svy: mean stunted underweight wasted, over(age_group)
svy: mean stunted wasted underweight, over(Region)
svy: mean stunted wasted underweight, over(wealth_index)
replace age_group = 1 if age_in_months < 6
replace age_group = 2 if inrange(age_in_months,6,11)
replace age_group = 3 if inrange(age_in_months,12,23)
replace age_group = 4 if inrange(age_in_months,24,35)
replace age_group = 5 if inrange(age_in_months,36,47)
replace age_group = 6 if inrange(age_in_months,48,59)
label define agegrp 1 "<6m" 2 "6–11m" 3 "12–23m" 4 "24–35m" 5 "36–47m" 6 "48–59m"
label values age_group agegrp
svy: mean stunted wasted underweight, over(age_group)
svy: mean stunted wasted underweight, over(gender)
svy: mean stunted wasted underweight, over(wealth_index)
svy: mean stunted wasted underweight, over(mother_edu)
svy: mean stunted, over(Region)
estat sd
preserve
collapse (mean) stunted wasted underweight [pweight=sw], by(Region)

export delimited using "region_prevalence.csv", replace
restore
preserve
collapse (mean) stunted wasted underweight [pweight=sw]
export delimited using "national_prevalence.csv", replace
restore
preserve
collapse (mean) stunted wasted underweight [pweight=sw], by(age_group)
export delimited using "agegroup_prevalence.csv", replace
restore
preserve
collapse (mean) stunted wasted underweight [pweight=sw], by(gender)
export delimited using "gender_prevalence.csv", replace
restore
preserve
collapse (mean) stunted wasted underweight [pweight=sw], by(mother_edu)
export delimited using "motheredu_prevalence.csv", replace
restore


gen stunted_bin = haz < -2 if haz != .

svy: logit stunted_bin i.gender c.age_in_months i.mother_edu i.wealth_index i.Region, or
