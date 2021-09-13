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
DECLARE @rptName varchar(100) = 'Cs Birthday List Addr W Casenum Open Cases (Detail)';
DECLARE @rptDesc varchar(500) = 'Cs Birthday List Addr W Casenum Open Cases (Detail)';
DECLARE @rptId varchar(50) = 'Cs Birthday List Addr W Casenum Open Cases';
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
	casenum,party_name,date_of_birth,party_role,address1,address2,city1,state1,zipcode1,staff_1,Attorney
			) 
AS (

SELECT
	cases.casenum
	,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) AS party_name
	,names.date_of_birth
	,(SELECT party_role_list.role FROM party_role_list WHERE party_role_list.id=party.partyrolelistid) AS party_role
	,(SELECT multi_addresses.address FROM multi_addresses WHERE multi_addresses.namesid=names.id AND default_addr=1) AS address1
	,(SELECT multi_addresses.address_2 FROM multi_addresses WHERE multi_addresses.namesid=names.id AND default_addr=1) AS address2
	,(SELECT multi_addresses.city FROM multi_addresses WHERE multi_addresses.namesid=names.id AND default_addr=1) AS city1
	,(SELECT multi_addresses.state FROM multi_addresses WHERE multi_addresses.namesid=names.id AND default_addr=1) AS state1
	,(SELECT multi_addresses.zipcode FROM multi_addresses WHERE multi_addresses.namesid=names.id AND default_addr=1) AS zipcode1
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
			AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') AS staff_1
	,(CASE WHEN (SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
						AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=3) IS NULL 
			THEN 
				(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
						AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000006'') 
			ELSE
				(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
						AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000008'') 
	END) AS Attorney
FROM 
	cases
JOIN party ON party.casesid=cases.id AND our_client=1
JOIN names ON names.id=party.namesid
JOIN matter ON matter.id=cases.matterid AND matcode IN (''MVA'', ''OTH'', ''PRL'') 
WHERE
	names.date_of_death IS  NULL
	AND cases.close_date IS NULL
	AND ((@startMONTH IS NULL OR (MONTH(date_of_birth)) >= @startMONTH)
	AND (@ENDMONTH IS NULL OR (MONTH(date_of_birth)) <= @ENDMONTH))
	AND ((@startday IS NULL OR (day(date_of_birth)) > @startday)
	AND (@ENDday IS NULL OR (day(date_of_birth)) <= @ENDday))
 )
 
 SELECT
	staff_1,
	Attorney,
	casenum,
	party_name,
	FORMAT(TRY_CAST(date_of_birth AS date), ''MM/dd/yyyy'') AS date_of_birth1,
	party_role,
	address1,
	address2,
	city1,
	state1,
	zipcode1
 FROM 
	cteAllData AS cte
 ORDER BY 
	(day(date_of_birth));',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_1', @newReport, N'Primary Staff', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Attorney', @newReport, N'Attorney', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Party Name', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'date_of_birth1', @newReport, N'Date of Birth', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_role', @newReport, N'Role', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'address1', @newReport, N'Address', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'address2', @newReport, N'Address 2', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'city1', @newReport, N'City', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'state1', @newReport, N'State', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'zipcode1', @newReport, N'Zipcode', 10)

INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'startmonth', N'[System.Int32]', 
	0, 1, N'Start Month', 0, 1, 0, 0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'endmonth', N'[System.Int32]', 
	0, 1, N'End Month', 0, 1, 0, 1)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'startday', N'[System.Int32]', 
	0, 1, N'Start Day', 0, 1, 0, 2)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'endday', N'[System.Int32]', 
	0, 1, N'End Day', 0, 1, 0, 3)
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