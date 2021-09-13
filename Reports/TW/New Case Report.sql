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
DECLARE @rptName varchar(100) = 'New Case Report';
DECLARE @rptDesc varchar(500) = 'New Case Report';
DECLARE @rptId varchar(50) = 'New Case Report';
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
				casenum,party_name,case_title,liability,date_created,referal,primary_staff,support3
				)
As (
SELECT
	cases.casenum
	, (SELECT TOP 1 names.fullname_lastfirst FROM names, party WHERE names.id=party.namesid AND party.casesid=cases.id ORDER BY record_num ASC) AS party_name
	,cases.case_title
	,matter.header AS liability
	,cases.date_created
	,(SELECT TOP 1 DATA FROM user_case_data,user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id
		AND user_case_fields.field_title=''Referral'') AS referal
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
		AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
		AND staffroleid=''00000000-0000-0000-0000-000000000001'') AS primary_staff
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
		AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
		AND staffroleid=''00000000-0000-0000-0000-000000000004'') AS support_3
		-- Rainmaker Not Found 
	
 FROM cases
 JOIN matter ON matter.id=cases.matterid
 )
 SELECT
	casenum
	,(
		CASE WHEN party_name IS NOT NULL OR party_name <> '''' AND case_title IS NOT NULL 
		   THEN  party_name + '' vs ''+ ISNULL(case_title,''Unknown'')
			 WHEN case_title IS NULL 
			 THEN party_name 
		   ELSE case_title
		END
	) AS case_name
	,liability
	,format(try_cast(date_created as date), ''MM/dd/yyyy'') as dte_created
	,referal
	,primary_staff
	,support3
 FROM 
	cteAllData;
',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'case_name', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'liability', @newReport, N'Liability', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'dte_created', @newReport, N'Date Created', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'referal', @newReport, N'Referral', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'primary_staff', @newReport, N'Primary Staff', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'support3', @newReport, N'Support 3', 6)

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