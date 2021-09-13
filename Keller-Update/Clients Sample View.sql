DECLARE @newReport uniqueidentifier = newid();
DECLARE @baseTableId uniqueidentifier = newid();
DECLARE @rptName varchar(100) = 'Clients Sample View';
DECLARE @rptDesc varchar(500) = 'Clients Sample View';
DECLARE @rptid varchar(50) = 'Clients Sample View';
--declare @StaffParmstr varchar(40) = null;

delete from reports_orm where title = @rptid or title = @rptName;
delete from reports where title = @rptName;

INSERT reports (id,title, description,report_object, read_only, reportcategoryid, date_created, 
	staffcreatedid,date_modified,staffmodifiedid, content, datelastrun, stafflastrunid,report_type)

VALUES (@baseTableId ,@rptName, @rptDesc,
N'Blank Report Object', 0,(SELECT top 1 id  FROM report_category where name = 'User Defined'),current_timestamp,
NULL,current_timestamp, NULL, NULL, NULL, NULL, 0)
;
-- insert the report object (title must be unique)
INSERT reports_orm (id, title, description, report_object, read_only, 
reportcategoryid, date_created, staffcreatedid, date_modified, staffmodifiedid, base_entity, 
raw_sql, main_table_id) 
VALUES (@newReport, @rptName, @rptName, N'Blank Report Object', 0, (SELECT top 1 id  FROM report_category where name = 'User Defined') , 
current_timestamp, NULL, NULL, NULL, N'Needles.ReportDesigner.ReportObjects.UserDefinedReport', '

with cteAllData(Case_Name,party_name,first_name,last_name,addres,company,city,state,zip,work_#,home_#,fax_#,cell_#,Email,CaseFacts,Date_of_Event,
dte_date,sol,DOB,SS#_TaxID#,languge)
as (
select 
cases.case_title as Case_Name,
(Select top 1 fullname_lastfirst From names,party Where party.namesid=names.id and party.casesid=cases.id) as party_name,
(select top 1 names.first_name from names,party where names.id=party.namesid and party.casesid=cases.id) as first_name,
(select top 1 names.last_long_name from names,party where names.id=party.namesid and party.casesid=cases.id) as last_name,
(select top 1 multi_addresses.address from multi_addresses,names,party where multi_addresses.namesid=names.id and names.id=party.namesid and party.casesid=cases.id and default_addr = 1) as addres,
(select top 1 multi_addresses.company from multi_addresses,names,party where multi_addresses.namesid=names.id and names.id=party.namesid and party.casesid=cases.id and default_addr = 1) as company,
(select top 1 multi_addresses.city from multi_addresses,names,party where multi_addresses.namesid=names.id and names.id=party.namesid and party.casesid=cases.id and default_addr = 1) as city,
(select top 1 multi_addresses.state from multi_addresses,names,party where multi_addresses.namesid=names.id and names.id=party.namesid and party.casesid=cases.id and default_addr = 1) as state,
(select top 1 multi_addresses.zipcode from multi_addresses,names,party where multi_addresses.namesid=names.id and names.id=party.namesid and party.casesid=cases.id and default_addr = 1) as zip,
(select top 1 ''('' + Substring(number,1,3) + '') '' + Substring(number,4,3) + ''-'' + Substring(number,7,4) from phone,names,party where 
party.namesid = names.id and party.casesid=cases.id and phone.namesid = names.id and title = ''Business'') as work_#,
 (select top 1 ''('' + Substring(number,1,3) + '') '' + Substring(number,4,3) + ''-'' + Substring(number,7,4) from phone,names,party where 
party.namesid = names.id and party.casesid=cases.id and phone.namesid = names.id and title = ''Home'') as home_#,
 (select top 1 ''('' + Substring(number,1,3) + '') '' + Substring(number,4,3) + ''-'' + Substring(number,7,4) from phone,names,party where 
party.namesid = names.id and party.casesid=cases.id and phone.namesid = names.id and title = ''Fax'') as fax_#,
 (select top 1 ''('' + Substring(number,1,3) + '') '' + Substring(number,4,3) + ''-'' + Substring(number,7,4) from phone,names,party where 
party.namesid = names.id and party.casesid=cases.id and phone.namesid = names.id and title = ''Mobile'') as cell_#,
(select top 1 online_accounts.account from online_accounts,online_account_category,names,party where 
party.namesid = names.id and party.casesid=cases.id and online_accounts.namesid = names.id and online_account_category.id = 
online_accounts.onlineaccountcategoryid
and online_account_category.title = ''Email'' and online_accounts.type = 0) as Email,
cases.synopsis as  CaseFacts,
cases.date_of_incident as Date_of_Event,
cast(cases.date_of_incident as date) as dte_date,

--CONVERT(VARCHAR(10), CAST(cases.date_of_incident AS TIME), 0) as time_of_event,
--convert(varchar(50), cast(cases.date_of_incident as time),0) as time_of_event,
 cases.lim_date as sol,
 (select top 1 names.date_of_birth from names,party where names.id=party.namesid and party.casesid=cases.id) as DOB,
 (select top 1 names.ss_number from names,party where names.id=party.namesid and party.casesid=cases.id) as SS#_TaxID#,
 (select top 1 race.race_name from race,names,party where race.id=names.idcodeid and party.namesid=names.id and party.casesid=cases.id) as languge

from cases

--join party on party.casesid = cases.id



)

select
Case_Name,
party_name,
first_name,
last_name,
addres,
company,
city,
state,
zip,
work_#,
home_#,
fax_#,
cell_#,
Email,
CaseFacts,
format(try_cast(Date_of_Event as date),''MM/dd/yyyy'') as Date_of_Event,
format(try_cast(convert(varchar(10),cast(dte_date as datetime),0) as time), ''hh:mm:ss tt'') as time_of_event,
format(try_cast(sol as date), ''MM/dd/yyyy'') as sol,
format(try_cast(DOB as date),''MM/dd/yyyy'') as DOB,
SS#_TaxID#,
languge

from cteAllData order by Case_Name,party_name;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Case_Name', @newReport, N'Case Name', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'first_name', @newReport, N'Contact First Name', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'last_name', @newReport, N'Contact Last Name', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'addres', @newReport, N'Address', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'company', @newReport, N'Company', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'city', @newReport, N'City', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'state', @newReport, N'State', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'zip', @newReport, N'Zip', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'work_#', @newReport, N'Phone Number', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'home_#', @newReport, N'Home Number', 10)

INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'fax_#', @newReport, N'Fax Number', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'cell_#', @newReport, N'Cell Phone', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Email', @newReport, N'Email', 13)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'CaseFacts', @newReport, N'Accident', 14)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Date_of_Event', @newReport, N'DOA', 15)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'time_of_event', @newReport, N'Time Of Accident', 16)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'sol', @newReport, N'SOL', 17)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'DOB', @newReport, N'DOB', 18)

INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'SS#_TaxID#', @newReport, N'Social Security #', 19)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'languge', @newReport, N'Language', 20)

