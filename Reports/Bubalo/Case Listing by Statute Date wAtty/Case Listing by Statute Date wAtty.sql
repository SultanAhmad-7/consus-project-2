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
DECLARE @rptName varchar(100) = 'Case Listing by Statute Date w/Atty';
DECLARE @rptDesc varchar(500) = 'Case Listing by Statute Date w/Atty';
DECLARE @rptId varchar(50) = 'Case Listing by Statute Date w/Atty';
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
				code,
				description,
				due_date,
				primary_staff,
				staff_assigned,
				team,
				matcode,
				case_date_3,
				staff_role,
				dormant,
				lim,
				status
				) 
AS (

SELECT
	cases.casenum,
	(SELECT TOP 1  names.fullname_lastfirst FROM names,party WHERE namesid=names.id AND party.namesid=names.id AND party.casesid=cases.id ORDER BY record_num ASC ) AS party_name,
	checklist_dir.code,
	checklist_dir.description,
	case_checklist.due_date,
	(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') AS primary_staff,
	(SELECT staff.staff_code FROM staff WHERE case_checklist.staffassignedid=staff.id) AS staff_assigned,
	(SELECT TOP 1 data FROM user_case_data, user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id AND user_case_fields.field_title=''TEAM'') AS team,
	matter.matcode,
	(SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=3) AS case_date_3,
	staff_role.role AS staff_role,
	cases.dormant,
	checklist_dir.lim,
	case_checklist.status
FROM 
	cases
JOIN case_checklist ON case_checklist.casesid=cases.id 
JOIN checklist_dir ON case_checklist.checklistdirid=checklist_dir.id AND (@lim IS NULL OR checklist_dir.lim IN (@lim))
JOIN staff_role ON checklist_dir.staffroleid=staff_role.id
JOIN matter ON matter.id=checklist_dir.matterid AND (@caseType IS NULL OR matter.id in (@caseType))
LEFT JOIN class ON class.id=cases.classid

WHERE 
	(@dueStartDate IS NULL OR case_checklist.due_date >= @dueStartDate) AND (@dueEndDate IS NULL OR case_checklist.due_date <= @dueEndDate)
	AND (@checklistCode IS NULL OR checklist_dir.id IN (@checklistCode))
	AND (@checklistStatus IS NULL OR case_checklist.status IN (@checklistStatus))
	AND (@primaryStaff IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') IN (@primaryStaff))
	AND 
	(@anystaff IS NULL OR ((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000002'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000003'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000004'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000005'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000006'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000007'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000008'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000009'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000010'') IN (@anystaff))or
	((SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') IN (@anystaff)) )
	AND (@staffRole IS NULL OR staff_role.role IN (@staffRole))
	AND (@dormant IS NULL OR cases.dormant = @dormant)
	AND (@class IS NULL OR class.classcode IN (@class))
	AND (@casestatus IS NULL OR cases.open_status IN (@casestatus))

)
SELECT
	casenum,
	party_name,
	code,
	description,
	FORMAT(TRY_CAST(due_date  AS DATE), ''MM/dd/yyyy'') AS due_dte,
	primary_staff,
	staff_assigned,
	team,
	matcode,
	FORMAT(TRY_CAST(case_date_3 AS DATE), ''MM/dd/yyyy'') AS case_date_3
	
FROM 
	cteAllData
ORDER BY 
	due_dte ASC,
	casenum ASC;',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'code', @newReport, N'Code', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'description', @newReport, N'Description', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'due_dte', @newReport, N'Lim Date', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'primary_staff', @newReport, N'Atty', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_assigned', @newReport, N'Staff Assigned', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'team', @newReport, N'Team', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'matcode', @newReport, N'Case Type', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'case_date_3', @newReport, N'Filed Suit', 9)

--INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'dormant', @newReport, N'Dormant', 10)
--INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'lim', @newReport, N'Lim', 11)
--INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'status', @newReport, N'Checklist Status', 12)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dueStartDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Lim Start Date', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dueEndDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Lim End Date', 0, 1, 0, 1)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'checklistCode', N'Needles.Core.Entities.Checklist.DirectoryChecklistSelection', 
	0, 1, N'Checklist Code', 0, 1, 0,2)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'checklistStatus', N'[System.String]', 
	0, 1, N'CheckList Status', 0, 1, 0, 3)

	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'primaryStaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,4)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'CaseType', N'Needles.Core.Entities.Common.CaseType', 
	1, 1, N'Case Type', 0, 1, 0,5)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'anystaff', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Any Staff', 0, 1, 0,6)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'staffRole', N'[System.String]', 
	1, 1, N'Staff Role', 0, 1, 0,7)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dormant', N'[System.String]', 
	0, 1, N'Dormant', 0, 1, 0, 8)
	
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'class', N'Needles.Core.Entities.Common.ClassCode', 
	1, 1, N'Class', 0, 1, 0,9)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'casestatus', N'[System.String]', 
	0, 1, N'Case Status', 0, 1, 0,10)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'lim', N'[System.String]', 
	0, 1, N'Lim', 0, 1, 0,11)

	


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