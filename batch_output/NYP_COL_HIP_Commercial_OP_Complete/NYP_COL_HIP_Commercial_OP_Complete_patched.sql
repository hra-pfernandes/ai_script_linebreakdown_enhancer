
--Added HIP FS for RadTherapy as per Ricardos Feedback 2.4.2025 SC
--Added HIP rates for 2024 Knee-Hip Replacement and Shoulder and Cardiac+Angioplasty 3.12.2025 SC
--Fixed clinic issue 3.18.2025 SC
--Updates 2025 Contract Rates by Naveen Abboju 08.14.2025
USE [COL]

IF OBJECT_ID('tempdb..#Step1') IS NOT NULL DROP TABLE #Step1
IF OBJECT_ID('tempdb..#Step1_Charges') IS NOT NULL DROP TABLE #Step1_Charges
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

where TypeOfBill = 'Outpatient'

	AND y.[Payer01Name] IN (
		'EMBLEM HEALTH HIP HMO/POS',
		'EMBLEM HEALTHCARE PARTNERS HMO',
		'EMBLEM HEALTH HIP BRIDGE NETWORK',
		'EMBLEM HEALTH HIP PPO',
		'CONNECTICARE POS/HMO'
		)

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'

	--and y.[AGE] < 65

	AND X.ServiceDateFrom < '2026-01-01'

--and x.[EncounterID] = '500053619194'


Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric

INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x

where x.[EncounterID] in (Select [EncounterID]
from #Step1)

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]


	, [OP_Default] = CASE
	WHEN 1=1 THEN Round([Amount] * 0.80, 2)
	ELSE 0
	END



	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 262
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 270	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 284	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 309
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 322
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 343

	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 1649	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 1699
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 1783	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 1939
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 2025
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 2159
	ELSE 0
	END



	, [AS] = CASE
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 8357		
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 8608
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 9035	
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 9827
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 10262	
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 10936	
	ELSE 0
	END



	, [Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 13062	
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 13454
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 14123	
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 15360
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 16039
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 17093
	ELSE 0
	END



	, [Vascular_Angioplasty] = CASE --Added '37228','37232' until we get feedback frm hospital 3.31.2025
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2020-01-01' and '2021-04-30') THEN 27169
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2021-05-01' and '2021-12-31') THEN 27984
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2022-01-01' and '2023-03-31') THEN 29375	
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2023-04-01' and '2023-12-31') THEN 31948
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2024-01-01' and '2024-12-31') THEN 33361
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2025-01-01' and '2025-12-31') THEN 35553
	ELSE 0
	END


	, [PTCA_Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2020-01-01' and '2021-04-30') THEN 35528
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2021-05-01' and '2021-12-31') THEN 36594
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2022-01-01' and '2023-03-31') THEN 38413	
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2023-04-01' and '2023-12-31') THEN 41778
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2024-01-01' and '2024-12-31') THEN 43626
	WHEN RevenueCode IN ('360','361','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','37228','37232','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.ServiceDateFrom between '2025-01-01' and '2025-12-31') THEN 46492
	ELSE 0
	END



	, [PTCA_Cardiac_Cath_Qualifier] = CASE
	WHEN (ProcedureCode between '93451' and '93583') THEN 1	
	ELSE 0
	END


	, [EPS] = CASE
	WHEN RevenueCode IN ('480') AND ProcedureCode in (select CAST(CPT AS nvarchar(50))
		from [QNS].[FSG].[HIP_EPS_Commercial_Rates_2018]) THEN IIF(EPS.[Rate] is null, 0, Round(EPS.[Rate], 2))
	ELSE 0 
	END



	, [Gamma_Knife] = CASE
 	WHEN RevenueCode IN ('360','333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 87385	
	WHEN RevenueCode IN ('360','333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 90006	
	WHEN RevenueCode IN ('360','333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 94480		
	WHEN RevenueCode IN ('360','333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 102757		
	WHEN RevenueCode IN ('360','333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 107303		
	WHEN RevenueCode IN ('360','333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 114353		
	ELSE 0
	END



	, [Implants] = CASE
	WHEN RevenueCode in ('274','275','276','278') AND x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') and (x.[Amount] > 1111) THEN Round([Amount] * 0.36, 2)
	ELSE 0
	END



	, [Blood] = CASE
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 2309
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 2379	
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 2497	
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 2716
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 2836
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 3022
	ELSE 0
	END



	, [Blood_Derivatives] = CASE
	WHEN (RevenueCode in ('380','381','382','383','384','385','386','389') or (RevenueCode IN ('387') and ProcedureCode IN ('J7185','J7186','J7187','J7188','J7189','J7190','J7191','J7192','J7193','J7194','J7195','J7196','J7197','J7198','J7199'))) THEN Round(Amount * 1.00, 2)
	ELSE 0
	END



	, [Dialysis] = CASE
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 1809
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 1863	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 1956	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 2127
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 2221
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 2367
	ELSE 0
	END



	, [Drugs] = CASE
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(ASP.[PaymentLimit] is null, Amount * 0.80, Round(([ASP].[PaymentLimit]/1.06) * 2.29 * Quantity, 2))	
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(ASP.[PaymentLimit] is null, Amount * 0.80, Round(([ASP].[PaymentLimit]/1.06) * 2.36 * Quantity, 2))
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(ASP.[PaymentLimit] is null, Amount * 0.80, Round(([ASP].[PaymentLimit]/1.06) * 2.36 * Quantity, 2))
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(ASP.[PaymentLimit] is null, Amount * 0.80, Round([ASP].[PaymentLimit] * 2.69 * Quantity, 2))
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(ASP.[PaymentLimit] is null, Amount * 0.80, Round([ASP].[PaymentLimit] * 2.81 * Quantity, 2))
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(ASP.[PaymentLimit] is null, Amount * 0.80, Round([ASP].[PaymentLimit] * 3.00 * Quantity, 2))
	ELSE 0
	END


	, [Chemotherapy] = CASE
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between '96401' and '96549') or (ProcedureCodeNumeric between '96360' and '96379'))) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 1440.240000	
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between '96401' and '96549') or (ProcedureCodeNumeric between '96360' and '96379'))) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 1484.000000
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between '96401' and '96549') or (ProcedureCodeNumeric between '96360' and '96379'))) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 1557.767767
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between '96401' and '96549') or (ProcedureCodeNumeric between '96360' and '96379'))) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 1694.2282234
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between '96401' and '96549') or (ProcedureCodeNumeric between '96360' and '96379'))) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 1769
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between '96401' and '96549') or (ProcedureCodeNumeric between '96360' and '96379'))) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 1885
	ELSE 0
	END



	, [Lab] = CASE
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, Amount * 0.80, Round(COV.[JK] * 2.31, 2)), Round(LAB1.[RATE] * 2.31, 2)) * Quantity	
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, Amount * 0.80, Round(COV.[JK] * 2.37, 2)), Round(LAB1.[RATE] * 2.37, 2)) * Quantity
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, Amount * 0.80, Round(COV.[JK] * 2.37, 2)), Round(LAB1.[RATE] * 2.37, 2)) * Quantity	
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, Amount * 0.80, Round(COV.[JK] * 0.7, 2)), Round(LAB1.[RATE] * 0.7, 2)) * Quantity
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, Amount * 0.80, Round(COV.[JK] * 0.7, 2)), Round(LAB1.[RATE] * 0.7, 2)) * Quantity
	ELSE 0
	END


	, [Radiology] = CASE
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.31, 2))		
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.37, 2))
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.37, 2))
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.71, 2))
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.83, 2))
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.02, 2))
	ELSE 0
	END

	

	, [Radiopharmaceuticals] = CASE
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN Round(x.[Amount] * 0.77, 2)		
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN Round(x.[Amount] * 0.77, 2)
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN Round(x.[Amount] * 0.77, 2)	
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN Round(x.[Amount] * 0.77, 2)	
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31') THEN Round(x.[Amount] * 0.77, 2)	
	ELSE 0
	END




	, [Radiation_Therapy] = CASE
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCode between '77261' and '77399') or (ProcedureCodeNumeric between '77401' and '77435') or (ProcedureCodeNumeric between '77469' and '77525'))) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, IIF(RAD.[Locality_1] IS NULL OR RAD.[Locality_1]=0, 0,RAD.[Locality_1] * 4.38  * Quantity), Round(M1.[RATE] * 4.38 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCode between '77261' and '77399') or (ProcedureCodeNumeric between '77401' and '77435') or (ProcedureCodeNumeric between '77469' and '77525'))) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, IIF(RAD.[Locality_1] IS NULL OR RAD.[Locality_1]=0, 0,RAD.[Locality_1] * 4.51  * Quantity), Round(M1.[RATE] * 4.51 * Quantity, 2))
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCode between '77261' and '77399') or (ProcedureCodeNumeric between '77401' and '77435') or (ProcedureCodeNumeric between '77469' and '77525'))) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, IIF(RAD.[Locality_1] IS NULL OR RAD.[Locality_1]=0, 0,RAD.[Locality_1] * 4.51  * Quantity), Round(M1.[RATE] * 4.51 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCode between '77261' and '77399') or (ProcedureCodeNumeric between '77401' and '77435') or (ProcedureCodeNumeric between '77469' and '77525'))) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, IIF(RAD.[Locality_1] IS NULL OR RAD.[Locality_1]=0, 0,RAD.[Locality_1] * 5.15  * Quantity), Round(M1.[RATE] * 5.15 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCode between '77261' and '77399') or (ProcedureCodeNumeric between '77401' and '77435') or (ProcedureCodeNumeric between '77469' and '77525'))) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, IIF(RAD.[Locality_1] IS NULL OR RAD.[Locality_1]=0,0, RAD.[Locality_1] * 5.38  * Quantity), Round(M1.[RATE] * 5.38 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCode between '77261' and '77399') or (ProcedureCodeNumeric between '77401' and '77435') or (ProcedureCodeNumeric between '77469' and '77525'))) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, IIF(RAD.[Locality_1] IS NULL OR RAD.[Locality_1]=0,0, RAD.[Locality_1] * 5.73  * Quantity), Round(M1.[RATE] * 5.73 * Quantity, 2))	
	ELSE 0
	END
	


	, [PT/OT/ST] = CASE
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 5.78 * Quantity, 2))		
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 5.95 * Quantity, 2))
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 5.95 * Quantity, 2))	
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 6.80 * Quantity, 2))	
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 7.10 * Quantity, 2))	
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 7.56 * Quantity, 2))	
	ELSE 0
	END



	, [Respiratory_Therapy] = CASE
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 5.78 * Quantity, 2))		
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 5.95 * Quantity, 2))
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 5.95 * Quantity, 2))		
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 6.80 * Quantity, 2))		
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 7.10 * Quantity, 2))	
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 7.56 * Quantity, 2))	
	ELSE 0
	END

	, M1.RATE

	, [Diagnostics] = CASE
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.31, 2))	
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.37, 2))
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.37, 2))	
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.37, 2))
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.83, 2))
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.02, 2))
	ELSE 0
	END



	, [IOP] = CASE
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 266	
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 274
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 288
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 314
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 348
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 371
	ELSE 0
	END



	, [Psych] = CASE
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 798	
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 822
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 863	
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 939
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 1044
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 1113
	ELSE 0
	END



	, [ECT] = CASE
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 2385	
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 2457
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 2579
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 2805
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 3121
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 3327
	ELSE 0
	END

	, [HipKnee_Replacement]=CASE
	WHEN Procedurecode IN ('27130','27132','27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31') THEN 72229
	WHEN Procedurecode IN ('27130','27132','27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 82031
	ELSE 0	
	END

	, [Shoulder_Replacement]=CASE
	WHEN Procedurecode IN ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31')  THEN 82031
	ELSE 0	
	END


	, [Per_Day] = CASE                                                                                                                                     
	WHEN ProcedureCode = '90785' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 144.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 149.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 156.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 170, IIF(y.[ServiceDateFrom] < '2025-01-01' ,189, 201))))) 	
	WHEN ProcedureCode = '90791' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 317.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 326.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 342.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 372, IIF(y.[ServiceDateFrom] < '2025-01-01' ,415, 442))))) 
	WHEN ProcedureCode = '90792' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 317.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 326.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 342.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 372, IIF(y.[ServiceDateFrom] < '2025-01-01' ,415, 442))))) 
	WHEN ProcedureCode = '90832' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 126.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 130.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 136.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 148, IIF(y.[ServiceDateFrom] < '2025-01-01' ,165, 175))))) 
	WHEN ProcedureCode = '90833' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 191.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 197.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 207.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 225, IIF(y.[ServiceDateFrom] < '2025-01-01' ,250, 266))))) 
	WHEN ProcedureCode = '90834' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 225.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 231.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 243.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 264, IIF(y.[ServiceDateFrom] < '2025-01-01' ,294, 313))))) 
	WHEN ProcedureCode = '90836' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 277.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 285.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 299.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 325, IIF(y.[ServiceDateFrom] < '2025-01-01' ,363, 386)))))
	WHEN ProcedureCode = '90837' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 337.620000, IIF(y.[ServiceDateFrom] < '2022-01-01', 347.7486000, IIF(y.[ServiceDateFrom] < '2023-04-01', 365.1360300, IIF(y.[ServiceDateFrom] < '2024-01-01', 397, IIF(y.[ServiceDateFrom] < '2025-01-01' ,442, 471)))))
	WHEN ProcedureCode = '90838' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 369.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 381.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 400.0500000, IIF(y.[ServiceDateFrom] < '2024-01-01', 435, IIF(y.[ServiceDateFrom] < '2025-01-01' ,483, 515)))))
	WHEN ProcedureCode = '90839' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 231.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 237.9300000, IIF(y.[ServiceDateFrom] < '2023-04-01', 249.8265000, IIF(y.[ServiceDateFrom] < '2024-01-01', 271, IIF(y.[ServiceDateFrom] < '2025-01-01' ,302, 322)))))
	WHEN ProcedureCode = '90840' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 231.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 237.9300000, IIF(y.[ServiceDateFrom] < '2023-04-01', 249.8265000, IIF(y.[ServiceDateFrom] < '2024-01-01', 271, IIF(y.[ServiceDateFrom] < '2025-01-01' ,302, 322)))))
	WHEN ProcedureCode = '90846' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 212.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 218.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 228.9000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 248, IIF(y.[ServiceDateFrom] < '2025-01-01' ,277, 295)))))
	WHEN ProcedureCode = '90847' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 225.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 231.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 242.5500000, IIF(y.[ServiceDateFrom] < '2024-01-01', 263, IIF(y.[ServiceDateFrom] < '2025-01-01' ,294, 313)))))
	WHEN ProcedureCode = '90849' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 197.880000, IIF(y.[ServiceDateFrom] < '2022-01-01', 203.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 213.1500000, IIF(y.[ServiceDateFrom] < '2024-01-01', 263, IIF(y.[ServiceDateFrom] < '2025-01-01' ,258, 275)))))
	WHEN ProcedureCode = '90853' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 159.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 164.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 172.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 187, IIF(y.[ServiceDateFrom] < '2025-01-01' ,208, 222)))))
	WHEN ProcedureCode = '90863' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 172.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 178.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 186.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 203, IIF(y.[ServiceDateFrom] < '2025-01-01' ,225, 240)))))

	WHEN ProcedureCode = '90901' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 229.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 235.8700000, IIF(y.[ServiceDateFrom] < '2023-04-01', 247.6635000, IIF(y.[ServiceDateFrom] < '2024-01-01', 269, IIF(y.[ServiceDateFrom] < '2025-01-01', 300, 320))))) 
	WHEN ProcedureCode = '96101' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 185.000000, IIF(y.[ServiceDateFrom] < '2022-01-01',   0.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 000.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01',   0, IIF(y.[ServiceDateFrom] < '2025-01-01',   0, 0))))) 
	WHEN ProcedureCode = '96102' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 184.847868, IIF(y.[ServiceDateFrom] < '2022-01-01',   0.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 000.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01',   0, IIF(y.[ServiceDateFrom] < '2025-01-01',   0, 0))))) 
	WHEN ProcedureCode = '96103' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 184.847868, IIF(y.[ServiceDateFrom] < '2022-01-01',   0.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', 000.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01',   0, IIF(y.[ServiceDateFrom] < '2025-01-01',   0, 0))))) 


	WHEN ProcedureCode = '99211' and RevenueCode = '914' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 277.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 286.0000000,IIF(y.[ServiceDateFrom] < '2023-01-01', 286.0000000,IIF(y.[ServiceDateFrom] < '2023-04-01', 300, IIF(y.[ServiceDateFrom] < '2024-01-01', 327, IIF(y.[ServiceDateFrom] < '2025-01-01' ,363, 387))))))
	WHEN ProcedureCode = '99212' and RevenueCode = '914' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 277.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 286.0000000,IIF(y.[ServiceDateFrom] < '2023-01-01', 286.0000000,IIF(y.[ServiceDateFrom] < '2023-04-01', 300, IIF(y.[ServiceDateFrom] < '2024-01-01', 327, IIF(y.[ServiceDateFrom] < '2025-01-01' ,363, 387))))))
	WHEN ProcedureCode = '99213' and RevenueCode = '914' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 289.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 298.0000000,IIF(y.[ServiceDateFrom] < '2023-01-01', 298.0000000,IIF(y.[ServiceDateFrom] < '2023-04-01', 303, IIF(y.[ServiceDateFrom] < '2024-01-01', 330, IIF(y.[ServiceDateFrom] < '2025-01-01' ,378, 403))))))
	WHEN ProcedureCode = '99214' and RevenueCode = '914' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 289.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 298.0000000,IIF(y.[ServiceDateFrom] < '2023-01-01', 298.0000000,IIF(y.[ServiceDateFrom] < '2023-04-01', 303, IIF(y.[ServiceDateFrom] < '2024-01-01', 330, IIF(y.[ServiceDateFrom] < '2025-01-01' ,378, 403))))))
	WHEN ProcedureCode = '99215' and RevenueCode = '914' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 289.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 298.0000000,IIF(y.[ServiceDateFrom] < '2023-01-01', 298.0000000,IIF(y.[ServiceDateFrom] < '2023-04-01', 303, IIF(y.[ServiceDateFrom] < '2024-01-01', 330, IIF(y.[ServiceDateFrom] < '2025-01-01' ,378, 403))))))
	ELSE 0																																																								
	END	



	, [Per_Unit] = CASE                                                                                                                                     
	WHEN ProcedureCode = '96105' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  267.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  281.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  295.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 321,IIF(y.[ServiceDateFrom] < '2025-01-01', 356, 380)))))
	WHEN ProcedureCode = '96110' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  182.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  191.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  201.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 218,IIF(y.[ServiceDateFrom] < '2025-01-01', 243, 259)))))
	WHEN ProcedureCode = '96112' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  322.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  339.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  356.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 387,IIF(y.[ServiceDateFrom] < '2025-01-01', 430, 459)))))	
	WHEN ProcedureCode = '96113' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  148.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  155.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  163.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 177,IIF(y.[ServiceDateFrom] < '2025-01-01', 197, 210)))))
	WHEN ProcedureCode = '96116' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  214.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  224.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  235.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 256,IIF(y.[ServiceDateFrom] < '2025-01-01', 285, 304)))))	
	WHEN ProcedureCode = '96121' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  196.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  206.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  216.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 235,IIF(y.[ServiceDateFrom] < '2025-01-01', 261, 278)))))
	WHEN ProcedureCode = '96125' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  282.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  296.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  311.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 338,IIF(y.[ServiceDateFrom] < '2025-01-01', 377, 401)))))
	WHEN ProcedureCode = '96127' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   15.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   15.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *   16.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 17, IIF(y.[ServiceDateFrom] < '2025-01-01',  20,  21)))))	
	WHEN ProcedureCode = '96130' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  272.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  286.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  300.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 327,IIF(y.[ServiceDateFrom] < '2025-01-01', 364, 387)))))
	WHEN ProcedureCode = '96131' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  207.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  217.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  228.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 248,IIF(y.[ServiceDateFrom] < '2025-01-01', 276, 294)))))	
	WHEN ProcedureCode = '96132' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  266.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  280.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  294.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 320,IIF(y.[ServiceDateFrom] < '2025-01-01', 355, 379)))))
	WHEN ProcedureCode = '96133' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  204.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  214.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  225.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 244,IIF(y.[ServiceDateFrom] < '2025-01-01', 273, 290)))))
	WHEN ProcedureCode = '96136' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   62.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   65.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *   68.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 74, IIF(y.[ServiceDateFrom] < '2025-01-01',  83,  88)))))
	WHEN ProcedureCode = '96137' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   48.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   51.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *   54.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 58, IIF(y.[ServiceDateFrom] < '2025-01-01',  65,  69)))))	
	WHEN ProcedureCode = '96138' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  103.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  108.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  113.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 123,IIF(y.[ServiceDateFrom] < '2025-01-01', 138, 147)))))
	WHEN ProcedureCode = '96139' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  103.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  108.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *  113.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 123,IIF(y.[ServiceDateFrom] < '2025-01-01', 138, 147)))))
	WHEN ProcedureCode = '96146' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *    6.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *    6.0000000, IIF(y.[ServiceDateFrom] < '2023-04-01', Quantity *    7.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01', 7,  IIF(y.[ServiceDateFrom] < '2025-01-01',   8,   9)))))
	ELSE 0																																		 
	END	


	, [No_Payment] = CASE
	WHEN (RevenueCode between 510 and 519) or (RevenueCode between 640 and 649) or (RevenueCode between 650 and 659) or (RevenueCode between 660 and 669) or (RevenueCode between 570 and 599) or (RevenueCode between 550 and 559) or (RevenueCode between 560 and 569) or (RevenueCode between 290 and 299) or (RevenueCode between 600 and 604) or (RevenueCode between 946 and 947) or (RevenueCode = '277') THEN 0.01
	ELSE 0
	END



	, case
	WHEN (y.[ServiceDateFrom] between '2020-01-27' and '2020-03-31') and [dp].[Dx] like '%B97.29%'	THEN 1
	WHEN (y.[ServiceDateFrom] between '2020-04-01' and '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1
	WHEN (y.[ServiceDateFrom] > '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1 --and [dp].[Px] is not null
	ELSE 0
	END As [COVID]


Into #Step2
From #Step1_Charges as x


	LEFT JOIN [COL].[Data].[Demo] as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px] as dp on x.[EncounterID] = dp.[EncounterID] and x.[Sequence] = dp.[Sequence]

	LEFT JOIN [Analytics].[FSG].[MedicareFeeSchedule(RBRVS)_Locality1] 				AS M1 ON M1.[CPT_CODE] = x.[ProcedureCode] AND X.ServiceDateFrom between M1.StartDate and M1.EndDate
	LEFT JOIN [Analytics].[dbo].[Medicare Lab Fee Schedule]			as LAB1 on LAB1.[HCPCS] = x.[ProcedureCode] and x.ServiceDateFrom between LAB1.[StartDate] AND LAB1.[EndDate] AND LAB1.[MOD] IS NULL
	LEFT JOIN [Analytics].[dbo].[MAC-Covid-19-Testing]				as COV on COV.[CPT_Code] = x.[ProcedureCode]

	LEFT JOIN [Analytics].[MCR].[ASP]								as ASP on ASP.[CPT] = x.[ProcedureCode] and (y.[ServiceDateFrom] between ASP.[StartDate] and ASP.[EndDate])
	LEFT JOIN [Analytics].[FSG].[Emblem-HIP_Rad_Therapy]            as RAD on RAD.[CPT] = x.[ProcedureCode]

	LEFT JOIN [QNS].[FSG].[HIP_EPS_Commercial_Rates_2018]			as EPS on CAST(EPS.CPT AS nvarchar(50)) = x.[ProcedureCode]

ORDER BY [EncounterID], x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate], [RevenueCode], [ProcedureCode], [Modifier1], [Amount], [OriginalPayment]
	
	, [OP_Default]					= IIF([ER]=0 and [No_Payment]=0 and [AS]=0 and [Cardiac_Cath]=0 and [Vascular_Angioplasty]=0 and [PTCA_Cardiac_Cath]=0 and [EPS]=0 and [Gamma_Knife]=0 and [Implants]=0 and [Blood]=0 and [Blood_Derivatives]=0 and [Dialysis]=0 and [Drugs]=0 and [Chemotherapy]=0 and [Lab]=0 and [Radiology]=0 and [Radiopharmaceuticals]=0 and [Radiation_Therapy]=0 and [PT/OT/ST]=0 and [Respiratory_Therapy]=0 and [Diagnostics]=0 and [IOP]=0 and [Psych]=0 and [ECT]=0 and [Per_Day]=0 and [Per_Unit]=0 and [Drugs]=0 and [Lab]=0 and [Radiology]=0, [OP_Default], 0)
	, [ER]
	, [AS]							= IIF([Cardiac_Cath]=0 and [Vascular_Angioplasty]=0 and [PTCA_Cardiac_Cath]=0 and [EPS]=0 and [Gamma_Knife]=0, [AS], 0)
	, [Cardiac_Cath]					
	, [Vascular_Angioplasty]
	, [PTCA_Cardiac_Cath]
	, [PTCA_Cardiac_Cath_Qualifier]
	, [EPS]
	, [Gamma_Knife]
	, [Implants]
	, [Blood]
	, [HipKnee_Replacement]
	, [Shoulder_Replacement]
	, [Blood_Derivatives]
	, [Dialysis]
	, [Drugs]			= IIF([Radiopharmaceuticals] != 0 OR (modifier1 in ('FB','SL') or Modifier1 IS NOT NULL), 0, [Drugs])				
	, [Chemotherapy]
	, [Lab]				
	, [Radiology]		= IIF([Radiopharmaceuticals] != 0 OR [Diagnostics]!=0, 0, [Radiology])			
	, [Radiopharmaceuticals] 	
	, [Radiation_Therapy]
	, [PT/OT/ST]
	, [Respiratory_Therapy]
	, [Diagnostics]		
	, [IOP]
	, [Psych]
	, [ECT]
	, [Per_Day]
	, [Per_Unit]
	, [No_Payment]					= IIF([Per_Day]=0 and [Per_Unit]=0, [No_Payment], 0)
	, [COVID]

Into #Step3
From #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]

	, SUM([OP_Default])					as [OP_Default]
	, MAX([ER])							as [ER]
	, MAX([AS])							as [AS]
	, MAX([Cardiac_Cath])				as [Cardiac_Cath]
	, MAX([Vascular_Angioplasty])		as [Vascular_Angioplasty]
	, MAX([PTCA_Cardiac_Cath])			as [PTCA_Cardiac_Cath]	
	, MAX([PTCA_Cardiac_Cath_Qualifier])	as [PTCA_Cardiac_Cath_Qualifier]	
	, MAX([HipKnee_Replacement])			as [HipKnee_Replacement]
	, MAX([Shoulder_Replacement])		as [Shoulder_Replacement]
	, MAX([EPS])							as [EPS]	
	, MAX([Gamma_Knife])					as [Gamma_Knife]
	, SUM([Implants])					as [Implants]
	, SUM([Blood])						as [Blood]
	, SUM([Blood_Derivatives])			as [Blood_Derivatives]
	, MAX([Dialysis])					as [Dialysis]
	, SUM([Drugs])						as [Drugs]
	, MAX([Chemotherapy])				as [Chemotherapy]
	, SUM([Lab])							as [Lab]
	, SUM([Radiology])					as [Radiology]
	, SUM([Radiopharmaceuticals])		as [Radiopharmaceuticals]	
	, SUM([Radiation_Therapy])			as [Radiation_Therapy]	
	, SUM([PT/OT/ST])					as [PT/OT/ST]	
	, SUM([Respiratory_Therapy])			as [Respiratory_Therapy]
	, SUM([Diagnostics])					as [Diagnostics]
 	, MAX([IOP])							as [IOP]
 	, MAX([Psych])						as [Psych]
	, MAX([ECT])							as [ECT]
	, SUM([Per_Day])						as [Per_Day]
	, SUM([Per_Unit])					as [Per_Unit]
	, MAX([No_Payment])					as [No_Payment]		
	, MAX([COVID])						as [COVID]

INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]

	, SUM([OP_Default])					as [OP_Default]
	, MAX([ER])							as [ER]
	, MAX([AS])							as [AS]
	, MAX([Cardiac_Cath])				as [Cardiac_Cath]
	, MAX([Vascular_Angioplasty])		as [Vascular_Angioplasty]
	, MAX([PTCA_Cardiac_Cath])			as [PTCA_Cardiac_Cath]	
	, MAX([PTCA_Cardiac_Cath_Qualifier])	as [PTCA_Cardiac_Cath_Qualifier]	
	, MAX([HipKnee_Replacement])			as [HipKnee_Replacement]
	, MAX([Shoulder_Replacement])		as [Shoulder_Replacement]
	, SUM([EPS])							as [EPS]
	, MAX([Gamma_Knife])					as [Gamma_Knife]
	, SUM([Implants])					as [Implants]
	, SUM([Blood])						as [Blood]
	, SUM([Blood_Derivatives])			as [Blood_Derivatives]
	, SUM([Dialysis])					as [Dialysis]	
	, SUM([Drugs])						as [Drugs]
	, SUM([Chemotherapy])				as [Chemotherapy]
	, SUM([Lab])							as [Lab]
	, SUM([Radiology])					as [Radiology]
	, SUM([Radiopharmaceuticals])		as [Radiopharmaceuticals]	
	, SUM([Radiation_Therapy])			as [Radiation_Therapy]
	, SUM([PT/OT/ST])					as [PT/OT/ST]	
	, SUM([Respiratory_Therapy])			as [Respiratory_Therapy]
	, SUM([Diagnostics])					as [Diagnostics]
 	, SUM([IOP])							as [IOP]
 	, SUM([Psych])						as [Psych]	
	, SUM([ECT])							as [ECT]
	, SUM([Per_Day])						as [Per_Day]
	, SUM([Per_Unit])					as [Per_Unit]
	, MAX([No_Payment])					as [No_Payment]	
	, MAX([COVID])						as [COVID]

INTO #Step3_2
FROM #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]

	, [Implants]			                = IIF([Gamma_Knife]!=0 or [HipKnee_Replacement]!=0 or [Shoulder_Replacement]!=0,0,[Implants])
	, [Blood_Derivatives]				= IIF([Gamma_Knife]!=0 or [HipKnee_Replacement]!=0 or [Shoulder_Replacement]!=0,0,[Blood_Derivatives])	
	-- ,[Drugs]							= IIF([Gamma_Knife]!=0 or [HipKnee_Replacement]!=0 or [Shoulder_Replacement]!=0 or([Vascular_Angioplasty]!=0 AND ([PTCA_Cardiac_Cath_Qualifier]=0 AND [PTCA_Cardiac_Cath]=0)) or ([Cardiac_Cath]!=0 AND ([PTCA_Cardiac_Cath_Qualifier]=0 AND [PTCA_Cardiac_Cath]=0)) or [EPS]!=0 or [Dialysis]!=0 or [ER]!=0, 0, [Drugs])
	, [Drugs]							= CASE
											WHEN [AS]<0 THEN [Drugs]
											WHEN ([Gamma_Knife]!=0 or [HipKnee_Replacement]!=0 or [Shoulder_Replacement]!=0 or([Vascular_Angioplasty]!=0 AND ([PTCA_Cardiac_Cath_Qualifier]=0 AND [PTCA_Cardiac_Cath]=0)) or ([Cardiac_Cath]!=0 AND ([PTCA_Cardiac_Cath_Qualifier]=0 AND [PTCA_Cardiac_Cath]=0)) or [EPS]!=0 or [Dialysis]!=0 or [ER]!=0 ) THEN 0
											ELSE [Drugs] END
	, [Radiopharmaceuticals]				= IIF([Diagnostics] !=0 or [HipKnee_Replacement]!=0 or [Shoulder_Replacement]!=0 or [Lab] != 0, 0, [Radiopharmaceuticals])
	, [Gamma_Knife]
	, [PTCA_Cardiac_Cath]				= IIF([PTCA_Cardiac_Cath_Qualifier]=1, [PTCA_Cardiac_Cath] , 0)
	, [PTCA_Cardiac_Cath_Qualifier]	
	, [HipKnee_Replacement]
	, [Shoulder_Replacement]
	, [Vascular_Angioplasty]				= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or [PTCA_Cardiac_Cath]!=0, 0, [Vascular_Angioplasty])	
	, [Cardiac_Cath]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [PTCA_Cardiac_Cath]!=0, 0, [Cardiac_Cath])
	, [EPS]								= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0, 0, [EPS])		
	, [AS]								= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0, 0, [AS])
	, [Dialysis]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0, 0, [Dialysis])
	, [Blood]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0, 0, [Blood])	
	, [ER]								= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0, 0, [ER])
	, [Chemotherapy]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0, 0, [Chemotherapy])
	, [ECT]								= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0, 0, [ECT])
	, [Psych]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0, 0, [Psych])
	, [IOP]								= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0, 0, [IOP])
	, [Per_Day]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0, 0, [Per_Day])	
	, [Per_Unit]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0, 0, [Per_Unit])	
	, [Radiation_Therapy]				= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0 or [Lab] !=0, 0, [Radiation_Therapy])
	, [Lab]								= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0, 0, [Lab])
	, [Radiology]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Radiology])
	, [PT/OT/ST]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [PT/OT/ST])
	, [Respiratory_Therapy]				= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Respiratory_Therapy])
	, [Diagnostics]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Diagnostics])
	, [No_Payment]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [No_Payment])	
	, [OP_Default]						= IIF([Shoulder_Replacement]!=0 or [HipKnee_Replacement]!=0 or [Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0 or [Radiation_Therapy] != 0 or [Radiopharmaceuticals] != 0 , 0, [OP_Default])
	, [COVID]

INTO #Step4
FROM #Step3_2

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (line-level, post-inline suppression, pre-aggregation)
--           joined to #Step4 for encounter-level suppression decisions.
--           #Step2 joined back on EncounterID+Sequence to recover
--           Sequence, Quantity, BillCharges (not carried into #Step3).
--
-- COLUMN SURVIVAL TRACE:
--   #Step3 is built with an EXPLICIT column list from #Step2.
--   Confirmed present in #Step3:
--     EncounterID, ServiceDate, RevenueCode, ProcedureCode, Modifier1,
--     Amount, OriginalPayment, OP_Default, ER, AS, Cardiac_Cath,
--     Vascular_Angioplasty, PTCA_Cardiac_Cath, PTCA_Cardiac_Cath_Qualifier,
--     EPS, Gamma_Knife, Implants, Blood, HipKnee_Replacement,
--     Shoulder_Replacement, Blood_Derivatives, Dialysis, Drugs,
--     Chemotherapy, Lab, Radiology, Radiopharmaceuticals, Radiation_Therapy,
--     PT/OT/ST, Respiratory_Therapy, Diagnostics, IOP, Psych, ECT,
--     Per_Day, Per_Unit, No_Payment, COVID
--   NOT present in #Step3 (narrow column list omits):
--     Sequence, Quantity, BillCharges, ProcedureCodeNumeric, Plan,
--     Payer01Code, Payer01Name, ServiceDateFrom, ServiceDateTo
--   These are recovered via LEFT JOIN to #Step2 on EncounterID+Sequence
--   inside #LineBreakdown.  Sequence is joined from #Step2 directly.
--
-- NO WINDOW_REDUCTION (has_window_reduction = false):
--   No LEAD slot columns in #Step3. #bSlots is omitted entirely.
--
-- CLASSIFICATION SUMMARY (from evidence: #Step3_1 = AGGREGATE_DATE,
--   #Step3_2 = AGGREGATE_ENC):
--
--   MAX categories (MAX in both AGGREGATE_DATE and AGGREGATE_ENC):
--     ER, AS, Cardiac_Cath, Vascular_Angioplasty, PTCA_Cardiac_Cath,
--     PTCA_Cardiac_Cath_Qualifier, HipKnee_Replacement, Shoulder_Replacement,
--     Gamma_Knife, No_Payment, COVID
--
--   HYBRID categories (MAX in AGGREGATE_DATE, SUM in AGGREGATE_ENC):
--     EPS, Dialysis, Chemotherapy, IOP, Psych, ECT
--
--   SUM categories (SUM in both steps):
--     OP_Default, Implants, Blood, Blood_Derivatives, Drugs, Lab, Radiology,
--     Radiopharmaceuticals, Radiation_Therapy, PT/OT/ST, Respiratory_Therapy,
--     Diagnostics, Per_Day, Per_Unit
--
--   INDICATOR_FLAG categories: COVID (binary 0/1) — $0 LinePayment
--     NOTE: COVID is MAX in both aggregation steps, so it receives a
--     ROW_NUMBER() with PARTITION BY EncounterID. Its LinePayment = $0.
--
--   ROW_NUMBER() count check:
--     MAX (incl. PTCA_Cardiac_Cath_Qualifier, No_Payment, COVID): 11
--     HYBRID: 6
--     WINDOW_REDUCTION: 0
--     Total ROW_NUMBER() lines: 17
--
-- SUPPRESSION HIERARCHY (from #Step4 IIF chains, tier 1 = highest):
--   1.  Gamma_Knife
--   2.  Shoulder_Replacement   (suppressed if Gamma_Knife != 0)
--   3.  HipKnee_Replacement    (suppressed if Gamma_Knife or Shoulder != 0)
--   4.  PTCA_Cardiac_Cath      (only pays when PTCA_Cardiac_Cath_Qualifier=1)
--   5.  Vascular_Angioplasty   (suppressed if Gamma_Knife/Shoulder/HipKnee/
--                                PTCA_Cardiac_Cath != 0)
--   6.  Cardiac_Cath           (suppressed if Gamma_Knife/Shoulder/HipKnee/
--                                Vascular_Angioplasty/PTCA_Cardiac_Cath != 0)
--   7.  EPS                    (suppressed if above != 0)
--   8.  AS                     (suppressed if above != 0)
--   9.  Dialysis               (suppressed if above != 0)
--  10.  Blood                  (suppressed if above != 0)
--  11.  ER                     (suppressed if above != 0)
--  12.  Chemotherapy           (suppressed if above != 0)
--  13.  ECT                    (suppressed if above != 0)
--  14.  Psych                  (suppressed if above != 0)
--  15.  IOP                    (suppressed if above != 0)
--  16.  Per_Day                (suppressed if above != 0)
--  17.  Per_Unit               (suppressed if above != 0)
--  18.  Radiation_Therapy      (suppressed if above != 0 OR Lab != 0)
--  19.  Lab                    (suppressed if above except Per_Unit/Per_Day != 0)
--  20.  Radiology              (suppressed if above != 0)
--  21.  PT/OT/ST               (suppressed if above != 0)
--  22.  Respiratory_Therapy    (suppressed if above != 0)
--  23.  Diagnostics            (suppressed if above != 0)
--  24.  No_Payment             (suppressed if above != 0)
--  25.  OP_Default             (suppressed if most named categories != 0)
--  Special: Implants, Blood_Derivatives, Radiopharmaceuticals, Drugs each
--           have their own IIF conditions in #Step4.
--=======================================================================

-- -----------------------------------------------------------------------
-- BLOCK 1: #bRanked
-- One ROW_NUMBER() per MAX, HYBRID, and INDICATOR_FLAG category.
-- SOURCE: #Step3 (the only table with all inline-suppressed pricing columns).
-- #Step3 does NOT have Sequence or Amount at the line level for the ORDER BY
-- tiebreaker; Amount IS present in #Step3. Sequence is NOT present in #Step3
-- (it was excluded from the explicit column list in the SELECT INTO #Step3).
-- Tiebreaker therefore uses Amount DESC, EncounterID ASC (no Sequence available).
-- -----------------------------------------------------------------------
SELECT
    b.*
    -- ---- MAX categories: PARTITION BY EncounterID ----
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]                        DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_ER
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[AS]                        DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_AS
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Cath]              DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Vascular_Angioplasty]      DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Vascular_Angioplasty
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA_Cardiac_Cath]         DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_PTCA_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA_Cardiac_Cath_Qualifier] DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_PTCA_Cardiac_Cath_Qualifier
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[HipKnee_Replacement]       DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_HipKnee_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Shoulder_Replacement]      DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Shoulder_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife]               DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Gamma_Knife
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[No_Payment]                DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_No_Payment
    -- ---- INDICATOR_FLAG category: COVID (binary 0/1, $0 LinePayment) ----
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]                     DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_COVID
    -- ---- HYBRID categories: PARTITION BY EncounterID, ServiceDate ----
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[EPS]                       DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_EPS
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Dialysis]                  DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Dialysis
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Chemotherapy]              DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Chemotherapy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[IOP]                       DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_IOP
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Psych]                     DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Psych
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[ECT]                       DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_ECT
INTO #bRanked
FROM #Step3 b;

-- #bSlots is omitted — has_window_reduction = false, no LEAD slot columns exist.

-- -----------------------------------------------------------------------
-- BLOCK 3: #LineBreakdown
-- One row per charge line.
-- #Step3 does NOT contain: Sequence, Quantity, BillCharges.
-- These are recovered via LEFT JOIN to #Step2 on EncounterID + ServiceDate.
-- Because #Step3 has no Sequence column, the join to #Step2 uses
-- EncounterID + ServiceDate. This may produce multiple matches per
-- #bRanked row when multiple charge lines share the same EncounterID
-- and ServiceDate. DISTINCT on the outer SELECT collapses exact duplicates.
-- Note: Sequence, Quantity, and BillCharges from #Step2 are display-only
-- here — LinePayment is computed from pricing columns already in #Step3
-- (via #bRanked), so no payment formula depends on this join result.
-- EPS in this script uses a fixed rate table lookup (not BillCharges * pct),
-- so BillCharges is not required for payment math — it is display-only.
-- -----------------------------------------------------------------------
SELECT DISTINCT
    b.[EncounterID]
    , src.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                              AS [BilledAmount]
    , src.[Quantity]
    , CAST(NULL AS DECIMAL(12,2))                             AS [BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Exact hierarchy order mirrors #Step4 IIF suppression chain.
    -- MAX:    IIF(rn=1, name, name_Non_Winner) — PARTITION BY EncounterID
    -- HYBRID: IIF(rn=1, name, name_Non_Winner) — PARTITION BY EncounterID+ServiceDate
    -- SUM:    flat label, no rank check
    -- INDICATOR_FLAG: placed after all dollar and Suppressed categories; $0
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- TIER 1: Gamma_Knife (MAX)
        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN IIF(b.rn_Gamma_Knife = 1, 'Gamma_Knife', 'Gamma_Knife_Non_Winner')

        -- TIER 2: Shoulder_Replacement (MAX)
        WHEN s4.[Shoulder_Replacement] != 0
         AND b.[Shoulder_Replacement] > 0
            THEN IIF(b.rn_Shoulder_Replacement = 1, 'Shoulder_Replacement', 'Shoulder_Replacement_Non_Winner')

        -- TIER 3: HipKnee_Replacement (MAX)
        WHEN s4.[HipKnee_Replacement] != 0
         AND b.[HipKnee_Replacement] > 0
            THEN IIF(b.rn_HipKnee_Replacement = 1, 'HipKnee_Replacement', 'HipKnee_Replacement_Non_Winner')

        -- TIER 4: PTCA_Cardiac_Cath (MAX — only non-zero in #Step4 when Qualifier=1)
        WHEN s4.[PTCA_Cardiac_Cath] != 0
         AND b.[PTCA_Cardiac_Cath] > 0
            THEN IIF(b.rn_PTCA_Cardiac_Cath = 1, 'PTCA_Cardiac_Cath', 'PTCA_Cardiac_Cath_Non_Winner')

        -- TIER 4b: PTCA_Cardiac_Cath_Qualifier (MAX — binary qualifier flag)
        WHEN s4.[PTCA_Cardiac_Cath_Qualifier] != 0
         AND b.[PTCA_Cardiac_Cath_Qualifier] > 0
            THEN IIF(b.rn_PTCA_Cardiac_Cath_Qualifier = 1, 'PTCA_Cardiac_Cath_Qualifier', 'PTCA_Cardiac_Cath_Qualifier_Non_Winner')

        -- TIER 5: Vascular_Angioplasty (MAX)
        WHEN s4.[Vascular_Angioplasty] != 0
         AND b.[Vascular_Angioplasty] > 0
            THEN IIF(b.rn_Vascular_Angioplasty = 1, 'Vascular_Angioplasty', 'Vascular_Angioplasty_Non_Winner')

        -- TIER 6: Cardiac_Cath (MAX)
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- TIER 7: EPS (HYBRID — MAX per date, SUM across dates)
        WHEN s4.[EPS] != 0
         AND b.[EPS] > 0
            THEN IIF(b.rn_EPS = 1, 'EPS', 'EPS_Non_Winner')

        -- TIER 8: AS (MAX)
        WHEN s4.[AS] != 0
         AND b.[AS] > 0
            THEN IIF(b.rn_AS = 1, 'AS', 'AS_Non_Winner')

        -- TIER 9: Dialysis (HYBRID)
        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN IIF(b.rn_Dialysis = 1, 'Dialysis', 'Dialysis_Non_Winner')

        -- TIER 10: Blood (SUM)
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- TIER 11: ER (MAX)
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- TIER 12: Chemotherapy (HYBRID)
        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN IIF(b.rn_Chemotherapy = 1, 'Chemotherapy', 'Chemotherapy_Non_Winner')

        -- TIER 13: ECT (HYBRID)
        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN IIF(b.rn_ECT = 1, 'ECT', 'ECT_Non_Winner')

        -- TIER 14: Psych (HYBRID)
        WHEN s4.[Psych] != 0
         AND b.[Psych] > 0
            THEN IIF(b.rn_Psych = 1, 'Psych', 'Psych_Non_Winner')

        -- TIER 15: IOP (HYBRID)
        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN IIF(b.rn_IOP = 1, 'IOP', 'IOP_Non_Winner')

        -- TIER 16: Per_Day (SUM)
        WHEN s4.[Per_Day] != 0
         AND b.[Per_Day] > 0
            THEN 'Per_Day'

        -- TIER 17: Per_Unit (SUM)
        WHEN s4.[Per_Unit] != 0
         AND b.[Per_Unit] > 0
            THEN 'Per_Unit'

        -- TIER 18: Radiation_Therapy (SUM — suppressed if Lab != 0 in #Step4)
        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'Radiation_Therapy'

        -- TIER 19: Lab (SUM)
        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Lab'

        -- TIER 20: Radiology (SUM)
        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Radiology'

        -- TIER 21: PT/OT/ST (SUM)
        WHEN s4.[PT/OT/ST] != 0
         AND b.[PT/OT/ST] > 0
            THEN 'PT/OT/ST'

        -- TIER 22: Respiratory_Therapy (SUM)
        WHEN s4.[Respiratory_Therapy] != 0
         AND b.[Respiratory_Therapy] > 0
            THEN 'Respiratory_Therapy'

        -- TIER 23: Diagnostics (SUM)
        WHEN s4.[Diagnostics] != 0
         AND b.[Diagnostics] > 0
            THEN 'Diagnostics'

        -- TIER 24: No_Payment (MAX — sentinel 0.01 value)
        WHEN s4.[No_Payment] != 0
         AND b.[No_Payment] > 0
            THEN IIF(b.rn_No_Payment = 1, 'No_Payment', 'No_Payment_Non_Winner')

        -- TIER 25: Implants (SUM — with own suppression in #Step4)
        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Implants'

        -- TIER 26: Blood_Derivatives (SUM — with own suppression in #Step4)
        WHEN s4.[Blood_Derivatives] != 0
         AND b.[Blood_Derivatives] > 0
            THEN 'Blood_Derivatives'

        -- TIER 27: Radiopharmaceuticals (SUM — with own suppression in #Step4)
        WHEN s4.[Radiopharmaceuticals] != 0
         AND b.[Radiopharmaceuticals] > 0
            THEN 'Radiopharmaceuticals'

        -- TIER 28: Drugs (SUM — with own suppression in #Step4)
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- TIER 29: OP_Default (SUM — catch-all)
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- Suppressed: line had a nonzero pricing value but #Step4 hierarchy zeroed it
        WHEN (
              ISNULL(b.[ER], 0)
            + ISNULL(b.[AS], 0)
            + ISNULL(b.[Cardiac_Cath], 0)
            + ISNULL(b.[Vascular_Angioplasty], 0)
            + ISNULL(b.[PTCA_Cardiac_Cath], 0)
            + ISNULL(b.[PTCA_Cardiac_Cath_Qualifier], 0)
            + ISNULL(b.[HipKnee_Replacement], 0)
            + ISNULL(b.[Shoulder_Replacement], 0)
            + ISNULL(b.[EPS], 0)
            + ISNULL(b.[Gamma_Knife], 0)
            + ISNULL(b.[Implants], 0)
            + ISNULL(b.[Blood], 0)
            + ISNULL(b.[Blood_Derivatives], 0)
            + ISNULL(b.[Dialysis], 0)
            + ISNULL(b.[Drugs], 0)
            + ISNULL(b.[Chemotherapy], 0)
            + ISNULL(b.[Lab], 0)
            + ISNULL(b.[Radiology], 0)
            + ISNULL(b.[Radiopharmaceuticals], 0)
            + ISNULL(b.[Radiation_Therapy], 0)
            + ISNULL(b.[PT/OT/ST], 0)
            + ISNULL(b.[Respiratory_Therapy], 0)
            + ISNULL(b.[Diagnostics], 0)
            + ISNULL(b.[IOP], 0)
            + ISNULL(b.[Psych], 0)
            + ISNULL(b.[ECT], 0)
            + ISNULL(b.[Per_Day], 0)
            + ISNULL(b.[Per_Unit], 0)
            + ISNULL(b.[No_Payment], 0)
            + ISNULL(b.[OP_Default], 0)
            + ISNULL(b.[COVID], 0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- INDICATOR_FLAG: COVID (binary 0/1, placed after suppressed, $0 LinePayment)
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN 'Contracted flat rate per contract period — Gamma Knife (Rev 360/333/339; CPT 61796-61800/63620/63621/77373/G0339)'

        WHEN s4.[Shoulder_Replacement] != 0
         AND b.[Shoulder_Replacement] > 0
            THEN 'Contracted flat rate per contract period — Shoulder Replacement (CPT 23470/23472-23474; 2024 only)'

        WHEN s4.[HipKnee_Replacement] != 0
         AND b.[HipKnee_Replacement] > 0
            THEN 'Contracted flat rate per contract period — Hip/Knee Replacement (CPT 27130/27132/27437-27447; 2023-2024)'

        WHEN s4.[PTCA_Cardiac_Cath] != 0
         AND b.[PTCA_Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period — PTCA+Cardiac Cath combined (Rev 360/361/481/490-499; vascular/PTCA CPT list; requires Qualifier CPT 93451-93583 on same encounter)'

        WHEN s4.[PTCA_Cardiac_Cath_Qualifier] != 0
         AND b.[PTCA_Cardiac_Cath_Qualifier] > 0
            THEN 'PTCA_Cardiac_Cath qualifier flag (CPT 93451-93583 present on encounter) — binary indicator, $0 direct payment'

        WHEN s4.[Vascular_Angioplasty] != 0
         AND b.[Vascular_Angioplasty] > 0
            THEN 'Contracted flat rate per contract period — Vascular Angioplasty (Rev 360/361/481/490-499; CPT 35450-35476/37228/37232/92920-92978/C9600-C9608)'

        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period — Cardiac Cath (Rev 481; CPT 93451-93583 range)'

        WHEN s4.[EPS] != 0
         AND b.[EPS] > 0
            THEN 'Fixed contracted rate from HIP_EPS_Commercial_Rates_2018 table (Rev 480; EPS CPT list)'

        WHEN s4.[AS] != 0
         AND b.[AS] > 0
            THEN 'Contracted flat rate per contract period — Ambulatory Surgery (Rev 360/361/362/369/481/490-499/750/790); one rate per encounter'

        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN 'Contracted flat rate per contract period — Dialysis (Rev 820-825/829-835/839-855/859/870-874/880-882/889)'

        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Contracted flat rate per contract period — Blood transfusion (Rev 390/391; CPT 36430)'

        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN 'Contracted flat rate per contract period — ER (Rev 450/451/452/456/459; two tiers: CPT 99281 lower rate, all other CPTs higher rate)'

        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN 'Contracted per-visit rate per contract period — Chemotherapy (Rev 260-264/269/330-332/335/940 with chemo CPTs 96360-96379/96401-96549)'

        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN 'Contracted flat rate per contract period — ECT (Rev 901; CPT 90870)'

        WHEN s4.[Psych] != 0
         AND b.[Psych] > 0
            THEN 'Contracted flat rate per contract period — Psych (Rev 912/913/944/945; CPT 90899)'

        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN 'Contracted flat rate per contract period — IOP (Rev 905/906; CPT 90899)'

        WHEN s4.[Per_Day] != 0
         AND b.[Per_Day] > 0
            THEN 'Contracted per-day rate by CPT code and contract period (Per_Day behavioral health CPT list: 90785/90791/90792/90832-90840/90846/90847/90849/90853/90863/90901/96101-96103/99211-99215 with Rev 914)'

        WHEN s4.[Per_Unit] != 0
         AND b.[Per_Unit] > 0
            THEN 'Contracted per-unit rate x Quantity by CPT code and contract period (Per_Unit psych testing CPT list: 96105-96146)'

        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'RBRVS/HIP Rad Therapy Rate x period multiplier x Quantity (Rev 333/330/339 with radiation CPTs 77261-77399/77401-77435/77469-77525)'

        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Medicare Lab Fee Schedule Rate x period multiplier x Quantity; fallback = MAC-Covid rate or Amount x 80% (Rev 300-312/314/319/923-925)'

        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'RBRVS (Locality 1) Rate x period multiplier (Rev 320-329/330/340-352/359/400-404/409/610-612/614-616/618/619)'

        WHEN s4.[PT/OT/ST] != 0
         AND b.[PT/OT/ST] > 0
            THEN 'RBRVS (Locality 1) Rate x period multiplier x Quantity (Rev 42x/43x/44x)'

        WHEN s4.[Respiratory_Therapy] != 0
         AND b.[Respiratory_Therapy] > 0
            THEN 'RBRVS (Locality 1) Rate x period multiplier x Quantity (Rev 412)'

        WHEN s4.[Diagnostics] != 0
         AND b.[Diagnostics] > 0
            THEN 'RBRVS (Locality 1) Rate x period multiplier (Rev 460/469-472/479-483/489/730-732/739-740/920-925/929)'

        WHEN s4.[No_Payment] != 0
         AND b.[No_Payment] > 0
            THEN 'No Payment revenue code category — contractual $0 (Rev 290-299/510-519/550-599/600-604/640-669/277/946-947); sentinel value 0.01'

        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Pct of charges: Amount x 36% — Implants (Rev 274/275/276/278; excl device pass-through codes; Amount > $1,111 threshold)'

        WHEN s4.[Blood_Derivatives] != 0
         AND b.[Blood_Derivatives] > 0
            THEN 'Pct of charges: Amount x 100% — Blood Derivatives (Rev 380-387/389; includes selected J-codes for Factor products)'

        WHEN s4.[Radiopharmaceuticals] != 0
         AND b.[Radiopharmaceuticals] > 0
            THEN 'Pct of charges: Amount x 77% — Radiopharmaceuticals (Rev 340/341/343/636; CPT A95xx/A96xx/A9700)'

        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'ASP PaymentLimit x period multiplier x Quantity; fallback = Amount x 80% (Rev 636 or Rev LIKE 25%; excl Modifier FB/SL or non-null modifier)'

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'Pct of charges: Amount x 80% — OP Default catch-all (applies when no other category matched)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag — binary 0/1 diagnosis flag (U07.1 / B97.29), no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:    IIF(s4.[CAT]!=0, IIF(rn=1, value, 0), 0)
    -- HYBRID: IIF(s4.[CAT]!=0, IIF(rn=1, value, 0), 0)
    --         rn partitioned by EncounterID+ServiceDate so each date
    --         contributes its winner's value; rn>1 on same date = $0
    -- SUM:    IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- INDICATOR_FLAG: $0 — never add b.[COVID] to LinePayment
    -- PTCA_Cardiac_Cath_Qualifier is a binary flag (0 or 1), $0 LinePayment
    -- No_Payment is a sentinel (0.01) — included so recon matches #Step5
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1,           ISNULL(b.[Gamma_Knife], 0),           0), 0)
        + IIF(s4.[Shoulder_Replacement] != 0,
              IIF(b.rn_Shoulder_Replacement = 1,  ISNULL(b.[Shoulder_Replacement], 0),  0), 0)
        + IIF(s4.[HipKnee_Replacement] != 0,
              IIF(b.rn_HipKnee_Replacement = 1,   ISNULL(b.[HipKnee_Replacement], 0),   0), 0)
        + IIF(s4.[PTCA_Cardiac_Cath] != 0,
              IIF(b.rn_PTCA_Cardiac_Cath = 1,     ISNULL(b.[PTCA_Cardiac_Cath], 0),     0), 0)
          -- PTCA_Cardiac_Cath_Qualifier is a binary 0/1 flag: $0 LinePayment
        + IIF(s4.[Vascular_Angioplasty] != 0,
              IIF(b.rn_Vascular_Angioplasty = 1,  ISNULL(b.[Vascular_Angioplasty], 0),  0), 0)
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1,           ISNULL(b.[Cardiac_Cath], 0),           0), 0)
        + IIF(s4.[AS] != 0,
              IIF(b.rn_AS = 1,                    ISNULL(b.[AS], 0),                    0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1,                    ISNULL(b.[ER], 0),                    0), 0)
        + IIF(s4.[No_Payment] != 0,
              IIF(b.rn_No_Payment = 1,            ISNULL(b.[No_Payment], 0),            0), 0)
          -- HYBRID categories: IIF(rn=1) partitioned by EncounterID+ServiceDate
        + IIF(s4.[EPS] != 0,
              IIF(b.rn_EPS = 1,                   ISNULL(b.[EPS], 0),                   0), 0)
        + IIF(s4.[Dialysis] != 0,
              IIF(b.rn_Dialysis = 1,              ISNULL(b.[Dialysis], 0),              0), 0)
        + IIF(s4.[Chemotherapy] != 0,
              IIF(b.rn_Chemotherapy = 1,          ISNULL(b.[Chemotherapy], 0),          0), 0)
        + IIF(s4.[IOP] != 0,
              IIF(b.rn_IOP = 1,                   ISNULL(b.[IOP], 0),                   0), 0)
        + IIF(s4.[Psych] != 0,
              IIF(b.rn_Psych = 1,                 ISNULL(b.[Psych], 0),                 0), 0)
        + IIF(s4.[ECT] != 0,
              IIF(b.rn_ECT = 1,                   ISNULL(b.[ECT], 0),                   0), 0)
          -- SUM categories
        + IIF(s4.[Blood] != 0,              ISNULL(b.[Blood], 0),              0)
        + IIF(s4.[Implants] != 0,           ISNULL(b.[Implants], 0),           0)
        + IIF(s4.[Blood_Derivatives] != 0,  ISNULL(b.[Blood_Derivatives], 0),  0)
        + IIF(s4.[Radiopharmaceuticals] != 0, ISNULL(b.[Radiopharmaceuticals], 0), 0)
        + IIF(s4.[Drugs] != 0,              ISNULL(b.[Drugs], 0),              0)
        + IIF(s4.[Lab] != 0,                ISNULL(b.[Lab], 0),                0)
        + IIF(s4.[Radiology] != 0,          ISNULL(b.[Radiology], 0),          0)
        + IIF(s4.[Radiation_Therapy] != 0,  ISNULL(b.[Radiation_Therapy], 0),  0)
        + IIF(s4.[PT/OT/ST] != 0,           ISNULL(b.[PT/OT/ST], 0),           0)
        + IIF(s4.[Respiratory_Therapy] != 0, ISNULL(b.[Respiratory_Therapy], 0), 0)
        + IIF(s4.[Diagnostics] != 0,        ISNULL(b.[Diagnostics], 0),        0)
        + IIF(s4.[Per_Day] != 0,            ISNULL(b.[Per_Day], 0),            0)
        + IIF(s4.[Per_Unit] != 0,           ISNULL(b.[Per_Unit], 0),           0)
        + IIF(s4.[OP_Default] != 0,         ISNULL(b.[OP_Default], 0),         0)
          -- INDICATOR_FLAG: COVID — $0, never add b.[COVID] to LinePayment
      , 2)

    -- No NCCI bundle step in this script — always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4  ON s4.[EncounterID] = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover Sequence and Quantity (not present in #Step3).
-- BillCharges recovered here as a display column only (not used in payment math).
LEFT  JOIN #Step2  src ON src.[EncounterID] = b.[EncounterID]
                       AND src.[ServiceDate] = b.[ServiceDate]
                       AND src.[ProcedureCode] = b.[ProcedureCode]
                       AND src.[RevenueCode]   = b.[RevenueCode]
ORDER BY b.[EncounterID], b.[ServiceDate];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	, [Implants]
	+[Blood]
	+[Blood_Derivatives]
	+[Radiopharmaceuticals]
	+[Drugs]
	+[Gamma_Knife] 
	+[PTCA_Cardiac_Cath]
	+[HipKnee_Replacement]
	+[Shoulder_Replacement]	
	+[Vascular_Angioplasty] 
	+[EPS]
	+[Cardiac_Cath]		    
	+[AS]				    
	+[Dialysis]			    
	+[ER]				    
	+[Chemotherapy]	
	+[IOP]
	+[Psych]
	+[ECT]				    
	+[Per_Day]
	+[Per_Unit]
	+[Lab]				    
	+[Radiology]		    
	+[Radiation_Therapy]    
	+[PT/OT/ST]			    
	+[Respiratory_Therapy]  
	+[Diagnostics]
	+[No_Payment]
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
	, y.[Blood_Derivatives]
	, y.[Radiopharmaceuticals]
	, y.[Drugs]
	, y.[Gamma_Knife] 
	, y.[PTCA_Cardiac_Cath]
	, y.[PTCA_Cardiac_Cath_Qualifier]
	, y.[HipKnee_Replacement]
	, y.[Shoulder_Replacement]
	, y.[Vascular_Angioplasty]
	, y.[EPS]
	, y.[Cardiac_Cath]		    
	, y.[AS]				    
	, y.[Dialysis]			    
	, y.[ER]				    
	, y.[Chemotherapy]	
	, y.[IOP]
	, y.[Psych]
	, y.[ECT]				    
	, y.[Per_Day]
	, y.[Per_Unit]
	, y.[Lab]				    
	, y.[Radiology]		    
	, y.[Radiation_Therapy]    
	, y.[PT/OT/ST]			    
	, y.[Respiratory_Therapy]  
	, y.[Diagnostics]		    
	, y.[OP_Default]	
	, y.[No_Payment]
	, y.[COVID]

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
	, Round((cast(x.[OriginalPayment] as float)/[BillCharges]) * 100, 2) as [% paid]
	, DATEDIFF(DAY, x.[ServiceDateFrom], GETDATE()) - 365 as DaysLeft
	
	, IIF(ISNULL(x.[Blood]					,0) > 0,      'Blood - '					+ Cast(x.[Blood]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Blood_Derivatives]		,0) > 0,      'Blood_Derivatives - '		+ Cast(x.[Blood_Derivatives]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Implants]				,0) > 0,      'Implants - '					+ Cast(x.[Implants]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiopharmaceuticals]	,0) > 0,      'Radiopharmaceuticals - '		+ Cast(x.[Radiopharmaceuticals]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Drugs]					,0) > 0,      'Drugs - '					+ Cast(x.[Drugs]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Gamma_Knife] 			,0) > 0,      'Gamma_Knife  - '				+ Cast(x.[Gamma_Knife] 				as varchar) + ', ','')
	+IIF(ISNULL(x.[PTCA_Cardiac_Cath]		,0) > 0,      'PTCA_Cardiac_Cath - '		+ Cast(x.[PTCA_Cardiac_Cath]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Vascular_Angioplasty]	,0) > 0,      'Vascular_Angioplasty - '		+ Cast(x.[Vascular_Angioplasty]		as varchar) + ', ','')
	+IIF(ISNULL(x.[EPS]						,0) > 0,      'EPS - '						+ Cast(x.[EPS]						as varchar) + ', ','')
	+IIF(ISNULL(x.[HipKnee_Replacement]		,0) > 0,      'HipKnee_Replacement - '		+ Cast(x.[HipKnee_Replacement]      as varchar) + ', ','')
	+IIF(ISNULL(x.[Shoulder_Replacement]	,0) > 0,      'Shoulder_Replacement - '		+ Cast(x.[Shoulder_Replacement]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Cardiac_Cath]			,0) > 0,      'Cardiac_Cath - '				+ Cast(x.[Cardiac_Cath]				as varchar) + ', ','')
	+IIF(ISNULL(x.[AS]						,0) > 0,      'AS - '						+ Cast(x.[AS]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Dialysis]				,0) > 0,      'Dialysis - '					+ Cast(x.[Dialysis]					as varchar) + ', ','')
	+IIF(ISNULL(x.[ER]						,0) > 0,      'ER - '						+ Cast(x.[ER]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Chemotherapy]			,0) > 0,      'Chemotherapy - '				+ Cast(x.[Chemotherapy]				as varchar) + ', ','')
	+IIF(ISNULL(x.[IOP]						,0) > 0,      'IOP - '						+ Cast(x.[IOP]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Psych]					,0) > 0,      'Psych - '					+ Cast(x.[Psych]					as varchar) + ', ','')
	+IIF(ISNULL(x.[ECT]						,0) > 0,      'ECT - '						+ Cast(x.[ECT]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Per_Day]					,0) > 0,      'Per_Day - '					+ Cast(x.[Per_Day]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Per_Unit]				,0) > 0,      'Per_Unit - '					+ Cast(x.[Per_Unit]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Lab]						,0) > 0,      'Lab - '						+ Cast(x.[Lab]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiology]				,0) > 0,      'Radiology - '				+ Cast(x.[Radiology]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiation_Therapy]		,0) > 0,      'Radiation_Therapy - '		+ Cast(x.[Radiation_Therapy]   		as varchar) + ', ','')
	+IIF(ISNULL(x.[PT/OT/ST]				,0) > 0,      'PT/OT/ST - '					+ Cast(x.[PT/OT/ST]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Respiratory_Therapy]		,0) > 0,      'Respiratory_Therapy - '		+ Cast(x.[Respiratory_Therapy] 		as varchar) + ', ','')
	+IIF(ISNULL(x.[Diagnostics]				,0) > 0,      'Diagnostics - '				+ Cast(x.[Diagnostics]				as varchar) + ', ','')
	+IIF(ISNULL(x.[No_Payment]				,0) > 0,      'No_Payment - '				+ Cast(x.[No_Payment]				as varchar) + ', ','')	
	+IIF(ISNULL(x.[OP_Default]				,0) > 0,      'OP_Default - '				+ Cast(x.[OP_Default]				as varchar) + ', ','')
	as ExpectedDetailed

, p.[expected_payment_analyst]
--	,x.[Implants]
--	,x.[Blood]
--	,x.[Blood_Derivatives]
--	,x.[Radiopharmaceuticals]
--	,x.[Drugs]
--	,x.[Gamma_Knife] 
--	,x.[PTCA_Cardiac_Cath]
--	,x.[PTCA_Cardiac_Cath_Qualifier]
--	,x.[Vascular_Angioplasty]
--	,x.[EPS]
--	,x.[Cardiac_Cath]		    
--	,x.[AS]				    
--	,x.[Dialysis]			    
--	,x.[ER]				    
--	,x.[Chemotherapy]	
--	,x.[IOP]
--	,x.[Psych]
--	,x.[ECT]				    
--	,x.[Per_Day]
--	,x.[Per_Unit]
--	,x.[Lab]				    
--	,x.[Radiology]		    
--	,x.[Radiation_Therapy]    
--	,x.[PT/OT/ST]			    
--	,x.[Respiratory_Therapy]  
--	,x.[Diagnostics]		    
--	,x.[OP_Default]
--	,x.[No_Payment]
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

--WHERE [ExpectedDetailed] LIKE '%OP_Default%'

--	where [AuditorName] like 'Isabe%'

Order by Round(Diff, 2) desc


Select [Status], count(*)
From #StepFinal
Group by [Status]
order by count(*) desc

--======================================================================
-- *** [AUDITOR PRICE BREAKDOWN SUMMARY QUERIES - INSERTED SECTION] ***
-- Run these after the main script completes.
-- #LineBreakdown = one row per charge line (EncounterID + ServiceDate + CPT/Rev).
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
    , 'NYP_COL_HIP_COM_OP'
    , GETDATE()
FROM #LineBreakdown lb
ORDER BY lb.[EncounterID], lb.[Sequence];

-- QUERY 2: Reconciliation - line-level sum vs encounter-level Price.
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



-- 		DECLARE @DBName SYSNAME = DB_NAME();
-- EXEC Analytics.dbo.InsertScriptsStepFinal
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_HIP_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- -- EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;