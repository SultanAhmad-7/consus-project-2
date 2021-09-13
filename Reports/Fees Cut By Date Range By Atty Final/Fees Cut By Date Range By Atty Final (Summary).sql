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
DECLARE @rptName varchar(100) = 'Fees Cut By Date Range By Atty Final (Summary)';
DECLARE @rptDesc varchar(500) = 'Fees Cut By Date Range By Atty Final (Summary)';
DECLARE @rptId varchar(50) = 'Fees Cut By Date Range By Atty Final';
DECLARE @rptObject varchar(100) = 'Blank Report Object';
DECLARE @rptCategoryId uniqueidentifier = (select top 1 [id] from [report_category]  WHERE [name] = 'User Defined');

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
WITH  cteAllData (
	casenum,staff_1,settle_paid,Settlement_Due,classcode,party_name,code,
	date_paid1,PaymentAmount,Settlement_Executed
				)
AS (

SELECT 
	cases.casenum
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') AS staff_1
	,(SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.valueid IN (SELECT value.id FROM value, value_code WHERE value.casesid=cases.id AND value_code.id=value.valuecodeid AND value_code.code=''SETTLE'')) AS settle_paid
	,(ISNULL ((SELECT SUM(value.due) FROM value,value_code WHERE value.casesid=cases.id AND value_code.id=value.valuecodeid AND value_code.code=''SETTLE''),0)) AS Settlement_Due
	,class.classcode
	,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) AS party_name
	,value_code.code
	,(SELECT TOP 1 (vp.date_paid) FROM value_payment vp WHERE vp.valueid = value.id AND vp.valueid IN (SELECT value.id FROM value,value_code WHERE value.id = vp.valueid AND value_code.id=value.valuecodeid AND value_code.code= ''ATTYFEE'')) AS date_paid1
	,(SELECT SUM(vp.payment_amount) FROM value_payment vp WHERE vp.valueid = value.id AND vp.valueid IN (SELECT value.id FROM value,value_code WHERE value.id = vp.valueid AND value_code.id=value.valuecodeid AND value_code.code= ''ATTYFEE''))  AS PaymentAmount
	,(SELECT TOP 1 (case_checklist.due_date) FROM case_checklist,checklist_dir WHERE case_checklist.casesid=cases.id AND case_checklist.status = ''Done'' AND checklist_dir.id=case_checklist.checklistdirid AND checklist_dir.code = ''E06'') AS Settlement_Executed
FROM
	cases
JOIN value ON value.casesid=cases.id
JOIN value_code ON value_code.id=value.valuecodeid AND value_code.code IN (''ATTYFEE'', ''SETTLE'')
LEFT JOIN class ON class.id=cases.classid
WHERE
	cases.id IN (SELECT case_checklist.casesid FROM case_checklist,checklist_dir WHERE case_checklist.casesid=cases.id AND case_checklist.status = ''Done'' AND checklist_dir.id=case_checklist.checklistdirid AND checklist_dir.code = ''E06''
			AND (@EnterStartDate IS NULL OR case_checklist.due_date>=@EnterStartDate) AND (@EnterEndDate IS NULL OR case_checklist.due_date<=@EnterEndDate))
	AND (@staffstr IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') IN (@staffstr))

 )
 
 SELECT 
	COUNT(casenum) AS Total_Cases
	,FORMAT(SUM(settle_paid), ''C2'') AS settle_paid
	,FORMAT(SUM(Settlement_Due), ''C2'') AS Settlement_Due
	,FORMAT(SUM(PaymentAmount), ''C2'') AS PaymentAmount
 FROM
	cteAllData AS cte;
  
  
  ',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Total_Cases', @newReport, N'Total Cases', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'settle_paid', @newReport, N'Total Settle Paid', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Settlement_Due', @newReport, N'Total Settlement Due', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'PaymentAmount', @newReport, N'Total Payment Amount', 3)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'staffstr', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'EnterStartDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Start Date', 0, 1, 0,1)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'EnterEndDate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'End Date', 0, 1, 0, 2)


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