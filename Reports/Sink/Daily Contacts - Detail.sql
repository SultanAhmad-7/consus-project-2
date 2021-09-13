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
DECLARE @rptName varchar(100) = 'Daily Contacts - Detail';
DECLARE @rptDesc varchar(500) = 'Daily Contacts - Detail';
DECLARE @rptId varchar(50) = 'Daily Contacts';
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


WITH cteAllDATA (
				intake_taken,date_of_birth,matcode,race,gender,
				fullname_lastfirst,primary_intake_staff,intake_staff,
				referral_source,Home_Email,homePhone,MobilePhone,BusinessPhone,
				PagerPhone,FaxPhone,address1,city1,state1,zipcode1,comments
				)
 AS (
SELECT 
		case_intake.intake_taken,
		names.date_of_birth,
		matter.matcode,
		(SELECT  race.race_name+ '' - '' +race.race_id FROM race WHERE names.idcodeid=race.id) AS race,
		names.gender,
		names.fullname_lastfirst,
		(SELECT staff.staff_code FROM staff WHERE staff.id=case_intake.primarystaffid) AS primary_intake_staff,
		(SELECT staff.staff_code FROM staff WHERE staff.id=case_intake.takenbystaffid) AS intake_staff,
		(SELECT TOP 1 DATA FROM case_intake_data cid,user_case_intake_matter,user_case_fields WHERE cid.usercaseintakematterid=user_case_intake_matter.id AND cid.caseintakeid=case_intake.id AND user_case_intake_matter.usercasefieldsid=user_case_fields.id AND user_case_fields.field_title=''Referral Source'') AS referral_source,
		(SELECT online_accounts.account FROM online_accounts,online_account_category WHERE online_accounts.namesid = names.id AND online_account_category.id = online_accounts.onlineaccountcategoryid
		and online_account_category.title = ''Email'' AND online_accounts.type = 0) AS Home_Email,
		(SELECT  ''('' + Substring(number,1,3) + '') '' 
		           + Substring(number,4,3) + ''-'' 
		           + Substring(number,7,4) FROM phone WHERE namesid = names.id AND title = ''Home'')  AS homePhone,
		(SELECT  ''('' + Substring(number,1,3) + '') '' 
		           + Substring(number,4,3) + ''-'' 
		           + Substring(number,7,4) FROM phone WHERE namesid = names.id AND title = ''Mobile'')  AS MobilePhone,
		(SELECT  ''('' + Substring(number,1,3) + '') '' 
		           + Substring(number,4,3) + ''-'' 
		           + Substring(number,7,4) FROM phone WHERE namesid = names.id AND title = ''Business'')  AS BusinessPhone,
		(SELECT  ''('' + Substring(number,1,3) + '') '' 
		           + Substring(number,4,3) + ''-'' 
		           + Substring(number,7,4) FROM phone WHERE namesid = names.id AND title = ''Pager'')  AS PagerPhone,
		(SELECT  ''('' + Substring(number,1,3) + '') '' 
		           + Substring(number,4,3) + ''-'' 
		           + Substring(number,7,4) FROM phone WHERE namesid = names.id AND title = ''Fax'')  AS FaxPhone,
		(SELECT multi_addresses.address FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS address1,
		(SELECT multi_addresses.city FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS city1,
		(SELECT multi_addresses.state FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS state1,
		(SELECT multi_addresses.zipcode FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS zipcode1,
		(SELECT TOP 1 DATA FROM case_intake_data cid,user_case_intake_matter WHERE cid.usercaseintakematterid=user_case_intake_matter.id AND cid.caseintakeid=case_intake.id AND user_case_intake_matter.field_title=''Comments'') AS comments
FROM 
	case_intake
JOIN matter ON matter.id=case_intake.matterid
JOIN case_intake_data ON case_intake.id=case_intake_data.caseintakeid
JOIN names ON case_intake_data.namesid=names.id
WHERE 
	case_intake.deleted = 0
	AND (@intakeName IS NULL OR names.id in (@intakeName))
	AND ((@intakeStartDate IS NULL OR case_intake.intake_taken >= @intakeStartDate) AND (@intakeEndDate IS NULL OR case_intake.intake_taken < @intakeEndDate))
	AND (@intakeStaff IS NULL OR (SELECT staff.id FROM staff WHERE staff.id=case_intake.takenbystaffid)  in (@intakeStaff))
	AND (@PrimaryStaff IS NULL OR (SELECT staff.id FROM staff WHERE staff.id=case_intake.primarystaffid) in (@PrimaryStaff))
	AND (@caseType IS NULL OR  matter.id in (@caseType))
	AND (@commentsParm IS NULL OR (SELECT TOP 1 DATA FROM case_intake_data cid,user_case_intake_matter WHERE cid.usercaseintakematterid=user_case_intake_matter.id AND cid.caseintakeid=case_intake.id AND user_case_intake_matter.field_title=''Comments'') like ''%''+@commentsParm+''%'')
)
SELECT
		FORMAT(TRY_CAST(intake_taken AS date), ''MM/dd/yyyy'') AS intke_taken,
		fullname_lastfirst,
		FORMAT(TRY_CAST(date_of_birth AS date), ''MM/dd/yyyy'') AS date_of_birth,
		matcode,
		race,
		(CASE WHEN gender = 0 THEN ''Other'' 
			when gender = 1 THEN ''Male'' ELSE ''Female'' END) AS gender,
		referral_source,
		Home_Email,
		homePhone,
		MobilePhone,
		BusinessPhone,
		PagerPhone,
		FaxPhone,
		address1,
		city1,
		state1,
		zipcode1,
		comments
FROM 
	cteAllDATA
ORDER BY intake_taken ASC;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'intke_taken', @newReport, N'Intake Taken', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'fullname_lastfirst', @newReport, N'Intake Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_of_birth', @newReport, N'DOB', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'matcode', @newReport, N'Case Type', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'race', @newReport, N'Race', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'gender', @newReport, N'Sex',5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referral_source', @newReport, N'Referral Source', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Home_Email', @newReport, N'E-mail Address', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'homePhone', @newReport, N'Home Phone', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'MobilePhone', @newReport, N'Mobile Phone', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'BusinessPhone', @newReport, N'Business Phone', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'PagerPhone', @newReport, N'Pager Phone', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'FaxPhone', @newReport, N'Fax #', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'address1', @newReport, N'Address', 13)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'city1', @newReport, N'City', 14)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'state1', @newReport, N'State', 15)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'zipcode1', @newReport, N'Zip Code', 16)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'comments', @newReport, N'Comments', 17)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'intakeName', N'Needles.Core.Entities.Common.Name', 
	1, 1, N'Intake Name', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'caseType', N'Needles.Core.Entities.Common.CaseType', 
	1, 1, N'Case Type', 0, 1, 0,1)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'intakeStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Intake Staff', 0, 1, 0,2)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'PrimaryStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,3)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'intakeStartDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Intake Start Date', 0, 1, 0,4)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'intakeEndDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Intake End Date', 0, 1, 0, 5)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'commentsParm', N'[System.String]', 
	0, 1, N'Comments Search Text', 0, 1, 0,6)


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