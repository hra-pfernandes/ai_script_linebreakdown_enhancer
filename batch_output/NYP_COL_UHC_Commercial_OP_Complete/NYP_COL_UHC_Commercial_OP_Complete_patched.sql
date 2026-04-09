
--Script Created on 12.11.2024 by SC
--Updated FS issues AND added mod 50 logic 1.13.2025 SC
--Added ECT Logic 2.28.2025 SC
--Unified AWP 2023-2024 into one table 3.14.2025 SC
--No reimbursment for clinics and clinic codes 3.14.2025 SC
--Added Zero Pay list for Radiology 4.22.2025 SC
--Added YLS SubscriberID logic, as per Ricardo's feedback by Naveen Abboju 07.01.2025
--Updated Feeschedules(AWP, RAD, ZeroRAD) till 2024.03.31 by Naveen Abboju 07.10.2025
--As per TK's feedback using 1st quater FS until we get 2nd, 3rd and 4th quater FS --Naveen Abboju 08.14.2025
--IV_Therapy had to update % rate for years 2023-07-01 to '2024-07-01'the % was 800% and should have been 590% -Brandan Skoko 2026.03.26


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
IF OBJECT_ID('tempdb..#StepFINal') IS NOT NULL DROP TABLE #StepFINal

IF OBJECT_ID('tempdb..#bRanked')       IS NOT NULL DROP TABLE #bRanked
IF OBJECT_ID('tempdb..#bSlots')        IS NOT NULL DROP TABLE #bSlots
IF OBJECT_ID('tempdb..#LineBreakdown') IS NOT NULL DROP TABLE #LineBreakdown
IF OBJECT_ID('tempdb..#recon_temp')    IS NOT NULL DROP TABLE #recon_temp




declare @Payor_Codes nvarchar(max)
set @Payor_Codes = 'T83,H92,H27,TG6,T59,T72,T73,T74,T76,H43,TU1'

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

INTO #Step1
FROM [COL].[Data].[Charges] as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.EncounterID = y.EncounterID
	LEFT JOIN [PRS].[dbo].[PRS_Data] as p on x.[EncounterID] = p.[patient_id_real]
	LEFT JOIN [PRS].[dbo].Underpayments AS p1 ON p.[patient_id_real] = p1.[patient_id_real]

where TypeOfBill = 'Outpatient'

	AND (Payer01Name IN (
    'UHC SHARED SERVICES/HARVARD PILGRIM',
    'UNITED HEALTHCARE HMO/POS',
    'UNITED HEALTHCARE PPO',
    'UNITED HEALTHCARE CHOICE PLUS',
    'UHC GLOBAL/INTERNATIONAL',
    'UHC SUREST FORMERLY BIND',
    'UNITED HEALTH CARE INDEMNITY',
    'UNITED HEALTHCARE ALL SAVERS PLAN',
    'UNITED HEALTHCARE INTERNATIONAL',
    'UNITED HEALTHCARE STUDENT RESOURCES',
    'UNITED HEALTHCARE EVERCARE',
    'APWU HEALTH PLAN UHC',
    'UNITED HEALTHCARE SELECT PLUS',
    'MSM UNITED HEALTHCARE STUDENT RESOURCES',
    'UHC RIVER VALLEY CHOICE PLUS',
    'UNITED MEDICAL RESOURCES UMR',
    'ZZZUNITED MEDICAL RESOURCES UMR',
    'UMR LEGACY FISERV HEALTH',
    'ZZZUMR LEGACY FISERV HEALTH',
    'UNITED HEALTHCARE COLUMBIA',
	'UNITED COMPASS EXCHANGE'
    ))

	AND p.[hospital] = 'NYP Columbia' AND p.[audit_by] IS NULL AND p.[audit_date] IS NULL AND p.[employee_type] = 'Analyst'
	-- and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	-- AND y.[AGE] < 65

	AND x.[ServiceDateFrom] < '2026-01-01'

Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric

INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x

where x.[EncounterID] IN (Select [EncounterID]
from #Step1)

--***********************************************************************************************************************************************************************************************************************************************************************************************************

select x.*
INto #modifier
from #Step1_Charges x
where Modifier1 = '50'

--***********************************************************************************************************************************************************************************************************************************************************************************************************

insert into #Step1_Charges
select *
from #modifier;

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]


	, [OP_Default] = CASE
	WHEN RevenueCode IN ('250','258','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') AND (y.[ServiceDateFrom] BETWEEN '2021-01-01' AND '2021-12-31') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 5.90* Quantity), 2)
	WHEN RevenueCode IN ('250','258','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') AND (y.[ServiceDateFrom] BETWEEN '2022-01-01' AND '2023-06-30') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 5.90* Quantity), 2)
	WHEN RevenueCode IN ('250','258','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 7.50* Quantity), 2)
	WHEN RevenueCode IN ('250','258','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 8.25* Quantity), 2)
	ELSE 0
	END

	, M1.[RATE]

	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','452','459') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 1580
	WHEN RevenueCode IN ('456') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 950

	WHEN RevenueCode IN ('450','451','452','459') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 1722	
	WHEN RevenueCode IN ('456') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 1036

	WHEN RevenueCode IN ('450','451','452','459') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 1860		
	WHEN RevenueCode IN ('456') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 1118
	
    WHEN RevenueCode IN ('450','451','452','459') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 2105		
	WHEN RevenueCode IN ('456') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 1207
	
    WHEN RevenueCode IN ('450','451','452','459') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 2316
	WHEN RevenueCode IN ('456') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 1328
    ELSE 0
	END

	, [AS] = CASE 

	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '0' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  2843
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '1' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  3673
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '2' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  5042
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '3' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  5557
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '4' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  6965
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '5' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  7928
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '6' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  8954
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '7' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 11682
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '8' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 11002
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] =  '9' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 13442
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] = '10' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 15834
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND Grouper.[ASC_Group] = 'UL' AND Grouper.[Code] IS NOT NULL AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN  3374
	
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) = '0' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  3070
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '1' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  3967
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '2' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  5446
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '3' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  6001
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '4' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  7522
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '5' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  8562
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '6' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  9671
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '7' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 12616
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '8' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 11883
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '9' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 14517
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) = '10' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 17101
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) = 'UL' AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN  3643	

	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '0' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 3448
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '1' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 4457
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '2' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 6116
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '3' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 6764
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '4' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 8449
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '5' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 9616
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '6' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 10861
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '7' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 14171
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '8' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 13346
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '9' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 16305
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] = '10' AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 19106
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] in ('UL','11') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN  4094

	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '0' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 3793
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '1' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 4903
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '2' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 6728
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '3' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 7441
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '4' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 9294
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '5' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 10578
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '6' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 11948
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '7' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 15590
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '8' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 14681
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] =  '9' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 17937
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] = '10' AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 21028
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','790') AND ((ProcedureCodeNumeric NOT BETWEEN 93451 AND 93464) AND (ProcedureCodeNumeric NOT BETWEEN 93530 AND 93533) AND (ProcedureCodeNumeric NOT BETWEEN 93561 AND 93568) AND (ProcedureCodeNumeric NOT BETWEEN 93580 AND 93583) AND (ProcedureCode NOT IN ('93503','93505','93571','93572'))) AND ASCGrouper.[ASC_Group] in ('UL','11') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 4504		
	ELSE 0
	END

	, [Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ((ProcedureCodeNumeric BETWEEN 93451 AND 93464) or (ProcedureCodeNumeric BETWEEN 93530 AND 93533) or (ProcedureCodeNumeric BETWEEN 93561 AND 93568) or (ProcedureCodeNumeric BETWEEN 93580 AND 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 15840
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ((ProcedureCodeNumeric BETWEEN 93451 AND 93464) or (ProcedureCodeNumeric BETWEEN 93530 AND 93533) or (ProcedureCodeNumeric BETWEEN 93561 AND 93568) or (ProcedureCodeNumeric BETWEEN 93580 AND 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 17266	
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ((ProcedureCodeNumeric BETWEEN 93451 AND 93464) or (ProcedureCodeNumeric BETWEEN 93530 AND 93533) or (ProcedureCodeNumeric BETWEEN 93561 AND 93568) or (ProcedureCodeNumeric BETWEEN 93580 AND 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 18647		
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ((ProcedureCodeNumeric BETWEEN 93451 AND 93464) or (ProcedureCodeNumeric BETWEEN 93530 AND 93533) or (ProcedureCodeNumeric BETWEEN 93561 AND 93568) or (ProcedureCodeNumeric BETWEEN 93580 AND 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 20139		
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ((ProcedureCodeNumeric BETWEEN 93451 AND 93464) or (ProcedureCodeNumeric BETWEEN 93530 AND 93533) or (ProcedureCodeNumeric BETWEEN 93561 AND 93568) or (ProcedureCodeNumeric BETWEEN 93580 AND 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 22154		
	ELSE 0
	END
	
	, [Endoscopy] = CASE
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ProcedureCode IN ('45378','45380','45381','45384','45385','G0105','G0121') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 5918		
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ProcedureCode IN ('45378','45380','45381','45384','45385','G0105','G0121') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 6510	
	ELSE 0
	END

	, [PTCA] = CASE
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ProcedureCode IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 37997
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ProcedureCode IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 41417
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ProcedureCode IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 44730	
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ProcedureCode IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 48308	
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') AND ProcedureCode IN ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 53142	
	ELSE 0
	END 

	, [Gamma_Knife] = CASE
	WHEN RevenueCode IN ('360') AND ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN  96977
	WHEN RevenueCode IN ('360') AND ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 105705	
	WHEN RevenueCode IN ('360') AND ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 114161		
	WHEN RevenueCode IN ('360') AND ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 123294	
	WHEN RevenueCode IN ('360') AND ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 135631 		
	ELSE 0
	END 


	, [Chemotherapy] = CASE
	WHEN RevenueCode IN ('331','332','335') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN ROUND(1238.116612,2)
	WHEN RevenueCode IN ('331','332','335') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN ROUND(1349.547107,2)
	WHEN RevenueCode IN ('331','332','335') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN ROUND(1457.510876,2)	
	WHEN RevenueCode IN ('331','332','335') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN ROUND(1574.1117456	,2)
	WHEN RevenueCode IN ('331','332','335') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN ROUND(1731,2)
	ELSE 0
	END

	, [IV_Therapy] = CASE 
	WHEN RevenueCode IN (260,269) AND (y.[ServiceDateFrom] BETWEEN '2021-01-01' AND '2021-12-31') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 5.90 * Quantity), 2)	
 	WHEN RevenueCode IN (260,269) AND (y.[ServiceDateFrom] BETWEEN '2022-01-01' AND '2023-06-30') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 5.90 * Quantity), 2)	
 	WHEN RevenueCode IN (260,269) AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 5.90 * Quantity), 2)	
 	WHEN RevenueCode IN (260,269) AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN ROUND(IIF(M1.[RATE] IS NULL or M1.[Rate]=0, [Amount] * 0.80, M1.[RATE] * 5.90 * Quantity), 2)	
	ELSE 0
	END

	, [Radiation_Therapy] = CASE
	WHEN RevenueCode IN ('330','333','339') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 1723 * Quantity
	WHEN RevenueCode IN ('330','333','339') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 1878 * Quantity	
	WHEN RevenueCode IN ('330','333','339') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 2028 * Quantity	
	WHEN RevenueCode IN ('330','333','339') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 2651 * Quantity		
	WHEN RevenueCode IN ('330','333','339') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 2918 * Quantity		
	ELSE 0
	END

 
	, [Radiology] = CASE
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN IIF(RAD0720.[SOURCE_FEE] IS NULL, IIF(ProcedureCode IN (SELECT CPT FROM [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay-2024]),0, Round(x.Amount * 0.50, 2)), Round(RAD0720.[SOURCE_FEE] * 1.60 * Quantity, 2))      			
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN IIF(RAD0721.[SOURCE_FEE] IS NULL, IIF(ProcedureCode IN (SELECT CPT FROM [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay-2024]),0, Round(x.Amount * 0.50, 2)), Round(RAD0721.[SOURCE_FEE] * 1.60 * Quantity, 2))
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN IIF(RAD24.[SOURCE_FEE] IS NULL,   IIF(ProcedureCode IN (SELECT CPT FROM [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay-2024]),0, Round(x.Amount * 0.50, 2)), Round(RAD24.[SOURCE_FEE] * 1.60 * Quantity, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN IIF(RAD24.[SOURCE_FEE] IS NULL,   IIF(ProcedureCode IN (SELECT CPT FROM [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay-2024]),0, Round(x.Amount * 0.50, 2)), Round(RAD24.[SOURCE_FEE] * 1.60 * Quantity, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '2024-12-31') THEN IIF(RAD24.[SOURCE_FEE] IS NULL,   IIF(ProcedureCode IN (SELECT CPT FROM [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay-2024]),0, Round(x.Amount * 0.50, 2)), Round(RAD24.[SOURCE_FEE] * 1.60 * Quantity, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') AND (y.[ServiceDateFrom] BETWEEN '2025-01-01' AND '9999-12-31') THEN IIF(RAD.[SOURCE_FEE]   IS NULL,   IIF(ProcedureCode IN (SELECT CPT FROM [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay]     ),0, Round(x.Amount * 0.50, 2)), Round(RAD.[SOURCE_FEE]   * 1.60 * Quantity, 2)) --- Partitioned contractyear due to addition of new Radiology schedule
	ELSE 0
	END


	, [Lab] = CASE --Added capitation to labs by putting them in 0.01 as of Ricardos's feedback from hospital. 6.13.2025 by Naveen Abboju
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN IIF(LAB0720.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB0720.[SOURCE_FEE] * 1.20 * Quantity, 2)) 
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN IIF(LAB0721.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB0721.[SOURCE_FEE] * 1.20 * Quantity, 2))
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN IIF(LAB24.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB24.[SOURCE_FEE] * 1.20 * Quantity, 2))	
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN IIF(LAB24.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB24.[SOURCE_FEE] * 1.20 * Quantity, 2))	
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN IIF(LAB24.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB24.[SOURCE_FEE] * 1.20 * Quantity, 2))	
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') THEN 0.01	
	ELSE 0
	END


	, [PET_Scan] = CASE
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 3734
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 4070
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 4396
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 4396
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 5222


	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78459') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 5145	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78459') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 5608	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78459') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 6057	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78459') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 6057	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78459') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 7196	

	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78491') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 3051	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78491') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 3326	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78491') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 3592	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78491') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 3592	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78491') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 4268	

	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78492') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 5140	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78492') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 5603	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78492') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 6051	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78492') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 6051	
	WHEN RevenueCode IN ('404') AND ProcedureCode IN ('78492') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 7189	
	ELSE 0
	END
       
	, [Ambulance] = CASE
	WHEN RevenueCode IN ('540','542','543','546','547','548','549') THEN Round([Amount] * 0.84, 2)
	ELSE 0
	END

	, [Drugs] = CASE
	WHEN RevenueCode IN ('343','344','634','635','636') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2020-09-30') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN Round(AWP0720.[Source Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') AND (y.[ServiceDateFrom] BETWEEN '2020-10-01' AND '2020-12-31') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN Round(AWP1020.[Source Rate] * 0.80 * Quantity, 2)	
	WHEN RevenueCode IN ('343','344','634','635','636') AND (y.[ServiceDateFrom] BETWEEN '2021-01-01' AND '2021-03-31') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN Round(AWP0121.[Source Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') AND (y.[ServiceDateFrom] BETWEEN '2021-04-01' AND '2022-06-30') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN Round(AWP0421.[Source Rate] * 0.80 * Quantity, 2)	
	WHEN RevenueCode IN ('343','344','634','635','636') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2022-12-31') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN Round(AWP0122.[Source Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') AND (y.[ServiceDateFrom] BETWEEN '2023-01-01' AND '2024-06-30') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN Round(AWP.[Source_Rate] * 0.84 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN Round(AWP.[Source_Rate] * 0.84 * Quantity, 2)
	ELSE 0
	END


	, [Provenge_Drugs] = CASE			
	WHEN RevenueCode IN ('636') AND x.[ProcedureCode] IN ('Q2043') AND (y.[ServiceDateFrom] BETWEEN '2020-07-01' AND '2021-06-30') THEN 61126
	WHEN RevenueCode IN ('636') AND x.[ProcedureCode] IN ('Q2043') AND (y.[ServiceDateFrom] BETWEEN '2021-07-01' AND '2022-06-30') THEN 66627	
	WHEN RevenueCode IN ('636') AND x.[ProcedureCode] IN ('Q2043') AND (y.[ServiceDateFrom] BETWEEN '2022-07-01' AND '2023-06-30') THEN 71957	
	WHEN RevenueCode IN ('636') AND x.[ProcedureCode] IN ('Q2043') AND (y.[ServiceDateFrom] BETWEEN '2023-07-01' AND '2024-06-30') THEN 71957	
	WHEN RevenueCode IN ('636') AND x.[ProcedureCode] IN ('Q2043') AND (y.[ServiceDateFrom] BETWEEN '2024-07-01' AND '9999-12-31') THEN 71957
	ELSE 0
	END


	, [Implants] = CASE
	WHEN RevenueCode IN ('274','275','276','278') AND (X.[ProcedureCode] NOT IN ('C1724', 'C1725', 'C1726', 'C1727', 'C1728', 'C1728', 'C1729', 'C1730', 'C1731', 'C1732', 'C1733', 'C1753', 'C1754', 'C1755', 'C1756', 'C1757', 'C1758', 'C1759', 'C1765', 'C1766', 'C1769', 'C1773', 'C1782', 'C1819', 'C1884', 'C1885', 'C1887', 'C1892', 'C1893', 'C1894', 'C2614', 'C2615', 'C2618', 'C2628', 'C2629', 'C2630') OR ProcedureCode IS NULL)THEN Round(Amount * 0.36, 2)
	ELSE 0
	END 


	, [Blood] = CASE
	WHEN ((RevenueCode in ('380','381','382','383','384','385','387','389','390') AND (ProcedureCode LIKE 'P901%' or ProcedureCode LIKE 'P902%' or ProcedureCode LIKE 'P903%' or ProcedureCode LIKE 'P904%' or ProcedureCode LIKE 'P905%' or ProcedureCode IN ('P9060'))) or (RevenueCode IN ('386') and (ProcedureCode IN ('J7178','J7180','J7181','J7182','J7183','J7185','J7186','J7187','J7189','J7190','J7191','J7192','J7193','J7194','J7195','J7196','J7197','J7198','J7199','J7200','J7201')))) THEN Round(Amount * 1.00, 2)
	ELSE 0
	END
	
	, [ECT] = CASE
	WHEN RevenueCode IN ('901') and ProcedureCode in ('90870') and (y.[ServiceDateFrom] between '2020-07-01' and '2022-06-30') THEN 1539	
	WHEN RevenueCode IN ('901') and ProcedureCode in ('90870') and (y.[ServiceDateFrom] between '2022-07-01' and '2022-09-30') THEN 1609	
	WHEN RevenueCode IN ('901') and ProcedureCode in ('90870') and (y.[ServiceDateFrom] between '2022-10-01' and '2023-06-30') THEN 1812	
	WHEN RevenueCode IN ('901') and ProcedureCode in ('90870') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 1957	
	WHEN RevenueCode IN ('901') and ProcedureCode in ('90870') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 2114
	ELSE 0
	END
	
	, [Miscellaneous] = CASE --Optimized format 5.15.2025 SC
    WHEN ProcedureCode IN ('90785','90791','90792','90832','90833','90834','90836','90837','90838','90839','90840','90846','90847','90849','90853','90870','90889','96105','96110','96112','96113','96116','96121','96125','96127','96130','96131','96132','96133','96136','96137','96138','96139','96146','96150','96151','96152','96153','96154','96155','99211','99212','99213','99214','99215','99231','99241','99242','99273','99244','99245','99341','99342','99343','99347','99348','99349','99441','99442','99443')
        THEN (CASE
    	WHEN (y.[ServiceDateFrom] between '2022-10-01' and '2023-06-30')THEN 
    		CASE ProcedureCode
    		    WHEN '90785' THEN 42.000        WHEN '90791' THEN 332.000       WHEN '90792' THEN 332.000       WHEN '90832' THEN 171.000
    		    WHEN '90833' THEN 113.000       WHEN '90834' THEN 194.000       WHEN '90836' THEN 170.000       WHEN '90837' THEN 206.010
    		    WHEN '90838' THEN 224.8452      WHEN '90839' THEN 229.554       WHEN '90840' THEN 84.7584       WHEN '90846' THEN 257.8068
    		    WHEN '90847' THEN 257.8068      WHEN '90849' THEN 125.9604      WHEN '90853' THEN 127.000       WHEN '90870' THEN 1812.000
    		    WHEN '90889' THEN 141.264       WHEN '96105' THEN 273.000       WHEN '96110' THEN 273.000       WHEN '96112' THEN 273.000
    		    WHEN '96113' THEN 168.000       WHEN '96116' THEN 273.000       WHEN '96121' THEN 273.000       WHEN '96125' THEN 273.000
    		    WHEN '96127' THEN 273.000       WHEN '96130' THEN 273.000       WHEN '96131' THEN 273.000       WHEN '96132' THEN 273.000
    		    WHEN '96133' THEN 273.000       WHEN '96136' THEN 138.000       WHEN '96137' THEN 138.000       WHEN '96138' THEN 138.000
    		    WHEN '96139' THEN 138.000       WHEN '96146' THEN 273.000       WHEN '96150' THEN 69.000        WHEN '96151' THEN 69.000
    		    WHEN '96152' THEN 69.000        WHEN '96153' THEN 69.000        WHEN '96154' THEN 69.000        WHEN '96155' THEN 69.000
    		    WHEN '99211' THEN 97.000        WHEN '99212' THEN 212.000       WHEN '99213' THEN 220.000       WHEN '99214' THEN 244.000
    		    WHEN '99215' THEN 332.000       WHEN '99231' THEN 137.000       WHEN '99241' THEN 99.000        WHEN '99242' THEN 219.000
    		    WHEN '99273' THEN 254.000       WHEN '99244' THEN 254.000       WHEN '99245' THEN 254.000       WHEN '99341' THEN 239.000
    		    WHEN '99342' THEN 285.000       WHEN '99343' THEN 356.000       WHEN '99347' THEN 239.000       WHEN '99348' THEN 285.000
    		    WHEN '99349' THEN 357.000       WHEN '99441' THEN 38.000        WHEN '99442' THEN 72.000        WHEN '99443' THEN 87.000
    		    ELSE 0
    		END
 		WHEN (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 
    	    CASE ProcedureCode
    	        WHEN '90785' THEN 46.000        WHEN '90791' THEN 359.000       WHEN '90792' THEN 359.000       WHEN '90832' THEN 184.000
    	        WHEN '90833' THEN 122.000       WHEN '90834' THEN 210.000       WHEN '90836' THEN 183.000       WHEN '90837' THEN 222.4908
    	        WHEN '90838' THEN 242.832816    WHEN '90839' THEN 247.91832     WHEN '90840' THEN 91.539072     WHEN '90846' THEN 278.431344
    	        WHEN '90847' THEN 278.431344    WHEN '90849' THEN 136.037232    WHEN '90853' THEN 137.308608    WHEN '90870' THEN 1956.7493741
    	        WHEN '90889' THEN 152.56512     WHEN '96105' THEN 295.000       WHEN '96110' THEN 295.000       WHEN '96112' THEN 295.000
    	        WHEN '96113' THEN 149.000       WHEN '96116' THEN 295.000       WHEN '96121' THEN 295.000       WHEN '96125' THEN 295.000
    	        WHEN '96127' THEN 295.000       WHEN '96130' THEN 295.000       WHEN '96131' THEN 295.000       WHEN '96132' THEN 295.000
    	        WHEN '96133' THEN 295.000       WHEN '96136' THEN 149.000       WHEN '96137' THEN 149.000       WHEN '96138' THEN 149.000
    	        WHEN '96139' THEN 149.000       WHEN '96146' THEN 295.000       WHEN '96150' THEN 75.000        WHEN '96151' THEN 75.000
    	        WHEN '96152' THEN 75.000        WHEN '96153' THEN 75.000        WHEN '96154' THEN 75.000        WHEN '96155' THEN 75.000
    	        WHEN '99211' THEN 104.000       WHEN '99212' THEN 229.000       WHEN '99213' THEN 238.000       WHEN '99214' THEN 263.000
    	        WHEN '99215' THEN 359.000       WHEN '99231' THEN 147.000       WHEN '99241' THEN 107.000       WHEN '99242' THEN 236.000
    	        WHEN '99273' THEN 275.000       WHEN '99244' THEN 275.000       WHEN '99245' THEN 275.000       WHEN '99341' THEN 258.000
    	        WHEN '99342' THEN 308.000       WHEN '99343' THEN 384.000       WHEN '99347' THEN 258.000       WHEN '99348' THEN 308.000
    	        WHEN '99349' THEN 385.000       WHEN '99441' THEN 41.000        WHEN '99442' THEN 78.000        WHEN '99443' THEN 94.000
    	        ELSE 0
    	    END 
		WHEN (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN
    		CASE ProcedureCode
    		    WHEN '90785' THEN 50.000        WHEN '90791' THEN 393.000       WHEN '90792' THEN 393.000       WHEN '90832' THEN 202.000
    		    WHEN '90833' THEN 134.000       WHEN '90834' THEN 231.000       WHEN '90836' THEN 202.000       WHEN '90837' THEN 244.73988
    		    WHEN '90838' THEN 267.1160976   WHEN '90839' THEN 272.500       WHEN '90840' THEN 100.6929792   WHEN '90846' THEN 306.2744784
    		    WHEN '90847' THEN 305.390       WHEN '90849' THEN 149.6409552   WHEN '90853' THEN 150.000       WHEN '90870' THEN 2145.000
    		    WHEN '90889' THEN 166.900       WHEN '96105' THEN 323.000       WHEN '96110' THEN 323.000       WHEN '96112' THEN 323.000
    		    WHEN '96113' THEN 164.000       WHEN '96116' THEN 323.000       WHEN '96121' THEN 323.000       WHEN '96125' THEN 323.000
    		    WHEN '96127' THEN 323.000       WHEN '96130' THEN 323.000       WHEN '96131' THEN 323.000       WHEN '96132' THEN 323.000
    		    WHEN '96133' THEN 323.000       WHEN '96136' THEN 164.000       WHEN '96137' THEN 164.000       WHEN '96138' THEN 164.000
    		    WHEN '96139' THEN 164.000       WHEN '96146' THEN 323.000       WHEN '96150' THEN 0.000         WHEN '96151' THEN 0.000
    		    WHEN '96152' THEN 0.000         WHEN '96153' THEN 0.000         WHEN '96154' THEN 0.000         WHEN '96155' THEN 0.000
    		    WHEN '99211' THEN 115.000       WHEN '99212' THEN 251.000       WHEN '99213' THEN 260.000       WHEN '99214' THEN 289.000
    		    WHEN '99215' THEN 393.000       WHEN '99231' THEN 148.000       WHEN '99241' THEN 118.000       WHEN '99242' THEN 259.000
    		    WHEN '99273' THEN 0.000         WHEN '99244' THEN 301.000       WHEN '99245' THEN 301.000       WHEN '99341' THEN 283.000
    		    WHEN '99342' THEN 337.000       WHEN '99343' THEN 421.000       WHEN '99347' THEN 283.000       WHEN '99348' THEN 337.000
    		    WHEN '99349' THEN 423.000       WHEN '99441' THEN 45.000        WHEN '99442' THEN 85.000        WHEN '99443' THEN 103.000
    		    ELSE 0
    		END 
		END) * Quantity
    	ELSE 0
    END


	, [Clinic] = CASE
	WHEN RevenueCode BETWEEN '510' AND '529' THEN 0.01 --Added to lower accounts with errors 3.11.2025 SC 
	ELSE 0
	END

	, case
	WHEN (y.[ServiceDateFrom] BETWEEN '2020-01-27' AND '2020-03-31') AND [dp].[Dx] like '%B97.29%'	THEN 1
	WHEN (y.[ServiceDateFrom] BETWEEN '2020-04-01' AND '2020-11-01') AND [dp].[Dx] like '%U07.1%'	THEN 1
	WHEN (y.[ServiceDateFrom] > '2020-11-01') AND [dp].[Dx] like '%U07.1%'	THEN 1
	ELSE 0
	END As [COVID]



Into #Step2
From #Step1_Charges as x


	LEFT JOIN [COL].[Data].[Demo] 															as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px] 															as dp on x.[EncounterID] = dp.[EncounterID] AND x.[Sequence] = dp.[Sequence]
	LEFT JOIN [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]							as Grouper ON Grouper.[Code] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[dbo].[Oxford_United_ASC_Grouper (2023.01.01)]					as ASCGroup2023 ON ASCGroup2023.[Code] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[FSG].[Oxford-UHC_ASC_Grouper(23-25)]								as ASCGrouper ON ASCGrouper.[Code] = x.[ProcedureCode] and x.ServiceDateFrom between ASCGrouper.[StartDate] and ASCGrouper.[EndDate] ---Added UHC-Oxford 2025 ASC Grouper till June 2025 following Path as per Ricardo's Suggestion(S:\WMCHealth\WMC Fee Schedules\New WMC fee schedule\UHC & Oxford\Grouper Fee schedules\United ASC Grouper - OPG Exhibit 07-01-2024 Including Code Updates for January 2025) 

	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2020.07.01)]								    as AWP0720 ON CAST(AWP0720.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2020.10.01)]								    as AWP1020 ON CAST(AWP1020.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2021.01.01)]								    as AWP0121 ON CAST(AWP0121.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2021.04.01)]								    as AWP0421 ON CAST(AWP0421.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2022.01.01)]								    as AWP0122 ON CAST(AWP0122.[CODE] as nvarchar(max)) = x.[ProcedureCode]

	LEFT JOIN [Analytics].[FSG].[Oxford-United AWP]											as AWP ON AWP.[CODE] = x.[ProcedureCode] and x.ServiceDateFrom between AWP.[StartDate] and AWP.[EndDate]

	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2019.07.01)]			as LAB0719 ON LAB0719.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2020.07.01)]			as LAB0720 ON LAB0720.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2021.07.01)]			as LAB0721 ON LAB0721.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2022.01.01)]			as LAB0122 ON LAB0122.[CPT] = x.[ProcedureCode]

	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedLaboratoryFeeSchedule-2024]					AS LAB24 ON LAB24.[CPT] = X.[ProcedureCode] and x.ServiceDateFrom between LAB24.StartDate and LAB24.EndDate

	LEFT JOIN [QNS].[FSG].[Oxford-United Radiology Fee Schedule 12581 (2019.07.01)]			as RAD0719 ON RAD0719.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Radiology Fee Schedule 12581 (2020.07.01)]			as RAD0720 ON RAD0720.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Radiology Fee Schedule 12581 (2021.07.01)]			as RAD0721 ON RAD0721.[CPT] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedRadiologyFeeSchedule-2024]					as RAD24 ON RAD24.[CPT] = x.[ProcedureCode] and x.ServiceDateFrom between RAD24.StartDate and RAD24.EndDate
	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay-2024]						AS ZERO ON ZERO.[CPT] = x.ProcedureCode and x.ServiceDateFrom between ZERO.StartDate and ZERO.EndDate

	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedRadiologyFeeSchedule]							as RAD ON RAD.[CPT] = x.[ProcedureCode] --and x.ServiceDateFrom between RAD.StartDate and RAD.EndDate
	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay]							AS Z1 ON Z1.[CPT] = x.ProcedureCode --and x.ServiceDateFrom between Z1.StartDate and Z1.EndDate

	LEFT JOIN [Analytics].[FSG].[MedicareFeeSchedule(RBRVS)_Locality1] 				     	as M1 ON M1.[CPT_CODE] = X.[ProcedureCode] AND (y.[ServiceDateFrom] BETWEEN M1.[StartDate] AND M1.[EndDate])

ORDER BY [EncounterID], x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate], [RevenueCode], [ProcedureCode], [Amount], [OriginalPayment]
	, [OP_Default]	= IIF([ER]=0 AND [AS]=0 AND [Cardiac_Cath]=0 AND [PTCA]=0 AND [Gamma_Knife]=0 AND [Implants]=0 AND [Blood]=0 AND [Drugs]=0 AND [Provenge_Drugs]=0 AND [Chemotherapy]=0 AND [Lab]=0 AND [Radiology]=0 AND [Radiation_Therapy]=0 AND [PET_Scan]=0 AND [Ambulance]=0 AND [Miscellaneous]=0 AND [Clinic]=0, [OP_Default], 0)
	, [ER]
	
	-- AS
	, LEAD([AS]/1, 0, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS1
	, LEAD([AS]/2, 1, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS2
	, LEAD([AS]/2, 2, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS3
	, LEAD([AS]/2, 3, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS4
	, LEAD([AS]/2, 4, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS5
	, LEAD([AS]/2, 5, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS6
	, LEAD([AS]/2, 6, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS7
	, LEAD([AS]/2, 7, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS8
	, LEAD([AS]/2, 8, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS9
	, LEAD([AS]/2, 9, 0) over (partition by [EncounterID] order by [AS] desc, [AS] Desc) AS AS10
	
	, [Endoscopy]
	, [Cardiac_Cath]
	, [PTCA]
	, [Gamma_Knife]
	, [Implants]
	, [Blood]
	, [Drugs]			=IIF( (modifier1 not in ('FB','SL') or Modifier1 IS NULL), [Drugs], 0) --Added to remove drugs with modifiers FB and SL as per Ricardo's suggestion on 3.11.2025
	, [Provenge_Drugs]
	, [Chemotherapy]
	, [IV_Therapy]
	, [Lab]
	, [Radiology]
	, [Radiation_Therapy]
	, [PET_Scan]
	, [Ambulance]
	, [Miscellaneous]
	, [Clinic]
	, [COVID]
	, [ECT]
INto #Step3
From #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]

	, SUM([OP_Default])				as [OP_Default]
	, MAX([ER])						as [ER]
	, MAX(AS1)+MAX(AS2)+MAX(AS3)+MAX(AS4)+MAX(AS5)+MAX(AS6)+MAX(AS7)+MAX(AS8)+MAX(AS9)+MAX(AS10) as [AS]
	, MAX([Endoscopy])				as [Endoscopy]	
	, MAX([Cardiac_Cath])			as [Cardiac_Cath]
	, MAX([PTCA])					as [PTCA]
	, MAX([Gamma_Knife])				as [Gamma_Knife]
	, SUM([Implants])				as [Implants]
	, SUM([Blood])					as [Blood]
	, SUM([Drugs])					as [Drugs]
	, SUM([Provenge_Drugs])			as [Provenge_Drugs]
	, MAX([Chemotherapy])			as [Chemotherapy]
	, SUM([IV_Therapy])				AS [IV_Therapy]
	, SUM([Lab])						as [Lab]
	, SUM([Radiology])				as [Radiology]	
	, SUM([Radiation_Therapy])		as [Radiation_Therapy]		
	, SUM([PET_Scan])				as [PET_Scan]
	, SUM([Ambulance])				as [Ambulance]	
	, SUM([Miscellaneous])			as [Miscellaneous]		
	, MAX([Clinic])					as [Clinic]
	, MAX([COVID])					as [COVID]	
	, MAX([ECT])						AS [ECT]
INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, SUM([OP_Default])			as [OP_Default]
	, MAX([ER])					as [ER]
	, MAX([AS])					as [AS]
	, MAX([Endoscopy])			as [Endoscopy]	
	, MAX([Cardiac_Cath])		as [Cardiac_Cath]
	, MAX([PTCA])				as [PTCA]
	, MAX([Gamma_Knife])			as [Gamma_Knife]	
	, SUM([Implants])			as [Implants]
	, SUM([Blood])				as [Blood]	
	, SUM([Drugs])				as [Drugs]			
	, SUM([Provenge_Drugs])		as [Provenge_Drugs]	
	, SUM([Chemotherapy])		as [Chemotherapy]
	, SUM([IV_Therapy])			AS [IV_Therapy]
	, SUM([Lab])					as [Lab]	
	, SUM([Radiology])			as [Radiology]	
	, SUM([Radiation_Therapy])	as [Radiation_Therapy]	
	, SUM([PET_Scan])			as [PET_Scan]
	, SUM([Ambulance])			as [Ambulance]	
	, SUM([Miscellaneous])		as [Miscellaneous]	
	, MAX([Clinic])				as [Clinic]
	, MAX([COVID])				as [COVID]	
	, MAX([ECT])						AS [ECT]

INTO #Step3_2
FROM #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	
	, [Implants]				=IIF([ER]=0,[Implants],0)
	, [Blood]				=IIF([AS] = 0 AND [ER]=0, [Blood], 0)
	, [Drugs]				=IIF([Endoscopy]=0 AND [ER] = 0 AND [ECT] =0 and [AS]=0,[Drugs],0)
	, [Provenge_Drugs]
	, [Gamma_Knife]	
	, [PTCA]					= IIF([Gamma_Knife]=0, [PTCA], 0)
	, [Cardiac_Cath]			= IIF([Gamma_Knife]=0 AND [PTCA]=0, [Cardiac_Cath], 0)
	, [Endoscopy]			= IIF([Gamma_Knife]=0 AND [PTCA]=0, [Endoscopy], 0)
	, [AS]					= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [Endoscopy]=0, [AS], 0)
	, [PET_Scan]				= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0, [PET_Scan], 0)
	, [ER]					= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0, [ER], 0)
	, [Chemotherapy]			= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0, [Chemotherapy], 0)
	, [IV_Therapy]			= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0, [IV_Therapy], 0)
	, [Radiation_Therapy]	= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0, [Radiation_Therapy], 0)
	, [ECT]					= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0, [ECT], 0)
	, [Lab]					= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0 AND [ECT] = 0 AND [Radiation_Therapy]=0 , [Lab], 0)
	, [Radiology]			= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0 AND [ECT] = 0 AND [Radiation_Therapy]=0 , [Radiology], 0)
	, [Ambulance]			= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0 AND [ECT] = 0 AND [Radiation_Therapy]=0 , [Ambulance], 0)
	, [Miscellaneous]		= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0 AND [ECT] = 0 AND [Radiation_Therapy]=0 and [Clinic]=0, [Miscellaneous], 0)	
	, [Clinic]				= IIF([Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0 AND [ECT] = 0 AND [Radiation_Therapy]=0 AND [Lab]=0 AND [Radiology]=0, [Clinic], 0)
	, [OP_Default]			= IIF([Miscellaneous] = 0 AND [Gamma_Knife]=0 AND [PTCA]=0 AND [Cardiac_Cath]=0 AND [AS]=0 AND [PET_Scan]=0 AND [ER]=0, [OP_Default], 0)
	, [COVID]

INTO #Step4
FROM #Step3_2

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (post-LEAD slot computation, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
--           #Step2 joined for Sequence, Quantity, BillCharges (not present in #Step3).
--
-- COLUMN SURVIVAL TRACE:
--   #Step3 is built with an EXPLICIT column list from #Step2.
--   Confirmed present in #Step3:
--     EncounterID, ServiceDate, RevenueCode, ProcedureCode, Amount, OriginalPayment,
--     OP_Default (computed), ER (computed),
--     AS1-AS10 (LEAD-computed), Endoscopy, Cardiac_Cath, PTCA, Gamma_Knife,
--     Implants, Blood, Drugs (filtered), Provenge_Drugs, Chemotherapy, IV_Therapy,
--     Lab, Radiology, Radiation_Therapy, PET_Scan, Ambulance, Miscellaneous,
--     Clinic, COVID, ECT
--   NOT present in #Step3 (explicit narrow list):
--     Sequence, Quantity, BillCharges, Modifier1, ProcedureCodeNumeric, Plan,
--     Payer01Code, Payer01Name, ServiceDateFrom, ServiceDateTo
--   These are recovered from #Step2 via LEFT JOIN on EncounterID + RevenueCode + ProcedureCode.
--   NOTE: #Step2 has no Sequence column carried into #Step3.
--   #Step2 DOES have Sequence. We join on EncounterID + RevenueCode + ProcedureCode + Amount
--   to recover Sequence, Quantity, BillCharges.
--
-- CLASSIFICATION SUMMARY (read from actual script, overriding stale discovery JSON):
--
-- MAX CATEGORIES (one winner per encounter — MAX in both AGGREGATE_DATE and AGGREGATE_ENC):
--   ER, Endoscopy, Cardiac_Cath, PTCA, Gamma_Knife, Clinic, ECT
--   (ER: MAX/MAX; Endoscopy: MAX/MAX; Cardiac_Cath: MAX/MAX; PTCA: MAX/MAX;
--    Gamma_Knife: MAX/MAX; Clinic: MAX/MAX; ECT: MAX/MAX)
--
-- HYBRID CATEGORIES (MAX in AGGREGATE_DATE, SUM in AGGREGATE_ENC):
--   Chemotherapy  (MAX in #Step3_1, SUM in #Step3_2)
--
-- SUM CATEGORIES (SUM in both aggregation steps — all matching lines pay):
--   OP_Default, Implants, Blood, Drugs, Provenge_Drugs, IV_Therapy, Lab,
--   Radiology, Radiation_Therapy, PET_Scan, Ambulance, Miscellaneous
--
-- WINDOW_REDUCTION CATEGORIES (slot-based payment via LEAD pivot):
--   AS : slots AS1-AS10  PARTITION BY EncounterID only
--        Reduction: AS1=full, AS2=AS/2, AS3-AS10=AS/2
--        rn_AS ORDER BY SUM(AS1..AS10) DESC
--
-- INDICATOR_FLAG CATEGORIES (binary 0/1, $0 LinePayment):
--   COVID
--
-- ROW_NUMBER() COMPLETENESS CHECK:
--   MAX (7): ER, Endoscopy, Cardiac_Cath, PTCA, Gamma_Knife, Clinic, ECT
--   HYBRID (1): Chemotherapy
--   WINDOW_REDUCTION (1): AS
--   INDICATOR_FLAG (1): COVID
--   TOTAL: 10 ROW_NUMBER() lines in #bRanked
--
-- SUPPRESSION HIERARCHY (from #Step4 IIF chain, tier 1 = highest priority):
--   1.  Gamma_Knife
--   2.  PTCA             (suppressed if Gamma_Knife != 0)
--   3.  Cardiac_Cath     (suppressed if Gamma_Knife OR PTCA != 0)
--   4.  Endoscopy        (suppressed if Gamma_Knife OR PTCA != 0)
--   5.  AS               (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR Endoscopy != 0)
--   6.  PET_Scan         (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS != 0)
--   7.  ER               (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS OR PET_Scan != 0)
--   8.  Chemotherapy     (suppressed if ER or any above != 0)
--   9.  IV_Therapy       (suppressed if ER or any above != 0)
--  10.  Radiation_Therapy(suppressed if ER or any above != 0)
--  11.  ECT              (suppressed if ER or any above != 0)
--  12.  Lab              (suppressed if ECT OR Radiation_Therapy or above != 0)
--  13.  Radiology        (suppressed if ECT OR Radiation_Therapy or above != 0)
--  14.  Ambulance        (suppressed if ECT OR Radiation_Therapy or above != 0)
--  15.  Miscellaneous    (suppressed if ECT OR Radiation_Therapy or above or Clinic != 0)
--  16.  Clinic           (suppressed if Lab OR Radiology or above != 0)
--  17.  OP_Default       (suppressed if Miscellaneous != 0 or most above != 0)
--  Special standalone (not in main tier chain):
--   Implants:     IIF([ER]=0, [Implants], 0)
--   Blood:        IIF([AS]=0 AND [ER]=0, [Blood], 0)
--   Drugs:        IIF([Endoscopy]=0 AND [ER]=0 AND [ECT]=0 AND [AS]=0, [Drugs], 0)
--   Provenge_Drugs: always passes (no suppression in #Step4)
--   COVID:        INDICATOR_FLAG, always passes
--=======================================================================

-- BLOCK 1: #bRanked
-- One ROW_NUMBER() per MAX category, HYBRID category, WINDOW_REDUCTION category,
-- and INDICATOR_FLAG category.
-- Count: 7 MAX + 1 HYBRID + 1 WINDOW_REDUCTION + 1 INDICATOR_FLAG = 10 ROW_NUMBER() calls.
-- Source table: #Step3 (contains all LEAD slot columns AS1-AS10).
-- NOTE: #Step3 does NOT contain Sequence or Amount per se — it does contain Amount
-- (carried explicitly in its SELECT list). Sequence is NOT in #Step3.
-- We use EncounterID + RevenueCode + ProcedureCode + Amount as a composite join key
-- back to #Step2 to recover Sequence, Quantity, BillCharges.
SELECT
    b.*
    -- MAX categories: PARTITION BY EncounterID, one winner per encounter
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]           DESC, b.[Amount] DESC) AS rn_ER
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Endoscopy]    DESC, b.[Amount] DESC) AS rn_Endoscopy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Cath] DESC, b.[Amount] DESC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA]         DESC, b.[Amount] DESC) AS rn_PTCA
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife]  DESC, b.[Amount] DESC) AS rn_Gamma_Knife
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Clinic]       DESC, b.[Amount] DESC) AS rn_Clinic
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ECT]          DESC, b.[Amount] DESC) AS rn_ECT
    -- HYBRID category: PARTITION BY EncounterID + ServiceDate
    -- Chemotherapy: MAX in #Step3_1 (per date), SUM in #Step3_2 (across dates) => HYBRID
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Chemotherapy] DESC, b.[Amount] DESC) AS rn_Chemotherapy
    -- WINDOW_REDUCTION: AS slots AS1-AS10, PARTITION BY EncounterID only
    -- ORDER BY SUM of ALL slot columns
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY (ISNULL(b.[AS1],0)+ISNULL(b.[AS2],0)+ISNULL(b.[AS3],0)+ISNULL(b.[AS4],0)
                   +ISNULL(b.[AS5],0)+ISNULL(b.[AS6],0)+ISNULL(b.[AS7],0)+ISNULL(b.[AS8],0)
                   +ISNULL(b.[AS9],0)+ISNULL(b.[AS10],0)) DESC
                  , b.[Amount] DESC) AS rn_AS
    -- INDICATOR_FLAG: COVID binary 0/1, PARTITION BY EncounterID, $0 LinePayment
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]        DESC, b.[Amount] DESC) AS rn_COVID
INTO #bRanked
FROM #Step3 b;

-- BLOCK 2: #bSlots
-- Extracts slot values from the rank-1 row for the AS WINDOW_REDUCTION category.
-- LEAD partition is EncounterID only => GROUP BY EncounterID only.
-- Uses GROUP BY + MAX(CASE...) pattern — no WHERE rn=1 which can produce duplicates.
SELECT
    [EncounterID]
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS1],  0) ELSE 0 END) AS AS1
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS2],  0) ELSE 0 END) AS AS2
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS3],  0) ELSE 0 END) AS AS3
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS4],  0) ELSE 0 END) AS AS4
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS5],  0) ELSE 0 END) AS AS5
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS6],  0) ELSE 0 END) AS AS6
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS7],  0) ELSE 0 END) AS AS7
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS8],  0) ELSE 0 END) AS AS8
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS9],  0) ELSE 0 END) AS AS9
    , MAX(CASE WHEN rn_AS = 1 THEN ISNULL([AS10], 0) ELSE 0 END) AS AS10
INTO #bSlots
FROM #bRanked
GROUP BY [EncounterID];

-- BLOCK 3: #LineBreakdown
-- Main line-level breakdown output. One row per charge line per encounter.
-- #Step3 does NOT contain Sequence, Quantity, or BillCharges.
-- These are recovered from #Step2 via LEFT JOIN on EncounterID + RevenueCode
-- + ProcedureCode + Amount (composite key that identifies the originating line).
-- BillCharges is a display-only column in this script (EPS does not exist here);
-- it is recovered to provide auditor context.
-- Sequence is recovered to enable ORDER BY and auditor traceability.
-- SELECT DISTINCT is used because the join to #Step2 on a composite non-unique
-- key can produce duplicates when multiple #Step3 rows share the same
-- EncounterID + RevenueCode + ProcedureCode + Amount values.
SELECT DISTINCT
    b.[EncounterID]
    , src.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                           AS [BilledAmount]
    , src.[Quantity]
    , src.[BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Hierarchy order exactly matches #Step4 IIF chain.
    -- MAX:    IIF(rn=1, name, name_Non_Winner)
    -- HYBRID: IIF(rn=1, name, name_Non_Winner)  [rn partitioned by EncounterID+ServiceDate]
    -- SUM:    flat label (all matching lines pay)
    -- WINDOW_REDUCTION: rank-based slot label
    -- INDICATOR_FLAG: placed after OP_Default and Suppressed_By_Hierarchy
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- TIER 1: Gamma_Knife (MAX)
        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN IIF(b.rn_Gamma_Knife = 1, 'Gamma_Knife', 'Gamma_Knife_Non_Winner')

        -- TIER 2: PTCA (MAX — suppressed if Gamma_Knife != 0)
        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN IIF(b.rn_PTCA = 1, 'PTCA', 'PTCA_Non_Winner')

        -- TIER 3: Cardiac_Cath (MAX — suppressed if Gamma_Knife OR PTCA != 0)
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- TIER 4: Endoscopy (MAX — suppressed if Gamma_Knife OR PTCA != 0)
        WHEN s4.[Endoscopy] != 0
         AND b.[Endoscopy] > 0
            THEN IIF(b.rn_Endoscopy = 1, 'Endoscopy', 'Endoscopy_Non_Winner')

        -- TIER 5: AS (WINDOW_REDUCTION — suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR Endoscopy != 0)
        WHEN s4.[AS] != 0
         AND (  ISNULL(b.[AS1],0)+ISNULL(b.[AS2],0)+ISNULL(b.[AS3],0)+ISNULL(b.[AS4],0)
              + ISNULL(b.[AS5],0)+ISNULL(b.[AS6],0)+ISNULL(b.[AS7],0)+ISNULL(b.[AS8],0)
              + ISNULL(b.[AS9],0)+ISNULL(b.[AS10],0)) > 0
            THEN CASE
                    WHEN b.rn_AS BETWEEN 1 AND 10 THEN 'AS_Ambulatory_Surgery'
                    ELSE 'AS_Ambulatory_Surgery_Beyond_Max'
                 END

        -- TIER 6: PET_Scan (SUM — suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS != 0)
        WHEN s4.[PET_Scan] != 0
         AND b.[PET_Scan] > 0
            THEN 'PET_Scan'

        -- TIER 7: ER (MAX — suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS OR PET_Scan != 0)
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- TIER 8: Chemotherapy (HYBRID — suppressed if ER or above != 0)
        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN IIF(b.rn_Chemotherapy = 1, 'Chemotherapy', 'Chemotherapy_Non_Winner')

        -- TIER 9: IV_Therapy (SUM — suppressed if ER or above != 0)
        WHEN s4.[IV_Therapy] != 0
         AND b.[IV_Therapy] > 0
            THEN 'IV_Therapy'

        -- TIER 10: Radiation_Therapy (SUM — suppressed if ER or above != 0)
        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'Radiation_Therapy'

        -- TIER 11: ECT (MAX — suppressed if ER or above != 0)
        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN IIF(b.rn_ECT = 1, 'ECT', 'ECT_Non_Winner')

        -- TIER 12: Lab (SUM — suppressed if ECT OR Radiation_Therapy or above != 0)
        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Lab'

        -- TIER 13: Radiology (SUM — suppressed if ECT OR Radiation_Therapy or above != 0)
        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Radiology'

        -- TIER 14: Ambulance (SUM — suppressed if ECT OR Radiation_Therapy or above != 0)
        WHEN s4.[Ambulance] != 0
         AND b.[Ambulance] > 0
            THEN 'Ambulance'

        -- TIER 15: Miscellaneous (SUM — suppressed if ECT OR Radiation_Therapy or Clinic or above != 0)
        WHEN s4.[Miscellaneous] != 0
         AND b.[Miscellaneous] > 0
            THEN 'Miscellaneous'

        -- TIER 16: Clinic (MAX — suppressed if Lab OR Radiology or above != 0)
        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN IIF(b.rn_Clinic = 1, 'Clinic', 'Clinic_Non_Winner')

        -- TIER 17: OP_Default (SUM — suppressed if Miscellaneous != 0 or most above != 0)
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- Standalone categories not in main tier chain (suppression per #Step4 IIF):
        -- Implants: IIF([ER]=0, [Implants], 0) — s4.[Implants] reflects this already
        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Implants'

        -- Blood: IIF([AS]=0 AND [ER]=0, [Blood], 0) — s4.[Blood] reflects this already
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- Drugs: IIF([Endoscopy]=0 AND [ER]=0 AND [ECT]=0 AND [AS]=0, [Drugs], 0)
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- Provenge_Drugs: no suppression in #Step4, always passes
        WHEN s4.[Provenge_Drugs] != 0
         AND b.[Provenge_Drugs] > 0
            THEN 'Provenge_Drugs'

        -- Suppressed: line has a non-zero category value but #Step4 hierarchy zeroed it
        WHEN (
              ISNULL(b.[ER],0)
            + ISNULL(b.[Endoscopy],0)
            + ISNULL(b.[Cardiac_Cath],0)
            + ISNULL(b.[PTCA],0)
            + ISNULL(b.[Gamma_Knife],0)
            + ISNULL(b.[Clinic],0)
            + ISNULL(b.[ECT],0)
            + ISNULL(b.[Chemotherapy],0)
            + ISNULL(b.[OP_Default],0)
            + ISNULL(b.[Implants],0)
            + ISNULL(b.[Blood],0)
            + ISNULL(b.[Drugs],0)
            + ISNULL(b.[Provenge_Drugs],0)
            + ISNULL(b.[IV_Therapy],0)
            + ISNULL(b.[Lab],0)
            + ISNULL(b.[Radiology],0)
            + ISNULL(b.[Radiation_Therapy],0)
            + ISNULL(b.[PET_Scan],0)
            + ISNULL(b.[Ambulance],0)
            + ISNULL(b.[Miscellaneous],0)
            + ISNULL(b.[COVID],0)
            + ISNULL(b.[AS1],0)+ISNULL(b.[AS2],0)+ISNULL(b.[AS3],0)
            + ISNULL(b.[AS4],0)+ISNULL(b.[AS5],0)+ISNULL(b.[AS6],0)
            + ISNULL(b.[AS7],0)+ISNULL(b.[AS8],0)+ISNULL(b.[AS9],0)+ISNULL(b.[AS10],0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- INDICATOR_FLAG: COVID (binary 0/1, placed after all dollar and suppressed categories)
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula for this line.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Gamma_Knife] != 0 AND b.[Gamma_Knife] > 0
            THEN 'Contracted flat rate per contract year (Gamma Knife: Rev 360, CPT 61796-61800/63620/63621/G0339/G0340)'

        WHEN s4.[PTCA] != 0 AND b.[PTCA] > 0
            THEN 'Contracted flat rate per contract year (PTCA: Rev 360/361/369/480/481/490/499/750/790, CPT 92920-92944/C9600-C9608)'

        WHEN s4.[Cardiac_Cath] != 0 AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract year (Cardiac Cath: Rev 360/361/369/480/481/490/499/750/790, CPT 93451-93568/93580-93583/93503/93505/93571/93572)'

        WHEN s4.[Endoscopy] != 0 AND b.[Endoscopy] > 0
            THEN 'Contracted flat rate per contract year (Endoscopy: Rev 360/361/369/480/481/490/499/750/790, CPT 45378/45380/45381/45384/45385/G0105/G0121)'

        WHEN s4.[AS] != 0
         AND (  ISNULL(b.[AS1],0)+ISNULL(b.[AS2],0)+ISNULL(b.[AS3],0)+ISNULL(b.[AS4],0)
              + ISNULL(b.[AS5],0)+ISNULL(b.[AS6],0)+ISNULL(b.[AS7],0)+ISNULL(b.[AS8],0)
              + ISNULL(b.[AS9],0)+ISNULL(b.[AS10],0)) > 0
            THEN CASE
                    WHEN b.rn_AS = 1  THEN 'AS grouper flat rate / 1 — 1st procedure, full contracted rate (Rev 360/361/369/481/490/499/750/790)'
                    WHEN b.rn_AS = 2  THEN 'AS grouper flat rate / 2 — 2nd procedure, 50% reduction'
                    WHEN b.rn_AS BETWEEN 3 AND 10
                                      THEN 'AS grouper flat rate / 2 — 3rd+ procedure, 50% reduction'
                    ELSE 'Beyond 10th AS procedure — $0'
                 END

        WHEN s4.[PET_Scan] != 0 AND b.[PET_Scan] > 0
            THEN 'Contracted flat rate per contract year per CPT (PET Scan: Rev 404, specific PET CPT codes)'

        WHEN s4.[ER] != 0 AND b.[ER] > 0
            THEN 'Contracted flat rate per contract year (ER: Rev 450/451/452/459 or Rev 456)'

        WHEN s4.[Chemotherapy] != 0 AND b.[Chemotherapy] > 0
            THEN 'Contracted per diem per contract year (Chemotherapy: Rev 331/332/335)'

        WHEN s4.[IV_Therapy] != 0 AND b.[IV_Therapy] > 0
            THEN 'RBRVS Rate x multiplier x Quantity; fallback = Amount x 80% (IV Therapy: Rev 260/269)'

        WHEN s4.[Radiation_Therapy] != 0 AND b.[Radiation_Therapy] > 0
            THEN 'Contracted flat rate per contract year x Quantity (Radiation Therapy: Rev 330/333/339)'

        WHEN s4.[ECT] != 0 AND b.[ECT] > 0
            THEN 'Contracted flat rate per contract year (ECT: Rev 901, CPT 90870)'

        WHEN s4.[Lab] != 0 AND b.[Lab] > 0
            THEN 'Capitation rate $0.01 per line (Lab: Rev 300-314/319/923-925)'

        WHEN s4.[Radiology] != 0 AND b.[Radiology] > 0
            THEN 'Radiology fee schedule Rate x 1.60 x Quantity; fallback = Amount x 50%; zero-pay list = $0 (Rev 320-329/340-349/350-359/400-409/610-619)'

        WHEN s4.[Ambulance] != 0 AND b.[Ambulance] > 0
            THEN 'Pct of charges: Amount x 84% (Ambulance: Rev 540/542/543/546/547/548/549)'

        WHEN s4.[Miscellaneous] != 0 AND b.[Miscellaneous] > 0
            THEN 'Contracted rate table per CPT per contract year x Quantity (Miscellaneous: specific CPT list 90785-99443)'

        WHEN s4.[Clinic] != 0 AND b.[Clinic] > 0
            THEN 'Capitation rate $0.01 per line (Clinic: Rev 510-529)'

        WHEN s4.[OP_Default] != 0 AND b.[OP_Default] > 0
            THEN 'RBRVS Rate x multiplier x Quantity; fallback = Amount x 80% — OP Default (specific Rev code list, CPT not matching higher-tier category)'

        WHEN s4.[Implants] != 0 AND b.[Implants] > 0
            THEN 'Pct of charges: Amount x 36% (Implants: Rev 274/275/276/278; excl device pass-through codes C1724-C2630)'

        WHEN s4.[Blood] != 0 AND b.[Blood] > 0
            THEN 'Pct of charges: Amount x 100% (Blood: Rev 380-390/386 with specific blood product CPTs)'

        WHEN s4.[Drugs] != 0 AND b.[Drugs] > 0
            THEN 'AWP Source Rate x 80-84% x Quantity by contract period (Drugs: Rev 343/344/634/635/636; excl Modifier FB/SL)'

        WHEN s4.[Provenge_Drugs] != 0 AND b.[Provenge_Drugs] > 0
            THEN 'Contracted flat rate per contract year (Provenge: Rev 636, CPT Q2043)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag — binary 0/1 value, no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pricing pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:              IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    -- HYBRID:           IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    --                   [rn partitioned by EncounterID+ServiceDate; each date winner pays]
    -- SUM:              IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- WINDOW_REDUCTION: slot-pivot from #bSlots keyed by EncounterID
    -- INDICATOR_FLAG:   $0 — never add b.[COVID] to LinePayment
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1, ISNULL(b.[Gamma_Knife], 0), 0), 0)
        + IIF(s4.[PTCA] != 0,
              IIF(b.rn_PTCA = 1, ISNULL(b.[PTCA], 0), 0), 0)
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1, ISNULL(b.[Cardiac_Cath], 0), 0), 0)
        + IIF(s4.[Endoscopy] != 0,
              IIF(b.rn_Endoscopy = 1, ISNULL(b.[Endoscopy], 0), 0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1, ISNULL(b.[ER], 0), 0), 0)
        + IIF(s4.[Clinic] != 0,
              IIF(b.rn_Clinic = 1, ISNULL(b.[Clinic], 0), 0), 0)
        + IIF(s4.[ECT] != 0,
              IIF(b.rn_ECT = 1, ISNULL(b.[ECT], 0), 0), 0)
          -- HYBRID category: IIF(rn=1) partitioned by EncounterID+ServiceDate
        + IIF(s4.[Chemotherapy] != 0,
              IIF(b.rn_Chemotherapy = 1, ISNULL(b.[Chemotherapy], 0), 0), 0)
          -- SUM categories: all matching lines pay
        + IIF(s4.[OP_Default] != 0,         ISNULL(b.[OP_Default], 0),         0)
        + IIF(s4.[Implants] != 0,            ISNULL(b.[Implants], 0),            0)
        + IIF(s4.[Blood] != 0,               ISNULL(b.[Blood], 0),               0)
        + IIF(s4.[Drugs] != 0,               ISNULL(b.[Drugs], 0),               0)
        + IIF(s4.[Provenge_Drugs] != 0,      ISNULL(b.[Provenge_Drugs], 0),      0)
        + IIF(s4.[IV_Therapy] != 0,          ISNULL(b.[IV_Therapy], 0),          0)
        + IIF(s4.[Lab] != 0,                 ISNULL(b.[Lab], 0),                 0)
        + IIF(s4.[Radiology] != 0,           ISNULL(b.[Radiology], 0),           0)
        + IIF(s4.[Radiation_Therapy] != 0,   ISNULL(b.[Radiation_Therapy], 0),   0)
        + IIF(s4.[PET_Scan] != 0,            ISNULL(b.[PET_Scan], 0),            0)
        + IIF(s4.[Ambulance] != 0,           ISNULL(b.[Ambulance], 0),           0)
        + IIF(s4.[Miscellaneous] != 0,       ISNULL(b.[Miscellaneous], 0),       0)
          -- WINDOW_REDUCTION: AS — each row gets its own rank's slot value from #bSlots pivot
        + IIF(s4.[AS] != 0,
              CASE b.rn_AS
                WHEN 1  THEN ISNULL(rd.[AS1],  0)
                WHEN 2  THEN ISNULL(rd.[AS2],  0)
                WHEN 3  THEN ISNULL(rd.[AS3],  0)
                WHEN 4  THEN ISNULL(rd.[AS4],  0)
                WHEN 5  THEN ISNULL(rd.[AS5],  0)
                WHEN 6  THEN ISNULL(rd.[AS6],  0)
                WHEN 7  THEN ISNULL(rd.[AS7],  0)
                WHEN 8  THEN ISNULL(rd.[AS8],  0)
                WHEN 9  THEN ISNULL(rd.[AS9],  0)
                WHEN 10 THEN ISNULL(rd.[AS10], 0)
                ELSE 0
              END,
              0)
          -- INDICATOR_FLAG: COVID — $0 contribution, never add b.[COVID] to LinePayment
      , 2)

    -- NCCI BUNDLED FLAG: no NCCI bundle step in this script — always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4 ON s4.[EncounterID]  = b.[EncounterID]
LEFT  JOIN #bSlots rd  ON rd.[EncounterID]  = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover Sequence, Quantity, BillCharges not present in #Step3.
-- Join on EncounterID + RevenueCode + ProcedureCode + Amount to identify the originating line.
-- DISTINCT on outer SELECT handles any residual duplicates from this join.
LEFT  JOIN #Step2  src ON src.[EncounterID]  = b.[EncounterID]
                       AND src.[RevenueCode]  = b.[RevenueCode]
                       AND src.[ProcedureCode]= b.[ProcedureCode]
                       AND src.[Amount]       = b.[Amount]
ORDER BY b.[EncounterID], src.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	, [Implants]
	+[Blood]	
	+[Drugs]
	+[Provenge_Drugs]
	+[Gamma_Knife]		
	+[PTCA]				
	+[Cardiac_Cath]	
	+[Endoscopy]
	+[AS]				
	+[PET_Scan]			
	+[ER]				
	+[Chemotherapy]
	+[IV_Therapy]		
	+[Radiation_Therapy]
	+[Lab]				
	+[Radiology]		
	+[Ambulance]
	+[Miscellaneous]
	+[Clinic]
	+[OP_Default]		
	+[ECT]
	as Price

INTO #Step5
FROM #Step4

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select
	x.*

	, y.[Price]
	, y.[Implants]
	, y.[Blood]	
	, y.[Drugs]	
	, y.[Provenge_Drugs]
	, y.[Gamma_Knife]			
	, y.[PTCA]				
	, y.[Cardiac_Cath]	
	, y.[Endoscopy]
	, y.[AS]				
	, y.[PET_Scan]			
	, y.[ER]				
	, y.[Chemotherapy]
	, Y.[IV_Therapy]		
	, y.[Radiation_Therapy]
	, y.[Lab]				
	, y.[Radiology]		
	, y.[Ambulance]
	, y.[Miscellaneous]
	, y.[Clinic]
	, y.[OP_Default]	
	, y.[COVID]
	, Y.[ECT]

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

INto #Step6
From [COL].[Data].[Demo] as x

	INner joIN #Step5 as y on x.[EncounterID] = y.[EncounterID]
	left joIN [COL].[Data].[Charges_With_CPT] as z on x.[EncounterID] = z.[EncounterID]

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

	, Round([Price], 2) as ExpectedPrice
	, Round([Price] - (cast(x.[OriginalPayment] as float)), 2) as Diff
	, Round((cast(x.[OriginalPayment] as float)/NULLIF([BillCharges], 0)) * 100, 2) as [% paid]
	, DATEDIFF(DAY, x.[ServiceDateFrom], GETDATE()) - 365 as DaysLeft
	
	, IIF(ISNULL(x.[Implants]			,0) > 0,      'Implants - '				+ Cast(x.[Implants]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Blood]				,0) > 0,      'Blood - '				+ Cast(x.[Blood]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Drugs]				,0) > 0,      'Drugs - '				+ Cast(x.[Drugs]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Provenge_Drugs]		,0) > 0,      'Provenge_Drugs - '		+ Cast(x.[Provenge_Drugs]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Gamma_Knife]			,0) > 0,      'Gamma_Knife - '			+ Cast(x.[Gamma_Knife]			as varchar) + ', ','')
	+IIF(ISNULL(x.[PTCA]				,0) > 0,      'PTCA - '					+ Cast(x.[PTCA]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Cardiac_Cath]		,0) > 0,      'Cardiac_Cath - '			+ Cast(x.[Cardiac_Cath]			as varchar) + ', ','')
	+IIF(ISNULL(x.[AS]					,0) > 0,      'AS - '					+ Cast(x.[AS]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Endoscopy]			,0) > 0,      'Endoscopy - '			+ Cast(x.[Endoscopy]			as varchar) + ', ','')
	+IIF(ISNULL(x.[PET_Scan]			,0) > 0,      'PET_Scan - '				+ Cast(x.[PET_Scan]				as varchar) + ', ','')
	+IIF(ISNULL(x.[ER]					,0) > 0,      'ER - '					+ Cast(x.[ER]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Chemotherapy]		,0) > 0,      'Chemotherapy - '			+ Cast(x.[Chemotherapy]			as varchar) + ', ','')
	+IIF(ISNULL(x.[IV_Therapy]			,0) > 0,      'IV Therapy - '			+ Cast(x.[IV_Therapy]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiation_Therapy]	,0) > 0,      'Radiation_Therapy - '	+ Cast(x.[Radiation_Therapy]	as varchar) + ', ','')
	+IIF(ISNULL(x.[Lab]					,0) > 0,      'Lab - '					+ Cast(x.[Lab]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiology]			,0) > 0,      'Radiology - '			+ Cast(x.[Radiology]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Ambulance]			,0) > 0,      'Ambulance - '			+ Cast(x.[Ambulance]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Miscellaneous]		,0) > 0,      'Miscellaneous - '		+ Cast(x.[Miscellaneous]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Clinic]				,0) > 0,      'Clinic - '				+ Cast(x.[Clinic]				as varchar) + ', ','')		
	+IIF(ISNULL(x.[ECT]					,0) > 0,      'ECT - '					+ Cast(x.[ECT]				as varchar) + ', ','')		
	+IIF(ISNULL(x.[OP_Default]			,0) > 0,      'OP_Default - '			+ Cast(x.[OP_Default]			as varchar) + ', ','')
	as ExpectedDetailed


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

INto #Step7
From #Step6 as x

	left joIN [PRS].[dbo].[PRS_Data] as p on x.[EncounterID] = p.[patient_id_real]

Order by Round([Price] - (cast(x.[OriginalPayment] as float)), 2) DESC

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*

  , [Status] = CASE
    WHEN (Diff IS NULL)                THEN 'Not Identified'
    WHEN (Diff < -500)                 THEN 'Accounts with Errors'      
    WHEN (Diff BETWEEN -500 AND 0.01)  THEN 'Paid Correctly'
    WHEN (Diff BETWEEN 0.01 AND 99.99) THEN 'Potential Projects'
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
    , 'NYP_COL_UHC_COM_OP'
    , GETDATE()
FROM #LineBreakdown lb
ORDER BY lb.[EncounterID], lb.[Sequence];

-- QUERY 2: Reconciliation -- line-level sum vs encounter-level Price.
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



-- 	DECLARE @DBName SYSNAME = DB_NAME();
-- EXEC Analytics.dbo.InsertScriptsStepFinal
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_UHC_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- --EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;