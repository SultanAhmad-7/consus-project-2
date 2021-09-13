declare @Open_Closed_All as varchar(50);-- = ''Open'';
declare @startOpenDate as datetime;-- = ''2020-01-01'';
declare @endOpenDate as datetime;-- = ''2020-02-01'';

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
DECLARE @rptName varchar(100) = 'M Keller Medrecs Multiclient (Group)';
DECLARE @rptDesc varchar(500) = 'M Keller Medrecs Multiclient (Group)';
DECLARE @rptId varchar(50) = 'M Keller Medrecs Multiclient';
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
				alt_case_num
				,casenum
				,party_name
				,Prvdr_Specialty
				,name1
				,Type_of_Record
				,Recs_Received
				,Dates_of_Service
				,Client_Name
				) 
AS (
SELECT 
		cases.alt_case_num
		,cases.casenum
		,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) AS party_name
		,(SELECT TOP 1 DATA  FROM user_tab4_data,user_case_fields WHERE user_tab4_data.tablistid=user_tab4_list.id AND 
				user_tab4_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Prvdr Specialty'') AS Prvdr_Specialty
		,(SELECT TOP 1 DATA  FROM user_tab4_data,user_case_fields WHERE user_tab4_data.tablistid=user_tab4_list.id AND 
				user_tab4_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Name'') AS name1
		,(SELECT TOP 1 DATA  FROM user_tab4_data,user_case_fields WHERE user_tab4_data.tablistid=user_tab4_list.id AND 
				user_tab4_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Type of Record'') AS Type_of_Record
		,(SELECT TOP 1 DATA  FROM user_tab4_data,user_case_fields WHERE user_tab4_data.tablistid=user_tab4_list.id AND 
				user_tab4_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Recs Received'') AS Recs_Received
		,(SELECT TOP 1 DATA  FROM user_tab4_data,user_case_fields WHERE user_tab4_data.tablistid=user_tab4_list.id AND 
				user_tab4_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Dates of Service'') AS Dates_of_Service
		,(SELECT TOP 1 DATA  FROM user_tab4_data,user_case_fields WHERE user_tab4_data.tablistid=user_tab4_list.id AND 
				user_tab4_data.usercasefieldid=user_case_fields.id AND user_case_fields.field_title=''Client Name'') AS Client_Name
FROM 
	cases
JOIN user_tab4_list ON user_tab4_list.casesid = cases.id
WHERE 
	(cases.alt_case_num = (@altcasenum) OR @altcasenum IS NULL) 
AND  cases.close_date IS NULL 

 )
 
 SELECT 
		Client_Name
		,name1
		,Prvdr_Specialty
		,Dates_of_Service
		,Type_of_Record
		,FORMAT(TRY_CAST(Recs_Received AS date), ''MM/dd/yyyy'') AS recdte1
 FROM 
	cteAllData AS cte
GROUP BY  
	Client_Name
	,name1
	,Prvdr_Specialty
	,Dates_of_Service
	,Type_of_Record
	,Recs_Received
ORDER BY
	Client_Name,name1,recdte1;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Client_Name', @newReport, N'Case Under', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'name1', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Prvdr_Specialty', @newReport, N'Speciality', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Dates_of_Service', @newReport, N'Dates of Service ', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Type_of_Record', @newReport, N'Record Type', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'recdte1', @newReport, N'Recs Received', 5)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'altcasenum', N'[System.String]', 
	0, 1, N'Enter Alt Case Number', 0, 1,1,0)
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