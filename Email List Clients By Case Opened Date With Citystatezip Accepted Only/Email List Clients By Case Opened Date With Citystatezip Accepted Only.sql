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
DECLARE @rptName varchar(100) = 'Email List Clients By Case Opened Date With Citystatezip Accepted Only';
DECLARE @rptDesc varchar(500) = 'Email List Clients By Case Opened Date With Citystatezip Accepted Only';
DECLARE @rptId varchar(50) = 'Email List Clients By Case Opened Date With Citystatezip Accepted Only';
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
				first_name,
				last_long_name,
				casenum,
				matcode,
				date_opened,
				classcode,
				city1,
				state1,
				zipcode1,
				Home_Email
				) 
AS (
SELECT
	names.first_name,
	names.last_long_name,
	cases.casenum,
	matter.matcode,
	cases.date_opened,
	class.classcode,
	(SELECT TOP 1 multi_addresses.city FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS city1,
	(SELECT TOP 1 multi_addresses.state FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS state1,
	(SELECT TOP 1 multi_addresses.zipcode FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS zipcode1,
	(SELECT TOP 1 online_accounts.account FROM online_accounts,online_account_category WHERE online_accounts.namesid = names.id AND online_account_category.id = online_accounts.onlineaccountcategoryid
		AND online_account_category.title = ''Email'' AND online_accounts.type = 0) AS Home_Email

FROM cases
JOIN matter ON matter.id=cases.matterid
LEFT JOIN class ON class.id=cases.classid
JOIN party ON party.casesid=cases.id
JOIN names ON names.id=party.namesid

WHERE 
	((SELECT TOP 1 online_accounts.account FROM online_accounts,online_account_category WHERE online_accounts.namesid = names.id AND online_account_category.id = online_accounts.onlineaccountcategoryid
		AND online_account_category.title = ''Email'' AND online_accounts.type = 0) IS NOT NULL 
	AND (SELECT TOP 1 online_accounts.account FROM online_accounts,online_account_category WHERE online_accounts.namesid = names.id AND online_account_category.id = online_accounts.onlineaccountcategoryid
		AND online_account_category.title = ''Email'' AND online_accounts.type = 0) <> '''')
	AND party.our_client = 1 
	AND ((@dateOpenedStart is null or cases.date_opened >= @dateOpenedStart) AND (@dateOpenedEnd is null or cases.date_opened <= @dateOpenedEnd))
	AND matter.matcode <> ''8MD''
	AND (
		class.classcode <> 	''REJ'' 
	AND class.classcode <> ''0RJ'' 
	AND class.classcode <> ''8KC'' 
	AND class.classcode <> ''9DR'' 
	AND class.classcode <> ''VB6'' 
	AND class.classcode <> ''VB7''
			)  

 AND (SELECT TOP 1 multi_addresses.default_addr FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) = 1
 AND names.deceased = 0
 )
 SELECT
	(first_name +'' ''+ last_long_name) AS [Party Name],
	casenum AS [Case #],
	matcode AS [Case Type],
	FORMAT(TRY_CAST(date_opened AS DATE), ''MM/dd/yyyy'') AS [Date Opened],
	classcode AS [Class],
	city1 AS [City],
	state1 AS [State],
	zipcode1 AS [Zip],
	Home_Email AS [Home E-Mail]
 FROM cteAllData
 ORDER BY last_long_name ASC;

',@baseTableId)

-- insert the columns, one row per column in the select

INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[Party Name]', @newReport, N'Party Name', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[Case #]', @newReport, N'Case #', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[Case Type]', @newReport, N'Case Type', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[Date Opened]', @newReport, N'Date Opened', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[Class]', @newReport, N'Class', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[City]', @newReport, N'City', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[State]', @newReport, N'State', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[Zip]', @newReport, N'Zip', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'[Home E-Mail]', @newReport, N'Home E-Mail', 8)



INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpenedStart', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Date Opened Start', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'dateOpenedEnd', N'System.Nullable`1[[System.DateTime]]', 
	0, 1, N'Date Opened End', 0, 1, 0,1)

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