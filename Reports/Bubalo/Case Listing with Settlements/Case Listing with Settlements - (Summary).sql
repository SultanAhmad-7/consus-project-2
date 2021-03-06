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
DECLARE @rptName varchar(100) = 'Case Listing with Settlements - (Summary)';
DECLARE @rptDesc varchar(500) = 'Case Listing with Settlements - (Summary)';
DECLARE @rptId varchar(50) = 'Case Listing with Settlements';
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
				party_name,
				ps,
				matcode,
				date_opened,
				date_settled,
				actual,
				start_date,
				description,
				total_value
				) 
as (
SELECT
	cases.casenum,
	(SELECT TOP 1  names.fullname_lastfirst FROM names,party WHERE namesid=names.id AND party.namesid=names.id AND party.casesid=cases.id ORDER BY record_num ASC ) AS party_name,
	(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') AS ps,
	matter.matcode,
	cases.date_opened,
	(SELECT TOP 1 insurance.date_settled FROM insurance WHERE  insurance.casesid=cases.id ) AS date_settled,
	(SELECT TOP 1 insurance.actual FROM insurance WHERE  insurance.casesid=cases.id ) AS actual,
	(SELECT TOP 1 value.start_date FROM value WHERE value.casesid=cases.id) AS start_date,
	(SELECT TOP 1 value_code.code FROM value,value_code WHERE value.casesid=cases.id AND value_code.id=value.valuecodeid) AS description,
	(SELECT TOP 1  value.total_value FROM value WHERE value.casesid=cases.id) AS total_value

FROM cases
JOIN matter ON matter.id=cases.matterid

WHERE 
		(@caseType IS NULL OR matter.matcode in (@caseType))
	AND (@primaryStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') in (@primaryStaff))
	AND ((@dateOpenStart IS NULL OR cases.date_opened >= @dateOpenStart) AND (@dateOpenEnd IS NULL OR cases.date_opened <= @dateOpenEnd))
	AND ((@dateCloseStart IS NULL OR cases.close_date >= @dateCloseStart) AND (@dateCloseEnd IS NULL OR cases.close_date <= @dateCloseEnd))
	AND (@caseStatus IS NULL OR cases.open_status = @caseStatus)

)
SELECT
	Count(casenum) as total_cases
FROM 
	cteAllData;',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'total_cases', @newReport, N'Total Cases', 0)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'CaseType', N'Needles.Core.Entities.Common.CaseType', 
	1, 1, N'Case Type', 0, 1, 0,0)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'PrimaryStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,1)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpenStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Open Start Date', 0, 1, 0,2)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpenEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Open End Date', 0, 1, 0, 3)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateCloseStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Close Start Date', 0, 1, 0,4)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateCloseEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Close End Date', 0, 1, 0, 5)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'caseStatus', N'[System.String]', 
	0, 1, N'Case Status', 0, 1, 0,6)	
	


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