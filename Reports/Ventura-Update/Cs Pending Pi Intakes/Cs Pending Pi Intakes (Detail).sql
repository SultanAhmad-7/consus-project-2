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
DECLARE @rptName varchar(100) = 'Cs Pending Pi Intakes (Detail)';
DECLARE @rptDesc varchar(500) = 'Cs Pending Pi Intakes (Detail)';
DECLARE @rptId varchar(50) = 'Cs Pending Pi Intakes';
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

WITH cteAllData	(
	matcode,FullName,Intake_Method,Intake_Status,Date_of_Para_Last_Review,Days_Since_Last_Review,Paralegal_Status_Notes,
	Wanted,Marketing_Sources,Case_Category,referredBy_Name,Staff_1,referral_fee_agreement,intake_taken
			)
AS (
SELECT 
	matcode
	,(SELECT TOP 1 n.fullname_lastfirst as FullName FROM case_intake_data ,names n WHERE case_intake_data.namesid=n.id AND  case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = ANY(SELECT user_case_intake_matter.id FROM user_case_intake_matter WHERE user_case_intake_matter.field_title = ''Name'' AND user_case_intake_matter.tab_id = 0 AND user_case_intake_matter.SELECTion = 1)) as FullName
	,(SELECT  data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Intake Method'') AS Intake_Method,
	(SELECT TOP 1 data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Intake Status'') AS Intake_Status
	,(SELECT TOP 1 data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Date of Para Last Review'') AS Date_of_Para_Last_Review
	,DATEDIFF(DAY,TRY_CAST((SELECT TOP 1 data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Date of Para Last Review'') AS datetime),GETDATE()) AS Days_Since_Last_Review
	,(SELECT TOP 1 data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Paralegal Status Notes'') AS Paralegal_Status_Notes
	,(SELECT TOP 1 data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Wanted'') AS Wanted
	,(SELECT TOP 1 data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Marketing Sources'') AS Marketing_Sources
	,(SELECT TOP 1 data FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid 
		AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Case Category'') AS Case_Category
	,(SELECT TOP 1 names.fullname_lastfirst FROM case_intake_data,names WHERE case_intake_data.namesid = names.id AND case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = ANY(SELECT user_case_intake_matter.id FROM user_case_intake_matter WHERE user_case_intake_matter.field_title = ''Referred By'' AND user_case_intake_matter.tab_id = 10 AND user_case_intake_matter.SELECTion = 1)) as referredBy_Name
	,(SELECT TOP 1 staff.staff_code FROM staff WHERE staff.id = case_intake.primarystaffid) AS Staff_1,
	(SELECT TOP 1 user_provider_data.data FROM user_provider_data JOIN user_case_fields ON user_case_fields.id = user_provider_data.usercasefieldid AND user_case_fields.field_title = ''Referral Fee Agreement''
			WHERE user_provider_data.providerid = (SELECT TOP 1 case_intake_data.namesid FROM case_intake_data WHERE case_intake.id=case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid =
			ANY(SELECT user_case_intake_matter.id FROM user_case_intake_matter WHERE user_case_intake_matter.field_title = ''Referred To'' AND user_case_intake_matter.tab_id = 10 AND user_case_intake_matter.SELECTion = 1))) AS referral_fee_agreement
	,case_intake.intake_taken
FROM case_intake
JOIN matter ON matter.id = case_intake.matterid 
AND matcode NOT IN (''BHB'',
					''BP'',
					''CRM'',
					''EVC'',
					''FRE'',
					''GMI'', 
					''GPM'',
					''LLC'',
					''MMM'', 
					''PRA'',
					''PRO'',
					''RE'',
					''ROB'',
					''TAL'',
					''TST'',
					''VIA'',
					''WIL'',
					''XAR'',
					''YAZ'',
					''ZOF'')

WHERE 
	rejected = 0
	AND (SELECT n.names_id AS FullName FROM case_intake_data ,names n WHERE case_intake_data.namesid=n.id AND  case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = ANY(SELECT user_case_intake_matter.id FROM user_case_intake_matter WHERE user_case_intake_matter.field_title = ''Name'' AND user_case_intake_matter.tab_id = 0 AND user_case_intake_matter.SELECTion = 1)) >= 1
)
SELECT 
	matcode,
	FullName,
	Intake_Method,
	Staff_1,
	FORMAT(intake_taken,''MM/dd/yyyy hh:mm:ss'') AS intake_dates,
	FORMAT(TRY_CAST(Date_of_Para_Last_Review AS Date),''MM/dd/yyyy'') AS Last_Review,
	Days_Since_Last_Review,
	Intake_Status,
	Paralegal_Status_Notes,
	Wanted,
	referredBy_Name,
	Marketing_Sources,
	referral_fee_agreement,
	Case_Category
FROM 
	cteAllData AS cte
ORDER BY
	intake_taken;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'matcode', @newReport, N'Case Type', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'FullName', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Intake_Method', @newReport, N'Method', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Staff_1', @newReport, N'Primary Staff', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'intake_dates', @newReport, N'Intake Date', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Last_Review', @newReport, N'Last Review', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Days_Since_Last_Review', @newReport, N'Days Since Last Review', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Intake_Status', @newReport, N'Status Type', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Paralegal_Status_Notes', @newReport, N'Status Notes', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Wanted', @newReport, N'Wanted', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referredBy_Name', @newReport, N'Referred By', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Marketing_Sources', @newReport, N'Marketing Sources', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referral_fee_agreement', @newReport, N'Marketing Sources', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Case_Category', @newReport, N'Case Category', 13)
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