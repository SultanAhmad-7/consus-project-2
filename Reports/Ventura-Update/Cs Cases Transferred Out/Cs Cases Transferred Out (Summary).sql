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
DECLARE @rptName varchar(100) = 'Cs Cases Transferred Out (Summary)';
DECLARE @rptDesc varchar(500) = 'Cs Cases Transferred Out (Summary)';
DECLARE @rptId varchar(50) = 'Cs Cases Transferred Out';
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
		casenum,party_name,case_type,classcode,DOL,reassign_dte,paralegal_status_notes,date_of_para_last_review,Number_of_Days_Since_Last_Follow_Up,
		reffered_to,Home_Email,Business_Phone,referral_fee_agreement,name_of_drug_or_product,origional_val_atty,marketing_sources,case_category,
		CL_SOL_Only,date_field,date_opened,date_retained,alt_case_num
				) 
AS (

SELECT 
	cases.casenum
	,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) AS party_name
	,matter.matcode AS case_type
	,class.classcode
	,cases.date_of_incident AS DOL
	,cases.reassign_date AS reassign_dte
	,(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.casesid=cases.id AND user_case_fields.id=user_case_data.usercasefieldid
			AND user_case_fields.field_title=''Paralegal Status Notes'') AS paralegal_status_notes
	,(SELECT TOP 1 data FROM user_case_data, user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id
			AND user_case_fields.field_title=''Date of Para Last Review'') AS date_of_para_last_review
	,CAST(DATEDIFF(day,ISNULL((SELECT TOP 1 data FROM user_case_data, user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id
			AND user_case_fields.field_title=''Date of Para Last Review''),cases.reassign_date),GETDATE()) AS float) AS Number_of_Days_Since_Last_Follow_Up
	,(SELECT TOP 1 fullname_lastfirst FROM names WHERE cases.referredto_namesid=names.id) AS reffered_to
	,(SELECT TOP 1 online_accounts.account FROM online_accounts,online_account_category,names WHERE cases.referredto_namesid = names.id AND online_accounts.namesid = names.id AND online_account_category.id = online_accounts.onlineaccountcategoryid
			AND online_account_category.title = ''Email'' AND online_accounts.type = 1) AS Home_Email
	,(SELECT  ''('' + Substring(number,1,3) + '') '' + Substring(number,4,3) + ''-'' + Substring(number,7,4) FROM phone,names WHERE cases.referredto_namesid = names.id 
			AND phone.namesid = names.id AND title = ''Business'') AS Business_Phone
	,(SELECT TOP 1 data FROM user_provider_data,user_case_fields,provider,names WHERE user_provider_data.usercasefieldid=user_case_fields.id AND user_provider_data.providerid = provider.id
			AND user_case_fields.field_title=''Referral Fee Agreement'' AND cases.referredto_namesid = names.id AND provider.id = names.id) AS referral_fee_agreement
	,(SELECT TOP 1 data FROM user_case_data, user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id
			AND user_case_fields.field_title=''Name of Drug or Product'') AS name_of_drug_or_product
	,(SELECT TOP 1 data FROM user_crm_data,user_crm_fields,user_crm_list WHERE user_crm_data.usercrmfieldid=user_crm_fields.id 
			AND user_crm_data.tablistid=user_crm_list.id AND user_crm_list.casesid=cases.id AND user_crm_fields.field_title=''Originating VL Atty'') AS origional_val_atty
	,(SELECT TOP 1 data FROM user_case_data, user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id
			AND user_case_fields.field_title=''Marketing Sources'') AS marketing_sources
	,(SELECT TOP 1 data FROM user_case_data, user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id
			AND user_case_fields.field_title=''Case Category'') AS case_category
	,(SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
			AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=4) AS CL_SOL_Only
	,(SELECT TOP 1 data FROM user_tab9_data,user_case_fields WHERE user_tab9_data.casesid=cases.id AND user_tab9_data.usercasefieldid=user_case_fields.id
			AND user_case_fields.field_title=''Date Filed'') AS date_field
	,cases.date_opened
	,(SELECT TOP 1 data FROM user_case_data, user_case_fields WHERE user_case_data.usercasefieldid=user_case_fields.id AND user_case_data.casesid=cases.id
			AND user_case_fields.field_title=''Date Retained'') AS date_retained
	,cases.alt_case_num
FROM cases
	JOIN matter ON matter.id=cases.matterid 
	LEFT JOIN class ON class.id=cases.classid
WHERE 
	cases.reassign_date IS NOT NULL
	AND cases.close_date IS  NULL
)
SELECT
	COUNT(casenum) AS tc
	,ROUND(AVG(Number_of_Days_Since_Last_Follow_Up),2) AS Number_of_Days_Since_Last_Follow_Up
FROM
	cteAllData;
',@baseTableId)
-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'tc', @newReport, N'Total Cases', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Number_of_Days_Since_Last_Follow_Up', @newReport, N'Avg. #DSLR', 1)

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