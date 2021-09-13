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
DECLARE @rptName varchar(100) = 'WIP Review Per Staff (Group By Case Number)';
DECLARE @rptDesc varchar(500) = 'WIP Review Per Staff (Group By Case Number)';
DECLARE @rptId varchar(50) = 'WIP Review';
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
				casenum,party_name,matcode,classcode,staff_1,ins,policy_type,policy,claim,adjuster_name,limits,minimum_amount,goal,date_settled,
				actual,ran_1,est_settlement_date,rand_2,contract_percentage_data,contract_fee,q1_contract,q1_goal,q2_contract,q2_goal,
				q3_contract,q3_goal,q4_contract,q4_goal,insurance_type
				) 
AS ( 

SELECT 
	cases.casenum,
	(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id and party.namesid=names.id ORDER BY record_num ASC) AS party_name,
	matter.matcode,
	class.classcode,
	(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
	and staff.id = case_staff.staffid and case_staff.matterstaffid=matter_staff.id 
	and staffroleid=''00000000-0000-0000-0000-000000000001'') AS staff_1,
	(SELECT TOP 1 fullname_lastfirst FROM names WHERE names.id=insurance.insurer_namesid) AS ins,
	(SELECT insurance_type.type FROM insurance_type WHERE insurance_type.id=insurance.insurancetypeid) AS policy_type,
	insurance.policy,
	insurance.claim,
	(SELECT TOP 1 fullname_lastfirst FROM names WHERE names.id=insurance.adjuster_namesid) AS adjuster_name,
	insurance.limits,
	insurance.minimum_amount,
	insurance.maximum_amount AS goal,
	insurance.date_settled,
	insurance.actual,
	ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) AS ran_1,
	(SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') AS est_settlement_date,
	ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) AS rand_2,
	(try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) AS float)/100)  AS contract_percentage_data,
	
	(insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) AS float)/100))) AS contract_fee,
	
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between str(@StartYear)+''-01-01'' and str(@StartYear)+''-03-31'' THEN ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) AS float)/100)))) ELSE 0 END) AS q1_contract,
	
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between str(@StartYear)+''-01-01'' and str(@StartYear)+''-03-31'' THEN insurance.maximum_amount else 0 END) AS q1_goal,
	
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between str(@StartYear)+''-04-01'' and str(@StartYear)+''-06-30'' THEN ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) AS float)/100)))) ELSE 0 END) AS q2_contract,
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between str(@StartYear)+''-04-01'' and str(@StartYear)+''-06-30'' THEN insurance.maximum_amount else 0 end) AS q2_goal,
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between str(@StartYear)+''-07-01'' and str(@StartYear)+''-09-30'' THEN ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) AS float)/100)))) ELSE 0 END) as q3_contract,
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between str(@StartYear)+''-07-01'' and str(@StartYear)+''-09-30'' THEN insurance.maximum_amount else 0 end) AS q3_goal,
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between  str(@StartYear)+''-10-01'' and str(@StartYear)+''-12-31'' THEN ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id and party.casesid=cases.id and
		user_case_fields.id=user_party_data.usercasefieldid and user_case_fields.field_title=''Contract Percentage'' and trim(ISNULL(data,'''') ) <>'''' and
		ISNUMERIC(left(data,1) ) = 1) ,''%'',''''),0) as float)/100)))) ELSE 0 END) AS q4_contract,
	(CASE WHEN (SELECT TOP 1 try_cast(data as date) FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid and user_insurance_data.insuranceid=insurance.id
		and user_case_fields.field_title=''Est. Settlement Date'') between  str(@StartYear)+''-10-01'' and str(@StartYear)+''-12-31'' THEN insurance.maximum_amount ELSE 0 END) AS q4_goal,
	(SELECT insurance_type.type FROM insurance_type WHERE insurance_type.id=insurance.insurancetypeid) AS insurance_type


FROM
	cases
JOIN matter ON matter.id=cases.matterid
LEFT JOIN class ON class.id=cases.classid
JOIN insurance ON insurance.casesid=cases.id

WHERE 
	cases.close_date is null 
	and ((SELECT names.names_id FROM names WHERE names.id=insurance.insurer_namesid) >= 1)
	and  class.classcode not in (''INT'',''TRU'')
	and (((@EnterAtty is null) or ((SELECT staff.id FROM case_staff, staff, matter_staff 
	WHERE cases.id = case_staff.casesid and staff.id = case_staff.staffid 
	and case_staff.matterstaffid=matter_staff.id and staffroleid=''00000000-0000-0000-0000-000000000001'') in (@EnterAtty))))
	and (@InsuranceTypeParm is null OR (SELECT insurance_type.id FROM insurance_type WHERE insurance_type.id=insurance.insurancetypeid) in (@InsuranceTypeParm))


)
 
SELECT 
	party_name,
	count(distinct casenum) AS dtc
FROM 
	cteAllData AS cte
GROUP BY 
	casenum,party_name
ORDER BY 
	party_name;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Party Name', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'dtc', @newReport, N'Total Cases For Party', 1)





INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'EnterAtty', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'InsuranceTypeParm', N'Needles.Core.Entities.Insurance.InsuranceType', 
	1, 1, N'Insurance Type', 0, 1, 0,1)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'StartYear', N'[System.Int32]', 
	0, 1, N'Enter Year', 0, 1, 0,2) 





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