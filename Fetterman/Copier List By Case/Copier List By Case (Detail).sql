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
DECLARE @rptName varchar(100) = 'Copier List By Case (Detail)';
DECLARE @rptDesc varchar(500) = 'Copier List By Case (Detail)';
DECLARE @rptId varchar(50) = 'Copier List By Case';
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
				staff_1,
				party_name,
				casenum,
				alt_case_num
				)
AS(
	SELECT 
		(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND  staff.id = case_staff.staffid AND  case_staff.matterstaffid=matter_staff.id 
			AND  staffroleid=''00000000-0000-0000-0000-000000000001'') AS staff_1,
		(SELECT TOP 1  names.fullname_lastfirst FROM names,party WHERE namesid=names.id AND  party.namesid=names.id AND  party.casesid=cases.id ORDER BY record_num ASC ) AS party_name,
		cases.casenum,
		cases.alt_case_num
	FROM
		cases
	WHERE 
		(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND  staff.id = case_staff.staffid AND  case_staff.matterstaffid=matter_staff.id 
			AND  staffroleid=''00000000-0000-0000-0000-000000000001'') IN (''ABC'', ''EIF'', ''SS'', ''KB'')
	AND ((@openedStartDate IS NULL OR cases.date_opened >= @openedStartDate) 
			AND  (@openedEndDate IS NULL OR cases.date_opened <= @openedEndDate))
	AND ((@closeStartDate IS NULL OR cases.close_date >= @closeStartDate)
			AND   (@closeEndDate IS NULL OR cases.close_date <= @closeEndDate))
)
SELECT
	party_name,
	casenum,
	alt_case_num,
	staff_1
FROM 
	cteAllData 
ORDER BY 
	party_name;',@baseTableId)

-- insert the columns, one row per column in the select

INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Party Name', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'alt_case_num', @newReport, N'Alt Case #', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_1', @newReport, N'Primary Staff', 3)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'openedStartDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Start Open Date', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'openedEndDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'End Open Date', 0, 1, 0,1)

	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'closeStartDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Start Close Date', 0, 1, 0,2)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'closeEndDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'End Close Date', 0, 1, 0,3)

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