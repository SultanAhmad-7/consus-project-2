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
DECLARE @rptName varchar(100) = 'Intake Listing Report w Reason for Rejection - Detail';
DECLARE @rptDesc varchar(500) = 'Intake Listing Report w Reason for Rejection - Detail';
DECLARE @rptId varchar(50) = 'Intake Listing Report w Reason for Rejection';
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
				Referral_Source,Casenum,FullName,
				DOI,CaseType,IntakeDate,Casemade,numdays,
				TakenByStaff,PrimarystaffCode,County,Zipcode,
				referredBy_Name,Reason_for_Rejection,Staff_9
				)
AS (
SELECT 
		(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE cases.id = user_case_data.casesid AND user_case_fields.id = user_case_data.usercasefieldid AND field_title = ''Referral Source'')  AS Referral_Source,
		TRY_CAST(cases.casenum AS varchar(50))   AS Casenum, 
		(SELECT (n.last_long_name+'', ''+n.first_name)  AS FullName FROM "cases" "c","party" "p","names" "n"  WHERE c.id = cases.id AND p.casesid = c.id AND p.namesid=n.id AND p.id = (SELECT TOP 1  id FROM party p2 WHERE p2.casesid = c.id ORDER BY record_num)) AS FullName,
		cases.date_of_incident AS DOI,
		(SELECT TOP 1 matter.matcode FROM matter WHERE matter.id = cases.matterid)  AS CaseType,
		cases.intake_date AS IntakeDate,
		cases.date_opened AS Casemade,
		DATEDIFF(dd,cases.intake_date,cases.date_opened)  AS numdays,
		(SELECT TOP 1 staff_code FROM staff WHERE staff.id = cases.staffintakeid)  AS TakenByStaff,
		(SELECT TOP 1 staff.staff_code FROM case_staff ,staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid = (SELECT TOP 1 matter_staff.id  FROM matter_staff WHERE matter_staff.id = case_staff.matterstaffid AND matter_staff.primary_staff = 1 AND matter_staff.matterid = cases.matterid)) AS PrimarystaffCode,
		(SELECT TOP 1 county  FROM multi_addresses,names,party WHERE multi_addresses.namesid = names.id AND names.id = party.namesid AND party.casesid = cases.id AND party.record_num = (SELECT TOP 1 p.record_num  FROM party p WHERE p.casesid = cases.id  AND default_addr = 1))  AS County,
		(SELECT TOP 1 zipcode  FROM multi_addresses,names,party WHERE multi_addresses.namesid = names.id AND names.id = party.namesid AND party.casesid = cases.id AND party.record_num = (SELECT TOP 1 p.record_num  FROM party p WHERE p.casesid = cases.id  AND default_addr = 1))  AS Zipcode,
		(SELECT names.fullname_lastfirst FROM names WHERE cases.referredby_namesid=names.id)  AS referredBy_Name,
		(SELECT TOP 1 data  FROM user_case_data,user_case_fields WHERE cases.id = user_case_data.casesid AND user_case_fields.id = user_case_data.usercasefieldid AND field_title = ''Reason for Rejection'')  AS Reason_for_Rejection,
		NULL AS Staff_9
FROM 
	cases
WHERE 
	(SELECT TOP 1 default_addr FROM multi_addresses,names,party WHERE multi_addresses.namesid = names.id AND names.id = party.namesid AND party.casesid = cases.id AND party.record_num = (SELECT TOP 1 p.record_num FROM party p WHERE p.casesid = cases.id) AND default_addr = 1) = 1
	AND cases.dormant = 0
	AND (@IntakeDateStartParm is null or (TRY_CAST(cases.intake_date AS date)) >= @IntakeDateStartParm) 
	AND (@IntakeDateENDParm is null or (TRY_CAST(cases.intake_date AS date)) <= @IntakeDateENDParm)

UNION

SELECT
		(SELECT TOP 1 data  FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Referral Source'')  AS Referral_Source,
		(CASE WHEN case_intake.rejected = 1 THEN ''Rejected'' ELSE ''Pending'' END) AS Rejected_,
		(SELECT last_long_name FROM names WHERE id = (SELECT namesid FROM case_intake_data WHERE usercaseintakematterid = 
		(SELECT id FROM user_case_intake_matter WHERE field_title = ''Name'' AND tab_id=0 AND SELECTion = 1 AND user_case_intake_matter.matterid = case_intake.matterid) AND caseintakeid=case_intake.id)) + '', '' + 
		(SELECT first_name FROM names WHERE id = (SELECT namesid FROM case_intake_data WHERE usercaseintakematterid = (SELECT id FROM user_case_intake_matter WHERE field_title = ''Name'' AND tab_id=0 AND SELECTion = 1 AND user_case_intake_matter.matterid = case_intake.matterid) AND caseintakeid=case_intake.id)) AS FullName,
		(SELECT TOP 1 data FROM case_intake_data,user_case_intake_matter WHERE case_intake.id=case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid=user_case_intake_matter.id AND user_case_intake_matter.field_title=''Date of Accident'') AS DOI,
		(SELECT TOP 1 matcode  FROM matter WHERE matter.id = case_intake.matterid)  AS CaseType,
		case_intake.intake_taken AS IntakeDate,
		NULL,
		NULL,
		(SELECT TOP 1 staff_code  FROM staff WHERE staff.id = case_intake.takenbystaffid)  AS TakenByStaff,
		(SELECT TOP 1 staff_code  FROM staff WHERE staff.id = case_intake.primarystaffid)  AS PrimarystaffCode,
		NULL AS County,
		NULL AS Zipcode,
		(SELECT TOP 1 data  FROM case_intake_data WHERE case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = any(SELECT user_case_intake_matter.id FROM user_case_intake_matter WHERE user_case_intake_matter.field_title = ''Referred By'' AND user_case_intake_matter.tab_id = 10 AND user_case_intake_matter.SELECTion = 1))   AS referredBy_Name,
		(SELECT TOP 1 data  FROM case_intake_data ,user_case_intake_matter WHERE case_intake.id = case_intake_data.caseintakeid AND case_intake_data.usercaseintakematterid = user_case_intake_matter.id AND field_title = ''Reason for Rejection'')  AS Reason_for_Rejection,
		NULL AS Staff_9  
FROM
	case_intake
WHERE 
	(@IntakeDateStartParm is null or (TRY_CAST(case_intake.intake_taken AS date)) >= @IntakeDateStartParm) 
	AND (@IntakeDateENDParm is null or (TRY_CAST(case_intake.intake_taken AS date)) <= @IntakeDateENDParm)

)
SELECT
		(CASE WHEN Casenum = ''Rejected'' THEN ''Rejected'' WHEN Casenum = ''PENDing'' THEN ''PENDing'' ELSE Casenum END) Casenum,
		FullName,
		FORMAT(TRY_CAST(DOI AS date), ''MM/dd/yyyy'') AS doi,
		CaseType,
		FORMAT(TRY_CAST(IntakeDate AS date), ''MM/dd/yyyy'') AS intke_date,
		FORMAT(TRY_CAST(IntakeDate AS datetime), ''hh:mm tt'') AS intake_time,
		FORMAT(TRY_CAST(Casemade AS date), ''MM/dd/yyyy'') AS csemade,
		TakenByStaff,
		PrimarystaffCode,
		County,
		Zipcode,
		(CASE WHEN (referredBy_Name IS NOT NULL OR referredBy_Name <> '''') THEN referredBy_Name ELSE ''Unknown'' END) AS referredBy_Name,
		Reason_for_Rejection,
		Staff_9
FROM 
	cteAllData
ORDER BY
	intke_date ASC,
	intake_time ASC,
	CaseType ASC,
	csemade ASC;',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'FullName', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'doi', @newReport, N'DOI',2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'CaseType', @newReport, N'Case Type', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'intke_date', @newReport, N'Intake Date', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'intake_time', @newReport, N'Intake Time', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'csemade', @newReport, N'Date Opened',6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'TakenByStaff', @newReport, N'Taken By', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'PrimarystaffCode', @newReport, N'Staff Assigned',8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'County', @newReport, N'County', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Zipcode', @newReport, N'Zip Code', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referredBy_Name', @newReport, N'Referred By', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Reason_for_Rejection', @newReport, N'Reason For Rejection', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Staff_9', @newReport, N'Staff 9', 13)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'IntakeDateStartParm', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Intake Start Date', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'IntakeDateENDParm', N'System.Nullable`1[[System.DateTime]]', 
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