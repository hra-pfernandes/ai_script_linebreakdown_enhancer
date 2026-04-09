
--Script Created on 12.12.2024 by SC
--Updated Feeschedules(AWP, RAD, ZeroRAD) till 2024.03.31 by Naveen Abboju 07.21.2025

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

	and Payer01Name IN (
		'OXFORD FREEDOM',
		'OXFORD LIBERTY',
		'SHOP OXFORD LIBERTY',
		'OXFORD HMO')

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
	-- and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	-- AND AGE < 65

	AND x.ServiceDateFrom < '2026-01-01'

-- and x.EncounterID = '500055639568'

Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric

INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x

where x.[EncounterID] in (Select [EncounterID]
from #Step1)
--*************************************************************************************************************************************************************************************************************************************************************************************************
select x.*
into #modifier
from #Step1_Charges x
WHERE Modifier1 = '50'

--***********************************************************************************************************************************************************************************************************************************************************************************************************

insert into #Step1_Charges
select *
from #modifier;


--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]


	, [OP_Default] = CASE
	WHEN RevenueCode IN ('250','258','260','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 6.67 * Quantity), 2) 	
	WHEN RevenueCode IN ('250','258','260','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-06-30') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 6.67 * Quantity), 2) 	
	WHEN RevenueCode IN ('250','258','260','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 6.67 * Quantity), 2) 	
	WHEN RevenueCode IN ('250','258','260','280','289','390','391','392','399','404','410','412','413','419','420','421','422','423','424','429','430','431','432','433','434','439','440','441','442','443','444','449','460','469','470','471','472','479','480','482','483','489','510','512','513','545','720','721','722','724','729','730','731','732','739','740','761','762','771','820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','860','861','900','901','914','915','916','917','918','919','920','921','922','929','940','942','943','948','949') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 7.18 * Quantity), 2) 	
	ELSE 0
	END

	, M1.[RATE]

	, [Fee_Schedule] = CASE
	WHEN 1=1 THEN 0
	ELSE 0
	END

	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 1414
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 1541	
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 1664		
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 1884	
	WHEN RevenueCode IN ('450','451','452','459') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 2028 

	WHEN RevenueCode IN ('456') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 842
	WHEN RevenueCode IN ('456') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 918	
	WHEN RevenueCode IN ('456') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 991		
	WHEN RevenueCode IN ('456') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 1070
	WHEN RevenueCode IN ('456') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 1152 

	ELSE 0
	END

	, [AS] = CASE 
	WHEN RevenueCode IN ('360','361','369','481','490','499','750','759','790') 
	THEN (CASE

	WHEN Grouper.[ASC_Group] =  '0' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  2145
	WHEN Grouper.[ASC_Group] =  '1' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  2770
	WHEN Grouper.[ASC_Group] =  '2' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  3803
	WHEN Grouper.[ASC_Group] =  '3' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  4194
	WHEN Grouper.[ASC_Group] =  '4' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  5249
	WHEN Grouper.[ASC_Group] =  '5' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  5979
	WHEN Grouper.[ASC_Group] =  '6' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  6755
	WHEN Grouper.[ASC_Group] =  '7' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  8809
	WHEN Grouper.[ASC_Group] =  '8' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  8299
	WHEN Grouper.[ASC_Group] =  '9' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 10137
	WHEN Grouper.[ASC_Group] = '10' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 11939
	WHEN Grouper.[ASC_Group] = 'UL' AND ProcedureCode IN (SELECT [Code]
		FROM [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 2383
	
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) = '0' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 2574
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '1' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 3323
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '2' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 4563
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '3' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 5029
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '4' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 6300
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '5' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 7174
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '6' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 8104
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '7' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 10571
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '8' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 9959
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) =  '9' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 12165
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) = '10' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 14326
	WHEN IIF((y.[ServiceDateFrom] < '2023-01-01'), Grouper.[ASC_Group],ASCGroup2023.[ASC_Group]) = 'UL' AND (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 3054

	WHEN ASCGrouper.[ASC_Group] =  '0' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 2891
	WHEN ASCGrouper.[ASC_Group] =  '1' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 3732
	WHEN ASCGrouper.[ASC_Group] =  '2' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 5152
	WHEN ASCGrouper.[ASC_Group] =  '3' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 5650
	WHEN ASCGrouper.[ASC_Group] =  '4' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 7077
	WHEN ASCGrouper.[ASC_Group] =  '5' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 8057
	WHEN ASCGrouper.[ASC_Group] =  '6' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 9102
	WHEN ASCGrouper.[ASC_Group] =  '7' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 11872
	WHEN ASCGrouper.[ASC_Group] =  '8' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 11187
	WHEN ASCGrouper.[ASC_Group] =  '9' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 13664
	WHEN ASCGrouper.[ASC_Group] = '10' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 16090
	WHEN ASCGrouper.[ASC_Group] = 'UL' and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 3430

	WHEN ASCGrouper.[ASC_Group] =  '0' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 3111
	WHEN ASCGrouper.[ASC_Group] =  '1' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 4017
	WHEN ASCGrouper.[ASC_Group] =  '2' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 5516
	WHEN ASCGrouper.[ASC_Group] =  '3' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 6080
	WHEN ASCGrouper.[ASC_Group] =  '4' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 7617
	WHEN ASCGrouper.[ASC_Group] =  '5' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 8671
	WHEN ASCGrouper.[ASC_Group] =  '6' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 9796
	WHEN ASCGrouper.[ASC_Group] =  '7' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 12777
	WHEN ASCGrouper.[ASC_Group] =  '8' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 12040
	WHEN ASCGrouper.[ASC_Group] =  '9' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 14705
	WHEN ASCGrouper.[ASC_Group] = '10' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 17316
	WHEN ASCGrouper.[ASC_Group] = 'UL' and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 3692		
	ELSE 0
	END)	
	ELSE 0
	END

	, [Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ((ProcedureCodeNumeric between 93451 and 93464) or (ProcedureCodeNumeric between 93530 and 93533) or (ProcedureCodeNumeric between 93561 and 93568) or (ProcedureCodeNumeric between 93580 and 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 14126
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ((ProcedureCodeNumeric between 93451 and 93464) or (ProcedureCodeNumeric between 93530 and 93533) or (ProcedureCodeNumeric between 93561 and 93568) or (ProcedureCodeNumeric between 93580 and 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 15397	
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ((ProcedureCodeNumeric between 93451 and 93464) or (ProcedureCodeNumeric between 93530 and 93533) or (ProcedureCodeNumeric between 93561 and 93568) or (ProcedureCodeNumeric between 93580 and 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 16629		
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ((ProcedureCodeNumeric between 93451 and 93464) or (ProcedureCodeNumeric between 93530 and 93533) or (ProcedureCodeNumeric between 93561 and 93568) or (ProcedureCodeNumeric between 93580 and 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 17959		
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ((ProcedureCodeNumeric between 93451 and 93464) or (ProcedureCodeNumeric between 93530 and 93533) or (ProcedureCodeNumeric between 93561 and 93568) or (ProcedureCodeNumeric between 93580 and 93583) or (ProcedureCode IN ('93503','93505','93571','93572'))) and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 19327		
	ELSE 0
	END
	
	, [Endoscopy] = CASE
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ProcedureCode IN ('45378','45380','45381','45384','45385','G0105','G0121') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 4859 		
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ProcedureCode IN ('45378','45380','45381','45384','45385','G0105','G0121') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 5229 	
	ELSE 0
	END

	, [PTCA] = CASE
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ProcedureCode in ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 33882
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ProcedureCode in ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 36931	
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ProcedureCode in ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 39886		
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ProcedureCode in ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 43077	
	WHEN RevenueCode IN ('360','361','369','480','481','490','499','750','790') and ProcedureCode in ('92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 46358 	
	ELSE 0
	END 

	, [Gamma_Knife] = CASE
	WHEN RevenueCode IN ('360') and ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN  86480
	WHEN RevenueCode IN ('360') and ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN  94263	
	WHEN RevenueCode IN ('360') and ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 101805		
	WHEN RevenueCode IN ('360') and ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 109949
	WHEN RevenueCode IN ('360') and ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 118327 
	ELSE 0
	END 


	, [Chemotherapy] = CASE
	WHEN RevenueCode in ('331','332','335') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 1184.830000
	WHEN RevenueCode in ('331','332','335') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 1291.464700
	WHEN RevenueCode in ('331','332','335') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 1394.781876 
	WHEN RevenueCode in ('331','332','335') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 1506.3644261 
	WHEN RevenueCode in ('331','332','335') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 1621 
	ELSE 0
	END

	, [IV_Therapy] = CASE
	WHEN RevenueCode IN ('260','269') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 6.67), 2) * Quantity	
	WHEN RevenueCode IN ('260','269') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-06-30') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 6.67), 2) * Quantity	
	WHEN RevenueCode IN ('260','269') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 6.67), 2) * Quantity	
	WHEN RevenueCode IN ('260','269') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN ROUND(IIF(M1.[RATE] is null, [Amount] * 0.80, M1.[RATE] * 6.95), 2) * Quantity	
	ELSE 0 
	END

	, [Radiation_Therapy] = CASE
	WHEN RevenueCode in ('330','333','339') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 1723 * Quantity
	WHEN RevenueCode in ('330','333','339') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 1878 * Quantity	
	WHEN RevenueCode in ('330','333','339') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 2028 * Quantity	
	WHEN RevenueCode in ('330','333','339') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 2191 * Quantity		
	WHEN RevenueCode in ('330','333','339') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 2357 * Quantity		
	ELSE 0
	END

 
	, [Radiology] = CASE
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN IIF(RAD0720.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(RAD0720.[SOURCE_FEE] * 1.60 * Quantity, 2))      			
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN IIF(RAD0721.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(RAD0721.[SOURCE_FEE] * 1.60 * Quantity, 2))
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN IIF(RAD24.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(RAD24.[SOURCE_FEE] * 1.60 * Quantity, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN IIF(RAD24.[SOURCE_FEE] IS NULL, IIF(Z1.[CPT] IS NOT NULL, 0, Round(x.Amount * 0.50, 2)), Round(RAD24.[SOURCE_FEE] * 1.60 * Quantity, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','329','340','341','342','349','350','351','352','359','400','401','402','403','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2024-07-01' and '2024-12-31') THEN IIF(RAD.[SOURCE_FEE]   IS NULL, IIF(Z1.[CPT] IS NOT NULL, 0, Round(x.Amount * 0.50, 2)), Round(RAD.[SOURCE_FEE]   * 1.60 * Quantity, 2)) --- Partitioned contractyear due to addition of new Radiology schedule		
	ELSE 0
	END


	, [Lab] = CASE 	--Added capitation to labs by putting them in 0.01 as of Ricardos's feedback from hospital. 5.28.2025 SC
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN IIF(LAB0720.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB0720.[SOURCE_FEE] * 1.20 * Quantity, 2)) 
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN IIF(LAB0721.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB0721.[SOURCE_FEE] * 1.20 * Quantity, 2))
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN IIF(LAB24.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB24.[SOURCE_FEE] * 1.20 * Quantity, 2))	
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN IIF(LAB24.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB24.[SOURCE_FEE] * 1.20 * Quantity, 2))	
	-- WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN IIF(LAB24.[SOURCE_FEE] IS NULL, Round(x.Amount * 0.50, 2), Round(LAB24.[SOURCE_FEE] * 1.20 * Quantity, 2))	
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') THEN 0.01
	ELSE 0
	END

	, [PET_Scan] = CASE
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 3348
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 3649	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') and (y.[ServiceDateFrom] between '2022-07-01' and '2024-06-30') THEN 3941	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78608','78609','78811','78812','78813','78814','78815','78816') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 4580	

	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78459') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 4605
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78459') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 5019	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78459') and (y.[ServiceDateFrom] between '2022-07-01' and '2024-06-30') THEN 5421	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78459') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 6301	

	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78491') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 2733
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78491') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 2979	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78491') and (y.[ServiceDateFrom] between '2022-07-01' and '2024-06-30') THEN 3217		
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78491') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 3739		
	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78492') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 4603
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78492') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 5017	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78492') and (y.[ServiceDateFrom] between '2022-07-01' and '2024-06-30') THEN 5419	
	WHEN RevenueCode IN ('404') and ProcedureCode IN ('78492') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 6299	

	ELSE 0
	END
       
	, [Ambulance] = CASE
	WHEN RevenueCode IN ('540','542','543','546','547','548','549') THEN Round([Amount] * 0.80, 2)
	ELSE 0
	END

	, [Drugs] = CASE
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2020-07-01' and '2020-09-30') THEN Round(AWP0720.[Source Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2020-10-01' and '2020-12-31') THEN Round(AWP1020.[Source Rate] * 0.80 * Quantity, 2)	
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN Round(AWP0121.[Source Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2021-04-01' and '2022-06-30') THEN Round(AWP0421.[Source Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2022-07-01' and '2022-12-31') THEN Round(AWP0122.[Source Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2023-01-01' and '2023-03-31') THEN Round(AWP.[Source_Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-06-30') THEN Round(AWP.[Source_Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2023-07-01' and '2023-09-30') THEN Round(AWP.[Source_Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2023-10-01' and '2023-12-31') THEN Round(AWP.[Source_Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-03-31') THEN Round(AWP.[Source_Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2024-04-01' and '2024-06-30') THEN Round(AWP.[Source_Rate] * 0.80 * Quantity, 2)
	WHEN RevenueCode IN ('343','344','634','635','636') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN Round(AWP.[Source_Rate] * 0.80 * Quantity, 2)
	ELSE 0
	END

	, [Provenge_Drugs] = CASE			
	WHEN RevenueCode IN ('636') and x.[ProcedureCode] IN ('Q2043') and (y.[ServiceDateFrom] between '2020-07-01' and '2021-06-30') THEN 61126
	WHEN RevenueCode IN ('636') and x.[ProcedureCode] IN ('Q2043') and (y.[ServiceDateFrom] between '2021-07-01' and '2022-06-30') THEN 66627	
	WHEN RevenueCode IN ('636') and x.[ProcedureCode] IN ('Q2043') and (y.[ServiceDateFrom] between '2022-07-01' and '2023-06-30') THEN 71957	
	WHEN RevenueCode IN ('636') and x.[ProcedureCode] IN ('Q2043') and (y.[ServiceDateFrom] between '2023-07-01' and '2024-06-30') THEN 71957	
	WHEN RevenueCode IN ('636') and x.[ProcedureCode] IN ('Q2043') and (y.[ServiceDateFrom] between '2024-07-01' and '9999-12-31') THEN 71957
	ELSE 0
	END


	, [Implants] = CASE
	WHEN RevenueCode in ('274','275','276','278') AND x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630')  THEN Round(Amount * 0.36, 2)
	ELSE 0
	END

	, [Blood] = CASE
	WHEN ((RevenueCode in ('380','381','382','383','384','385','386','387','389','390')) or (ProcedureCode LIKE 'P901%' or ProcedureCode LIKE 'P902%' or ProcedureCode LIKE 'P903%' or ProcedureCode LIKE 'P904%' or ProcedureCode LIKE 'P905%' or ProcedureCode IN ('P9060')) or (RevenueCode in ('386') and (ProcedureCode IN ('J7178','J7180','J7181','J7182','J7183','J7185','J7186','J7187','J7189','J7190','J7191','J7192','J7193','J7194','J7195','J7196','J7197','J7198','J7199','J7200','J7201')))) THEN Round(Amount * 1.00, 2)
	ELSE 0
	END

	, [IOP] = CASE
	WHEN RevenueCode IN ('905','906','945') and ProcedureCode IN ('90899') THEN Round(x.Amount * 0.80, 2)
	ELSE 0
	END

	, [Clinic] = CASE
	WHEN (RevenueCode between 510 and 529) THEN 0.01
	ELSE 0
	END

	, case
	WHEN (y.[ServiceDateFrom] between '2020-01-27' and '2020-03-31') and [dp].[Dx] like '%B97.29%'	THEN 1
	WHEN (y.[ServiceDateFrom] between '2020-04-01' and '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1
	WHEN (y.[ServiceDateFrom] > '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1 --and [dp].[Px] is not null
	ELSE 0
	END As [COVID]

	, [CPT_91040]= CASE
	WHEN ProcedureCode = '91040' THEN 1
	ELSE 0
	END

	, [CPT_43235]= CASE
	WHEN ProcedureCode = '43235' THEN 1
	ELSE 0
	END
Into #Step2
From #Step1_Charges as x


	LEFT JOIN [COL].[Data].[Demo] as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px] as dp on x.[EncounterID] = dp.[EncounterID] and x.[Sequence] = dp.[Sequence]

	LEFT JOIN [QNS].[FSG].[Oxford-United ASC Grouper (2020.07.01)]							as Grouper ON Grouper.[Code] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[dbo].[Oxford_United_ASC_Grouper (2023.01.01)]					as ASCGroup2023 ON ASCGroup2023.[Code] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[FSG].[Oxford-UHC_ASC_Grouper(23-25)]								as ASCGrouper ON ASCGrouper.[Code] = x.[ProcedureCode] and x.ServiceDateFrom between ASCGrouper.[StartDate] and ASCGrouper.[EndDate]

	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2020.07.01)]								    as AWP0720 ON CAST(AWP0720.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2020.10.01)]								    as AWP1020 ON CAST(AWP1020.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2021.01.01)]								    as AWP0121 ON CAST(AWP0121.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2021.04.01)]								    as AWP0421 ON CAST(AWP0421.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United AWP (2022.01.01)]								    as AWP0122 ON CAST(AWP0122.[CODE] as nvarchar(max)) = x.[ProcedureCode]
	LEFT JOIN [Analytics].[FSG].[Oxford-United AWP]							   				as AWP ON AWP.[CODE] = x.[ProcedureCode] and x.ServiceDateFrom between AWP.StartDate and AWP.EndDate


	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2019.07.01)]			as LAB0719 ON LAB0719.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2020.07.01)]			as LAB0720 ON LAB0720.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2021.07.01)]			as LAB0721 ON LAB0721.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Laboratory Fee Schedule 1089 (2022.01.01)]			as LAB0122 ON LAB0122.[CPT] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedLaboratoryFeeSchedule-2024]					AS LAB24 ON LAB24.[CPT] = X.[ProcedureCode] and x.ServiceDateFrom between LAB24.StartDate and LAB24.EndDate

	LEFT JOIN [QNS].[FSG].[Oxford-United Radiology Fee Schedule 12581 (2019.07.01)]			as RAD0719 ON RAD0719.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Radiology Fee Schedule 12581 (2020.07.01)]			as RAD0720 ON RAD0720.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Oxford-United Radiology Fee Schedule 12581 (2021.07.01)]			as RAD0721 ON RAD0721.[CPT] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedRadiologyFeeSchedule-2024]					as RAD24 ON RAD24.[CPT] = x.[ProcedureCode] and x.ServiceDateFrom between RAD24.StartDate and RAD24.EndDate

	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedRadiologyFeeSchedule]							as RAD ON RAD.[CPT] = x.[ProcedureCode] --and x.ServiceDateFrom between RAD.StartDate and RAD.EndDate
	LEFT JOIN [Analytics].[FSG].[Oxford-UnitedRadiology-ZeroPay]							AS Z1 ON Z1.[CPT] = x.ProcedureCode --and x.ServiceDateFrom between Z1.StartDate and Z1.EndDate


	LEFT JOIN [Analytics].[FSG].[MedicareFeeSchedule(RBRVS)_Locality1] 						AS M1 ON M1.[CPT_CODE] = x.[ProcedureCode] AND (y.ServiceDateFrom between M1.[StartDate] and M1.[EndDate])

ORDER BY [EncounterID], x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate], [RevenueCode], [ProcedureCode], [Amount], [OriginalPayment]
	, [OP_Default]	= IIF([ER]=0 and [AS]=0 and [Cardiac_Cath]=0 AND [IV_Therapy]=0 and [PTCA]=0 and [Gamma_Knife]=0 and [Implants]=0 and [Blood]=0 and [Drugs]=0 and [Provenge_Drugs]=0 and [Chemotherapy]=0 and [Lab]=0 and [Radiology]=0 and [Radiation_Therapy]=0 and [PET_Scan]=0 and [Ambulance]=0 and [IOP]=0 and [Fee_Schedule]=0 and [Clinic]=0, [OP_Default], 0)
	, [Fee_Schedule] = IIF([ER]=0 and [AS]=0 and [Cardiac_Cath]=0 AND [IV_Therapy]=0 and [PTCA]=0 and [Gamma_Knife]=0 and [Implants]=0 and [Blood]=0 and [Drugs]=0 and [Provenge_Drugs]=0 and [Chemotherapy]=0 and [Lab]=0 and [Radiology]=0 and [Radiation_Therapy]=0 and [PET_Scan]=0 and [Ambulance]=0 and [IOP]=0 and [Clinic]=0, [Fee_Schedule], 0)
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
	, [Drugs]			=iif( (modifier1 not in ('FB','SL') or Modifier1 IS NULL), [Drugs], 0)
	, [Provenge_Drugs]
	, [Chemotherapy]
	, [Lab]
	, [Radiology]
	, [Radiation_Therapy]
	, [PET_Scan]
	, [Ambulance]
	, [IV_Therapy]
	, [IOP]
	, [Clinic]
	, [COVID]
	, [CPT_91040]
	, [CPT_43235]

Into #Step3
From #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]

	, SUM([OP_Default])				as [OP_Default]
	, SUM([Fee_Schedule])			as [Fee_Schedule]
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
	, MAX([Lab])						as [Lab]
	, SUM([Radiology])				as [Radiology]	
	, SUM([Radiation_Therapy])		as [Radiation_Therapy]		
	, SUM([PET_Scan])				as [PET_Scan]
	, SUM([Ambulance])				as [Ambulance]		
	, SUM([IOP])						as [IOP]
	, MAX([Clinic])					as [Clinic]
	, MAX([COVID])					as [COVID]	
	, SUM([IV_Therapy])				AS [IV_Therapy]
	, MAX([CPT_91040])					as [CPT_91040]
	, MAX([CPT_43235])					as [CPT_43235]
INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, SUM([OP_Default])			as [OP_Default]
	, SUM([Fee_Schedule])		as [Fee_Schedule]	
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
	, MAX([Lab])					as [Lab]	
	, SUM([Radiology])			as [Radiology]	
	, SUM([Radiation_Therapy])	as [Radiation_Therapy]	
	, SUM([PET_Scan])			as [PET_Scan]
	, SUM([Ambulance])			as [Ambulance]	
	, SUM([IOP])					as [IOP]
	, MAX([Clinic])				as [Clinic]
	, MAX([COVID])				as [COVID]	
	, SUM([IV_Therapy])				AS [IV_Therapy]
	, MAX([CPT_91040])					as [CPT_91040]
	, MAX([CPT_43235])					as [CPT_43235]

INTO #Step3_2
FROM #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	
	, [Implants]				
	, [Blood]				=IIF([AS] = 0 and [ER]=0, [Blood], 0)
	, [Drugs]				= IIF([ER]= 0 and [Endoscopy]=0 and [AS]=0, [Drugs], 0)
	, [Provenge_Drugs]
	, [Gamma_Knife]	
	, [PTCA]					= IIF([Gamma_Knife]=0, [PTCA], 0)
	, [Cardiac_Cath]			= IIF([Gamma_Knife]=0 and [PTCA]=0, [Cardiac_Cath], 0)
	, [Endoscopy]			= IIF([Gamma_Knife]=0 and [PTCA]=0, [Endoscopy], 0)
	, [AS]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [Endoscopy]=0, [AS], 0)
	, [PET_Scan]				= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0, [PET_Scan], 0)
	, [ER]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0, [ER], 0)
	, [Chemotherapy]			= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0, [Chemotherapy], 0)
	, [IV_Therapy]			= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0, [IV_Therapy], 0)
	, [Radiation_Therapy]	= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0, [Radiation_Therapy], 0)
	, [IOP]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0 and [Radiation_Therapy]=0 , [IOP], 0)		
	, [Lab]					= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0 and [Radiation_Therapy]=0 and [IOP]=0, [Lab], 0)
	, [Radiology]			= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0 and [Radiation_Therapy]=0 and [IOP]=0, [Radiology], 0)
	, [Ambulance]			= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0 and [Radiation_Therapy]=0 and [IOP]=0, [Ambulance], 0)
	, [Fee_Schedule]			= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0 and [Radiation_Therapy]=0 and [IOP]=0 and [Lab]=0 and [Radiology]=0, [Fee_Schedule], 0)	
	, [Clinic]				= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0 and [Radiation_Therapy]=0 and [IOP]=0 and [Lab]=0 and [Radiology]=0, [Clinic], 0)
	
	, [OP_Default]			= IIF([Gamma_Knife]=0 and [PTCA]=0 and [Cardiac_Cath]=0 and [AS]=0 and [PET_Scan]=0 and [ER]=0 and [Chemotherapy]=0 and [Radiation_Therapy]=0 and [IOP]=0, [OP_Default], 0)
	, [COVID]

	, [CPT_91040]
	, [CPT_43235]

	, [Both_91040&43235] = IIF([CPT_43235]=1 AND [CPT_91040]=1,1,0)
INTO #Step4
FROM #Step3_2

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (post-LEAD slot computation, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
--           #Step2 joined for Sequence, Quantity, BillCharges (not present in #Step3).
--
-- COLUMN SURVIVAL TRACE:
--   #Step3 is built from #Step2 with an EXPLICIT column list.
--   Confirmed present in #Step3: EncounterID, ServiceDate, RevenueCode,
--   ProcedureCode, Amount, OriginalPayment, OP_Default, Fee_Schedule, ER,
--   AS1-AS10 (LEAD-computed), Endoscopy, Cardiac_Cath, PTCA, Gamma_Knife,
--   Implants, Blood, Drugs (with modifier filter applied), Provenge_Drugs,
--   Chemotherapy, Lab, Radiology, Radiation_Therapy, PET_Scan, Ambulance,
--   IV_Therapy, IOP, Clinic, COVID, CPT_91040, CPT_43235.
--   NOT present in #Step3: Sequence, Quantity, BillCharges, Modifier1,
--   ProcedureCodeNumeric, Plan, Payer01Code, Payer01Name.
--   Sequence, Quantity, BillCharges recovered via LEFT JOIN to #Step2 on
--   EncounterID + ServiceDate + ProcedureCode (best available unique key
--   since Sequence is absent from #Step3).
--
-- MAX CATEGORIES (one winner per encounter; PARTITION BY EncounterID):
--   ER, Gamma_Knife, Endoscopy, Cardiac_Cath, PTCA, Lab, Clinic
--
-- HYBRID CATEGORIES (MAX per ServiceDate in #Step3_1, SUM in #Step3_2;
--   one winner per EncounterID+ServiceDate):
--   Chemotherapy
--
-- SUM CATEGORIES (all matching lines pay):
--   OP_Default, Fee_Schedule, Implants, Blood, Drugs, Provenge_Drugs,
--   Radiology, Radiation_Therapy, PET_Scan, Ambulance, IV_Therapy, IOP
--
-- WINDOW_REDUCTION CATEGORIES (slot-based payment via LEAD pivot):
--   AS : slots AS1-AS10 (PARTITION BY EncounterID only)
--
-- INDICATOR_FLAG CATEGORIES (binary 0/1, $0 LinePayment):
--   COVID, CPT_91040, CPT_43235
--
-- SUPPRESSION HIERARCHY (tier 1 = highest priority, from #Step4):
--   1.  Gamma_Knife
--   2.  PTCA            (suppressed if Gamma_Knife != 0)
--   3.  Cardiac_Cath    (suppressed if Gamma_Knife OR PTCA != 0)
--   4.  Endoscopy       (suppressed if Gamma_Knife OR PTCA != 0)
--   5.  AS              (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR Endoscopy != 0)
--   6.  PET_Scan        (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS != 0)
--   7.  ER              (suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS OR PET_Scan != 0)
--   8.  Chemotherapy    (suppressed if any above != 0)
--   9.  IV_Therapy      (suppressed if any above != 0)
--  10.  Radiation_Therapy (suppressed if Chemotherapy or any above != 0)
--  11.  IOP             (suppressed if Radiation_Therapy or any above != 0)
--  12.  Lab             (suppressed if IOP or any above != 0)
--  13.  Radiology       (suppressed if IOP or any above != 0)
--  14.  Ambulance       (suppressed if IOP or any above != 0)
--  15.  Fee_Schedule    (suppressed if Lab OR Radiology or any above != 0)
--  16.  Clinic          (suppressed if Lab OR Radiology or any above != 0)
--  17.  OP_Default      (suppressed if IOP or any above != 0)
--  Special: Implants always pays (no suppression by hierarchy in #Step4).
--           Blood suppressed if AS != 0 or ER != 0.
--           Drugs suppressed if ER != 0 or Endoscopy != 0 or AS != 0.
--           Provenge_Drugs not suppressed by hierarchy in #Step4.
--           COVID/CPT_91040/CPT_43235 are indicator flags; always $0 payment.
--=======================================================================

-- BLOCK 1: #bRanked
-- One ROW_NUMBER() per MAX, HYBRID, WINDOW_REDUCTION, and INDICATOR_FLAG category.
-- Count check:
--   MAX categories:             ER, Gamma_Knife, Endoscopy, Cardiac_Cath, PTCA, Lab, Clinic  = 7
--   HYBRID categories:          Chemotherapy                                                  = 1
--   WINDOW_REDUCTION categories: AS                                                           = 1
--   INDICATOR_FLAG categories:  COVID, CPT_91040, CPT_43235                                  = 3
--   TOTAL ROW_NUMBER() calls = 12
-- NOTE: #Step3 has no Sequence column. We ORDER BY Amount DESC as tiebreaker.
--       EncounterID ASC used as final stable tiebreaker.
SELECT
    b.*
    -- MAX categories: PARTITION BY EncounterID
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]           DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_ER
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife]  DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Gamma_Knife
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Endoscopy]    DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Endoscopy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Cath] DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA]         DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_PTCA
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Lab]          DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Lab
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Clinic]       DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Clinic
    -- HYBRID categories: PARTITION BY EncounterID + ServiceDate
    -- Chemotherapy: MAX in #Step3_1 (aggregate_date), SUM in #Step3_2 (aggregate_enc) => HYBRID
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Chemotherapy] DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Chemotherapy
    -- WINDOW_REDUCTION: AS, PARTITION BY EncounterID only (lead_partition_by = EncounterID_only)
    -- ORDER BY SUM of ALL AS slot columns
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY (  ISNULL(b.[AS1], 0) + ISNULL(b.[AS2], 0) + ISNULL(b.[AS3], 0)
                    + ISNULL(b.[AS4], 0) + ISNULL(b.[AS5], 0) + ISNULL(b.[AS6], 0)
                    + ISNULL(b.[AS7], 0) + ISNULL(b.[AS8], 0) + ISNULL(b.[AS9], 0)
                    + ISNULL(b.[AS10], 0)) DESC
                  , b.[Amount] DESC, b.[EncounterID] ASC) AS rn_AS
    -- INDICATOR_FLAG categories: PARTITION BY EncounterID, same as MAX
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]      DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_COVID
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[CPT_91040]  DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_CPT_91040
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[CPT_43235]  DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_CPT_43235
INTO #bRanked
FROM #Step3 b;

-- BLOCK 2: #bSlots
-- Extracts slot values from the rank-1 row for AS (WINDOW_REDUCTION) per encounter.
-- bslots_group_by = EncounterID_only (LEAD PARTITION BY EncounterID only).
-- Uses GROUP BY + MAX(CASE...) pattern.
SELECT
    [EncounterID]
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
INTO #bSlots
FROM #bRanked
GROUP BY [EncounterID];

-- BLOCK 3: #LineBreakdown
-- One row per charge line. Sequence, Quantity, BillCharges are not present in #Step3;
-- recovered via LEFT JOIN to #Step2 on EncounterID + ServiceDate + ProcedureCode.
-- Because #Step2 may have multiple rows per EncounterID+ServiceDate+ProcedureCode
-- (e.g. modifier-50 duplicates), SELECT DISTINCT collapses any cross-join duplicates.
-- ServiceCategory hierarchy order matches #Step4 IIF chain exactly.
SELECT DISTINCT
    b.[EncounterID]
    -- Sequence recovered from #Step2 (not present in #Step3)
    , src.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                        AS [BilledAmount]
    -- Quantity recovered from #Step2 (not present in #Step3)
    , src.[Quantity]
    -- BillCharges recovered from #Step2 (not present in #Step3; display only)
    , src.[BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Hierarchy order matches #Step4 IIF suppression chain exactly.
    -- MAX:     one winner per encounter (rn partitioned by EncounterID)
    -- HYBRID:  one winner per encounter per service date (rn partitioned by EncounterID+ServiceDate)
    -- SUM:     all matching lines labeled (no rank check)
    -- WINDOW_REDUCTION: slot-sum check to confirm AS value present, then rank label
    -- INDICATOR_FLAG:   placed after all dollar categories and Suppressed_By_Hierarchy
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- TIER 1: Gamma_Knife (MAX)
        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN IIF(b.rn_Gamma_Knife = 1, 'Gamma_Knife', 'Gamma_Knife_Non_Winner')

        -- TIER 2: PTCA (MAX) — suppressed if Gamma_Knife != 0
        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN IIF(b.rn_PTCA = 1, 'PTCA', 'PTCA_Non_Winner')

        -- TIER 3: Cardiac_Cath (MAX) — suppressed if Gamma_Knife OR PTCA != 0
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- TIER 4: Endoscopy (MAX) — suppressed if Gamma_Knife OR PTCA != 0
        WHEN s4.[Endoscopy] != 0
         AND b.[Endoscopy] > 0
            THEN IIF(b.rn_Endoscopy = 1, 'Endoscopy', 'Endoscopy_Non_Winner')

        -- TIER 5: AS (WINDOW_REDUCTION via AS1-AS10 slots, PARTITION BY EncounterID)
        -- Suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR Endoscopy != 0
        WHEN s4.[AS] != 0
         AND (  ISNULL(b.[AS1],0) + ISNULL(b.[AS2],0) + ISNULL(b.[AS3],0)
              + ISNULL(b.[AS4],0) + ISNULL(b.[AS5],0) + ISNULL(b.[AS6],0)
              + ISNULL(b.[AS7],0) + ISNULL(b.[AS8],0) + ISNULL(b.[AS9],0)
              + ISNULL(b.[AS10],0)) > 0
            THEN CASE
                    WHEN b.rn_AS BETWEEN 1 AND 10 THEN 'AS_Ambulatory_Surgery'
                    ELSE 'AS_Ambulatory_Surgery_Beyond_Max'
                 END

        -- TIER 6: PET_Scan (SUM) — suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS != 0
        WHEN s4.[PET_Scan] != 0
         AND b.[PET_Scan] > 0
            THEN 'PET_Scan'

        -- TIER 7: ER (MAX) — suppressed if Gamma_Knife OR PTCA OR Cardiac_Cath OR AS OR PET_Scan != 0
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- TIER 8: Chemotherapy (HYBRID) — suppressed if any above != 0
        -- MAX in #Step3_1 (per date), SUM in #Step3_2 (per encounter) => HYBRID
        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN IIF(b.rn_Chemotherapy = 1, 'Chemotherapy', 'Chemotherapy_Non_Winner')

        -- TIER 9: IV_Therapy (SUM) — suppressed if any above != 0
        WHEN s4.[IV_Therapy] != 0
         AND b.[IV_Therapy] > 0
            THEN 'IV_Therapy'

        -- TIER 10: Radiation_Therapy (SUM) — suppressed if Chemotherapy or any above != 0
        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'Radiation_Therapy'

        -- TIER 11: IOP (SUM) — suppressed if Radiation_Therapy or any above != 0
        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN 'IOP'

        -- TIER 12: Lab (MAX) — suppressed if IOP or any above != 0
        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN IIF(b.rn_Lab = 1, 'Lab', 'Lab_Non_Winner')

        -- TIER 13: Radiology (SUM) — suppressed if IOP or any above != 0
        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Radiology'

        -- TIER 14: Ambulance (SUM) — suppressed if IOP or any above != 0
        WHEN s4.[Ambulance] != 0
         AND b.[Ambulance] > 0
            THEN 'Ambulance'

        -- TIER 15: Fee_Schedule (SUM) — suppressed if Lab OR Radiology or any above != 0
        WHEN s4.[Fee_Schedule] != 0
         AND b.[Fee_Schedule] > 0
            THEN 'Fee_Schedule'

        -- TIER 16: Clinic (MAX) — suppressed if Lab OR Radiology or any above != 0
        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN IIF(b.rn_Clinic = 1, 'Clinic', 'Clinic_Non_Winner')

        -- TIER 17: OP_Default (SUM — catch-all) — suppressed if IOP or any above != 0
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- TIER 18: Drugs (SUM) — special suppression: ER=0 AND Endoscopy=0 AND AS=0
        -- s4.[Drugs] already reflects the correct post-suppression outcome from #Step4
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- TIER 19: Provenge_Drugs (SUM) — not suppressed by hierarchy in #Step4
        WHEN s4.[Provenge_Drugs] != 0
         AND b.[Provenge_Drugs] > 0
            THEN 'Provenge_Drugs'

        -- TIER 20: Implants (SUM) — not suppressed by hierarchy in #Step4
        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Implants'

        -- TIER 21: Blood (SUM) — suppressed if AS != 0 or ER != 0 in #Step4
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- Suppressed: line matched a category but #Step4 hierarchy zeroed it
        -- Include all pricing columns AND slot columns AND indicator flags in the sum
        -- so that pure-flag lines also receive 'Suppressed_By_Hierarchy' if warranted
        WHEN (
              ISNULL(b.[ER],0)               + ISNULL(b.[Gamma_Knife],0)
            + ISNULL(b.[Endoscopy],0)        + ISNULL(b.[Cardiac_Cath],0)
            + ISNULL(b.[PTCA],0)
            + ISNULL(b.[Chemotherapy],0)     + ISNULL(b.[IV_Therapy],0)
            + ISNULL(b.[Radiation_Therapy],0) + ISNULL(b.[IOP],0)
            + ISNULL(b.[Lab],0)              + ISNULL(b.[Radiology],0)
            + ISNULL(b.[Ambulance],0)
            + ISNULL(b.[Fee_Schedule],0)     + ISNULL(b.[Clinic],0)
            + ISNULL(b.[OP_Default],0)
            + ISNULL(b.[Drugs],0)            + ISNULL(b.[Provenge_Drugs],0)
            + ISNULL(b.[Implants],0)         + ISNULL(b.[Blood],0)
            + ISNULL(b.[PET_Scan],0)
            + ISNULL(b.[COVID],0)
            + ISNULL(b.[CPT_91040],0)        + ISNULL(b.[CPT_43235],0)
            + ISNULL(b.[AS1],0)  + ISNULL(b.[AS2],0)  + ISNULL(b.[AS3],0)
            + ISNULL(b.[AS4],0)  + ISNULL(b.[AS5],0)  + ISNULL(b.[AS6],0)
            + ISNULL(b.[AS7],0)  + ISNULL(b.[AS8],0)  + ISNULL(b.[AS9],0)
            + ISNULL(b.[AS10],0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- INDICATOR_FLAG: COVID (binary 0/1, placed after all dollar and suppressed categories)
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        -- INDICATOR_FLAG: CPT_91040
        WHEN b.[CPT_91040] != 0
            THEN IIF(b.rn_CPT_91040 = 1, 'CPT_91040_Flag', 'CPT_91040_Flag_Non_Winner')

        -- INDICATOR_FLAG: CPT_43235
        WHEN b.[CPT_43235] != 0
            THEN IIF(b.rn_CPT_43235 = 1, 'CPT_43235_Flag', 'CPT_43235_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula for each category.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN 'Contracted flat rate per contract year (Gamma Knife Rev 360; CPT list: 61796-61800/63620/63621/G0339/G0340)'

        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN 'Contracted flat rate per contract year (PTCA Rev 360/361/369/480/481/490/499/750/790; CPT list: 92920-92944/C9600-C9608)'

        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract year (Cardiac Cath Rev 360/361/369/480/481/490/499/750/790; CPT range 93451-93583/93503/93505/93571/93572)'

        WHEN s4.[Endoscopy] != 0
         AND b.[Endoscopy] > 0
            THEN 'Contracted flat rate per contract year (Endoscopy Rev 360/361/369/480/481/490/499/750/790; CPT 45378/45380/45381/45384/45385/G0105/G0121)'

        WHEN s4.[AS] != 0
         AND (  ISNULL(b.[AS1],0) + ISNULL(b.[AS2],0) + ISNULL(b.[AS3],0)
              + ISNULL(b.[AS4],0) + ISNULL(b.[AS5],0) + ISNULL(b.[AS6],0)
              + ISNULL(b.[AS7],0) + ISNULL(b.[AS8],0) + ISNULL(b.[AS9],0)
              + ISNULL(b.[AS10],0)) > 0
            THEN CASE
                    WHEN b.rn_AS = 1
                        THEN 'Contracted ASC grouper flat rate / 1 — 1st procedure, full rate (Rev 360/361/369/481/490/499/750/759/790)'
                    WHEN b.rn_AS = 2
                        THEN 'Contracted ASC grouper flat rate / 2 — 2nd procedure, 50% reduction'
                    WHEN b.rn_AS BETWEEN 3 AND 10
                        THEN 'Contracted ASC grouper flat rate / 2 — 3rd-10th procedure, 50% reduction'
                    ELSE 'Beyond 10th AS procedure in encounter — $0'
                 END

        WHEN s4.[PET_Scan] != 0
         AND b.[PET_Scan] > 0
            THEN 'Contracted flat rate per contract year per CPT (PET Scan Rev 404; CPT list: 78459/78491/78492/78608-78816)'

        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN 'Contracted flat rate per contract year (ER Rev 450/451/452/459 or Rev 456 at lower rate)'

        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN 'Contracted per diem per contract year (Chemotherapy Rev 331/332/335)'

        WHEN s4.[IV_Therapy] != 0
         AND b.[IV_Therapy] > 0
            THEN 'RBRVS Rate x multiplier (6.67 or 6.95) x Quantity; fallback = Amount x 80% (IV Therapy Rev 260/269)'

        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'Contracted flat rate per contract year x Quantity (Radiation Therapy Rev 330/333/339)'

        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN 'Pct of charges: Amount x 80% (IOP Rev 905/906/945 + CPT 90899)'

        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Capitation placeholder — $0.01 per line (Lab Rev 300-312/314/319/923-925; actual fee schedule rates commented out)'

        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Radiology Fee Schedule SOURCE_FEE x 1.60 x Quantity; fallback = Amount x 50% (Rev 320-329/340-342/349-352/359/400-403/409/610-619); zero-pay CPTs from ZeroPay table'

        WHEN s4.[Ambulance] != 0
         AND b.[Ambulance] > 0
            THEN 'Pct of charges: Amount x 80% (Ambulance Rev 540/542/543/546/547/548/549)'

        WHEN s4.[Fee_Schedule] != 0
         AND b.[Fee_Schedule] > 0
            THEN 'Fee Schedule — $0 under current contract terms (placeholder column; always 0)'

        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN 'Capitation placeholder — $0.01 per line (Clinic Rev 510-529)'

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'RBRVS Rate x multiplier (6.67 or 7.18) x Quantity; fallback = Amount x 80% — OP Default catch-all (applicable OP Rev codes not covered by other categories)'

        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'AWP Source Rate x 80% x Quantity (Drugs Rev 343/344/634/635/636; excl Modifier FB/SL); date-banded AWP tables'

        WHEN s4.[Provenge_Drugs] != 0
         AND b.[Provenge_Drugs] > 0
            THEN 'Contracted flat rate per contract year (Provenge Drugs Rev 636 + CPT Q2043)'

        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Pct of charges: Amount x 36% (Implants Rev 274/275/276/278; excl device pass-through codes)'

        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Pct of charges: Amount x 100% (Blood Rev 380-390 or blood product CPTs P901x-P905x/P9060 or clotting factor CPTs)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag — binary 0/1 value, no dollar payment'

        WHEN b.[CPT_91040] != 0
            THEN 'CPT 91040 presence indicator flag — binary 0/1 value, no dollar payment'

        WHEN b.[CPT_43235] != 0
            THEN 'CPT 43235 presence indicator flag — binary 0/1 value, no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:              IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, ISNULL(b.[CAT],0), 0), 0)
    -- HYBRID:           IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, ISNULL(b.[CAT],0), 0), 0)
    --                   (rn partitioned by EncounterID+ServiceDate; each date winner pays)
    -- SUM:              IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- WINDOW_REDUCTION: slot-pivot from #bSlots keyed by EncounterID
    -- INDICATOR_FLAG:   $0 — never add b.[COVID]/b.[CPT_91040]/b.[CPT_43235] to sum
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1, ISNULL(b.[Gamma_Knife], 0), 0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1, ISNULL(b.[ER], 0), 0), 0)
        + IIF(s4.[Endoscopy] != 0,
              IIF(b.rn_Endoscopy = 1, ISNULL(b.[Endoscopy], 0), 0), 0)
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1, ISNULL(b.[Cardiac_Cath], 0), 0), 0)
        + IIF(s4.[PTCA] != 0,
              IIF(b.rn_PTCA = 1, ISNULL(b.[PTCA], 0), 0), 0)
        + IIF(s4.[Lab] != 0,
              IIF(b.rn_Lab = 1, ISNULL(b.[Lab], 0), 0), 0)
        + IIF(s4.[Clinic] != 0,
              IIF(b.rn_Clinic = 1, ISNULL(b.[Clinic], 0), 0), 0)
          -- HYBRID categories
        + IIF(s4.[Chemotherapy] != 0,
              IIF(b.rn_Chemotherapy = 1, ISNULL(b.[Chemotherapy], 0), 0), 0)
          -- WINDOW_REDUCTION: AS — each row gets its own rank's slot value from #bSlots
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
          -- SUM categories
        + IIF(s4.[PET_Scan] != 0,           ISNULL(b.[PET_Scan], 0),          0)
        + IIF(s4.[IV_Therapy] != 0,         ISNULL(b.[IV_Therapy], 0),        0)
        + IIF(s4.[Radiation_Therapy] != 0,  ISNULL(b.[Radiation_Therapy], 0), 0)
        + IIF(s4.[IOP] != 0,                ISNULL(b.[IOP], 0),               0)
        + IIF(s4.[Radiology] != 0,          ISNULL(b.[Radiology], 0),         0)
        + IIF(s4.[Ambulance] != 0,          ISNULL(b.[Ambulance], 0),         0)
        + IIF(s4.[Fee_Schedule] != 0,       ISNULL(b.[Fee_Schedule], 0),      0)
        + IIF(s4.[OP_Default] != 0,         ISNULL(b.[OP_Default], 0),        0)
        + IIF(s4.[Drugs] != 0,              ISNULL(b.[Drugs], 0),             0)
        + IIF(s4.[Provenge_Drugs] != 0,     ISNULL(b.[Provenge_Drugs], 0),    0)
        + IIF(s4.[Implants] != 0,           ISNULL(b.[Implants], 0),          0)
        + IIF(s4.[Blood] != 0,              ISNULL(b.[Blood], 0),             0)
          -- INDICATOR_FLAG: COVID, CPT_91040, CPT_43235 — $0, never added to sum
      , 2)

    -- NCCI BUNDLED FLAG: no NCCI bundle step in this script — always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4  ON s4.[EncounterID] = b.[EncounterID]
LEFT  JOIN #bSlots rd  ON rd.[EncounterID] = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover Sequence, Quantity, BillCharges not present in #Step3.
-- Join on EncounterID + ServiceDate + ProcedureCode to minimise fan-out.
-- SELECT DISTINCT on the outer query collapses any remaining duplicates from modifier-50 rows.
LEFT  JOIN #Step2  src ON src.[EncounterID]    = b.[EncounterID]
                       AND src.[ServiceDate]   = b.[ServiceDate]
                       AND src.[ProcedureCode] = b.[ProcedureCode]
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
	+[IOP]
	+[Fee_Schedule]
	+[Clinic]
	+[OP_Default]		
		
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
	, Y.IV_Therapy
	, y.[Radiation_Therapy]				
	, y.[Lab]				
	, y.[Radiology]		
	, y.[Ambulance]
	, y.[IOP]	
	, y.[Fee_Schedule]
	, y.[Clinic]
	, y.[OP_Default]	
	, y.[COVID]
	, Y.[Both_91040&43235]

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
	+IIF(ISNULL(x.[IV_Therapy]		    ,0) > 0,      'IV Therapy - '			+ Cast(x.[IV_Therapy]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiation_Therapy]	,0) > 0,      'Radiation_Therapy - '	+ Cast(x.[Radiation_Therapy]	as varchar) + ', ','')
	+IIF(ISNULL(x.[Lab]					,0) > 0,      'Lab - '					+ Cast(x.[Lab]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiology]			,0) > 0,      'Radiology - '			+ Cast(x.[Radiology]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Ambulance]			,0) > 0,      'Ambulance - '			+ Cast(x.[Ambulance]			as varchar) + ', ','')
	+IIF(ISNULL(x.[IOP]					,0) > 0,      'IOP - '					+ Cast(x.[IOP]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Fee_Schedule]		,0) > 0,      'Fee_Schedule - '			+ Cast(x.[Fee_Schedule]			as varchar) + ', ','')	
	+IIF(ISNULL(x.[Clinic]				,0) > 0,      'Clinic - '				+ Cast(x.[Clinic]				as varchar) + ', ','')		
	+IIF(ISNULL(x.[OP_Default]			,0) > 0,      'OP_Default - '			+ Cast(x.[OP_Default]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Both_91040&43235]	,0) > 0,      'This claim has both CPTS: 91040 & 43235, they are commonly denied by payor, however based on Nicole feedback they should be paid' ,'')
	as ExpectedDetailed

--	,x.[Implants]
--	,x.[Blood]	
--	,x.[Drugs]
--	,x.[Provenge_Drugs]
--	,x.[Gamma_Knife]			
--	,x.[PTCA]				
--	,x.[Cardiac_Cath]		
--	,x.[AS]				
--	,x.[PET_Scan]			
--	,x.[ER]				
--	,x.[Chemotherapy]		
--	,x.[Radiation_Therapy]
--	,x.[Psych]					
--	,x.[Lab]				
--	,x.[Radiology]		
--	,x.[Ambulance]
--	,x.[Miscellaneous]
--	,x.[IOP]
--	,x.[Fee_Schedule]
--	,x.[Clinic]
--	,x.[OP_Default]
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

--where ExpectedDetailed like '%Blood%'
--swhere Diff =0  -- 1525

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
    , 'NYP_COL_OXFORD_COM_OP'
    , GETDATE()
FROM #LineBreakdown lb
ORDER BY lb.[EncounterID], lb.[Sequence];

-- QUERY 2: Reconciliation — line-level sum vs encounter-level Price.
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
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_OXFORD_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- --EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;