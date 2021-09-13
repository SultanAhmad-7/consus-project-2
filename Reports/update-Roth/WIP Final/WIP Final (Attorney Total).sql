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
DECLARE @rptName varchar(100) = 'WIP Final (Attorney Total)';
DECLARE @rptDesc varchar(500) = 'WIP Final (Attorney Total)';
DECLARE @rptId varchar(50) = 'WIP Final';
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


WITH cteAllData 
				(
					casenum,party_name,matcode,classcode,staff_1,ins,policy_type,policy,claim,adjuster_name,limits,minimum_amount,goal,date_settled,
					actual,ran_1,est_settlement_date,rAND_2,contract_percentage_data,contract_fee,q1_2018_contract,q1_2018_goal,q2_2018_contract,
					q2_2018_goal,q3_2018_contract,q3_2018_goal,q4_2018_contract,q4_2018_goal
				)
AS ( 
SELECT 
	cases.casenum
	,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) as party_name
	,matter.matcode
	,class.classcode
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid 
			AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
			AND staffroleid=''00000000-0000-0000-0000-000000000001'') as staff_1
	,(SELECT TOP 1 fullname_lastfirst FROM names WHERE names.id=insurance.insurer_namesid) as ins
	,(SELECT insurance_type.type FROM insurance_type WHERE insurance_type.id=insurance.insurancetypeid) as policy_type
	,insurance.policy
	,insurance.claim
	,(SELECT TOP 1 fullname_lastfirst FROM names WHERE names.id=insurance.adjuster_namesid) as adjuster_name
	,insurance.limits
	,insurance.minimum_amount
	,insurance.maximum_amount as goal
	,insurance.date_settled
	,insurance.actual
	,ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as ran_1
	,(SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') as est_settlement_date
	,ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as rAND_2
	,(try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as float)/100)  as contract_percentage_data
	,(insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as float)/100))) as contract_fee
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between ''2021-01-01'' AND ''2021-03-31'' then ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as float)/100)))) else 0 end) as q1_2018_contract
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between ''2021-01-01'' AND ''2021-03-31'' then insurance.maximum_amount else 0 end) as q1_2018_goal
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between ''2021-04-01'' AND ''2021-06-30'' then ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as float)/100)))) else 0 end) as q2_2018_contract
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between ''2021-04-01'' AND ''2021-06-30'' then insurance.maximum_amount else 0 end) as q2_2018_goal
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between ''2021-07-01'' AND ''2021-09-30'' then ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as float)/100)))) else 0 end) as q3_2018_contract
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between ''2021-07-01'' AND ''2021-09-30'' then insurance.maximum_amount else 0 end) as q3_2018_goal
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between  ''2021-10-01'' AND ''2021-12-31'' then ((insurance.minimum_amount * ((try_cast(ISNULL(REPLACE((SELECT max(data) FROM user_party_data,party,user_case_fields WHERE user_party_data.partyid=party.id AND party.casesid=cases.id AND
			user_case_fields.id=user_party_data.usercasefieldid AND user_case_fields.field_title=''Contract Percentage'' AND trim(ISNULL(data,'''') ) <>'''' AND
			ISNUMERIC(LEFT(data,1) ) = 1) ,''%'',''''),0) as float)/100)))) else 0 end) as q4_2018_contract
	,(case when (SELECT TOP 1 data FROM user_insurance_data, user_case_fields WHERE user_case_fields.id=user_insurance_data.usercasefieldid AND user_insurance_data.insuranceid=insurance.id
			AND user_case_fields.field_title=''Est. Settlement Date'') between  ''2021-10-01'' AND ''2021-12-31'' then insurance.maximum_amount else 0 end) as q4_2018_goal
	

FROM cases
JOIN matter ON matter.id=cases.matterid
LEFT JOIN class on class.id=cases.classid
JOIN insurance on insurance.casesid=cases.id
WHERE cases.close_date is null 
AND ((SELECT names.names_id FROM names WHERE names.id=insurance.insurer_namesid) >= 1)
AND class.classcode not in (''INT'',''TRU'')
AND ((insurance.minimum_amount is not null AND insurance.minimum_amount <> 0) 	
			OR (insurance.maximum_amount is not null AND insurance.maximum_amount <> 0))
AND (((@enter_atty is null) or ((SELECT staff.id FROM case_staff, staff, matter_staff 
					WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
					AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'') in (@enter_atty))))
AND (@Ins_Type_Parm is null OR (SELECT insurance_type.id FROM insurance_type WHERE insurance_type.id=insurance.insurancetypeid) in (@Ins_Type_Parm))

)
 
 SELECT 
	COUNT(DISTINCT casenum) AS dtc
	,staff_1
	,FORMAT(sum(minimum_amount), ''C2'') AS mini_amount
	,FORMAT(sum(goal), ''C2'') AS goal
	,FORMAT(sum(actual), ''C2'') AS actual
	,FORMAT(sum(contract_fee), ''C2'') AS contract_fee
	,FORMAT(sum(q1_2018_contract), ''C2'') AS q1_2018_contract
	,FORMAT(sum(q1_2018_goal), ''C2'') AS q1_2018_goal
	,FORMAT(sum(q2_2018_contract), ''C2'') AS q2_2018_contract
	,FORMAT(sum(q2_2018_goal), ''C2'') AS q2_2018_goal
	,FORMAT(sum(q3_2018_contract), ''C2'') AS q3_2018_contract
	,FORMAT(sum(q3_2018_goal), ''C2'') AS q3_2018_goal
	,FORMAT(sum(q4_2018_contract), ''C2'') AS q4_2018_contract
	,FORMAT(sum(q4_2018_goal), ''C2'') AS q4_2018_goal
	,FORMAT((sum(q1_2018_contract)+sum(q2_2018_contract)+sum(q3_2018_contract)+sum(q4_2018_contract)) / COUNT (DISTINCT casenum),''C2'') AS Avg_WIP_Case_Contract_Fee
	,FORMAT((sum(q1_2018_goal)+sum(q2_2018_goal)+sum(q3_2018_goal)+sum(q4_2018_goal)) / COUNT(DISTINCT casenum), ''C2'') AS Avg_WIP_Case_Goal
	,FORMAT(((sum(q1_2018_goal)+sum(q2_2018_goal)+sum(q3_2018_goal)+sum(q4_2018_goal)) / COUNT(DISTINCT casenum)) - ((sum(q1_2018_contract)+sum(q2_2018_contract)+sum(q3_2018_contract)+sum(q4_2018_contract)) / COUNT (DISTINCT casenum)) , ''C2'') AS reduction
	,FORMAT((sum(q1_2018_contract)+sum(q2_2018_contract)+sum(q3_2018_contract)+sum(q4_2018_contract)),''C2'') total_contract_fee_wip
	,FORMAT((sum(q1_2018_goal)+sum(q2_2018_goal)+sum(q3_2018_goal)+sum(q4_2018_goal)), ''C2'') AS total_goal_wip
FROM 
	cteAllData AS cte
GROUP BY
	staff_1
ORDER BY
	staff_1;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'dtc', @newReport, N'Total Cases For Attorney', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_1', @newReport, N'Primary Staff', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'mini_amount', @newReport, N'Total Minimum Amount', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'goal', @newReport, N'Total Goal', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'actual', @newReport, N'Total Insurance Actual', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'contract_fee', @newReport, N'Total Contract Fee', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q1_2018_contract', @newReport, N'Total Q1 2021 Contract Fee', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q1_2018_goal', @newReport, N'Total Q1 2021 Goal', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q2_2018_contract', @newReport, N'Total Q2 2021 Contract Fee', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q2_2018_goal', @newReport, N'Total Q2 2021 Goal', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q3_2018_contract', @newReport, N'Total Q3 2021 Contract Fee', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q3_2018_goal', @newReport, N'Total Q3 2021 Goal', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q4_2018_contract', @newReport, N'Total Q4 2021 Contract Fee', 12)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'q4_2018_goal', @newReport, N'Total Q4 2021 Goal', 13)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Avg_WIP_Case_Contract_Fee', @newReport, N'Avg WIP/Case Contract Fee', 14)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Avg_WIP_Case_Goal', @newReport, N'Avg WIP/Case Goal', 15)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'reduction', @newReport, N'Average Reduction', 16)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'total_contract_fee_wip', @newReport, N'2021 Total WIP Contract Fee', 17)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'total_goal_wip', @newReport, N'2021 Total WIP Goal', 18)




INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'enter_atty', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Primary Staff', 0, 1, 0,0)
INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'Ins_Type_Parm', N'Needles.Core.Entities.Insurance.InsuranceType', 
	1, 1, N'Insurance Type', 0, 1, 0,1)



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