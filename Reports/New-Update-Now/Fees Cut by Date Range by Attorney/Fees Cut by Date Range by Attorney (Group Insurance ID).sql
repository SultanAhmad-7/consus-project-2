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
DECLARE @rptName varchar(100) = 'Fees Cut by Date Range by Attorney (Group Insurance ID)';
DECLARE @rptDesc varchar(500) = 'Fees Cut by Date Range by Attorney (Group Insurance ID)';
DECLARE @rptId varchar(50) = 'Fees Cut by Date Range by Attorney';
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
	casenum,atty,minimum,Payment_Goal,p_g,Est_Settlement_Date,actual,date_resolved,Settlement_Paid,Settlement_Due,
	class,party_name,id
	)
AS (
	SELECT 
		cases.casenum
		,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') AS atty
		,insurance.minimum_amount AS minimum
		,(CASE WHEN 
					ISNULL((SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.date_paid IS NOT NULL AND value_payment.date_paid >= @startdate AND value_payment.date_paid <= @enddate 
						AND value_payment.valueid IN (SELECT value.id FROM value,value_code WHERE value.casesid=cases.id AND value_code.code=''ATTYFEE'' AND value_code.id=value.valuecodeid)),0)=0
				THEN 
					(SELECT SUM(i.maximum_amount) FROM insurance i WHERE i.id=insurance.id AND insurance.id IN (SELECT user_insurance_data.insuranceid FROM user_insurance_data,
							user_case_fields WHERE user_insurance_data.insuranceid=insurance.id AND user_insurance_data.usercasefieldid=user_case_fields.id 
								AND user_case_fields.field_title=''Est. Settlement Date'' AND TRY_CAST(data AS date)>=@startdate AND TRY_CAST(data AS date)<=@enddate) ) 
				ELSE 
					(SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.date_paid IS NOT NULL AND value_payment.date_paid >= @startdate AND value_payment.date_paid <= @enddate 
								AND value_payment.valueid IN (SELECT value.id FROM value,value_code WHERE value.casesid=cases.id AND value_code.code=''ATTYFEE''
								AND value_code.id=value.valuecodeid)) END) AS Payment_Goal
		,(CASE WHEN 
				ISNULL((SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.date_paid IS NOT NULL AND value_payment.date_paid >= @startdate AND value_payment.date_paid <= @enddate AND value_payment.valueid IN (SELECT value.id FROM value,value_code WHERE value.casesid=cases.id AND value_code.code=''ATTYFEE''
					AND value_code.id=value.valuecodeid)),0)=0 
				THEN 
					''G'' 
				ELSE 
					''P'' END) AS p_g
		,(SELECT TOP 1 data FROM user_insurance_data,user_case_fields WHERE user_insurance_data.insuranceid=insurance.id AND user_insurance_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Est. Settlement Date'') AS Est_Settlement_Date
		,insurance.actual
		,insurance.date_settled AS date_resolved
		,(SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.valueid IN (SELECT value.id FROM value,value_code WHERE value.casesid=cases.id
				AND value_code.id=value.valuecodeid AND value_code.code=''SETTLE'')) AS Settlement_Paid
		,ISNULL((SELECT SUM(value.due) FROM value,value_code WHERE value.casesid=cases.id AND value_code.id=value.valuecodeid AND value_code.code=''SETTLE''),0) AS Settlement_Due
		,class.classcode AS class
		,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) AS party_name
		,insurance.id
	
	FROM 
		cases
	JOIN insurance ON insurance.casesid=cases.id
	LEFT JOIN class ON class.id=cases.classid
	WHERE 
		(@staff1 IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') IN (@staff1))
	AND cases.id IN (SELECT value.casesid FROM value,value_code WHERE value.casesid=cases.id AND value.valuecodeid=value_code.id AND value_code.code=''ATTYFEE'' AND value.id IN (SELECT value_payment.valueid FROM value_payment WHERE value_payment.valueid=value.id AND value_payment.date_paid is not  NULL AND value_payment.date_paid>=@startdate AND value_payment.date_paid<=@enddate))

UNION 

	SELECT 
		cases.casenum
		,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') AS atty
		,insurance.minimum_amount AS minimum
		,(CASE WHEN 
					ISNULL((SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.date_paid IS NOT NULL AND value_payment.date_paid >= @startdate AND value_payment.date_paid <= @enddate 
							AND value_payment.valueid IN (SELECT value.id FROM value,value_code WHERE value.casesid=cases.id AND value_code.code=''ATTYFEE'' AND value_code.id=value.valuecodeid)),0)=0
				THEN 
					(SELECT SUM(i.maximum_amount) FROM insurance i WHERE i.id=insurance.id AND insurance.id IN (SELECT user_insurance_data.insuranceid FROM user_insurance_data,user_case_fields WHERE user_insurance_data.insuranceid=insurance.id AND user_insurance_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Est. Settlement Date'' AND TRY_CAST(data AS date)>=@startdate AND TRY_CAST(data AS date)<=@enddate) ) 
				ELSE 
					(SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.date_paid IS NOT NULL AND value_payment.date_paid >= @startdate AND value_payment.date_paid <= @enddate AND value_payment.valueid IN (SELECT value.id FROM value,value_code WHERE value.casesid=cases.id AND value_code.code=''ATTYFEE'' AND value_code.id=value.valuecodeid)) END) AS Payment_Goal
		,(CASE WHEN 
					ISNULL((SELECT SUM(value_payment.payment_amount) FROM value_payment WHERE value_payment.date_paid IS NOT NULL AND value_payment.date_paid >= @startdate AND value_payment.date_paid <= @enddate AND value_payment.valueid IN (SELECT value.id FROM value,value_code WHERE value.casesid=cases.id AND value_code.code=''ATTYFEE'' AND value_code.id=value.valuecodeid)),0)=0 
				THEN 
					''G'' 
				ELSE 
					''P'' END) AS p_g
		,(SELECT TOP 1 data FROM user_insurance_data,user_case_fields WHERE user_insurance_data.insuranceid=insurance.id AND user_insurance_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Est. Settlement Date'') AS Est_Settlement_Date
		,insurance.actual
		,insurance.date_settled AS date_resolved
		,NULL AS Settlement_Paid
		,NULL AS Settlement_Due
		,class.classcode AS class
		,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) AS party_name
		,insurance.id
	
	FROM 
		cases
	JOIN insurance ON insurance.casesid=cases.id
	LEFT JOIN class ON class.id=cases.classid
	WHERE 
	(@staff1 IS NULL OR (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') IN (@staff1))
	AND insurance.id IN (SELECT user_insurance_data.insuranceid FROM user_insurance_data,user_case_fields WHERE user_insurance_data.insuranceid=insurance.id AND user_insurance_data.usercasefieldid=user_case_fields.id 
			AND user_case_fields.field_title=''Est. Settlement Date'' AND TRY_CAST(data AS date)>=@startdate AND TRY_CAST(data AS date)<=@enddate)
)

 SELECT 
		casenum
		,FORMAT(minimum,''C2'') AS Minimum_Amt
		,FORMAT(TRY_CAST(Est_Settlement_Date AS date), ''MM/dd/yyyy'') AS Est_Settlement_Date
		,FORMAT(actual,''C2'') AS Actual_Amt
		,FORMAT(TRY_CAST(date_resolved AS date), ''MM/dd/yyyy'') AS date_resolved
 FROM cteAllData AS cte
 GROUP BY casenum,minimum,Est_Settlement_Date,actual,date_resolved,id
 ORDER BY casenum, minimum;

',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Minimum_Amt', @newReport, N'Minimum', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Est_Settlement_Date', @newReport, N'Est Settlement Date', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Actual_Amt', @newReport, N'Actual', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_resolved', @newReport, N'Date Resolved', 4)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'startdate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Start Date', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'enddate', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'End Date', 0, 1, 0, 1)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'staff1', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0, 2)

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