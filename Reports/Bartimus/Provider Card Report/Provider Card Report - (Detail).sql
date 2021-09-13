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
DECLARE @rptName varchar(100) = 'Provider Card Report - (Detail)';
DECLARE @rptDesc varchar(500) = 'Provider Card Report - (Detail)';
DECLARE @rptId varchar(50) = 'Provider Card Report';
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
				provider_name,
				company,
				address1,
				address_2,
				city,
				state,
				zipcode
				)
AS (
SELECT
	names.fullname_lastfirst AS provider_name,
	(SELECT TOP 1 multi_addresses.company FROM multi_addresses WHERE multi_addresses.namesid=names.id) AS company,
	(SELECT multi_addresses.address FROM multi_addresses WHERE multi_addresses.namesid=names.id  AND multi_addresses.default_addr=1) AS address1,
	(SELECT multi_addresses.address_2 FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS address_2,
	(SELECT multi_addresses.city FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS city,
	(SELECT multi_addresses.state FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS state,
	(SELECT multi_addresses.zipcode FROM multi_addresses WHERE multi_addresses.namesid=names.id AND multi_addresses.default_addr=1) AS zipcode
	
	
FROM 
	provider
JOIN names ON provider.id=names.id
WHERE 
	(@Christmas IS NULL OR (SELECT TOP 1 data FROM user_provider_data,user_case_fields WHERE user_provider_data.providerid=provider.id AND user_provider_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title = ''Christmas'') in (@Christmas))
	AND (@openHouse IS NULL OR (SELECT TOP 1 data FROM user_provider_data,user_case_fields WHERE user_provider_data.providerid=provider.id AND user_provider_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title = ''Open House'') in (@OpenHouse))
)
	SELECT
			provider_name,
			company,
			address1,
			address_2,
			city,
			state,
			zipcode
	FROM cteAllData;',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'provider_name', @newReport, N'Provider Name', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'company', @newReport, N'Company Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'address1', @newReport, N'Address 1',2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'address_2', @newReport, N'Address 2', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'city', @newReport, N'City', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'state', @newReport, N'State', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'zipcode', @newReport, N'Zip Code',6)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'Christmas', N'[System.String]',
	1, 1, N'Christmas', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'openHouse', N'[System.String]',
	0, 1, N'Open House', 1, 1, 0,0)
	


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