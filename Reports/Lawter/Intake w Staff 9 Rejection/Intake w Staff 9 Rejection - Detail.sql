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
DECLARE @rptName varchar(100) = 'Intake w Staff 9 Rejection - Detail';
DECLARE @rptDesc varchar(500) = 'Intake w Staff 9 Rejection - Detail';
DECLARE @rptId varchar(50) = 'Intake w Staff 9 Rejection';
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
				Case_Type
				,Date_of_Accident
				,First_Name
				,Last_Name
				,Referred_By
				,Primary_Staff
				,Staff_9
				,Class
				,Reason_for_Rejection
				,Intake_Date
				) 
AS (
	SELECT
	
	(SELECT matcode FROM matter WHERE id = matterid) AS Case_Type,
	(SELECT TOP 1 data FROM case_intake_data,user_case_intake_matter WHERE case_intake.id=case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid=user_case_intake_matter.id AND user_case_intake_matter.field_title=''Date of Accident'') AS Date_of_Accident,
	
	(SELECT first_name FROM names WHERE id = (SELECT namesid FROM case_intake_data WHERE usercaseintakematterid = 
	        (SELECT id FROM user_case_intake_matter WHERE field_title = ''''Name'''' AND tab_id=0 AND SELECTion = 1 AND user_case_intake_matter.matterid = case_intake.matterid) AND caseintakeid=case_intake.id)) AS First_Name,
	(SELECT last_long_name FROM names WHERE id = (SELECT namesid FROM case_intake_data WHERE usercaseintakematterid = 
	        (SELECT id FROM user_case_intake_matter WHERE field_title = ''''Name'''' AND tab_id=0 AND SELECTion = 1 AND user_case_intake_matter.matterid = case_intake.matterid) AND caseintakeid=case_intake.id)) AS Last_Name,
	
	(SELECT TOP 1 data FROM case_intake_data WHERE case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = any(SELECT user_case_intake_matter.id 
	                    FROM user_case_intake_matter WHERE user_case_intake_matter.field_title = ''''Referred By'''' AND user_case_intake_matter.tab_id = 10 AND user_case_intake_matter.SELECTion = 1)) AS Referred_By,
	
	
	(SELECT staff_code FROM staff WHERE staff.id = case_intake.primarystaffid) AS Primary_Staff,
	
	(SELECT TOP 1 data FROM case_intake_data WHERE usercaseintakematterid = (SELECT TOP 1(id)
 FROM user_case_intake_matter 
	        WHERE field_title = ''''Staff 9'''' AND user_case_intake_matter.matterid = case_intake.matterid) AND caseintakeid=case_intake.id) AS Staff_9,
	
	(SELECT classcode FROM class WHERE class.id = (SELECT case_intake_data.picklistid FROM case_intake_data WHERE case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = any(SELECT user_case_intake_matter.id 
        FROM user_case_intake_matter WHERE user_case_intake_matter.binding_path = ''''Intake_CaseIntakeData_Class_Title'''' AND user_case_intake_matter.tab_id = 10 AND user_case_intake_matter.SELECTion = 1))) AS Class,

	(SELECT TOP 1 data FROM case_intake_data WHERE usercaseintakematterid = (SELECT id FROM user_case_intake_matter WHERE field_title = ''''Reason for Rejection'''' AND user_case_intake_matter.matterid = case_intake.matterid) AND caseintakeid=case_intake.id) AS Reason_for_Rejection,

	intake_taken AS Intake_Date
FROM 
	case_intake
WHERE
	((@IntakeDateStartParm IS NULL OR case_intake.intake_taken>=@IntakeDateStartParm)
	AND 
	(@IntakeDateEndParm IS NULL OR case_intake.intake_taken<=@IntakeDateEndParm))

 )
 
 SELECT 
		Case_Type
		,FORMAT(TRY_CAST(Date_of_Accident AS date), ''''MM/dd/yyyy'''') AS Date_of_Accident
		,First_Name
		,Last_Name
		,Referred_By
		,FORMAT(TRY_CAST(Intake_Date AS date), ''''MM/dd/yyyy hh:mm tt'''') AS Intake_Date
		,Primary_Staff
		,Staff_9
		,Class
		,Reason_for_Rejection
		
 FROM 	
		cteAllData AS cte;',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Case_Type', @newReport, N'Case Type', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Date_of_Accident', @newReport, N'Date of Accident', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'First_Name', @newReport, N'First Name',2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Last_Name', @newReport, N'Last Name', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Referred_By', @newReport, N'Referred By', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Intake_Date', @newReport, N'Intake Date', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Primary_Staff', @newReport, N'Primary Staff',6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Staff_9', @newReport, N'Staff 9', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Class', @newReport, N'Class',8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Reason_for_Rejection', @newReport, N'Reason for Rejection', 9)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'IntakeDateStartParm', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Intake Start Date', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'IntakeDateEndParm', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Intake End Date', 0, 1, 0, 1)


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