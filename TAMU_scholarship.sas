/* Author: Sneha Naik	 														        */
/* Purpose: SAS assignment to practice arrays and variable lists,		                */
/* 			combining data and producing reports.								        */

/* Include Header and librefs with necessary descriptions. */
libname datasets "/folders/myfolders/" access=readonly;
filename out11 "/folders/myfolders/output.pdf";

/* Housekeeping function to erase all existing titles and footnotes */
title;
footnote;
ods noproctitle;

/* Open pdf file to capture output, no style specified */
ods pdf file=out11;

proc format;
	value $groupfmt 'Single'='1' 'Several'='2 - 9' 'Ten or More'='10+' other='0';
run;


title "Rows with over 100% urban population";

proc print data=datasets.all_texas noobs;
	where pct_city > 1;
	format city_group $groupfmt.;
run;


/* Create a narrow table from the wide table to enlist funds */
/* Delete missing values of funds and retain index value i */
data student_funds;
	set datasets.tamu_scholarships;
	keep student_id i fund_code;
	array fundcodes{*} fund:;
	num_funds=dim(fundcodes);

	do i=1 to num_funds;

		if missing(fundcodes{i}) then
			delete;
		else
			fund_code=fundcodes{i};
		output;
	end;
run;

/* Sort the above dataset in place 	 */
proc sort data=student_funds;
	by fund_code;
run;


/* Create a sorted copy of the funds_list in work library */
proc sort data=datasets.funds_list out=funds_sorted;
	by fund_code;
run;

/* Merge sorted students funds and funds_sorted dataset */
/* Delete the rows where the awards are not rewarded to any student. */
data fund_type (keep=student_id i fund_code Category);
	merge student_funds funds_sorted;
	by fund_code;

	if missing(student_id) then
		delete;
run;


/* Transpose into a wide data set */
proc sort data=fund_type;
	by student_id;
run;

proc transpose data=fund_type prefix=FUND_TYPE out=wide_types  (drop=_name_ _label_);
	by student_id;
	id i;
	var category;
run;


/* Summarize the data from wide_types dataset and scholarships dataset  */
/* Create 3 new variables for Academic scholarship, Emergency scholarship and total funds */
data scholarship_funds;
	merge wide_types datasets.tamu_scholarships;
	by student_id;
	array fund_type{*} fund_type:;
	array fund_amount{*} amount:;

	fund_ctr =dim(fund_type);

	do i=1 to fund_ctr;


		if fund_type{i}="Academic" then
			funds_acad=sum(of fund_amount{i});
		else if fund_type{i}="Emergency" then
			funds_emerg=sum(of fund_amount{i});
		funds_tot=sum(of fund_amount{*});
	end;
	label funds_acad="Academic amount" 
		  funds_emerg="Emergency amount" 
		  funds_tot="Total Scholarships";
run;


/* Print the descriptor portion and data of scholarship_funds dataset */
/* Variables in the descriptor should be in legal order, and not in alphabetical */
/* Supply appropriate title, suppress OBS and display labels */
title "Descriptor portion of the final data set";

proc contents data=scholarship_funds VARNUM;
RUN;

title "Data portion of the final data set";

proc print data=scholarship_funds noobs label;
	var student_id name major funds_acad funds_emerg funds_tot;
run;

ods pdf close;
