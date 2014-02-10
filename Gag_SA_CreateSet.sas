/*Create data set to be used for SA Gag comm logbook index of abundance
 Kyle Shertzer, 10/21/05
*/

LIBNAME  logbook 'W:\Data\logbookCONFIDENTIAL' ;
LIBNAME  SAGag 'W:\SEDAR\Updates2014\Gag\Indicies\CommHL' ;

options ps=100 ls=100 pageno=1;


data Alldata;
	set logbook.logbook_05_13_13;
	
	*Assign area.  If multiple reported, choose first;
	IF (area ne . and area ne 0)  THEN triparea = area;
       else IF (area1 ne . and area1 ne 0) THEN triparea = area1;
       ELSE IF (area2 NE . and area2 ne 0) THEN triparea = area2;
	   else if (area3 ne . and area3 ne 0) then triparea = area3;

    *Distinguish SA from GOM and from north of SA;
    if      (triparea gt 2382 and triparea le 2384) then triparea=2;
    else if    (triparea gt 2482 and triparea le 2484) then triparea=2;
    else if    (triparea ge 2581 and triparea le 2584) then triparea=3;
    else if    (triparea ge 2681 and triparea le 2685) then triparea=4;
    else if    (triparea ge 2782 and triparea le 2785) then triparea=5;
    else if    (triparea ge 2882 and triparea le 2885) then triparea=6;
    else if    (triparea ge 2982 and triparea le 2984) then triparea=7;
    else if    (triparea=3085 or triparea=2985) then triparea=8;
    else if    (triparea=3086 or triparea=2986 or triparea=2886) then triparea=9;
    else if    (triparea=3087 or triparea=2987 or triparea=2887) then triparea=10;
    else if    (triparea=3088 or triparea=2988 or triparea=2888) then triparea=11;
    else if    (triparea=3089 or triparea=2989) then triparea=12;
    else if    (triparea=2889 or triparea=2789) then triparea=13;
    else if    (triparea=3090 or triparea=2990 or triparea=2890 or triparea=2790) then triparea=14;
    else if    (triparea=3091 or triparea=2991 or triparea=2891 or triparea=2791) then triparea=15;
    else if    (triparea=3092 or triparea=2992 or triparea=2892 or triparea=2792) then triparea=16;
    else if    (triparea=3093 or triparea=2993 or triparea=2893 or triparea=2793) then triparea=17;
    else if    (triparea=3094 or triparea=2994 or triparea=2894 or triparea=2794) then triparea=18;
    else if    (triparea=2995 or triparea=2895 or triparea=2896 or triparea=2897) then triparea=19;
    else if    (triparea ge 2795 and triparea le 2797) then triparea=20;
    else if    (triparea ge 2695 and triparea le 2697) then triparea=21;

    if triparea ge 1 and triparea le 100 then region='GOM';
    if triparea gt 2400 and triparea le 3676 then region='SA';
	if triparea ge 2483 and triparea lt 2500 then delete; *include 2482 in SA;
	if triparea=2382 then region='SA';
	if triparea gt 3676 then region='north';
    if triparea=. or triparea=0 then delete; 

	*proc freq data=Alldata order=freq;
	*tables region;


run;

data SAGag.SA;
	set Alldata;
    if (region ne 'SA') then delete;
	
	drop Species;
	species2=1.0*Species; *convert character to numeric;
	proc sort; by species2;

	title 'Frequency of trips by area';
	proc freq;
	tables triparea;
run;

*import excel spreadsheet with list of SA species;
PROC IMPORT OUT= WORK.spp 
            DATAFILE= "W:\SEDAR\Updates2014\Gag\Indicies\CommHL\Amend_13B_species.xlsx" 
            DBMS=excelcs REPLACE;  sheet="NMFS list";
RUN;

*convert name of column from xls worksheet and add dummy variable for merging; 
data spp2;
	set spp;	
	species2=NMFS_spp;
	drop NMFS_spp;
	dummy=1;
	proc sort; by species2;
run;


*merge data sets by species;
data SAGag.sa_sg;
	merge SAGag.SA spp2; by species2; 
	if dummy=1;
	species=species2;
	drop dummy species2;
	
	*Consolidate extra species codes for the few species where they exist;
	if (species=3800) then species=1414;
	if (species=4471 or species=4473 or species=4475 or species=4477) then species=4470;
	if (species=3762) then species=3760;
	if (species=3775 or species=3776 or species=3777) then species=3765;
	if (species=3300 or species=3301 or species=3303) then species=3302;
	if (species=3351 or species=3353 or species=3355) then species=3360;
    
	if species=. then delete;
	if schedule=. then delete;
    if totlbs=0.0 then delete;
	if(triparea lt 2900) then delete;
	year=year(started);
	month=month(started);
	if numgear = . or effort = . or fished = . then delete;
    if away = .  or away ne (landed - started + 1) then delete;
	if year = 2013 then delete;
	if year = 1991 then delete;
	if year = 1992 then delete;
	if triparea ge 3400 then state='NC'; 
	else if    (triparea ge 3200 and triparea lt 3400) then state='SC';
	else if    (triparea ge 2900 and triparea lt 3200) then state='GN';
	else if     triparea lt 2900 then state='SFL';

	if month ge 9 then season=3; 
	else if    (month ge 5 and montha lt 9) then season=2;
	else if    month<5 then season=1;
	*proc freq order=freq;
	*tables gear;
run;

data sa_sg;
	set SAGag.sa_sg;
    if month = 3 or month = 4 then delete;  *drop months;
	if species=1422 then species=1423;      *convert black to gag;
	if triparea lt 2900 then delete;        *delete areas south of Cape Canaveral;
	proc sort; by schedule species;
	proc means noprint; by schedule species;
	id year month triparea state gear numgear effort fished crew;
	var totlbs;
	output out=sa_sg_nb sum=;
run;

data gag;
	set sa_sg_nb;
	if species=1423; 
	*proc freq order=freq;
	*tables gear;
run;

data gag;
	set gag;
	if triparea ge 3400 then state='NC'; 
	else if    (triparea ge 3200 and triparea lt 3400) then state='SC';
	else if    (triparea ge 2900 and triparea lt 3200) then state='GN';
	else if     triparea lt 2900 then state='SFL';

	if month ge 9 then season=3; 
	else if    (month ge 5 and montha lt 9) then season=2;
	else if    month<5 then season=1;


    proc freq;
	title 'Number of trips reporting gag';
	tables year*state/ nopercent norow nocol;
	
	*proc freq;
	*title 'Reported landings (pounds) of gag';
	*title 'Number trips reporting gag';
	*tables year*state / nopercent norow nocol out=gag_tab;
	*weight totlbs;

     *proc print data=gag_tab;
run;
*############# Evaluate Trip Limit #####################;
data gaglimit;
	set gag;
	if species=1423;
	if gutted>900;
run;

proc freq data=gaglimit;
	title 'Trips at 90% of gag limit';
	tables year/ nopercent norow nocol;
run;

data gagtrips;
	set gag;
	if species=1423;
	if (gear="H" or gear="E");
	if (gear = "H" or gear = "E") then gear="H";
	if numgear > 10 or numgear < 1 then delete;
	if effort > 40 or effort < 1 then delete;
	if crew > 12 then delete;
	numgear1=round (numgear, 1);
	effort1=round (effort, 1);
	if numgear1 ne numgear or effort1 ne effort then delete;
	if fished>0.0;
run;

data gagtrips;
	set gagtrips;
	toteffort=fished*effort*numgear;
	cpue=totlbs/toteffort;
run;

proc freq data=gagtrips;
	title 'Total trips';
	tables year/ nopercent norow nocol;
run;
proc sort data=gagtrips;
	by year season state;
run;
proc means data=gagtrips noprint;
	by  year season state;  
	*var caught weight; 
    var gutted;
    output out=landbymonth sum=;
run;

proc means data=gagtrips noprint;
	by  year season state;  
	*var caught weight; 
    var cpue;
    output out=cpuebyseason mean=;
run;
data gagtripstrim;
	set gagtrips;
	if month=5 or month=6 or month=7 or month=8 or month=9;
run;

	proc freq data=gagtripstrim;
	title 'Total trips: May-Aug';
	tables year*state/ nopercent norow nocol;
run;




data SAGag.sa_sg_clean_handline;
	set sa_sg_nb;
	if (gear="H" or gear="E");
	if (gear = "H" or gear = "E") then gear="H";
	if numgear > 10 or numgear < 1 then delete;
	if effort > 40 or effort < 1 then delete;
	if crew > 12 then delete;
	numgear1=round (numgear, 1);
	effort1=round (effort, 1);
	if numgear1 ne numgear or effort1 ne effort then delete;
	if fished>0.0;
	*proc freq order=freq;
	*tables gear;
run;


data SAGag.trip_species;
	set SAGag.sa_sg_clean_handline;
	keep schedule species;
	proc sort; by schedule;
	proc export data=SAGag.trip_species 
				outfile="W:\SEDAR\Updates2014\Gag\Indicies\CommHL\tripspecies.csv"
				dbms=csv
				replace;
run;



data SAGag.sa_sg_handline_U;
	set SAGag.sa_sg_clean_handline;
	hookhrs=fished*effort*numgear;
	cpue=totlbs/hookhrs;
	keep schedule species cpue year month state season;
	proc sort; by schedule;
	proc export data=SAGag.sa_sg_handline_U 
				outfile="W:\SEDAR\Updates2014\Gag\Indicies\CommHL\SA.SG.hline.U.csv"
				dbms=csv
				replace;
run;

