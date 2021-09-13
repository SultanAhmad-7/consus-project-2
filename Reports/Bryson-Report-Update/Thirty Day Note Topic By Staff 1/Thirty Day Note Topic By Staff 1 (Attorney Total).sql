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
DECLARE @rptName varchar(100) = 'Thirty Day Note Topic By Staff 1 (Attorney Total)';
DECLARE @rptDesc varchar(500) = 'Thirty Day Note Topic By Staff 1 (Attorney Total)';
DECLARE @rptId varchar(50) = 'Thirty Day Note Topic By Staff 1';
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
WITH cteAllData(
				casenum,Party_Name,Case_Date_9,Staff_1,Day,Client_Contacted
				)
AS (
SELECT DISTINCT
	cases.casenum
	,dbo.sp_first_party(cases.id) AS Party_Name
	,(SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
		AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=9) AS Case_Date_9
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
		AND staffroleid=''00000000-0000-0000-0000-000000000001'') AS Staff_1
	,Datediff(Day,(SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=9), GETDATE()) AS Day
	,(SELECT count(case_notes.casesid) FROM case_notes,case_note_topic WHERE case_notes.casesid = cases.id AND case_note_topic.id = case_notes.casenoteTOPicid AND case_note_topic.topic in (''30 Day Atty/Client Contact'',''Client Contact'')
			AND  (((@NoteDateStartParm IS NULL) OR case_notes.note_date >= @NoteDateStartParm) AND ((@NoteDateEndParm IS NULL) OR case_notes.note_date <= @NoteDateEndParm))) AS Client_Contacted
FROM 
	cases
JOIN matter ON matter.id=cases.matterid AND matter.matcode IN (''CPX'', ''IRS'', ''TRX'', ''TXS'', ''TX3'', ''TXC'', ''BH'')
LEFT OUTER JOIN Party ON party.casesid = cases.id
WHERE 
	cases.close_date IS NULL
	AND Datediff(Day,(SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
				AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=9), GETDATE()) > 30
	AND party.our_client = 1
	AND((@Staff1str IS NULL) OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
				AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') in (@Staff1str))

)
SELECT
	 COUNT(casenum) AS TOTAL_BY_STAFF1
	,Staff_1
	,SUM((CASE WHEN (Client_Contacted IS NOT NULL  OR  Client_Contacted <> '''') THEN 1 ELSE 0 END)) AS TOTAL_CONTACT__IN
	,((COUNT(casenum)) - (SUM((CASE WHEN (Client_Contacted IS NOT NULL  OR  Client_Contacted <> '''') THEN 1 ELSE 0 END)))) AS CONTACT_NOT_IN
FROM
	cteAllData
GROUP BY 
	Staff_1;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'TOTAL_BY_STAFF1', @newReport, N'Total Open Cases For Attorney', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Staff_1', @newReport, N'Staff 3', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'TOTAL_CONTACT__IN', @newReport, N'Total Clients Contacted', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'CONTACT_NOT_IN', @newReport, N'Total Not Contacted', 3)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'Staff1str', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Staff Name', 0, 1, 0,0)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'NoteDateStartParm', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Start Note Date', 0, 1, 0,1)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'NoteDateEndParm', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'End Note Date', 0, 1, 0, 2)

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