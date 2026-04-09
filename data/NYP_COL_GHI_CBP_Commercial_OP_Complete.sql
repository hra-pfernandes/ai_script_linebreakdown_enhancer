
--Updated Dec 2024 rates 2.19.2025
--Added 2024 GHI CBP FS 2.20.2025 SC
--Fixed drug logic 3.13.2025 SC
--As per Isabellas advised and ricardo's, Split plan Drugs should reimbursed at ASP rates 3.18.2025 SC
--Updated 2025 Contract rates by Naveen Abboju 07.30.2025
USE [COL]

IF OBJECT_ID('tempdb..#Step1') IS NOT NULL DROP TABLE #Step1
IF OBJECT_ID('tempdb..#Step1_Charges') IS NOT NULL DROP TABLE #Step1_Charges
IF OBJECT_ID('tempdb..#modifier') IS NOT NULL DROP TABLE #modifier
IF OBJECT_ID('tempdb..#Step2') IS NOT NULL DROP TABLE #Step2
IF OBJECT_ID('tempdb..#Step3') IS NOT NULL DROP TABLE #Step3
IF OBJECT_ID('tempdb..#Step3_1') IS NOT NULL DROP TABLE #Step3_1
IF OBJECT_ID('tempdb..#Step3_2') IS NOT NULL DROP TABLE #Step3_2
IF OBJECT_ID('tempdb..#Step4') IS NOT NULL DROP TABLE #Step4
IF OBJECT_ID('tempdb..#Step5') IS NOT NULL DROP TABLE #Step5
IF OBJECT_ID('tempdb..#Step6') IS NOT NULL DROP TABLE #Step6
IF OBJECT_ID('tempdb..#Step7') IS NOT NULL DROP TABLE #Step7
IF OBJECT_ID('tempdb..#StepFinal') IS NOT NULL DROP TABLE #StepFinal

IF OBJECT_ID('tempdb..#bRanked')       IS NOT NULL DROP TABLE #bRanked
IF OBJECT_ID('tempdb..#bSlots')        IS NOT NULL DROP TABLE #bSlots
IF OBJECT_ID('tempdb..#LineBreakdown') IS NOT NULL DROP TABLE #LineBreakdown
IF OBJECT_ID('tempdb..#recon_temp')    IS NOT NULL DROP TABLE #recon_temp





--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

INTO #Step1
FROM [COL].[Data].[Charges] as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.EncounterID = y.EncounterID
	LEFT JOIN [PRS].[dbo].[PRS_Data] as p on x.[EncounterID] = p.[patient_id_real]
-- LEFT JOIN [PRS].[dbo].Underpayments AS p1 ON p.[patient_id_real] = p1.[patient_id_real]

where TypeOfBill = 'Outpatient'

	and (Payer01Name IN ('EMBLEM HEALTH GHI/ANTHEM CBP','EMBLEM HEALTH GHI/EMPIRE CBP'))

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
	-- and ( p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	--and y.[AGE] < 65


	and y.ServiceDateFrom < '2025-10-01'
	--and YEAR(y.ServiceDateFrom) between '2021' and '2026'




Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '' or ProcedureCode is null, 0, CAST(Left(ProcedureCode,5) as numeric)) as ProcedureCodeNumeric

INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.EncounterID = y.EncounterID

where x.[EncounterID] in (Select [EncounterID]
from #Step1);

--***********************************************************************************************************************************************************************************************************************************************************************************************************
select x.*
into #modifier
from #Step1_Charges x
where Modifier1 = '50'

--****************************************************************************************************************************************************************************************************************************
insert into #Step1_Charges
select *
from #modifier;

--***********************************************************************************************************************************************************************************************************************************************************************************************************
WITH
	CTE
	AS
	(
		SELECT M1.[HCPCS], M1.[MOD], M1.[StartDate], M1.[EndDate], M1.[RATE]
		FROM [Analytics].[dbo].[MedicareFeeSchedule_Locality_1] M1
		WHERE M1.StartDate <= (Select TOP 1
				x.ServiceDateFrom
			FROM #Step1_Charges as x
			WHERE x.ProcedureCode = M1.HCPCS)
			and M1.EndDate >= (Select TOP 1
				x.ServiceDateFrom
			FROM #Step1_Charges as x
			WHERE x.ProcedureCode = M1.HCPCS)
	)

Select distinct x.[EncounterID], [RevenueCode], [ProcedureCode], IIF(y.[ServiceDateFrom] < '2022-01-01', IIF(y.[ServiceDateFrom] < '2021-01-01', Grouper2.[Grouper], Grouper1.[Grouper]), Grouper3.[Grouper]) as [ASC_Group], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]
	, AGE

	, [Fee_Schedule] = CASE
	WHEN x.[ProcedureCode] IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2022]) and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN IIF(cbp_crn_2022.[RATE] is null, 0, Round(cbp_crn_2022.[RATE] * 3.25, 2))	* Quantity 
	WHEN x.[ProcedureCode] IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2023]) and (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-31')	THEN IIF(cbp_crn_2023.[RATE] is null, 0, Round(cbp_crn_2023.[RATE] * 3.25, 2))	* Quantity 
	WHEN x.[ProcedureCode] IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2023]) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31')	THEN IIF(cbp_crn_2023.[RATE] is null, 0, Round(cbp_crn_2023.[RATE] * 3.30, 2))	* Quantity
	WHEN x.[ProcedureCode] IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2024]) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31')	THEN IIF(cbp_crn_2024.[RATE] is null, 0, Round(cbp_crn_2024.[RATE] * 3.75, 2))	* Quantity
	WHEN x.[ProcedureCode] IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2025]) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31')	THEN IIF(cbp_crn_2025.[RATE] is null, 0, Round(cbp_crn_2025.[RATE] * 3.99, 2))	* Quantity
	ELSE 0
	END

	
	, [Mammography_NoReduction] = CASE
	WHEN (M1.[MULT PROC] NOT IN ('4') and M1.[BILATSURG] NOT IN ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2023-03-23' AND '2023-10-31')	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 8.69, 2)), Round(F3.[RATE] * [Quantity] * 8.69, 2))  
	WHEN (M1.[MULT PROC] NOT IN ('4') and M1.[BILATSURG] NOT IN ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2023-11-01' AND '2023-12-31')	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 10.14, 2)), Round(F3.[RATE] * [Quantity] * 10.14, 2)) 
	WHEN (M1.[MULT PROC] NOT IN ('4') and M1.[BILATSURG] NOT IN ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2024-01-01' AND '2024-03-31')	THEN IIF(F3.[RATE] is null or F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.77, 2)) , Round(F3.[RATE] * [Quantity] * 9.77, 2)) 
	WHEN (M1.[MULT PROC] NOT IN ('4') and M1.[BILATSURG] NOT IN ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2024-01-01' AND '2024-11-30')	THEN IIF(F3.[RATE] is null or F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.37, 2)) , Round(F3.[RATE] * [Quantity] * 9.37, 2)) 
	WHEN (M1.[MULT PROC] NOT IN ('4') and M1.[BILATSURG] NOT IN ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2024-12-01' AND '2024-12-31')	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.22, 2)), Round(F3.[RATE] * [Quantity] * 9.22, 2)) 	
	WHEN (M1.[MULT PROC] NOT IN ('4') and M1.[BILATSURG] NOT IN ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2025-01-01' AND '2025-12-31')	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.50, 2)), Round(F3.[RATE] * [Quantity] * 9.50, 2)) 		ELSE 0
	END

	, [Mammography_Reduction] = CASE
	WHEN (M1.[MULT PROC] IN ('4') or M1.[BILATSURG] in ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2023-03-23' AND '2023-10-31') 	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 8.69, 2)), Round(F3.[RATE] * [Quantity] * 8.69, 2)) 
	WHEN (M1.[MULT PROC] IN ('4') or M1.[BILATSURG] in ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2023-11-01' AND '2023-12-31')	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 10.14, 2)), Round(F3.[RATE] * [Quantity] * 10.14, 2))  
	WHEN (M1.[MULT PROC] IN ('4') or M1.[BILATSURG] in ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2024-01-01' AND '2024-03-31')	THEN IIF(F3.[RATE] is null or F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.77, 2)) , Round(F3.[RATE] * [Quantity] * 9.77, 2))   
	WHEN (M1.[MULT PROC] IN ('4') or M1.[BILATSURG] in ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2024-01-01' AND '2024-11-30')	THEN IIF(F3.[RATE] is null or F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.37, 2)) , Round(F3.[RATE] * [Quantity] * 9.37, 2))  
	WHEN (M1.[MULT PROC] IN ('4') or M1.[BILATSURG] in ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2024-12-01' AND '2024-12-31')	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.22, 2)), Round(F3.[RATE] * [Quantity] * 9.22, 2)) 
	WHEN (M1.[MULT PROC] IN ('4') or M1.[BILATSURG] in ('1')) AND x.ProcedureCode IN ('77067','77063') and (y.[ServiceDateFrom] between '2025-01-01' AND '2025-12-31')	THEN IIF(F3.[RATE] IS NULL OR F3.[RATE] = 0,  IIF(F2.[RATE] IS NULL OR F2.[RATE]=0 , 0, Round(F2.[RATE] * [Quantity] * 9.50, 2)), Round(F3.[RATE] * [Quantity] * 9.50, 2)) 	ELSE 0
	END


	, [OP_Default] = CASE 
	WHEN x.[ProcedureCode] NOT IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2022]) and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN Round(x.[Amount] * 0.82, 2)	
	WHEN x.[ProcedureCode] NOT IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2022]) and (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-31')	THEN Round(x.[Amount] * 0.82, 2)	
	WHEN x.[ProcedureCode] NOT IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2022]) and (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06')	THEN Round(x.[Amount] * 0.82, 2)
	WHEN x.[ProcedureCode] NOT IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2023]) and (y.[ServiceDateFrom] between '2023-06-07' and '2023-12-31')	THEN Round(x.[Amount] * 0.82, 2)
	WHEN x.[ProcedureCode] NOT IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2024]) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31')	THEN Round(x.[Amount] * 0.82, 2)
	WHEN x.[ProcedureCode] NOT IN (SELECT [CPT4]
		FROM [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2025]) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31')	THEN Round(x.[Amount] * 0.82, 2)
	ELSE 0
	END

	
	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') THEN 1801
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN 1916	
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') THEN 2041
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') THEN 2159	
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') THEN 2904	
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2023-06-07' and '2023-12-31') THEN 2825	
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN 3176	
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') THEN 3047
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') THEN 2998
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') THEN 3088
	ELSE 0
	END



	, [AS] = CASE 
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '1' THEN  7658
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '2' THEN  9290
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '3' THEN 10080
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '4' THEN 10702
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '5' THEN 11109
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '6' THEN 12008
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '7' THEN 12060
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '8' THEN 12149
	WHEN (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') and RevenueCode IN ('360','361','362','367','369','391','480','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2020]) and Grouper1.[Grouper] =  '9' THEN 11998
		
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '01' THEN  8347
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '02' THEN 10126
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '03' THEN 10987
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '04' THEN 11665
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '05' THEN 12109
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '06' THEN 13089
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '07' THEN 13146
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '08' THEN 13242
	WHEN (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBC_Grouper_2021]) and Grouper2.[Grouper] = '09' THEN 13078
	
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '1' THEN  8889
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '2' THEN 10784
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '3' THEN 11701
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '4' THEN 12423
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '5' THEN 12896
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '6' THEN 13940
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '7' THEN 14000
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '8' THEN 14103
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and ProcedureCode IN (SELECT [CPT]
		FROM [Analytics].[dbo].[Empire_BCBS_Grouper_2022]) and Grouper3.[Grouper] =  '9' THEN 13928
	
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '01' THEN  9403
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '02' THEN 11407 
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '03' THEN 12377
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '04' THEN 13141
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '05' THEN 13641
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '06' THEN 14746
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '07' THEN 14809
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '08' THEN 14918
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '09' THEN 14733
	
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '01' THEN  9829
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '02' THEN 11924
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '03' THEN 12938
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '04' THEN 13736
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '05' THEN 14259
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '06' THEN 15414
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '07' THEN 15480
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '08' THEN 15594
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-06-06') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '09' THEN 15400

	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '01' THEN  9945
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '02' THEN 12066  
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '03' THEN 13092
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '04' THEN 13899
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '05' THEN 14429
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '06' THEN 15597
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '07' THEN 15664
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '08' THEN 15779
	WHEN (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '09' THEN 15583
	

	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '01' THEN 11610
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '02' THEN 14085  
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '03' THEN 15283
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '04' THEN 16226
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '05' THEN 16844
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '06' THEN 18208
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '07' THEN 18286
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '08' THEN 18421
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] =  '09' THEN 18192

	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '01' THEN 11183
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '02' THEN 13567  
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '03' THEN 14721
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '04' THEN 15629
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '05' THEN 16223
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '06' THEN 17536
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '07' THEN 17613
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '08' THEN 17742
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '09' THEN 17522
	
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '01' THEN 10727
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '02' THEN 13013  
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '03' THEN 14120
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '04' THEN 14991
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '05' THEN 15561
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '06' THEN 16820
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '07' THEN 16894
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '08' THEN 17018
	WHEN (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '09' THEN 16806

	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '01' THEN 10555
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '02' THEN 12804
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '03' THEN 13893
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '04' THEN 14751
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '05' THEN 15311
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '06' THEN 16550
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '07' THEN 16623
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '08' THEN 16745
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] =  '09' THEN 16537

	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '01' THEN 10872
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '02' THEN 13188
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '03' THEN 14310
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '04' THEN 15194
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '05' THEN 15770
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '06' THEN 17047
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '07' THEN 17122
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '08' THEN 17247
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER] =  '09' THEN 17033

	ELSE 0
	END


	, [AS_Default] = CASE
	WHEN (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper3.[Grouper] IS NULL THEN IIF([Amount] is null, 0, Round([Amount] * 0.71, 2))
	WHEN (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-22') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] IS NULL THEN IIF([Amount] is null, 0, Round([Amount] * 0.741, 2))
	WHEN (y.[ServiceDateFrom] between '2023-03-23' and '2023-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] IS NULL THEN IIF(R1.[RATE] is null or R1.[RATE] = 0, 0, Round(R1.[RATE] * 8.69, 2))
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] IS NULL THEN IIF(r.[RATE] is null or r.[RATE] = 0, 0, Round(r.[RATE] * 10.14, 2)) 
	WHEN (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper4.[Grouper] IS NULL THEN IIF(r.[RATE] is null or r.[RATE] = 0, 0, Round(r.[RATE] * 10.14, 2))
	WHEN (y.[ServiceDateFrom] between '2024-01-01' and '2024-11-30') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] IS NULL THEN IIF(r.[RATE] is null or r.[RATE] = 0, 0, Round(r.[RATE] * 9.77, 2)) 
	WHEN (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and Grouper5.[ASC GROUP] IS NULL THEN IIF(r.[RATE] is null or r.[RATE] = 0, 0, Round(r.[RATE] * 9.22, 2)) 
	WHEN (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') and RevenueCode IN ('360','361','362','367','369','391','481','490','499','700','709','720','721','722','723','724','729','750','759','760','761','769') and G.[GROUPER]          IS NULL THEN IIF(r.[RATE] is null or r.[RATE] = 0, 0, Round(r.[RATE] * 9.50, 2)) 
	ELSE 0
	END

	
	, [Cardiac_Cath] = CASE
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') THEN 18711	
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN 28066	
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') THEN 29891
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2023-01-01' and '2023-06-06') THEN 31619
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') THEN 31470
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') THEN 36738
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN 35385
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') THEN 33940
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') THEN 33396
	WHEN [ProcedureCode] IN ('93501','93503','93505','93508','93510','93511','93514','93524','93526','93527','93528','93529','93530','93531','93532','93533','93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93563','93564','93565','93566','93567','93568','93580','93581','93582','93583','33221','33227','33228','33229','33230','33231','33262','33263','33264','0281T','G0448') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') THEN 34398
	ELSE 0
	END

	
	, [PTCA] = CASE
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') THEN 66075
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN 70039	
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') THEN 74592
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2023-01-01' and '2023-06-06') THEN 78903	
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') THEN 78533	
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') THEN 91679
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN 88302
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN 88302
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') THEN 84698
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') THEN 83339
	WHEN [ProcedureCode] IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92980','92981','92982','92984','92986','92987','92995','92996','92997','92998','C9600','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','G0290','G0291') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') THEN 85839
	ELSE 0
	END 


	, [EPS] = CASE
	WHEN ProcedureCode in ('93600','93602','93603','93609','93610','93612','93613','93615','93616','93618','93619','93620','93621','93622','93623','93624','93631','93640','93641','93642','93650','93651','93652','93653','93654','93655','93656','93657') THEN Round(BillCharges * 0.74, 2)
	ELSE 0
	END



	, [Lithotripsy] = CASE
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') THEN 17306
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN 18344
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') THEN 19536
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2023-01-01' and '2023-06-06') THEN 20665	
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') THEN 20568
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') THEN 24011
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN 23127
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') THEN 22183
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') THEN 21827
	WHEN RevenueCode in ('790','799') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') THEN 22482
	ELSE 0
	END



	, [Gamma_Knife] = CASE
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') THEN 134943
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN 143040		
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') THEN 152337
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2023-01-01' and '2023-06-06') THEN 161142	
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') THEN 160386	
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') THEN 187234	
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN 180338
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') THEN 172976	
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') THEN 170201	
	WHEN ProcedureCode IN ('61793','61796','61797','61798','61799','63620','63621') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') THEN 175307	
	ELSE 0
	END


	, [Implants] = CASE
	WHEN RevenueCode in ('275','278') AND x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') THEN IIF([Amount] is null, 0, Round([Amount] * 0.36, 2))
	ELSE 0
	END



	, [Blood] = CASE
	WHEN RevenueCode in ('380','381','382','383','384','385','386','387','388','389') THEN IIF([Amount] is null, 0, Round([Amount] * 1.00, 2))
	ELSE 0
	END



	, [Drugs] = CASE 
	WHEN RevenueCode IN ('631','632','633','634','635','636') THEN IIF(ASP.PaymentLimit is null, Round(Amount * 0.82, 2), Round(ASP.Paymentlimit * Quantity, 2))	
	ELSE 0
	END


	, [Chemotherapy] = CASE
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2020-01-01' and '2020-12-31') THEN 1943.590863	
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN 2060.206315	
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31') THEN 2194.000000
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2023-01-01' and '2023-06-06') THEN 2320.8132	
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2023-06-07' and '2023-10-31') THEN 2309.91736338028
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2023-11-01' and '2023-12-31') THEN 2696.70
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN 2597
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2024-04-01' and '2024-11-30') THEN 2491
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2024-12-01' and '2024-12-31') THEN 2451
	WHEN (RevenueCode IN ('331','332','335') or (RevenueCode IN ('280','289','940') and ProcedureCode IN ('96401','96402','96405','96406','96409','96410','96411','96413','96415','96416','96417','96420','96422','96423','96425','96440','96445','96446','96450','96521','96522','96523','96542','96549','Q0083','Q0084','Q0085'))) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-10-31') THEN 2525
	ELSE 0
	END

	, [Lab] = CASE
	WHEN RevenueCode between '300' and '307' or RevenueCode between '310' and '314' or RevenueCode in ('309','319') then Round(isnull(L1.RATE, 0) * 0.70 * Quantity, 2)
	ELSE 0
	END

	, [Clinic] =0 

	, [Hyperbaric] = 0

	, [IV_Therapy] = CASE
	WHEN RevenueCode IN ('260','261','262','263','264','269','280','761','940') AND ProcedureCode IN ('90760','90761','90765','90766','90767','90768','90770','90771','90772','90773','90774','90775','90776','90779','96360','96361','96365','96366','96367','96368','96369','96370','96371','96372','96373','96374','96375','96376','C8957','Q0081') THEN Round(Amount * 0.74, 2)
	ELSE 0
	END

	, [IOP] = 0

	, [Partial_Hospitalization] = 0

	, [Observation] = 0

	, [Psych] = 0

	, [ECT] = 0

	, [Miscellaneous] = 0
																																																									 
	, [Home_Health] = 0

	, case
	WHEN (y.[ServiceDateFrom] between '2020-01-27' and '2020-03-31') and [dp].[Dx] like '%B97.29%'	THEN 1
	WHEN (y.[ServiceDateFrom] between '2020-04-01' and '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1
	WHEN (y.[ServiceDateFrom] > '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1 --and [dp].[Px] is not null
	ELSE 0
	END As [COVID]


Into #Step2
From #Step1_Charges as x


	LEFT JOIN [COL].[Data].[Demo]							as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px]							as dp on x.[EncounterID] = dp.[EncounterID] and x.[Sequence] = dp.[Sequence]

	LEFT JOIN [Analytics].[dbo].[Empire_BCBC_Grouper_2020]	as Grouper1 on Grouper1.[CPT] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[dbo].[Empire_BCBC_Grouper_2021]	as Grouper2 on Grouper2.[CPT] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[dbo].[Empire_BCBS_Grouper_2022]	as Grouper3 on Grouper3.[CPT] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[dbo].[Empire_BCBS_Grouper_2023]	as Grouper4 on Grouper4.[CPT] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[dbo].[Empire_BCBS_Grouper_2024]	as Grouper5 on Grouper5.[CPT4 CODE] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[FSG].[EMPIRE_BCBS_ASC_GROUPER]	as G on G.[CPT] = x.[ProcedureCode] AND (y.[ServiceDateFrom] BETWEEN G.[STARTDATE] AND G.[ENDDATE])


	LEFT JOIN [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2022]					as cbp_crn_2022 on cbp_crn_2022.[CPT4]	= x.[ProcedureCode] and (y.[ServiceDateFrom] between cbp_crn_2022.[StartDate] and cbp_crn_2022.[EndDate])
	LEFT JOIN [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2023]					as cbp_crn_2023 on cbp_crn_2023.[CPT4]	= x.[ProcedureCode] and IIF(x.[Modifier1] is null or x.[Modifier1] NOT IN ('CS'), '00', x.[Modifier1]) = cbp_crn_2023.[Modifier] and (y.[ServiceDateFrom] between cbp_crn_2023.[StartDate] and cbp_crn_2023.[EndDate])
	LEFT JOIN [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2024]					as cbp_crn_2024 on cbp_crn_2024.[CPT4]	= x.[ProcedureCode] and (y.[ServiceDateFrom] between cbp_crn_2024.[StartDate] and cbp_crn_2024.[EndDate])
	LEFT JOIN [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2025]					as cbp_crn_2025 on cbp_crn_2025.[CPT4]	= x.[ProcedureCode] and (y.[ServiceDateFrom] between cbp_crn_2025.[StartDate] and cbp_crn_2025.[EndDate])
	LEFT JOIN [Analytics].[MCR].[ASP]						as ASP on ASP.[CPT] = x.[ProcedureCode] and (y.[ServiceDateFrom] between ASP.[StartDate] and ASP.[EndDate])

	LEFT JOIN [Analytics].[dbo].[MAC-Covid-19-Testing]		as COV on COV.[CPT_Code] = x.[ProcedureCode]

	left join [COL].[FSG].[Medicare Fee Schedule (RBRVS) Locality 1-Cornell and Columbia (2024)]	as r on r.[CPT CODE] = x.[ProcedureCode]
	left join [Analytics].[dbo].[Medicare Lab Fee Schedule]	 AS L1 on x.[ProcedureCode] = L1.[HCPCS] and x.ServiceDateFrom between L1.[StartDate] AND L1.[EndDate] AND L1.[MOD] IS NULL
	LEFT JOIN [Analytics].[dbo].[MedicareFeeSchedule_Locality_1] 					AS M1 ON M1.HCPCS = X.ProcedureCode AND y.ServiceDateFrom BETWEEN M1.StartDate and M1.EndDate and M1.MOD = 'TC'
	LEFT JOIN [Analytics].[FSG].[MedicareFeeSchedule(RBRVS)_Locality1] 				AS F3 ON F3.[CPT_CODE] = x.[ProcedureCode] AND YEAR(F3.StartDate) = '2020'
	LEFT JOIN [Analytics].[FSG].[NYP_BCBS_OP_FeeSchedule_(2024)] 					AS F2 ON F2.[CPT] = x.[ProcedureCode] and F2.[Modifier] IS NULL

	LEFT JOIN (
		SELECT
		[HCPCS], [MOD], [StartDate], [EndDate], [Rate],
		ROW_NUMBER() OVER (PARTITION BY [HCPCS] order by CASE
							WHEN [Mod] = 'TC' THEN 1
							WHEN [Mod] IN ('26','53') THEN 2
							ELSE 3
							END) AS row_num
	FROM CTE
		) R1
	ON x.procedureCode = R1.[HCPCS] and R1.row_num = 1

ORDER BY [EncounterID], x.[Sequence]
--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate],  [RevenueCode], [ProcedureCode], [Amount], [OriginalPayment], [Sequence], [Quantity]
	, [OP_Default]  =IIF([Mammography_Reduction]=0 AND [Mammography_NoReduction]=0 AND [Lab]=0 AND [AS]=0 and [ER]=0 and [Cardiac_Cath]=0 and [PTCA]=0 and [Lithotripsy]=0 and [Gamma_Knife]=0 and [EPS]=0 and [IV_Therapy]=0 and [Fee_Schedule]=0 and [Drugs]=0 and [Clinic]=0 and [Blood] = 0, [OP_Default], 0)
		--AS
	, LEAD([AS]/1, 0, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS1
	, LEAD([AS]/2, 1, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS2
	, LEAD([AS]/4, 2, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS3
	, LEAD([AS]/4, 3, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS4
	, LEAD([AS]/4, 4, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS5
	, LEAD([AS]/4, 5, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS6
	, LEAD([AS]/4, 6, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS7
	, LEAD([AS]/4, 7, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS8
	, LEAD([AS]/4, 8, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS9
	, LEAD([AS]/4, 9, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS10


	, LEAD([Mammography_Reduction]/1, 0, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad1
	, LEAD([Mammography_Reduction]/2, 1, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad2
	, LEAD([Mammography_Reduction]/2, 2, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad3
	, LEAD([Mammography_Reduction]/2, 3, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad4
	, LEAD([Mammography_Reduction]/2, 4, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad5
	, LEAD([Mammography_Reduction]/2, 5, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad6
	, LEAD([Mammography_Reduction]/2, 6, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad7
	, LEAD([Mammography_Reduction]/2, 7, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad8
	, LEAD([Mammography_Reduction]/2, 8, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad9
	, LEAD([Mammography_Reduction]/2, 9, 0) over (partition by [EncounterID] order by [Mammography_Reduction] desc) AS Rad10

	, [Mammography_NoReduction]
	, [Fee_Schedule]		=IIF([Mammography_Reduction]!=0 or [Mammography_NoReduction]!=0 or [Drugs]!=0 or [Lab]!=0,0,[Fee_Schedule])
	, [ER]
	, [AS_Default] = IIF([AS]=0 and [Cardiac_Cath]=0 and [PTCA]=0 and [EPS]=0 and [Lithotripsy]=0 and [Gamma_Knife]=0, [AS_Default], 0)
	, [Cardiac_Cath]
	, [PTCA]
	, [EPS]
	, [Lithotripsy]
	, [Gamma_Knife]
	, [Implants]
	, [Blood]
	, [Drugs]			=IIF( (modifier1 not in ('FB','SL') or Modifier1 IS NULL), [Drugs], 0)
	, [Chemotherapy]
	, [Lab]
	, [Clinic] = IIF([Miscellaneous]=0, [Clinic], 0)
	, [Hyperbaric]
	, [IV_Therapy]
	, [IOP]
	, [Partial_Hospitalization]
	, [Observation]
	, [Psych]
	, [ECT]
	, [Miscellaneous]
	, [Home_Health]
	, [COVID]

Into #Step3
FROM #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]
	, SUM([Fee_Schedule])							as [Fee_Schedule]
	, SUM([OP_Default])								as [OP_Default]
	, MAX([ER])										as [ER]	
	, MAX(AS1)+MAX(AS2)+MAX(AS3)+MAX(AS4)+MAX(AS5)+MAX(AS6)+MAX(AS7)+MAX(AS8)+MAX(AS9)+MAX(AS10) as [AS]
	, SUM([AS_Default])								as [AS_Default]
	, MAX([Cardiac_Cath])							as [Cardiac_Cath]	
	, MAX([PTCA])									as [PTCA]
	, MAX([EPS])										as [EPS]
	, MAX([Lithotripsy])								as [Lithotripsy]
	, MAX([Gamma_Knife])								as [Gamma_Knife]
	, SUM([Implants])								as [Implants]
	, SUM([Blood])									as [Blood]
	, SUM([Drugs])									as [Drugs]	
	, MAX([Chemotherapy])							as [Chemotherapy]
	, SUM([Lab])										as [Lab]	
	, SUM([Clinic])									as [Clinic]
	, SUM([Hyperbaric])								as [Hyperbaric]	
	, SUM([IV_Therapy])								as [IV_Therapy]	
	, MAX([IOP])										as [IOP]
	, MAX([Partial_Hospitalization])					as [Partial_Hospitalization]
	, MAX([Observation])								as [Observation]
	, MAX([Psych])									as [Psych]
	, MAX([ECT])										as [ECT]
	, MAX([Home_Health])								as [Home_Health]
	, SUM([Miscellaneous])							as [Miscellaneous]
	, MAX([COVID])									as [COVID]
	, MAX(Rad1)+MAX(Rad2)+MAX(Rad3)+MAX(Rad4)+MAX(Rad5)+MAX(Rad6)+MAX(Rad7)+MAX(Rad8)+MAX(Rad9)+MAX(Rad10) as [Mammography_Reduction]
	, SUM([Mammography_NoReduction])       AS [Mammography_NoReduction]

INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, SUM([Fee_Schedule])					as [Fee_Schedule]
	, SUM([OP_Default])								as [OP_Default]
	, MAX([ER])								as [ER]	
	, MAX([AS])								as [AS]
	, SUM([AS_Default])						as [AS_Default]
	, SUM([Cardiac_Cath])					as [Cardiac_Cath]	
	, SUM([PTCA])							as [PTCA]
	, MAX([EPS])								as [EPS]
	, SUM([Lithotripsy])						as [Lithotripsy]
	, MAX([Gamma_Knife])						as [Gamma_Knife]
	, SUM([Implants])						as [Implants]
	, SUM([Blood])							as [Blood]
	, SUM([Drugs])							as [Drugs]
	, SUM([Chemotherapy])					as [Chemotherapy]
	, SUM([Lab])								as [Lab]	
	, SUM([Clinic])							as [Clinic]
	, SUM([Hyperbaric])						as [Hyperbaric]	
	, SUM([IV_Therapy])						as [IV_Therapy]
	, SUM([IOP])								as [IOP]
	, SUM([Partial_Hospitalization])			as [Partial_Hospitalization]
	, SUM([Observation])						as [Observation]
	, SUM([Psych])							as [Psych]	
	, SUM([ECT])								as [ECT]
	, SUM([Miscellaneous])					as [Miscellaneous]
	, SUM([Home_Health])						as [Home_Health]
	, MAX([COVID])							as [COVID]
	, SUM([Mammography_Reduction])			as [Mammography_Reduction]
	, SUM([Mammography_NoReduction])       AS [Mammography_NoReduction]
INTO #Step3_2
FROM #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
drop table if exists #implants
select Encounterid, [Implants]
into #implants
from #Step3_2
where Implants>0

--***********************************************************************************************************************************************************************************************************************************************************************************************************

Select [EncounterID]	
	, [Drugs]						= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [ER]=0, [Drugs], 0)										
	, [Implants]						= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [ER]=0 and [Fee_Schedule]= 0, [Implants], 0)			
	, [Blood]	
	


	, [Gamma_Knife]	
	, [PTCA]							= IIF([Gamma_Knife]=0, [PTCA], 0)
	, [Cardiac_Cath]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [EPS]=0, [Cardiac_Cath], 0)
	, [Lithotripsy]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0, [Lithotripsy], 0)
	, [EPS]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Lithotripsy]=0, [EPS], 0)	
	, [AS]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0, [AS], 0)
	, [AS_Default]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0, [AS_Default], 0)	
	, [Observation]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0, [Observation], 0)
	, [ECT]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0, [ECT], 0)
	, [Chemotherapy]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0, [Chemotherapy], 0)
	, [ER]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0, [ER], 0)
	, [Partial_Hospitalization]		= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0, [Partial_Hospitalization], 0)
	, [IOP]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0, [IOP], 0)
	, [Psych]						= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0, [Psych], 0)
	, [Miscellaneous]				= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0, [Miscellaneous], 0)
	, [Home_Health]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0, [Home_Health], 0)
	, [Lab]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0 and [IV_Therapy]=0, [Lab], 0)
	, [Mammography_NoReduction]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0 and [IV_Therapy]=0, [Mammography_NoReduction], 0)
	, [Mammography_Reduction]							= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0 and [IV_Therapy]=0, [Mammography_Reduction], 0)
	, [Clinic]						= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0, [Clinic], 0)
	, [Hyperbaric]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0, [Hyperbaric], 0)
	, [IV_Therapy]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0 , [IV_Therapy], 0)
	, [Fee_Schedule]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0 and [IV_Therapy]=0 , [Fee_Schedule], 0)
	
	, [OP_Default]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Lithotripsy]=0 and [EPS]=0 and [AS]=0 and [AS_Default]=0 and [Observation]=0 and [ECT]=0 and [Chemotherapy]=0 and [ER]=0 and [Partial_Hospitalization]=0 and [IOP]=0 and [Psych]=0, [OP_Default], 0)
	
	
	, [COVID]


INTO #Step4
FROM #Step3_2
--***********************************************************************************************************************************************************************************************************************************************************************************************************
update  s
	set s.[Implants]= i.implants
	from #Step4 s
	inner join #implants i on i.EncounterID = s.encounterid
	where s.[AS] > 0

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (post-LEAD slot computation, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
--           #Step2 joined for BillCharges (required for EPS payment formula).
--
-- MAX CATEGORIES (one winner per encounter):
--   ER, EPS, Gamma_Knife
--
-- HYBRID CATEGORIES (MAX per ServiceDate in AGGREGATE_DATE, SUM in AGGREGATE_ENC;
--   one winner per EncounterID+ServiceDate):
--   Cardiac_Cath, PTCA, Lithotripsy, Chemotherapy, IOP,
--   Partial_Hospitalization, Observation, Psych, ECT, Home_Health
--
-- SUM CATEGORIES (all matching lines pay):
--   Fee_Schedule, OP_Default, AS_Default, Implants, Blood, Drugs,
--   Lab, Clinic, Hyperbaric, IV_Therapy, Miscellaneous, Mammography_NoReduction
--
-- WINDOW_REDUCTION CATEGORIES (slot-based payment via LEAD pivot):
--   AS           : slots AS1-AS10  (PARTITION BY EncounterID)
--   Mammography_Reduction : slots Rad1-Rad10 (PARTITION BY EncounterID)
--
-- INDICATOR_FLAG CATEGORIES (binary 0/1, $0 LinePayment):
--   COVID
--
-- SUPPRESSION HIERARCHY (tier 1 = highest priority, from #Step4):
--   1. Gamma_Knife
--   2. PTCA           (suppressed if Gamma_Knife != 0)
--   3. Cardiac_Cath   (suppressed if Gamma_Knife OR PTCA OR EPS != 0)
--   4. Lithotripsy    (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath != 0)
--   5. EPS            (suppressed if Gamma_Knife OR PTCA OR Lithotripsy != 0)
--   6. AS             (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR Lithotripsy OR EPS != 0)
--   7. AS_Default     (suppressed if AS or any above != 0)
--   8. Observation    (suppressed if AS_Default or any above != 0)
--   9. ECT            (suppressed if AS_Default or any above != 0)
--  10. Chemotherapy   (suppressed if Observation OR ECT or any above != 0)
--  11. ER             (suppressed if Chemotherapy or any above != 0)
--  12. Partial_Hospitalization (suppressed if ER or any above != 0)
--  13. IOP            (suppressed if Partial_Hospitalization or any above != 0)
--  14. Psych          (suppressed if IOP or any above != 0)
--  15. Miscellaneous  (suppressed if Psych or any above != 0)
--  16. Home_Health    (suppressed if Psych or any above != 0)
--  17. Lab            (suppressed if IV_Therapy or any above != 0)
--  18. Mammography_NoReduction / Mammography_Reduction (suppressed if Lab or above != 0)
--  19. Clinic / Hyperbaric / IV_Therapy (suppressed if Psych or any above != 0)
--  20. Fee_Schedule   (suppressed if IV_Therapy or many above != 0)
--  21. OP_Default     (suppressed if most named categories != 0)
--  Special: Drugs/Implants have their own IIF conditions in #Step4.
--           Blood is not explicitly suppressed by the hierarchy in #Step4.
--=======================================================================

-- BLOCK 1: #bRanked
-- One ROW_NUMBER() per MAX category, HYBRID category, WINDOW_REDUCTION category,
-- and INDICATOR_FLAG category.
-- Count check: 3 MAX + 10 HYBRID + 2 WINDOW_REDUCTION + 1 INDICATOR_FLAG = 16 ROW_NUMBER() calls.
-- NOTE: #Step3 has an explicit narrow column list (no RevenueCode, ProcedureCode, Sequence,
-- Amount, BillCharges, Quantity). These are retrieved via LEFT JOIN to #Step2 in #LineBreakdown.
-- #Step3 DOES contain all LEAD slot columns (AS1-AS10, Rad1-Rad10) and all pricing columns.
SELECT
    b.*
    -- MAX categories: PARTITION BY EncounterID
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]         DESC, b.[EncounterID] ASC) AS rn_ER
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[EPS]        DESC, b.[EncounterID] ASC) AS rn_EPS
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife] DESC, b.[EncounterID] ASC) AS rn_Gamma_Knife
    -- HYBRID categories: PARTITION BY EncounterID, ServiceDate
    -- One winner per encounter per service date.
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Cardiac_Cath] DESC, b.[EncounterID] ASC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[PTCA]         DESC, b.[EncounterID] ASC) AS rn_PTCA
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Lithotripsy]  DESC, b.[EncounterID] ASC) AS rn_Lithotripsy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Chemotherapy] DESC, b.[EncounterID] ASC) AS rn_Chemotherapy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[IOP]          DESC, b.[EncounterID] ASC) AS rn_IOP
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Partial_Hospitalization] DESC, b.[EncounterID] ASC) AS rn_Partial_Hospitalization
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Observation]  DESC, b.[EncounterID] ASC) AS rn_Observation
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Psych]        DESC, b.[EncounterID] ASC) AS rn_Psych
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[ECT]          DESC, b.[EncounterID] ASC) AS rn_ECT
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Home_Health]  DESC, b.[EncounterID] ASC) AS rn_Home_Health
    -- WINDOW_REDUCTION categories: PARTITION BY EncounterID (lead_partition_by = EncounterID_only)
    -- ORDER BY the SUM of ALL slot columns for each category.
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY (ISNULL(b.AS1,0)+ISNULL(b.AS2,0)+ISNULL(b.AS3,0)+ISNULL(b.AS4,0)+ISNULL(b.AS5,0)
                   +ISNULL(b.AS6,0)+ISNULL(b.AS7,0)+ISNULL(b.AS8,0)+ISNULL(b.AS9,0)+ISNULL(b.AS10,0)) DESC
                  , b.[EncounterID] ASC) AS rn_AS
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY (ISNULL(b.Rad1,0)+ISNULL(b.Rad2,0)+ISNULL(b.Rad3,0)+ISNULL(b.Rad4,0)+ISNULL(b.Rad5,0)
                   +ISNULL(b.Rad6,0)+ISNULL(b.Rad7,0)+ISNULL(b.Rad8,0)+ISNULL(b.Rad9,0)+ISNULL(b.Rad10,0)) DESC
                  , b.[EncounterID] ASC) AS rn_Mammography_Reduction
    -- INDICATOR_FLAG category: PARTITION BY EncounterID (same as MAX), $0 LinePayment
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]       DESC, b.[EncounterID] ASC) AS rn_COVID
INTO #bRanked
FROM #Step3 b;

-- BLOCK 2: #bSlots
-- Extracts slot values from the rank-1 row for each WINDOW_REDUCTION category per encounter.
-- bslots_group_by = EncounterID_only for both AS and Mammography_Reduction.
-- Uses GROUP BY + MAX(CASE...) pattern so both window categories are handled in one pass.
SELECT
    [EncounterID]
    -- AS slots: captured from the rn_AS = 1 row
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS1,  0) ELSE 0 END) AS AS1
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS2,  0) ELSE 0 END) AS AS2
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS3,  0) ELSE 0 END) AS AS3
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS4,  0) ELSE 0 END) AS AS4
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS5,  0) ELSE 0 END) AS AS5
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS6,  0) ELSE 0 END) AS AS6
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS7,  0) ELSE 0 END) AS AS7
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS8,  0) ELSE 0 END) AS AS8
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS9,  0) ELSE 0 END) AS AS9
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL(AS10, 0) ELSE 0 END) AS AS10
    -- Mammography_Reduction slots: captured from the rn_Mammography_Reduction = 1 row
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad1,  0) ELSE 0 END) AS Rad1
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad2,  0) ELSE 0 END) AS Rad2
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad3,  0) ELSE 0 END) AS Rad3
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad4,  0) ELSE 0 END) AS Rad4
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad5,  0) ELSE 0 END) AS Rad5
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad6,  0) ELSE 0 END) AS Rad6
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad7,  0) ELSE 0 END) AS Rad7
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad8,  0) ELSE 0 END) AS Rad8
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad9,  0) ELSE 0 END) AS Rad9
    , MAX(CASE WHEN rn_Mammography_Reduction = 1 THEN ISNULL(Rad10, 0) ELSE 0 END) AS Rad10
INTO #bSlots
FROM #bRanked
GROUP BY [EncounterID];

-- BLOCK 3: #LineBreakdown
-- Main line-level breakdown output. One row per charge line.
-- #Step3 does not contain RevenueCode, ProcedureCode, Sequence, Amount,
-- BillCharges, or Quantity. These are recovered via LEFT JOIN to #Step2
-- on EncounterID + ServiceDate (the narrowest join key available in #Step3).
-- NOTE: #Step2 may have multiple rows per EncounterID+ServiceDate (one per
-- charge line). DISTINCT is applied on the outer SELECT to collapse duplicates
-- that arise because #Step3 itself has one row per line before the aggregation
-- steps, but the LEAD columns in #Step3 are computed per-EncounterID ordering.
-- The join to #Step2 src uses EncounterID alone for BillCharges because
-- BillCharges is only needed for EPS (which is already computed at line level
-- in #Step2 as Round(BillCharges * 0.74,2) and that computed value is NOT
-- carried into #Step3). EPS in #Step3 contains the already-computed dollar
-- amount from #Step2, so no BillCharges recalculation is needed.
-- BillCharges is included as a display column only via NULL placeholder.
SELECT DISTINCT
    b.[EncounterID]
    -- Sequence, ProcedureCode, RevenueCode, Amount, BillCharges, Quantity
    -- are NOT present in #Step3 (explicit narrow column list).
    -- They are recovered from #Step2 via LEFT JOIN on EncounterID+ServiceDate.
    -- Because one ServiceDate may have multiple lines, we use src columns
    -- directly � DISTINCT on the outer SELECT handles duplicates.
    , b.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                          AS [BilledAmount]
    , b.[Quantity]
    , b.[BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Condition structure per category type:
    --   MAX:    s4.[CAT]!=0 AND b.[CAT]>0 => IIF(rn=1, name, name_Non_Winner)
    --   HYBRID: s4.[CAT]!=0 AND b.[CAT]>0 => IIF(rn=1, name, name_Non_Winner)
    --           (rn partitioned by EncounterID+ServiceDate, so each date's
    --            winner gets the plain label, rn>1 on same date = Non_Winner)
    --   SUM:    s4.[CAT]!=0 AND b.[CAT]>0 => flat label (no rank check)
    --   WINDOW_REDUCTION: check that s4 category survived AND this line has
    --            any slot sum > 0, then rank-based label.
    --   INDICATOR_FLAG: after OP_Default and Suppressed_By_Hierarchy,
    --            IIF(rn=1, name, name_Non_Winner), $0 LinePayment.
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- ---- TIER 1: Gamma_Knife (MAX) ----
        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN IIF(b.rn_Gamma_Knife = 1, 'Gamma_Knife', 'Gamma_Knife_Non_Winner')

        -- ---- TIER 2: PTCA (HYBRID) ----
        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN IIF(b.rn_PTCA = 1, 'PTCA', 'PTCA_Non_Winner')

        -- ---- TIER 3: Cardiac_Cath (HYBRID) ----
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- ---- TIER 4: Lithotripsy (HYBRID) ----
        WHEN s4.[Lithotripsy] != 0
         AND b.[Lithotripsy] > 0
            THEN IIF(b.rn_Lithotripsy = 1, 'Lithotripsy', 'Lithotripsy_Non_Winner')

        -- ---- TIER 5: EPS (MAX) ----
        WHEN s4.[EPS] != 0
         AND b.[EPS] > 0
            THEN IIF(b.rn_EPS = 1, 'EPS', 'EPS_Non_Winner')

        -- ---- TIER 6: AS (WINDOW_REDUCTION via AS1-AS10 slots) ----
        WHEN s4.[AS] != 0
         AND (  ISNULL(b.AS1,0)+ISNULL(b.AS2,0)+ISNULL(b.AS3,0)+ISNULL(b.AS4,0)+ISNULL(b.AS5,0)
              + ISNULL(b.AS6,0)+ISNULL(b.AS7,0)+ISNULL(b.AS8,0)+ISNULL(b.AS9,0)+ISNULL(b.AS10,0)) > 0
            THEN CASE
                    WHEN b.rn_AS BETWEEN 1 AND 10 THEN 'AS_Ambulatory_Surgery'
                    ELSE 'AS_Ambulatory_Surgery_Beyond_Max'
                 END

        -- ---- TIER 7: AS_Default (SUM) ----
        WHEN s4.[AS_Default] != 0
         AND b.[AS_Default] > 0
            THEN 'AS_Default'

        -- ---- TIER 8: Observation (HYBRID) ----
        WHEN s4.[Observation] != 0
         AND b.[Observation] > 0
            THEN IIF(b.rn_Observation = 1, 'Observation', 'Observation_Non_Winner')

        -- ---- TIER 9: ECT (HYBRID) ----
        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN IIF(b.rn_ECT = 1, 'ECT', 'ECT_Non_Winner')

        -- ---- TIER 10: Chemotherapy (HYBRID) ----
        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN IIF(b.rn_Chemotherapy = 1, 'Chemotherapy', 'Chemotherapy_Non_Winner')

        -- ---- TIER 11: ER (MAX) ----
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- ---- TIER 12: Partial_Hospitalization (HYBRID) ----
        WHEN s4.[Partial_Hospitalization] != 0
         AND b.[Partial_Hospitalization] > 0
            THEN IIF(b.rn_Partial_Hospitalization = 1, 'Partial_Hospitalization', 'Partial_Hospitalization_Non_Winner')

        -- ---- TIER 13: IOP (HYBRID) ----
        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN IIF(b.rn_IOP = 1, 'IOP', 'IOP_Non_Winner')

        -- ---- TIER 14: Psych (HYBRID) ----
        WHEN s4.[Psych] != 0
         AND b.[Psych] > 0
            THEN IIF(b.rn_Psych = 1, 'Psych', 'Psych_Non_Winner')

        -- ---- TIER 15: Miscellaneous (SUM) ----
        WHEN s4.[Miscellaneous] != 0
         AND b.[Miscellaneous] > 0
            THEN 'Miscellaneous'

        -- ---- TIER 16: Home_Health (HYBRID) ----
        WHEN s4.[Home_Health] != 0
         AND b.[Home_Health] > 0
            THEN IIF(b.rn_Home_Health = 1, 'Home_Health', 'Home_Health_Non_Winner')

        -- ---- TIER 17: Lab (SUM) ----
        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Lab'

        -- ---- TIER 18: Mammography_Reduction (WINDOW_REDUCTION via Rad1-Rad10 slots) ----
        WHEN s4.[Mammography_Reduction] != 0
         AND (  ISNULL(b.Rad1,0)+ISNULL(b.Rad2,0)+ISNULL(b.Rad3,0)+ISNULL(b.Rad4,0)+ISNULL(b.Rad5,0)
              + ISNULL(b.Rad6,0)+ISNULL(b.Rad7,0)+ISNULL(b.Rad8,0)+ISNULL(b.Rad9,0)+ISNULL(b.Rad10,0)) > 0
            THEN CASE
                    WHEN b.rn_Mammography_Reduction BETWEEN 1 AND 10 THEN 'Mammography_Reduction'
                    ELSE 'Mammography_Reduction_Beyond_Max'
                 END

        -- ---- TIER 18b: Mammography_NoReduction (SUM) ----
        WHEN s4.[Mammography_NoReduction] != 0
         AND b.[Mammography_NoReduction] > 0
            THEN 'Mammography_NoReduction'

        -- ---- TIER 19: Clinic (SUM) ----
        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN 'Clinic'

        -- ---- TIER 20: Hyperbaric (SUM) ----
        WHEN s4.[Hyperbaric] != 0
         AND b.[Hyperbaric] > 0
            THEN 'Hyperbaric'

        -- ---- TIER 21: IV_Therapy (SUM) ----
        WHEN s4.[IV_Therapy] != 0
         AND b.[IV_Therapy] > 0
            THEN 'IV_Therapy'

        -- ---- TIER 22: Fee_Schedule (SUM) ----
        WHEN s4.[Fee_Schedule] != 0
         AND b.[Fee_Schedule] > 0
            THEN 'Fee_Schedule'

        -- ---- TIER 23: Drugs (SUM) ----
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- ---- TIER 24: Implants (SUM) ----
        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Implants'

        -- ---- TIER 25: Blood (SUM) ----
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- ---- TIER 26: OP_Default (SUM � catch-all) ----
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- ---- Suppressed: line matched a category but #Step4 hierarchy zeroed it ----
        WHEN (
              ISNULL(b.[ER],0)                        + ISNULL(b.[EPS],0)
            + ISNULL(b.[Gamma_Knife],0)
            + ISNULL(b.[Cardiac_Cath],0)              + ISNULL(b.[PTCA],0)
            + ISNULL(b.[Lithotripsy],0)
            + ISNULL(b.[AS_Default],0)
            + ISNULL(b.[Observation],0)               + ISNULL(b.[ECT],0)
            + ISNULL(b.[Chemotherapy],0)
            + ISNULL(b.[Partial_Hospitalization],0)   + ISNULL(b.[IOP],0)
            + ISNULL(b.[Psych],0)
            + ISNULL(b.[Miscellaneous],0)             + ISNULL(b.[Home_Health],0)
            + ISNULL(b.[Lab],0)
            + ISNULL(b.[Mammography_NoReduction],0)
            + ISNULL(b.[Clinic],0)                    + ISNULL(b.[Hyperbaric],0)
            + ISNULL(b.[IV_Therapy],0)
            + ISNULL(b.[Fee_Schedule],0)
            + ISNULL(b.[Drugs],0)                     + ISNULL(b.[Implants],0)
            + ISNULL(b.[Blood],0)
            + ISNULL(b.[OP_Default],0)
            + ISNULL(b.[COVID],0)
            + ISNULL(b.AS1,0) + ISNULL(b.AS2,0) + ISNULL(b.AS3,0)
            + ISNULL(b.AS4,0) + ISNULL(b.AS5,0) + ISNULL(b.AS6,0)
            + ISNULL(b.AS7,0) + ISNULL(b.AS8,0) + ISNULL(b.AS9,0) + ISNULL(b.AS10,0)
            + ISNULL(b.Rad1,0) + ISNULL(b.Rad2,0) + ISNULL(b.Rad3,0)
            + ISNULL(b.Rad4,0) + ISNULL(b.Rad5,0) + ISNULL(b.Rad6,0)
            + ISNULL(b.Rad7,0) + ISNULL(b.Rad8,0) + ISNULL(b.Rad9,0) + ISNULL(b.Rad10,0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- ---- INDICATOR_FLAG: COVID (binary 0/1, placed after dollar and suppressed categories) ----
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula for this line.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN 'Contracted flat rate per contract period (Gamma Knife CPT list: 61793/61796-61799/63620/63621)'

        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN 'Contracted flat rate per contract period (PTCA CPT list: 92920-92944/92980-92998/C9600-C9608/G0290/G0291)'

        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period (Cardiac Cath CPT list: 93451-93583/33221-33264/G0448)'

        WHEN s4.[Lithotripsy] != 0
         AND b.[Lithotripsy] > 0
            THEN 'Contracted flat rate per contract period (Lithotripsy Rev 790/799)'

        WHEN s4.[EPS] != 0
         AND b.[EPS] > 0
            THEN 'Pct of BillCharges: BillCharges x 74% (EPS CPT list: 93600-93657)'

        WHEN s4.[AS] != 0
         AND (  ISNULL(b.AS1,0)+ISNULL(b.AS2,0)+ISNULL(b.AS3,0)+ISNULL(b.AS4,0)+ISNULL(b.AS5,0)
              + ISNULL(b.AS6,0)+ISNULL(b.AS7,0)+ISNULL(b.AS8,0)+ISNULL(b.AS9,0)+ISNULL(b.AS10,0)) > 0
            THEN CASE
                    WHEN b.rn_AS = 1  THEN 'Contracted grouper-based flat rate � 1st AS procedure, full rate (Rev 36x/39x/48x/49x/70x/72x-75x)'
                    WHEN b.rn_AS = 2  THEN 'Contracted grouper-based flat rate / 2 � 2nd AS procedure reduction'
                    WHEN b.rn_AS BETWEEN 3 AND 10
                                      THEN 'Contracted grouper-based flat rate / 4 � 3rd+ AS procedure reduction'
                    ELSE 'Beyond 10th AS procedure in encounter � $0'
                 END

        WHEN s4.[AS_Default] != 0
         AND b.[AS_Default] > 0
            THEN 'AS Default pct of charges (Amount x 71%-82% depending on period; or RBRVS Rate x multiplier) � ASC Rev codes, no grouper match'

        WHEN s4.[Observation] != 0
         AND b.[Observation] > 0
            THEN 'Observation � $0 under current contract terms (placeholder column)'

        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN 'ECT � $0 under current contract terms (placeholder column)'

        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN 'Contracted per diem per contract period (Chemotherapy Rev 331/332/335 or Rev 280/289/940 + chemo CPTs)'

        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN 'Contracted flat rate per contract period (ER Rev 450/451/452/459)'

        WHEN s4.[Partial_Hospitalization] != 0
         AND b.[Partial_Hospitalization] > 0
            THEN 'Partial Hospitalization � $0 under current contract terms (placeholder column)'

        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN 'IOP � $0 under current contract terms (placeholder column)'

        WHEN s4.[Psych] != 0
         AND b.[Psych] > 0
            THEN 'Psych � $0 under current contract terms (placeholder column)'

        WHEN s4.[Miscellaneous] != 0
         AND b.[Miscellaneous] > 0
            THEN 'Miscellaneous � $0 under current contract terms (placeholder column)'

        WHEN s4.[Home_Health] != 0
         AND b.[Home_Health] > 0
            THEN 'Home Health � $0 under current contract terms (placeholder column)'

        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Medicare Lab Fee Schedule x 70% x Quantity (Rev 300-307/309-314/319)'

        WHEN s4.[Mammography_Reduction] != 0
         AND (  ISNULL(b.Rad1,0)+ISNULL(b.Rad2,0)+ISNULL(b.Rad3,0)+ISNULL(b.Rad4,0)+ISNULL(b.Rad5,0)
              + ISNULL(b.Rad6,0)+ISNULL(b.Rad7,0)+ISNULL(b.Rad8,0)+ISNULL(b.Rad9,0)+ISNULL(b.Rad10,0)) > 0
            THEN CASE
                    WHEN b.rn_Mammography_Reduction = 1  THEN 'RBRVS/FS Rate x period multiplier x Quantity � 1st mammography, full rate (MULT PROC=4 or BILATSURG=1, CPT 77067/77063)'
                    WHEN b.rn_Mammography_Reduction BETWEEN 2 AND 10
                                                         THEN 'RBRVS/FS Rate x period multiplier x Quantity / 2 � 2nd+ mammography, multiple procedure reduction (MULT PROC=4 or BILATSURG=1)'
                    ELSE 'Beyond 10th mammography procedure in encounter � $0'
                 END

        WHEN s4.[Mammography_NoReduction] != 0
         AND b.[Mammography_NoReduction] > 0
            THEN 'RBRVS/FS Rate x period multiplier x Quantity � No multiple-procedure reduction (mammography, no MULT PROC=4 / BILATSURG flag, CPT 77067/77063)'

        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN 'Clinic � $0 under current contract terms (placeholder column)'

        WHEN s4.[Hyperbaric] != 0
         AND b.[Hyperbaric] > 0
            THEN 'Hyperbaric � $0 under current contract terms (placeholder column)'

        WHEN s4.[IV_Therapy] != 0
         AND b.[IV_Therapy] > 0
            THEN 'Pct of charges: Amount x 74% (IV Therapy CPT list: 90760-90776/96360-96376 with Rev 260-264/269/280/761/940)'

        WHEN s4.[Fee_Schedule] != 0
         AND b.[Fee_Schedule] > 0
            THEN 'GHI CBP CRN Fee Schedule Rate x period multiplier x Quantity (CPT in fee schedule tables for applicable contract year)'

        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'ASP PaymentLimit x Quantity; fallback = Amount x 82% (Drugs Rev 631-636; excl Modifier FB/SL)'

        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Pct of charges: Amount x 36% (Implants Rev 275/278; excl device pass-through codes)'

        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Pct of charges: Amount x 100% (Blood Rev 380-389)'

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'Pct of charges: Amount x 82% � OP Default catch-all (CPT not in fee schedule for applicable year)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag � binary 0/1 value, no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pattern matched � $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:     IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    -- HYBRID:  IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)  [same as MAX]
    -- SUM:     IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- WINDOW_REDUCTION: slot-pivot from #bSlots keyed by EncounterID
    -- INDICATOR_FLAG: $0 � never add b.[COVID] to LinePayment
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1, ISNULL(b.[Gamma_Knife], 0), 0), 0)
        + IIF(s4.[EPS] != 0,
              IIF(b.rn_EPS = 1, ISNULL(b.[EPS], 0), 0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1, ISNULL(b.[ER], 0), 0), 0)
          -- HYBRID categories: IIF(rn=1) partitioned by EncounterID+ServiceDate
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1, ISNULL(b.[Cardiac_Cath], 0), 0), 0)
        + IIF(s4.[PTCA] != 0,
              IIF(b.rn_PTCA = 1, ISNULL(b.[PTCA], 0), 0), 0)
        + IIF(s4.[Lithotripsy] != 0,
              IIF(b.rn_Lithotripsy = 1, ISNULL(b.[Lithotripsy], 0), 0), 0)
        + IIF(s4.[Chemotherapy] != 0,
              IIF(b.rn_Chemotherapy = 1, ISNULL(b.[Chemotherapy], 0), 0), 0)
        + IIF(s4.[IOP] != 0,
              IIF(b.rn_IOP = 1, ISNULL(b.[IOP], 0), 0), 0)
        + IIF(s4.[Partial_Hospitalization] != 0,
              IIF(b.rn_Partial_Hospitalization = 1, ISNULL(b.[Partial_Hospitalization], 0), 0), 0)
        + IIF(s4.[Observation] != 0,
              IIF(b.rn_Observation = 1, ISNULL(b.[Observation], 0), 0), 0)
        + IIF(s4.[Psych] != 0,
              IIF(b.rn_Psych = 1, ISNULL(b.[Psych], 0), 0), 0)
        + IIF(s4.[ECT] != 0,
              IIF(b.rn_ECT = 1, ISNULL(b.[ECT], 0), 0), 0)
        + IIF(s4.[Home_Health] != 0,
              IIF(b.rn_Home_Health = 1, ISNULL(b.[Home_Health], 0), 0), 0)
          -- SUM categories
        + IIF(s4.[Fee_Schedule] != 0,       ISNULL(b.[Fee_Schedule], 0),       0)
        + IIF(s4.[OP_Default] != 0,         ISNULL(b.[OP_Default], 0),         0)
        + IIF(s4.[AS_Default] != 0,         ISNULL(b.[AS_Default], 0),         0)
        + IIF(s4.[Implants] != 0,           ISNULL(b.[Implants], 0),           0)
        + IIF(s4.[Blood] != 0,              ISNULL(b.[Blood], 0),              0)
        + IIF(s4.[Drugs] != 0,              ISNULL(b.[Drugs], 0),              0)
        + IIF(s4.[Lab] != 0,                ISNULL(b.[Lab], 0),                0)
        + IIF(s4.[Clinic] != 0,             ISNULL(b.[Clinic], 0),             0)
        + IIF(s4.[Hyperbaric] != 0,         ISNULL(b.[Hyperbaric], 0),         0)
        + IIF(s4.[IV_Therapy] != 0,         ISNULL(b.[IV_Therapy], 0),         0)
        + IIF(s4.[Miscellaneous] != 0,      ISNULL(b.[Miscellaneous], 0),      0)
        + IIF(s4.[Mammography_NoReduction] != 0, ISNULL(b.[Mammography_NoReduction], 0), 0)
          -- WINDOW_REDUCTION: AS � each row gets its own rank's slot value from #bSlots pivot
        + IIF(s4.[AS] != 0,
              CASE b.rn_AS
                WHEN 1  THEN ISNULL(rd.AS1,  0)
                WHEN 2  THEN ISNULL(rd.AS2,  0)
                WHEN 3  THEN ISNULL(rd.AS3,  0)
                WHEN 4  THEN ISNULL(rd.AS4,  0)
                WHEN 5  THEN ISNULL(rd.AS5,  0)
                WHEN 6  THEN ISNULL(rd.AS6,  0)
                WHEN 7  THEN ISNULL(rd.AS7,  0)
                WHEN 8  THEN ISNULL(rd.AS8,  0)
                WHEN 9  THEN ISNULL(rd.AS9,  0)
                WHEN 10 THEN ISNULL(rd.AS10, 0)
                ELSE 0
              END,
              0)
          -- WINDOW_REDUCTION: Mammography_Reduction � Rad slots from #bSlots pivot
        + IIF(s4.[Mammography_Reduction] != 0,
              CASE b.rn_Mammography_Reduction
                WHEN 1  THEN ISNULL(rd.Rad1,  0)
                WHEN 2  THEN ISNULL(rd.Rad2,  0)
                WHEN 3  THEN ISNULL(rd.Rad3,  0)
                WHEN 4  THEN ISNULL(rd.Rad4,  0)
                WHEN 5  THEN ISNULL(rd.Rad5,  0)
                WHEN 6  THEN ISNULL(rd.Rad6,  0)
                WHEN 7  THEN ISNULL(rd.Rad7,  0)
                WHEN 8  THEN ISNULL(rd.Rad8,  0)
                WHEN 9  THEN ISNULL(rd.Rad9,  0)
                WHEN 10 THEN ISNULL(rd.Rad10, 0)
                ELSE 0
              END,
              0)
          -- INDICATOR_FLAG: COVID � $0 contribution, never add b.[COVID] to LinePayment
      , 2)

    -- NCCI BUNDLED FLAG: no NCCI bundle step in this script � always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4  ON s4.[EncounterID]  = b.[EncounterID]
LEFT  JOIN #bSlots rd  ON rd.[EncounterID]  = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover line-level display columns not present in #Step3.
-- Join on EncounterID + ServiceDate (both present in #Step3/bRanked).
-- Sequence, ProcedureCode, RevenueCode, Amount are recovered here.
--LEFT  JOIN #Step2  src ON src.[EncounterID] = b.[EncounterID]
--                       AND src.[ServiceDate] = b.[ServiceDate]
ORDER BY b.[EncounterID], b.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	
	, [Drugs]	
	+[Implants]
	+[Blood]	
	+[Gamma_Knife]	
	+[PTCA]							
	+[Cardiac_Cath]					
	+[Lithotripsy]					
	+[AS]							
	+[AS_Default]					
	+[EPS]							
	+[Observation]					
	+[ECT]											
	+[Chemotherapy]					
	+[ER]							
	+[Partial_Hospitalization]		
	+[IOP]							
	+[Psych]						
	+[Miscellaneous]				
	+[Home_Health]					
	+[Lab]			
	+[Clinic]	
	+[Hyperbaric]
	+[IV_Therapy]
	+[Fee_Schedule]
	+[OP_Default]
	+[Mammography_Reduction]
	+[Mammography_NoReduction]
	as Price

INTO #Step5
FROM #Step4

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select
	x.*

	, y.[Price]
	, y.[Drugs]	
	, y.[Implants]
	, y.[Blood]	
	, y.[Gamma_Knife]	
	, y.[PTCA]							
	, y.[Cardiac_Cath]					
	, y.[Lithotripsy]					
	, y.[AS]							
	, y.[AS_Default]					
	, y.[EPS]							
	, y.[Observation]					
	, y.[ECT]													
	, y.[Chemotherapy]					
	, y.[ER]							
	, y.[Partial_Hospitalization]		
	, y.[IOP]							
	, y.[Psych]						
	, y.[Miscellaneous]				
	, y.[Home_Health]					
	, y.[Lab]	
	, y.[Clinic]
	, y.[Hyperbaric]
	, y.[IV_Therapy]			
	, y.[Fee_Schedule]
	, y.[OP_Default]
	, y.[COVID]
	, y.[Mammography_Reduction]
	, y.[Mammography_NoReduction]
	, z.[RevCode1]
	, z.[CPT1]
	, z.[RevCode2]
	, z.[CPT2]
	, z.[RevCode3]
	, z.[CPT3]
	, z.[RevCode4]
	, z.[CPT4]
	, z.[RevCode5]
	, z.[CPT5]
	, z.[RevCode6]
	, z.[CPT6]
	, z.[RevCode7]
	, z.[CPT7]
	, z.[RevCode8]
	, z.[CPT8]
	, z.[RevCode9]
	, z.[CPT9]
	, z.[RevCode10]
	, z.[CPT10]
	, z.[RevCode11]
	, z.[CPT11]
	, z.[RevCode12]
	, z.[CPT12]

Into #Step6
From [COL].[Data].[Demo] as x

	inner join #Step5 as y on x.[EncounterID] = y.[EncounterID]
	left join [COL].[Data].[Charges_With_CPT] as z on x.[EncounterID] = z.[EncounterID]

--***********************************************************************************************************************************************************************************************************************************************************************************************************	
SELECT
	x.[Hospital]
	, x.[HospitalCode]
	, x.[TypeOfBill]
	, x.[TypeOfBillNumeric]
	, x.[ID]
	, x.[EncounterID]
	, x.[PRS_ID]
	, x.[PatientLast]
	, x.[PatientFirst]
	, x.[PatientSex]
	, x.[PatientDOB]
	, x.[PaidDate]	
	, x.[ServiceDateFrom]
	, x.[ServiceDateTo]
	, DATEDIFF(DAY, x.[ServiceDateFrom], x.[ServiceDateTo]) AS [Length of Stay]	
	, x.[Contract]
	, x.[Plan]
	, x.[Payer01Code]
	, x.[Payer01Name]
	, x.[ServiceCode]
	, x.[ClaimCategory]
	, x.[ValueAmount1]
	, x.[ValueCode1]
	, x.[SubscriberID]
	, x.[BillCharges]
	, x.[Payer01Payment]
	, x.[Payer02Payment]
	, x.[PatientResponsibility]
	, x.[OriginalPayment]
	-- ,p.expected_payment_analyst
	  
	, Round([Price], 2) as ExpectedPrice
	, Round([Price] - (cast(x.[OriginalPayment] as float)), 2) as Diff
	, Round((cast(x.[OriginalPayment] as float)/NULLIF([BillCharges], 0)) * 100, 2) as [% paid]
	, DATEDIFF(DAY, x.[ServiceDateFrom], GETDATE()) - 365 as DaysLeft
	
	, IIF(ISNULL(x.[Drugs]						,0) > 0,      'Drugs - '							+ Cast(x.[Drugs]						as varchar) + ', ','')					
	+IIF(ISNULL(x.[Implants]					,0) > 0,      'Implants - '							+ Cast(x.[Implants]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Blood]						,0) > 0,      'Blood - '							+ Cast(x.[Blood]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Gamma_Knife]					,0) > 0,      'Gamma_Knife - '						+ Cast(x.[Gamma_Knife]					as varchar) + ', ','')
	+IIF(ISNULL(x.[PTCA]						,0) > 0,      'PTCA - '								+ Cast(x.[PTCA]							as varchar) + ', ','')
	+IIF(ISNULL(x.[Cardiac_Cath]				,0) > 0,      'Cardiac_Cath - '						+ Cast(x.[Cardiac_Cath]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Lithotripsy]					,0) > 0,      'Lithotripsy - '						+ Cast(x.[Lithotripsy]					as varchar) + ', ','')
	+IIF(ISNULL(x.[AS]							,0) > 0,      'AS - '								+ Cast(x.[AS]							as varchar) + ', ','')
	+IIF(ISNULL(x.[AS_Default]					,0) > 0,      'AS_Default - '						+ Cast(x.[AS_Default]					as varchar) + ', ','')
	+IIF(ISNULL(x.[EPS]							,0) > 0,      'EPS - '								+ Cast(x.[EPS]							as varchar) + ', ','')
	+IIF(ISNULL(x.[Observation]					,0) > 0,      'Observation - '						+ Cast(x.[Observation]					as varchar) + ', ','')
	+IIF(ISNULL(x.[ECT]							,0) > 0,      'ECT - '								+ Cast(x.[ECT]							as varchar) + ', ','')
	+IIF(ISNULL(x.[Chemotherapy]				,0) > 0,      'Chemotherapy - '						+ Cast(x.[Chemotherapy]					as varchar) + ', ','')
	+IIF(ISNULL(x.[ER]							,0) > 0,      'ER - '								+ Cast(x.[ER]							as varchar) + ', ','')
	+IIF(ISNULL(x.[IOP]							,0) > 0,      'IOP - '								+ Cast(x.[IOP]							as varchar) + ', ','')
	+IIF(ISNULL(x.[Psych]						,0) > 0,      'Psych - '							+ Cast(x.[Psych]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Miscellaneous]				,0) > 0,      'Miscellaneous - '					+ Cast(x.[Miscellaneous]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Home_Health]					,0) > 0,      'Home_Health - '						+ Cast(x.[Home_Health]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Lab]							,0) > 0,      'Lab - '								+ Cast(x.[Lab]							as varchar) + ', ','')
	+IIF(ISNULL(x.[Clinic]						,0) > 0,      'Clinic - '							+ Cast(x.[Clinic]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Hyperbaric]					,0) > 0,      'Hyperbaric - '						+ Cast(x.[Hyperbaric]					as varchar) + ', ','')
	+IIF(ISNULL(x.[IV_Therapy]					,0) > 0,      'IV_Therapy - '						+ Cast(x.[IV_Therapy]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Mammography_Reduction]				,0) > 0,      'Mammography Reduction - '				+ Cast(x.[Mammography_Reduction]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Mammography_NoReduction]			,0) > 0,      'Mammography NO Reduction - '			+ Cast(x.[Mammography_NoReduction]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Fee_Schedule]					,0) > 0,  'Fee_Schedule - '						+ Cast(x.[Fee_Schedule]					as varchar) + ', ','')
	+IIF(ISNULL(x.[OP_Default]					,0) > 0,      'OP_Default - '						+ Cast(x.[OP_Default]					as varchar) + ', ','')
	
	as ExpectedDetailed


	
--	,p.[expected_payment_analyst]
--	,x.[Drugs]	
--	,x.[Implants]
--	,x.[Blood]	
--	,x.[Gamma_Knife]	
--	,x.[PTCA]							
--	,x.[Cardiac_Cath]					
--	,x.[Lithotripsy]					
--	,x.[AS]							
--	,x.[AS_Default]					
--	,x.[EPS]							
--	,x.[Observation]					
--	,x.[ECT]							
--	,x.[Dialysis_with_CAPD_CCPD]	
--	,x.[Dialysis_without_CAPD_CCPD]							
--	,x.[Chemotherapy]					
--	,x.[ER]							
--	,x.[Partial_Hospitalization]		
--	,x.[IOP]							
--	,x.[Psych]						
--	,x.[Miscellaneous]				
--	,x.[Home_Health]					
--	,x.[Lab]							
--	,x.[Clinic]
--	,x.[Hyperbaric]
--	,x.[IV_Therapy]					
--	,x.[FS_OP_Default]
--	,x.[COVID]
	
	, [Base_Rate] = null
	, [Weights] = null
	, x.[DRG]
	, x.[RevCode1]
	, x.[CPT1]
	, x.[RevCode2]
	, x.[CPT2]
	, x.[RevCode3]
	, x.[CPT3]
	, x.[RevCode4]
	, x.[CPT4]
	, x.[RevCode5]
	, x.[CPT5]
	, x.[RevCode6]
	, x.[CPT6]
	, x.[RevCode7]
	, x.[CPT7]
	, x.[RevCode8]
	, x.[CPT8]
	, x.[RevCode9]
	, x.[CPT9]
	, x.[RevCode10]
	, x.[CPT10]
	, x.[RevCode11]
	, x.[CPT11]
	, x.[RevCode12]
	, x.[CPT12]

	, p.[AuditorName]
	, p.[employee_type]
	, p.[audit_by]
	, p.[audit_date]
	, p.[notes]
	, p.[date] as [Date Downloaded]




, [Price_Breakdown_Detail] = (
		SELECT STRING_AGG(
			'Seq:'  + CAST(lb.[Sequence]      AS VARCHAR(MAX)) +
			' CPT:' + ISNULL(CAST(lb.[ProcedureCode] AS VARCHAR(MAX)), '') +
			' Rev:' + ISNULL(CAST(lb.[RevenueCode]   AS VARCHAR(MAX)), '') +
			' | Cat:'     + CAST(lb.[ServiceCategory]  AS VARCHAR(MAX)) +
			' | Billed:$' + CAST(CONVERT(DECIMAL(12,2), ISNULL(lb.[BilledAmount], 0)) AS VARCHAR(MAX)) +
			' | Paid:$'   + CAST(CONVERT(DECIMAL(12,2), ISNULL(lb.[LinePayment],   0)) AS VARCHAR(MAX))
		, ' || ')
		WITHIN GROUP (ORDER BY lb.[Sequence])
		FROM #LineBreakdown lb
		WHERE lb.[EncounterID] = x.[EncounterID]
	)

Into #Step7
From #Step6 as x

	left join [PRS].[dbo].[PRS_Data] as p on x.[EncounterID] = p.[patient_id_real]

Order by Round([Price] - (cast(x.[OriginalPayment] as float)), 2) DESC

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*

  , [Status] = CASE
    WHEN (Diff is null)                THEN 'Not Identified'
    WHEN (Diff < -500)                 THEN 'Accounts with Errors'      
    WHEN (Diff between -500 and 0.01)  THEN 'Paid Correctly'
    WHEN (Diff between 0.01 and 99.99) THEN 'Potential Projects'
    WHEN (DaysLeft >= 0)               THEN 'Timely'  
    WHEN (Diff >= 100)                 THEN 'Underpaid'
    ELSE  'Not Identified'
    END



INTO #StepFinal
FROM #Step7 as x

Order by Round(Diff, 2) desc

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
FROM #StepFinal
Order by Round(Diff, 2) desc

Select [Status], count(*)
From #StepFinal
Group by [Status]
order by count(*) desc

--======================================================================
-- *** [AUDITOR PRICE BREAKDOWN SUMMARY QUERIES - INSERTED SECTION] ***
-- Run these after the main script completes.
-- #LineBreakdown = one row per charge line (EncounterID + Sequence).
-- ServiceCategory = final hierarchy decision (from #Step4 suppression logic).
-- 'Suppressed_By_Hierarchy' = line matched a category but a higher-tier
--   category won for this encounter.
-- 'No_Payment_Category' = line did not match any pricing pattern.
-- BundledByNCCI = 0 (no NCCI bundle step in this script).
--======================================================================

-- QUERY 1: Full line-level detail for all claims.
-- One row per charge line. Use this to trace exactly how each CPT/Rev Code
-- was categorized and priced, and which lines were suppressed by the
-- contract hierarchy.
SELECT
    lb.[EncounterID]
    , lb.[Sequence]
    , lb.[ProcedureCode]
    , lb.[RevenueCode]
    , lb.[ServiceDate]
    , lb.[BilledAmount]
    , lb.[Quantity]
    , lb.[ServiceCategory]
    , lb.[PricingMethod]
    , lb.[LinePayment]       AS [ContractualPayment_Line]
    , lb.[BundledByNCCI]     AS [ZeroedByNCCI_Flag]
FROM #LineBreakdown lb
ORDER BY lb.[EncounterID], lb.[Sequence];

-- INSERT line-level results into persistent audit table for reporting and tracking.
-- ScriptName identifies this specific contract script for cross-run comparisons.
INSERT INTO [Automation].[dbo].[LineBreakdown_Results]
    (EncounterID, Sequence, ProcedureCode, RevenueCode, ServiceDate,
     BilledAmount, Quantity,
     ServiceCategory, PricingMethod,
     LinePayment, BundledByNCCI, ScriptName, RunDate)
SELECT
    lb.[EncounterID]
    , lb.[Sequence]
    , lb.[ProcedureCode]
    , lb.[RevenueCode]
    , lb.[ServiceDate]
    , lb.[BilledAmount]
    , lb.[Quantity]
    , lb.[ServiceCategory]
    , lb.[PricingMethod]
    , lb.[LinePayment]
    , lb.[BundledByNCCI]
    , 'NYP_COL_EMBLEM_GHI_CBP_OP'
    , GETDATE()
FROM #LineBreakdown lb
ORDER BY lb.[EncounterID], lb.[Sequence];

-- QUERY 2: Reconciliation � line-level sum vs encounter-level Price.
-- Rows returned here indicate a mismatch that must be investigated.
-- In a correctly generated breakdown, this query should return 0 rows.
DROP TABLE IF EXISTS #recon_temp;

SELECT
    lb.[EncounterID]
    , SUM(lb.[LinePayment]) AS LineBreakdown_Total
INTO #recon_temp
FROM #LineBreakdown lb
GROUP BY lb.[EncounterID];

SELECT
    r.[EncounterID]
    , r.[LineBreakdown_Total]
    , p.[Price]                                     AS EncounterLevel_Price
    , (r.[LineBreakdown_Total] - p.[Price])          AS Discrepancy
FROM #recon_temp r
INNER JOIN #Step5 p ON r.[EncounterID] = p.[EncounterID]
WHERE ABS(r.[LineBreakdown_Total] - p.[Price]) > 1.00
ORDER BY ABS(r.[LineBreakdown_Total] - p.[Price]) DESC;

