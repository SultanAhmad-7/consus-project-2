-- SQL Server Session Handling Parameters
SET NOCOUNT ON;
SET DEADLOCK_PRIORITY LOW;
SET LANGUAGE us_english;
SET LOCK_TIMEOUT 30000;
SET IMPLICIT_TRANSACTIONS OFF;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOEXEC OFF;
-- Declare RAISERROR Parameters
DECLARE @ErrorNumber [INT] = 0;
DECLARE @ErrorSeverity [INT] = 10;
DECLARE @ErrorState [INT] = 0;
DECLARE @ErrorProcedure [NVARCHAR] (128) = NULL;
DECLARE @ErrorLine [INT] = 0;
DECLARE @ErrorMessage [NVARCHAR] (4000) = NULL;
DECLARE @RaiseErrorText [NVARCHAR] (4000) = NULL;
-- Declare Local Script Specific Parameters
DECLARE @newReport uniqueidentifier = newid();
DECLARE @baseTableId uniqueidentifier = newid();
DECLARE @rptName varchar(100) = 'Daily Wanted - Detail';
DECLARE @rptDesc varchar(500) = 'Daily Wanted - Detail';
DECLARE @rptId varchar(50) = 'Daily Wanted';
DECLARE @rptObject varchar(100) = 'Blank Report Object';
DECLARE @rptCategoryId uniqueidentifier = (select top 1 [id] from [report_category] where [name] = 'User Defined');

-- T-SQL Script
BEGIN
   BEGIN TRY
      BEGIN TRANSACTION @rptName WITH MARK 'Neos Report';
         IF EXISTS
            (
               SELECT
                  TOP 1 [title] 
               FROM
                  [reports_orm] 
               WHERE 
                  [title] = @rptid 
               OR 
                  [title] = @rptName
            )
               BEGIN
                  DELETE FROM 
                     [reports_orm]
                  WHERE 
                     [title] = @rptid
                  OR 
                     [title] = @rptName;
               END;

         IF EXISTS
            (
               SELECT
                  TOP 1 [title]
               FROM
                  [reports] 
               WHERE 
                  [title] = @rptName
            )
               BEGIN
                  DELETE FROM 
                     [reports] 
                  WHERE 
                     [title] = @rptName;
               END;

         -- BEGIN ADDITIONAL T-SQL CODE

INSERT reports (id,title, description,report_object, read_only, reportcategoryid, date_created, 
	staffcreatedid,date_modified,staffmodifiedid, content, datelastrun, stafflastrunid,report_type)

VALUES (@baseTableId ,@rptName, @rptDesc,@rptObject, 0,@rptCategoryId,current_timestamp,
NULL,current_timestamp, NULL, NULL, NULL, NULL, 0)
;
-- insert the report object (title must be unique)
INSERT reports_orm (id, title, description, report_object, read_only, 
reportcategoryid, date_created, staffcreatedid, date_modified, staffmodifiedid, base_entity, 
raw_sql, main_table_id) 
VALUES (@newReport, @rptName, @rptName, @rptObject, 0, @rptCategoryId , 
current_timestamp, NULL, NULL, NULL, N'Needles.ReportDesigner.ReportObjects.UserDefinedReport', '

WITH cteAllData (
				casenum,last_name,lst_name,date_of_birth,
				gender,race,referred_by,
				referral_source,matcode,
				intake_date,intake_staff,
				status,car#,date_contract_signed,appt_date,appt_time,
				why_appt_note_same_day,gro_requested_by,
				gro_date,gro_reason,
				mobile_#,home_#,business_#,pager_#,Home_Email,ss_number,zipcode
				)
AS (
SELECT 
		cases.casenum,
		(names.first_name + '' ''+names.last_long_name) AS last_name,
		names.last_long_name as lst_name,
		names.date_of_birth,
		names.gender,
		(SELECT race.race_name + '' - ''+race.race_id FROM race WHERE names.idcodeid=race.id) AS race,
		(SELECT TOP 1 n.fullname_lastfirst FROM names n WHERE n.id=cases.referredby_namesid) AS referred_by,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Referral Source'') AS referral_source,
		matter.matcode,
		cases.intake_date,
		(SELECT staff.staff_code FROM staff WHERE staff.id=cases.staffintakeid) AS intake_staff,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Status'') AS status,
		(SELECT TOP 1 DATA FROM user_tab6_data,user_case_fields WHERE user_tab6_data.casesid=cases.id AND user_tab6_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Number of People in Car'') AS car#,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Date Contract Signed'') AS date_contract_signed,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Appt Date'') AS appt_date,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Appt Time'') AS appt_time,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Why Appt Not Same Day'') AS why_appt_note_same_day,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''GRO Requested By'') AS gro_requested_by,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''GRO Date'') AS gro_date,
		(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''GRO Reason'') AS gro_reason,
		(SELECT TOP 1 ''('' + Substring(number,1,3) + '') '' 
				+ Substring(number,4,3) + ''-'' 
				+ Substring(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Mobile'') AS mobile_#,
		(SELECT TOP 1 ''('' + Substring(number,1,3) + '') '' 
				+ Substring(number,4,3) + ''-'' 
				+ Substring(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Home'') AS home_#,
		(SELECT TOP 1 ''('' + Substring(number,1,3) + '') '' 
				+ Substring(number,4,3) + ''-'' 
				+ Substring(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Business'') AS business_#,
		(SELECT TOP 1 ''('' + Substring(number,1,3) + '') '' 
				+ Substring(number,4,3) + ''-'' 
				+ Substring(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Pager'') AS pager_#,
		(SELECT TOP 1 online_accounts.account FROM online_accounts,online_account_category WHERE online_accounts.namesid = names.id   AND  online_account_category.id = online_accounts.onlineaccountcategoryid
				and online_account_category.title = ''Email'' AND online_accounts.type = 0) AS Home_Email,
		names.ss_number,
		(SELECT TOP 1 multi_addresses.zipcode FROM multi_addresses WHERE multi_addresses.namesid=names.id  AND multi_addresses.default_addr=1) AS zipcode
FROM 
	cases
JOIN matter ON cases.matterid=matter.id
JOIN party ON party.casesid=cases.id AND party.our_client=1
JOIN names ON party.namesid=names.id
WHERE 
	(@caseType IS NULL OR matter.id in (@caseType))
	AND
	(@primaryStaff IS NULL OR  (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
	AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') in  (@primaryStaff)) and
	(
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') in (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000003'') in (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000004'') in (@anyStaff)) or
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000005'') in (@anyStaff)) or
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000006'') in (@anyStaff)) or
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000007'') in (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000008'') in (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			and staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000009'') in (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
	AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000010'') in (@anyStaff))
)
 AND ((@dateOpendStart IS NULL OR cases.date_opened >= @dateOpendStart) AND (@dateOpendEnd IS NULL OR cases.date_opened <= @dateOpendEnd)) 
 AND ((@dateCloseStart IS NULL OR cases.close_date >= @dateCloseStart) AND (@dateCloseEnd IS NULL OR cases.close_date <= @dateCloseEnd))
)
SELECT
	casenum,
	last_name,
	FORMAT(TRY_CAST(date_of_birth AS date),''MM/dd/yyyy'') AS dob,
	(CASE WHEN gender = 0 THEN ''Other''
		WHEN gender = 1 THEN ''Male'' ELSE ''Female'' END) as gender,
	race,
	referred_by,
	referral_source,
	matcode,
	FORMAT(TRY_CAST(intake_date AS date),''MM/dd/yyyy'') AS intake_date,
	intake_staff,
	status,
	car#,
	FORMAT(TRY_CAST(date_contract_signed AS date),''MM/dd/yyyy'') AS date_contract_signed,
	FORMAT(TRY_CAST(appt_date AS date),''MM/dd/yyyy'') AS appt_date,
	FORMAT(TRY_CAST(appt_time AS TIME), ''hh:mm tt'') AS appt_time,
	why_appt_note_same_day,
	gro_requested_by,
	FORMAT(TRY_CAST(gro_date AS date),''MM/dd/yyyy'') AS gro_date,
	gro_reason,
	pager_#,
	mobile_#,
	home_#,
	business_#,
	Home_Email,
	ss_number,
	zipcode
FROM
	cteAllData
order by 
	lst_name ASC, casenum ASC;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'last_name', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'dob', @newReport, N'DOB', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'gender', @newReport, N'Sex', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'race', @newReport, N'Race', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referred_by', @newReport, N'Referred By',5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referral_source', @newReport, N'Referral Source', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'matcode', @newReport, N'Case Type', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'intake_date', @newReport, N'Intake Date', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'intake_staff', @newReport, N'Intake Staff', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'status', @newReport, N'Status', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'car#', @newReport, N'# in Car', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_contract_signed', @newReport, N'Date Contract Signed', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'appt_date', @newReport, N'Appt Date', 13)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'appt_time', @newReport, N'Appt Time', 14)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'why_appt_note_same_day', @newReport, N'Why Appt Note Same Day', 15)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'gro_requested_by', @newReport, N'Gro Requested By', 16)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'gro_date', @newReport, N'Gro Date', 17)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'gro_reason', @newReport, N'Gro Reason', 18)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'pager_#', @newReport, N'Default Phone', 19)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'mobile_#', @newReport, N'Mobile Phone', 20)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'home_#', @newReport, N'Home Phone', 21)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'business_#', @newReport, N'Business Phone', 22)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Home_Email', @newReport, N'E-mail Address', 23)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'ss_number', @newReport, N'SSN', 24)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'zipcode', @newReport, N'Zip Code', 25)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'caseType', N'Needles.Core.Entities.Common.CaseType', 
	1, 1, N'Case Type', 0, 1, 0,1)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'anyStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Enter Staff', 0, 1, 0,2)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'primaryStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,3)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpendStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Open Start Date', 0, 1, 0,4)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpendEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Open End Date', 0, 1, 0, 5)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateCloseStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Close Start Date', 0, 1, 0,6)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateCloseEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Close End Date', 0, 1, 0, 7)


         -- END ADDITIONAL T-SQL CODE

      -- CHECK FOR TRANSACTION
      IF (XACT_STATE()) <> 0
         BEGIN
            IF
               (XACT_STATE()) = 1 COMMIT TRANSACTION;
            ELSE
               ROLLBACK TRANSACTION;
         END;
   END TRY
   BEGIN CATCH
      IF @ErrorNumber BETWEEN 13000 AND 2147483647 AND @ErrorNumber <> 50000
         BEGIN
            SELECT
                 @ErrorNumber = ERROR_NUMBER()
               , @ErrorSeverity = ERROR_SEVERITY()
               , @ErrorState = ERROR_STATE()
               , @ErrorProcedure = ERROR_PROCEDURE()
               , @ErrorLine = ERROR_LINE()
               , @ErrorMessage = ERROR_MESSAGE();
            RAISERROR
            (
                 @ErrorNumber
               , @ErrorSeverity
               , @ErrorState
               , @ErrorProcedure
               , @ErrorLine
               , @ErrorMessage
            ) WITH NOWAIT, LOG;
            IF (XACT_STATE()) <> 0
               BEGIN
                  IF
                     (XACT_STATE()) = 1 COMMIT TRANSACTION;
                  ELSE
                     ROLLBACK TRANSACTION;
               END;
         END;
      ELSE
         BEGIN
            SELECT
                 @ErrorMessage = ERROR_MESSAGE()
               , @ErrorSeverity = ERROR_SEVERITY()
               , @ErrorState = ERROR_STATE();
            RAISERROR
            (
                 @ErrorMessage
               , @ErrorSeverity
               , @ErrorState
            ) WITH NOWAIT, LOG;
            IF (XACT_STATE()) <> 0
               BEGIN
                  IF
                     (XACT_STATE()) = 1 COMMIT TRANSACTION;
                  ELSE
                     ROLLBACK TRANSACTION;
               END;
         END;
   END CATCH;
END;
GO