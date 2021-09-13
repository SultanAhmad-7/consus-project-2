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
DECLARE @rptName varchar(100) = 'Phone Singed Report (Detail)';
DECLARE @rptDesc varchar(500) = 'Phone Singed Report (Detail)';
DECLARE @rptId varchar(50) = 'Phone Singed Report';
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
				casenum,
				first_name,
				last_name,
				date_opened,
				close_date,
				header,
				classcode,
				status,
				date_contract_signed,
				referred_by,
				home_#,
				mobile_#,
				fax_#,
				business_#,
				pager_#,
				Home_Email,
				car#,
				zipcode
				) 
AS (
SELECT 
	cases.casenum,
	names.first_name,
	names.last_long_name AS last_name,
	cases.date_opened,
	cases.close_date,
	matter.matcode,
	class.classcode,
	(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Status'') AS status,
	(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE  user_case_data.casesid=cases.id AND user_case_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Date Contract Signed'') AS date_contract_signed,
	(SELECT TOP 1 n.fullname_lastfirst FROM names n WHERE n.id=cases.referredby_namesid) AS referred_by,
	(SELECT TOP 1 ''('' + SUBSTRING(number,1,3) + '') '' 
           + SUBSTRING(number,4,3) + ''-'' 
           + SUBSTRING(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Home'') AS home_#,
	(SELECT TOP 1 ''('' + SUBSTRING(number,1,3) + '') '' 
           + SUBSTRING(number,4,3) + ''-'' 
           + SUBSTRING(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Mobile'') AS mobile_#,
	(SELECT TOP 1 ''('' + SUBSTRING(number,1,3) + '') '' 
           + SUBSTRING(number,4,3) + ''-'' 
           + SUBSTRING(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Fax'') AS fax_#,
	(SELECT TOP 1 ''('' + SUBSTRING(number,1,3) + '') '' 
           + SUBSTRING(number,4,3) + ''-'' 
           + SUBSTRING(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Business'') AS business_#,
	(SELECT TOP 1 ''('' + SUBSTRING(number,1,3) + '') '' 
           + SUBSTRING(number,4,3) + ''-'' 
           + SUBSTRING(number,7,4) FROM phone WHERE phone.namesid = names.id   AND  title = ''Pager'') AS pager_#,
	(SELECT TOP 1 online_accounts.account FROM online_accounts,online_account_category WHERE online_accounts.namesid = names.id   AND  online_account_category.id = online_accounts.onlineaccountcategoryid
			and online_account_category.title = ''Email'' AND online_accounts.type = 0) AS Home_Email,
	(SELECT TOP 1 DATA FROM user_tab6_data,user_case_fields WHERE user_tab6_data.casesid=cases.id AND user_tab6_data.usercasefieldid=user_case_fields.id
			AND user_case_fields.field_title=''Number of People in Car'') AS car#,
	(SELECT TOP 1 multi_addresses.zipcode FROM multi_addresses WHERE multi_addresses.namesid=names.id  AND multi_addresses.default_addr=1) AS zipcode
FROM cases
JOIN matter ON cases.matterid=matter.id
LEFT JOIN class ON cases.classid=class.id AND (class.classcode <> ''RIN'' AND class.classcode <> ''INQ'')
JOIN party ON party.casesid=cases.id AND party.our_client=1
JOIN names ON party.namesid=names.id
WHERE
	(@caseType IS NULL OR matter.id IN (@caseType))
	AND
	(@primaryStaff IS NULL OR  (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
	AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') in  (@primaryStaff)) AND
	(
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') IN (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000003'') IN (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000004'') IN (@anyStaff)) or
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000005'') IN (@anyStaff)) or
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000006'') IN (@anyStaff)) or
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000007'') IN (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000008'') IN (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000009'') IN (@anyStaff)) or 
	(@anyStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000010'') IN (@anyStaff))
	)
	AND ((@dateOpendStart IS NULL OR cases.date_opened >= @dateOpendStart) AND (@dateOpendEnd IS NULL OR cases.date_opened <= @dateOpendEnd)) 
	AND ((@dateCloseStart IS NULL OR cases.close_date >= @dateCloseStart) AND (@dateCloseEnd IS NULL OR cases.close_date <= @dateCloseEnd))
	
)
SELECT
	first_name,
	last_name,
	FORMAT(TRY_CAST(date_opened AS date),''MM/dd/yyyy'') AS date_opened,
	header,
	status,
	FORMAT(TRY_CAST(date_contract_signed AS date), ''MM/dd/yyyy'') AS date_contract_signed,
	classcode,
	referred_by,
	casenum,
	home_#,
	mobile_#,
	fax_#,
	business_#,
	pager_#,
	Home_Email,
	car#,
	zipcode
FROM 
	cteAllData
ORDER BY
	first_name,
	last_name,
	casenum;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'first_name', @newReport, N'First Name', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'last_name', @newReport, N'Last Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_opened', @newReport, N'Case Date Opened', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'header', @newReport, N'Case Type', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'status', @newReport, N'Status', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_contract_signed', @newReport, N'Date Contact Singed',5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'classcode', @newReport, N'Class', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referred_by', @newReport, N'Referred By', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'home_#', @newReport, N'Home #', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'mobile_#', @newReport, N'Mobile #', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'fax_#', @newReport, N'Fax #', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'business_#', @newReport, N'Business #', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'pager_#', @newReport, N'First #', 13)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Home_Email', @newReport, N'Home Email', 14)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'car#', @newReport, N'# in Car', 15)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'zipcode', @newReport, N'Zip Code', 16)



INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'caseType', N'Needles.Core.Entities.Common.CaseType', 
	1, 1, N'Case Type', 0, 1, 0,0)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'primaryStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,1)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'anyStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Staff Name', 0, 1, 0,2)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpendStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Start Open Date', 0, 1, 0,3)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpendEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'End Open Date', 0, 1, 0, 4)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateCloseStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Start Close Date', 0, 1, 0,5)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateCloseEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'End Close Date', 0, 1, 0, 6)

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