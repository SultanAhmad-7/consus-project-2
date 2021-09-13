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
DECLARE @rptName varchar(100) = 'Expense Summary Court And Case W Adv - Detail';
DECLARE @rptDesc varchar(500) = 'Expense Summary Court And Case W Adv - Detail';
DECLARE @rptId varchar(50) = 'Expense Summary Court And Case W Adv - Detail';
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

Begin 

delete from reports_orm where title = @rptid or title = @rptName;
delete from reports where title = @rptName;

INSERT reports (id,title, description,report_object, read_only, reportcategoryid, date_created, 
	staffcreatedid,date_modified,staffmodifiedid, content, datelastrun, stafflastrunid,report_type)

VALUES (@baseTableId ,@rptName, @rptDesc,
N'Blank Report Object', 0,(SELECT top 1 id  FROM report_category where name = 'User Defined'),current_timestamp,
NULL,current_timestamp, NULL, NULL, NULL, NULL, 0)
;
-- insert the report object (title must be unique)
INSERT reports_orm (id, title, description, report_object, read_only, 
reportcategoryid, date_created, staffcreatedid, date_modified, staffmodifiedid, base_entity, 
raw_sql, main_table_id) 
VALUES (@newReport, @rptName, @rptName, N'Blank Report Object', 0, (SELECT top 1 id  FROM report_category where name = 'User Defined') , 
current_timestamp, NULL, NULL, NULL, N'Needles.ReportDesigner.ReportObjects.UserDefinedReport', '

with cteAllData(party_name,alt_case_num,casenum,code,start_date,provider_name,memo,purpose_of_transaction,totl_val) as (
select 
(select top 1  names.fullname_lastfirst from names,party 
where namesid=names.id and party.namesid=names.id	and party.casesid=cases.id Order by record_num ASC ) as party_name,
	cases.alt_case_num,
	cases.casenum,
	
	value_code.code,
	value.start_date,

	(select top 1 names.fullname_lastfirst from names where value.namesid=names.id  ) as provider_name, 

	value.memo,	

	
	(select top 1 data from user_value_data,user_case_fields where user_value_data.valueid=value.id and user_value_data.usercasefieldid=user_case_fields.id and 
	user_case_fields.field_title= ''Purpose of Transaction'') as purpose_of_transaction,
(case when (select top 1 value_payment.credit_debit from value_payment
where value_payment.valueid = value.id)= 0 then (value.total_value * -1) else value.total_value end) as totl_val
from cases
join value on value.casesid=cases.id
join value_code on value_code.id=value.valuecodeid


where 

(value_code.code = ''ce reimb'' OR  
 value_code.code = ''cc reimb'' OR  value_code.code = ''advance'' OR value_code.code = ''adv reimb'' OR  value_code.code = ''acc rept'' OR  value_code.code = ''backgrd ck'' OR  
  value_code.code = ''cert copy'' OR  value_code.code = ''copy depo'' OR   value_code.code = ''consult'' OR   value_code.code = ''ct costs'' OR    value_code.code = ''delivery'' OR  
  value_code.code = ''expert fee'' OR   value_code.code = ''investigat'' OR   value_code.code = ''filing fee'' OR   value_code.code = ''jury fee'' OR   value_code.code = ''legal'' OR  
 value_code.code = ''loan'' OR   value_code.code = ''loan inter'' OR   value_code.code = ''med bill'' OR   value_code.code = ''med narrat'' OR   value_code.code = ''med record'' OR  
 value_code.code = ''mediation'' OR    value_code.code = ''mileage'' OR  value_code.code = ''misc'' OR   value_code.code = ''out copies'' OR   value_code.code = ''parking'' OR  
  value_code.code = ''phone conf'' OR   value_code.code = ''photos'' OR   value_code.code = ''pro serv'' OR   value_code.code = ''ref exp'' OR  value_code.code = ''ref fee'' OR  
 value_code.code = ''research'' OR   value_code.code = ''sec of st'' OR   value_code.code = ''shipping'' OR   value_code.code = ''storage'' OR   value_code.code = ''sub court'' OR  
 value_code.code = ''sub depo'' OR   value_code.code = ''supplies'' OR   value_code.code = ''trav air'' OR   value_code.code = ''trav cab'' OR   value_code.code = ''trav car'' OR  
 value_code.code = ''trav gas'' OR     value_code.code = ''trav hotel'' OR   value_code.code = ''trav meal'' OR    value_code.code = ''video depo'' OR    value_code.code = ''witness fe'' OR  
 value_code.code = ''in copies'' OR   value_code.code = ''in dvd'' OR    value_code.code= ''in fax'' OR   value_code.code = ''in postage'' OR    value_code.code = ''in telepho'' OR  
value_code.code = ''e filing'' OR value_code.code = ''sub prod'' OR value_code.code= ''subr gv cl'' OR value_code.code = ''amnt cl an'' OR value_code.code = ''amnt cl tr'' OR 
value_code.code = ''amnt msa'' OR value_code.code = ''amnt cl'' OR value_code.code = ''in video'')
and  (@caseNumber is null or cases.id in (@caseNumber)) 
)

select 
party_name,
alt_case_num,
casenum,
code,
format(try_cast(start_date as date),''MM/dd/yyyy'') as strat_dte,
provider_name,
memo,
purpose_of_transaction,
format(totl_val,''c2'') as ttl_val

from cteAllData 
order by code, strat_dte,party_name;

 
 
 
 ',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Party Name', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'alt_case_num', @newReport, N'T and S File #', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Needle Case #', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'code', @newReport, N'Code', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'strat_dte', @newReport, N'Start Date', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'provider_name', @newReport, N'Provider', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'memo', @newReport, N'Memo', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'purpose_of_transaction', @newReport, N'Purpose Of Transaction', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'ttl_val', @newReport, N'DEBIT / (CREDIT)', 8)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'caseNumber', N'Needles.Core.Entities.Common.Case', 
	0, 1, N'Case #', 0, 1, 0,0)

END;

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