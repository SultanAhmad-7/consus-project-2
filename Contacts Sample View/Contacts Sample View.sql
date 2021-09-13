DECLARE @newReport uniqueidentifier = newid();
DECLARE @baseTableId uniqueidentifier = newid();
DECLARE @rptName varchar(100) = 'Contacts Sample View';
DECLARE @rptDesc varchar(500) = 'Contacts Sample View';
DECLARE @rptid varchar(50) = 'Contacts Sample View';
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

with cteAllData(casenum,party_name,type,prefix,last_name,initial_name,first_name,suffix,city,state,zipcode,county,company,addres,salution,Home_Phone,Work_Phone,Cell_Phone,
Fax_#,Direct_Dial,ext,contact_title,Home_Email,Website,date_of_birth,date_of_death,ss_number,lang,gen)
as (
select
	cases.casenum,
	(select top 1 names.fullname_lastfirst from names where names.id=party.namesid
	and party.casesid=cases.id order by record_num ASC) as party_name,
	(select party_role_list.role from party_role_list where party.partyrolelistid=party_role_list.id) as type,

	
		(select prefix.name from prefix where  names.prefixid=prefix.id  ) as prefix,
			(select top 1 names.last_long_name from names, party where names.id=party.namesid
	and party.casesid=cases.id order by record_num ASC) as last_name,
			(select top 1 names.initial from names, party where names.id=party.namesid
	and party.casesid=cases.id order by record_num ASC) as initial_name,
	(select top 1 names.first_name from names where names.id=party.namesid
	and party.casesid=cases.id order by record_num ASC) as first_name,
	
	(select suffix.name from suffix where  names.suffixid=suffix.id ) as suffix,
	(select multi_addresses.city from multi_addresses where multi_addresses.namesid=names.id and multi_addresses.default_addr=1) as city,
(select multi_addresses.state from multi_addresses where multi_addresses.namesid=names.id and multi_addresses.default_addr=1) as state,
(select multi_addresses.zipcode from multi_addresses where multi_addresses.namesid=names.id and multi_addresses.default_addr=1) as zipcode,
(select multi_addresses.county from multi_addresses where multi_addresses.namesid=names.id and multi_addresses.default_addr=1) as county,
(select multi_addresses.company from multi_addresses where multi_addresses.namesid=names.id and multi_addresses.default_addr=1) as company,
(select multi_addresses.address from multi_addresses where multi_addresses.namesid=names.id and multi_addresses.default_addr=1) as addres,
(select multi_addresses.salutation from multi_addresses where multi_addresses.namesid=names.id and multi_addresses.default_addr=1) as salution,
(select  ''('' + Substring(number,1,3) + '') '' 
           + Substring(number,4,3) + ''-'' 
           + Substring(number,7,4) from phone where namesid = names.id and title = ''Home'') as Home_Phone,
(select  ''('' + Substring(number,1,3) + '') '' 
           + Substring(number,4,3) + ''-'' 
           + Substring(number,7,4) from phone where namesid = names.id and title = ''Business'') as Work_Phone,
(select  ''('' + Substring(number,1,3) + '') '' 
           + Substring(number,4,3) + ''-'' 
           + Substring(number,7,4) from phone where namesid = names.id and title = ''Mobile'') as Cell_Phone,
(select  ''('' + Substring(number,1,3) + '') '' 
           + Substring(number,4,3) + ''-'' 
           + Substring(number,7,4) from phone where namesid = names.id and title = ''Business Fax'') as Fax_#,
(select  ''('' + Substring(number,1,3) + '') '' 
           + Substring(number,4,3) + ''-'' 
           + Substring(number,7,4) from phone where namesid = names.id and title = ''Direct Dial'') as Direct_Dial,
		   (select top 1 phone.extension from phone where namesid = names.id ) as ext,
		   (select top 1 phone.title from phone where namesid = names.id ) as contact_title,
(select top 1 online_accounts.account from online_accounts,online_account_category where online_accounts.namesid = names.id and online_account_category.id = online_accounts.onlineaccountcategoryid
and online_account_category.title = ''Email'' and online_accounts.type = 0) as Home_Email,
(select top 1 online_accounts.account from online_accounts,online_account_category where online_accounts.namesid = names.id and online_account_category.id = online_accounts.onlineaccountcategoryid
and online_account_category.title = ''Website'' and online_accounts.type = 0) as Website,
names.date_of_birth,
names.date_of_death,
names.ss_number,
(select race.race_name from race where names.idcodeid=race.id) as lang,
(case when names.gender =1  then ''Male'' when names.gender = 2 then ''Female'' else ''Other'' end ) as gen

 from cases
 join matter on matter.id=cases.matterid
 join party on party.casesid=cases.id
 join names on party.namesid=names.id


)

select
casenum,
(case when (party_name is not null OR party_name <> '''') and company is not null then (party_name + '' (''+ Isnull(company,'''') + '') '') 
when company is null then party_name  else company end ) as party_name,
type,
prefix,
last_name,
initial_name,
first_name,
suffix,
company,
salution,
addres,
city,
state,
zipcode,
county,
Home_Phone,
Work_Phone,
Cell_Phone,
Fax_#,
Direct_Dial,
Home_Email,
Website,
ext,
contact_title,
format(try_cast(date_of_birth as date),''MM/dd/yyyy'') as date_of_birth,
format(try_cast(date_of_death as date),''MM/dd/yyyy'') as date_of_death,
ss_number,
lang,
gen

from cteAllData order by casenum;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Save As', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'type', @newReport, N'Type', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'prefix', @newReport, N'Prefix', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'last_name', @newReport, N'Last Name', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'initial_name', @newReport, N'Middle Name', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'first_name', @newReport, N'First Name', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'suffix', @newReport, N'Suffix', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'company', @newReport, N'Company Name', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'salution', @newReport, N'Salution', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'addres', @newReport, N'Address', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'city', @newReport, N'City', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'state', @newReport, N'State', 12)

INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'zipcode', @newReport, N'Zipcode', 13)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'county', @newReport, N'County', 14)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'contact_title', @newReport, N'Phone Type', 15)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Home_Phone', @newReport, N'Home Phone #', 16)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Work_Phone', @newReport, N'Work Phone', 17)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Cell_Phone', @newReport, N'Mobile Phone', 18)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Fax_#', @newReport, N'Fax #', 19)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Direct_Dial', @newReport, N'Direct Dial #', 20)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Home_Email', @newReport, N'Email', 21)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Website', @newReport, N'Website', 22)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'ext', @newReport, N'Extension', 23)

INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_of_birth', @newReport, N'DOB', 24)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_of_death', @newReport, N'DOD', 25)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'ss_number', @newReport, N'Contact SSN #', 26)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'lang', @newReport, N'Languge', 27)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'gen', @newReport, N'Gender', 28)

