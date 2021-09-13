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
DECLARE @rptName varchar(100) = 'Pi Atty Case List W Case Status (Detail)';
DECLARE @rptDesc varchar(500) = 'Pi Atty Case List W Case Status (Detail)';
DECLARE @rptId varchar(50) = 'Pi Atty Case List W Case Status';
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
	casenum,party_name,date_opened,lim_date,primary_staff,staff_3,matcode,description,
	Days_SLR,alt_case_num,case_date_3,close_date,lit_status,reassign_date,refer_to_id,staff_8,staff_6,
	stf_person,user_case_case_rating,user_case_Atty_Last_Review,user_case_Attorney_Review_Notes,classcode,origional_val_atty
				)
AS (

SELECT
	cases.casenum
	,(SELECT TOP 1 fullname_lastfirst FROM party,names WHERE casesid = cases.id AND party.namesid=names.id ORDER BY record_num ASC) AS party_name
	,cases.date_opened
	,cases.lim_date
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
			AND staffroleid=''00000000-0000-0000-0000-000000000008'') AS primary_staff
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
			AND staffroleid=''00000000-0000-0000-0000-000000000003'') AS staff_3
	,matter.matcode
	,class.description
	,DATEDIFF(DAY,(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.casesid = cases.id AND user_case_data.usercasefieldid = user_case_fields.id 
			AND field_title = ''Date of Atty Last Review''), GETDATE()) AS Days_SLR
	,cases.alt_case_num
	,(SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
			AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=3) AS case_date_3
	,cases.close_date
	,(CASE WHEN (SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
			AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=3) IS NULL THEN ''Pre-Lit'' ELSE ''Lit'' END) AS lit_status
	,cases.reassign_date
	,(SELECT names.names_id FROM names WHERE names.id = cases.referredto_namesid) AS refer_to_id
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
			AND staffroleid=''00000000-0000-0000-0000-000000000008'') AS staff_8
	,(SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
			AND staffroleid=''00000000-0000-0000-0000-000000000006'') AS staff_6
	,(CASE WHEN (SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
			AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=3) IS NULL 
	  THEN (SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
			AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000001'')
	   ELSE (SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid AND case_staff.matterstaffid=matter_staff.id 
					AND staffroleid=''00000000-0000-0000-0000-000000000003'')
	   END) AS stf_person
	,(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.casesid = cases.id AND user_case_data.usercasefieldid = user_case_fields.id 
			AND field_title = ''Case Rating'') AS user_case_case_rating
	,(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.casesid = cases.id AND user_case_data.usercasefieldid = user_case_fields.id 
			AND field_title = ''Date of Atty Last Review'') AS user_case_Atty_Last_Review
	,(SELECT TOP 1 data FROM user_case_data,user_case_fields WHERE user_case_data.casesid = cases.id AND user_case_data.usercasefieldid = user_case_fields.id 
			AND field_title = ''Attorney Review Notes'') AS user_case_Attorney_Review_Notes
	,class.classcode
	,(SELECT TOP 1 data FROM user_crm_data,user_crm_fields,user_crm_list WHERE user_crm_data.usercrmfieldid=user_crm_fields.id 
			AND user_crm_data.tablistid=user_crm_list.id AND user_crm_list.casesid=cases.id AND user_crm_fields.field_title=''Originating VL Atty'') AS origional_val_atty
FROM 
	cases
JOIN matter ON matter.id = cases.matterid
LEFT JOIN class ON class.id = cases.classid
WHERE 
	cases.close_date IS NULL
	AND cases.reassign_date IS NULL
	AND (
		 (SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
							AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=3) IS NULL
		AND (@Enter_Staff_Id IS NULL or (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
												AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000006'') in (@Enter_Staff_Id))
		AND (SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
		AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000006'') NOT IN (''Michael'', ''Kelly'',''Josh'' ) 
		OR (
			(SELECT casedate FROM case_dates, matter_dates WHERE cases.id = case_dates.casesid AND cases.matterid = matter_dates.matterid 
							AND case_dates.datelabelid=matter_dates.datelabelid AND display_order=3) is not null
			AND (@Enter_Staff_Id IS NULL or (SELECT staff.id FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
											AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000008'') in (@Enter_Staff_Id))
			AND (SELECT staff_code FROM case_staff, staff, matter_staff WHERE cases.id = case_staff.casesid AND staff.id = case_staff.staffid 
				AND case_staff.matterstaffid=matter_staff.id AND staffroleid=''00000000-0000-0000-0000-000000000008'') NOT IN (''Michael'', ''Kelly'',''Josh'')
			)
	)
	AND matter.matcode NOT IN (
								''BCM'',
								''BHB'',
								''BKC'',
								''BP'',
								''C13'',
								''COL'',
								''DRU'', 
								''DUI'', 
								''EVC'',
								''FAM'',
								''FRC'',
								''FRE'',
								''GEL'',
								''GMD'',
								''GMI'',
								''GML'',
								''HR'',
								''INS'',
								''LIMBO'',
								''LLC'',
								''MMM'',
								''MTM'',
								''PRA'',
								''RE'',
								''ROB'',
								''SS'', 
								''TAL'',
								''VIA'',
								''WC'',
								''WIL'',
								''XAR'',
								''YAZ'',
								''ZOF''
								)

 )
 
 SELECT 
	casenum
	,party_name
	,matcode
	,description
	,staff_3
	,stf_person
	,FORMAT(try_cast(lim_date AS date), ''MM/dd/yyyy'') AS lim_date
	,FORMAT(try_cast(case_date_3 AS date), ''MM/dd/yyyy'') AS case_date_3
	,Days_SLR
	,FORMAT(try_cast(user_case_Atty_Last_Review AS date), ''MM/dd/yyy'') AS user_case_Atty_Last_Review
	,user_case_Attorney_Review_Notes
	,origional_val_atty
	,user_case_case_rating
 FROM 
	cteAllData AS cte
 ORDER BY
	stf_person, case_date_3,party_name ASC, lit_status DESC;',@baseTableId)

-- insert the columns, one row per column in the select
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'casenum', @newReport, N'Case #', 0)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'party_name', @newReport, N'Party Name', 1)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'matcode', @newReport, N'Case Type', 2)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'description', @newReport, N'File Stage', 3)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'stf_person', @newReport, N'Pre-Lit Para', 4)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'staff_3', @newReport, N'Lit Para', 5)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'lim_date', @newReport, N'SOL', 6)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'case_date_3', @newReport, N'Date Filed', 7)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'Days_SLR', @newReport, N'#Days SLR', 8)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'user_case_Atty_Last_Review', @newReport, N'Atty Review Date', 9)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'user_case_Attorney_Review_Notes', @newReport, N'Atty Review Notes', 10)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'origional_val_atty', @newReport, N'Originating VL Atty', 11)
INSERT report_columns_orm (id, binding, reportid, name, col_order) VALUES (newid(), N'user_case_case_rating', @newReport, N'Case Rating', 12)


INSERT report_parameters_orm (id, reportid, name, type, multi_value, visible, description, use_string_value, is_sql_parm, is_required, parm_order) 
	VALUES (newid(), @newReport, N'Enter_Staff_Id', N'Needles.Core.Entities.Common.StaffPersonBasic', 
	1, 1, N'Enter Staff', 0, 1, 0,0)



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