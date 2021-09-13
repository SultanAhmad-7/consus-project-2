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
DECLARE @rptName varchar(100) = 'Cases Opened with Detail - (Summary)';
DECLARE @rptDesc varchar(500) = 'Cases Opened with Detail - (Summary)';
DECLARE @rptId varchar(50) = 'Cases Opened with Detail';
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
				date_opened,
				close_date,
				matcode,
				staff_1,
				TEAM,
				Injury_Severity,
				Transferred_FROM,
				Transfer_Date
				) 
as (
SELECT
	cases.casenum,
	(SELECT TOP 1  names.fullname_lastfirst FROM names,party WHERE namesid=names.id AND party.namesid=names.id AND party.casesid=cases.id ORDER BY record_num ASC ) AS party_name,
	cases.date_opened,
	cases.close_date,
	matter.matcode,
	(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') AS staff_1,
	(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id AND user_case_fields.field_title=''TEAM'') AS TEAM,
	(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id AND user_case_fields.field_title=''Injury Severity'') AS Injury_Severity,
	(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id AND user_case_fields.field_title=''Transferred FROM'') AS Transferred_FROM,
	(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id AND user_case_fields.field_title=''Transfer Date'') AS Transfer_Date
FROM 
	cases
	JOIN matter ON matter.id=cases.matterid AND (@CaseType IS NULL OR matter.matcode IN (@CaseType))
WHERE
	((@OpenDateStart IS NULL OR cases.date_opened >= @OpenDateStart) AND (@OpenDateEnd IS NULL OR cases.date_opened <= @OpenDateEnd))
	AND 
	((@CloseDateStart IS NULL OR cases.close_date >= @CloseDateStart) AND (@CloseDateEnd IS NULL OR cases.close_date <= @CloseDateEnd))
	AND 
	(@PrimaryStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') IN (@PrimaryStaff))
	AND 
	(@casestatus IS NULL OR cases.open_status IN (@casestatus))
	and
	(@anystaff IS NULL OR ((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000003'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000004'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000005'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000006'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000007'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000008'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000009'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000010'') IN (@anystaff)) OR
		((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') IN (@anystaff)) )
)
SELECT 
	COUNT(casenum) AS total_cases
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
	VALUES (newid(), @newReport, N'anystaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Any Staff', 0, 1, 0,2)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'OpenDateStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Open Start Date', 0, 1, 0,3)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'OpenDateEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Open End Date', 0, 1, 0, 4)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'CloseDateStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Close Start Date', 0, 1, 0,5)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'CloseDateEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Close End Date', 0, 1, 0, 6)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'casestatus', N'[System.String]', 
	0, 1, N'Case Status', 0, 1, 0,7)	
	


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