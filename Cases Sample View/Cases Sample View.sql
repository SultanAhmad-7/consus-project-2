DECLARE @newReport uniqueidentifier = newid();
DECLARE @baseTableId uniqueidentifier = newid();
DECLARE @rptName varchar(100) = 'Cases Sample View';
DECLARE @rptDesc varchar(500) = 'Cases Sample View';
DECLARE @rptid varchar(50) = 'Cases Sample View';
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

with cteAllData(casenum,date_created,created_By,open_status,first_party,primary_staff,staff_2,staff_3,staff_4,case_type,referal,close_date,
status_note,sub_status,sub_status_note,sub_status_1,sub_status_1_note,Priority_Code_Note,Priority_Code)
as (
select
	cases.casenum,
	cases.date_created,
	(select staff.staff_code from staff where cases.staffcreatedid=staff.id) as created_By,
	cases.open_status,

	
	(select top 1 names.fullname_lastfirst from names, party where names.id=party.namesid
	and party.casesid=cases.id order by record_num ASC) as first_party,
	(select staff_code from case_staff, staff, matter_staff where cases.id = case_staff.casesid 
and staff.id = case_staff.staffid and case_staff.matterstaffid=matter_staff.id 
and staffroleid=''00000000-0000-0000-0000-000000000001'') as primary_staff,
(select staff_code from case_staff, staff, matter_staff where cases.id = case_staff.casesid 
and staff.id = case_staff.staffid and case_staff.matterstaffid=matter_staff.id 
and staffroleid=''00000000-0000-0000-0000-000000000002'') as staff_2,
(select staff_code from case_staff, staff, matter_staff where cases.id = case_staff.casesid 
and staff.id = case_staff.staffid and case_staff.matterstaffid=matter_staff.id 
and staffroleid=''00000000-0000-0000-0000-000000000003'') as staff_3,
(select staff_code from case_staff, staff, matter_staff where cases.id = case_staff.casesid 
and staff.id = case_staff.staffid and case_staff.matterstaffid=matter_staff.id 
and staffroleid=''00000000-0000-0000-0000-000000000004'') as staff_4,
matter.matcode as case_type,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Referral'') as referal,
cases.close_date,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Status Note'') as status_note,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Sub Status'') as sub_status,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Sub Status Note'') as sub_status_note,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Sub Status 1'') as sub_status_1,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Sub Status 1 Note'') as sub_status_1_note,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Priority Code Note'') as Priority_Code_Note,
(select top 1 data from user_case_data,user_case_fields where user_case_data.usercasefieldid=user_case_fields.id and user_case_data.casesid=cases.id
and user_case_fields.field_title=''Priority Code'') as Priority_Code
 from cases
 join matter on matter.id=cases.matterid

)

select
casenum,
first_party,
case_type,
format(try_cast(date_created as date), ''MM/dd/yyyy'') as dte_created,
primary_staff,
staff_2,
staff_3,
staff_4,
created_By,
(case when open_status = 1 then ''Open'' else ''Close'' end ) as open_status,
referal,
format(try_cast(close_date as date),''MM/dd/yyyy'') as close_date,
status_note,
sub_status,
sub_status_note,
sub_status_1,
sub_status_1_note,
Priority_Code_Note,
Priority_Code
from cteAllData order by casenum;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'first_party', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'case_type', @newReport, N'Case Type', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'dte_created', @newReport, N'Date Created', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'primary_staff', @newReport, N'Primary Staff', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_2', @newReport, N'Staff 2', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_3', @newReport, N'Staff 3', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_4', @newReport, N'Staff 4', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'created_By', @newReport, N'Created By', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'open_status', @newReport, N'Status', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referal', @newReport, N'Referral', 10)

INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'close_date', @newReport, N'Date Closed', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'status_note', @newReport, N'Status Note', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'sub_status', @newReport, N'Sub Status', 13)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'sub_status_note', @newReport, N'Sub Status Note', 14)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'sub_status_1', @newReport, N'Sub Status 1', 15)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'sub_status_1_note', @newReport, N'Sub Status 1 Note', 16)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Priority_Code', @newReport, N'Priority Code', 17)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Priority_Code_Note', @newReport, N'Priority Code Note', 18)

