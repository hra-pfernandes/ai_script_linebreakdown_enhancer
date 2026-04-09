
--Updated 2025 contract rates Naveen Abboju 08.15.2025

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
	LEFT JOIN [PRS].[dbo].Underpayments AS p1 ON p.[patient_id_real] = p1.[patient_id_real]

where TypeOfBill = 'Outpatient'

	and (Payer01Name IN ('EMBLEM HEALTH HIP ESSENTIAL 12', 'HEALTHCARE PARTNERS EXCHANGE','HEALTHCARE PARTNERS SELECT CARE EXCHANGE', 'EMBLEM HEALTH SELECT CARE EXCHANGE','CONNECTICARE IND EXCHANGE'))

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
	--    and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	and y.[ServiceDateFrom] < '2026-01-01'

-- and x.[EncounterID] IN ('100054387467')

Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric

INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x

where x.[EncounterID] in (Select [EncounterID]
from #Step1)

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select distinct x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]


	, [OP_Default] = 
	
	CASE
	WHEN 1=1 THEN Round([Amount] * 0.50, 2)
	ELSE 0
	END

	, [Other OP] = CASE
	WHEN [ProcedureCode] in ('C1732', 'C1760', 'C1759', 'C1766', 'C1730', 'C1894', 'J2370', '88305', '77062', 'C1882', '88300', 'Q0163', 'J1815', 'C1769', '0124A', '91312', 'C2617', 'C2625', '86923', '77386', '95708', '95700', '77061', '86920', 'C1763', 'J3490', '90750', '90471', 'C1887', '88313', '88346', '88307', '88342', 'BLANK', 'V2788', 'G1003', '36600', 'C1713', 'C1819', '76999', '94640', '90480', '90651', '88309', '88341', '57155', 'C1717', '88185', '88360', '88365', '88184', 'C1776', '88311', 'P9047', '88173', 'C1751', '90460', '88312', '88112', '90882', '90472', '90713', '90648', '80323', 'C1874', 'C1725', '90620', 'C9153', 'J2371', '36514', 'P9045', 'C1889', '77385', '88304', '59320', 'L8679', 'Q9968', '88377', 'J8499', 'P9012', '90710', '90696', '90461', '75970', '86870', 'C1753', '97802', 'C1758', '88333', '88334', 'C1893', '80321', '80320', 'Q0164', 'S0191', '94626', '88302', '94002', '94644', 'C1788', '90734', 'A4270', 'C1876', '51600', '77412', '77387', 'J2710', '90707', 'J7298', 'J9999', '81479', '88350', 'Q0144', '88348', 'C9145', 'J1790', 'C1789', 'H2011', '80329', 'C1757', '93798', 'J0184', '88331', '88332', '88344', 'J2470', 'L8606', '88362', 'C1747', 'C1726') THEN Round([Amount] * 0.50, 2)
	ELSE 0
	END


	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 164
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 169	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 178	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 193
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 202
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode IN ('99281') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 215

	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 1035	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 1066
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode NOT IN ('99281') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 1119	
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode Not IN ('99281') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 1217
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode Not IN ('99281') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 1271
	WHEN RevenueCode IN ('450','451','452','456','459') and ProcedureCode Not IN ('99281') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 1355


	ELSE 0
	END



	, [AS] = CASE
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 5246		
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 5403
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 5672	
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 6168	
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 6441 	
	WHEN RevenueCode IN ('360','361','362','369','481','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 6864	

	ELSE 0
	END



	, [Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 8198	
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 8444
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 8864	
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 9640	
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 10067 
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 10729 
	
	ELSE 0
	END



	, [Vascular_Angioplasty] = CASE
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 17053	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 17564
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 18437	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 20052	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 20939 	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 20939 	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 22315 	
	
	ELSE 0
	END



	, [PTCA_Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 22299	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 22968
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 24110	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 26222
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 26222
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 29181
	
	ELSE 0
	END

	

	, [PTCA_Cardiac_Cath_Qualifier] = CASE
	WHEN (ProcedureCodeNumeric between 93451 and 93583) THEN 1		
	ELSE 0
	END



	, [EPS] = CASE
	WHEN RevenueCode IN ('480') AND ProcedureCode in (select CAST(CPT AS nvarchar(50))
		from [QNS].[FSG].[HIP_EPS_Commercial_Rates_2018]) THEN IIF(EPS.[Rate] is null, 0, Round(EPS.[Rate], 2))
	ELSE 0 
	END



	, [Gamma_Knife] = CASE
 	WHEN RevenueCode IN ('333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 54848	
	WHEN RevenueCode IN ('333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 56493	
	WHEN RevenueCode IN ('333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 59301	
	WHEN RevenueCode IN ('333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 64496
	WHEN RevenueCode IN ('333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 67350 
	WHEN RevenueCode IN ('333','339') and ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','77373','G0339') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 71774 

	ELSE 0
	END



	, [Blood] = CASE
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 1449
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 1493	
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 1567	
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 1704	
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 1780 
	WHEN RevenueCode in ('390','391') and ProcedureCode in ('36430') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 1897 
	
	ELSE 0
	END



	, [Blood_Derivatives] = CASE
	WHEN (RevenueCode in ('380','381','382','383','384','385','386','389') or (RevenueCode IN ('387') and ProcedureCode IN ('J7185','J7186','J7187','J7188','J7189','J7190','J7191','J7192','J7193','J7194','J7195','J7196','J7197','J7198','J7199'))) THEN Round(Amount * 1.00, 2)
	ELSE 0
	END



	, [Dialysis] = CASE
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 1135
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 1169	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 1227
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 1335
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 1394 
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 1486 
	
	ELSE 0
	END



	, [Drugs] = CASE
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(ASP.[PaymentLimit] is null, 0, Round(([ASP].[PaymentLimit]/1.06) * 1.44 * Quantity, 2))	
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(ASP.[PaymentLimit] is null, 0, Round(([ASP].[PaymentLimit]/1.06) * 1.49 * Quantity, 2))
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(ASP.[PaymentLimit] is null, 0, Round(([ASP].[PaymentLimit]/1.06) * 1.49 * Quantity, 2))	
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(ASP.[PaymentLimit] is null, 0, Round(([ASP].[PaymentLimit]/1.06) * 1.49 * Quantity, 2))	
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(ASP.[PaymentLimit] is null, 0, Round(([ASP].[PaymentLimit]/1.06) * 1.49 * Quantity, 2))	
	WHEN (RevenueCode in ('636') or RevenueCode LIKE '25%') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(ASP.[PaymentLimit] is null, 0, Round(([ASP].[PaymentLimit]/1.06) * 1.90 * Quantity, 2))	
	
	ELSE 0
	END



	, [Chemotherapy] = CASE
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379))) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 930.720000	
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379))) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 930.831600
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379))) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 977.102064	
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379))) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 1062.6962048	
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379))) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 1110
	WHEN (RevenueCode IN ('260','261','262','263','264','269','330','331','332','335','940') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379))) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 1182
	
	ELSE 0
	END



	, [Lab] = CASE
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, 0, Round(COV.[JK] * 1.46, 2)), Round(LAB1.[RATE] * 1.46, 2))	
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, 0, Round(COV.[JK] * 1.50, 2)), Round(LAB1.[RATE] * 1.50, 2))
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, 0, Round(COV.[JK] * 1.50, 2)), Round(LAB1.[RATE] * 1.50, 2))	
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2023-04-01' and '2025-12-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, 0, Round(COV.[JK] * 0.70, 2)), Round(LAB1.[RATE] * 0.70, 2))	
	ELSE 0
	END



	, [Radiology] = CASE
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.46, 2))		
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.50, 2))
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.50, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.72, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.79, 2))	
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.91, 2))	
	
	ELSE 0
	END



	, [Radiopharmaceuticals] = CASE
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN Round(x.[Amount] * 0.48, 2)		
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN Round(x.[Amount] * 0.50, 2)
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN Round(x.[Amount] * 0.50, 2)	
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN Round(x.[Amount] * 0.50, 2)	
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN Round(x.[Amount] * 0.48, 2)	
	WHEN RevenueCode IN ('340','341','343','636') and ((ProcedureCode LIKE 'A95%') or (ProcedureCode LIKE 'A96%') or (ProcedureCode IN ('A9700'))) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN Round(x.[Amount] * 0.48, 2)	
	ELSE 0
	END




	, [Radiation_Therapy] = CASE
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.77 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.85 * Quantity, 2))
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 2.85 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.25 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.39 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.62 * Quantity, 2))	
	
	ELSE 0
	END



	, [PT/OT/ST] = CASE
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.64 * Quantity, 2))		
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.75 * Quantity, 2))
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.75 * Quantity, 2))	
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 4.28 * Quantity, 2))	
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 4.47 * Quantity, 2))	
	WHEN ((RevenueCode LIKE '42%') or (RevenueCode LIKE '43%') or (RevenueCode LIKE '44%')) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 4.77 * Quantity, 2))	
	
	ELSE 0
	END



	, [Respiratory_Therapy] = CASE
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.64 * Quantity, 2))		
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.75 * Quantity, 2))
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 3.75 * Quantity, 2))		
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 4.28 * Quantity, 2))		
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 4.47 * Quantity, 2))
	WHEN RevenueCode IN ('412') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 4.77 * Quantity, 2))
	ELSE 0
	END



	, [Diagnostics] = CASE
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.46, 2))	
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.50, 2))
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.50, 2))	
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.50, 2))	
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','481','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null or M1.[RATE] = 0, 0, Round(M1.[RATE] * 1.79, 2))	
	
	ELSE 0
	END



	, [IOP] = CASE
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 167	
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 172
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 181	
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 197	
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 205
	WHEN RevenueCode IN ('905','906') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 218
	ELSE 0
	END



	, [Psych] = CASE
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 501	
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 516
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 542
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 589
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 615 
	WHEN RevenueCode IN ('912','913','944','945') and ProcedureCode IN ('90899') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 655 
	ELSE 0
	END



	, [ECT] = CASE
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2020-01-01' and '2021-04-30') THEN 1497	
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2021-05-01' and '2021-12-31') THEN 1542
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2022-01-01' and '2023-03-31') THEN 1619	
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2023-04-01' and '2023-12-31') THEN 1761
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31') THEN 1838 
	WHEN RevenueCode IN ('901') and ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN 1959 
	ELSE 0
	END



	, [Per_Day] = CASE                                                                                                                                     
	WHEN ProcedureCode = '90785' THEN IIF(y.[ServiceDateFrom] < '2021-05-01',  91.000000, IIF(y.[ServiceDateFrom] < '2022-01-01',  93.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31',  98.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 106, IIF(y.[ServiceDateFrom] < '2025-01-01'	,111    , 119))))) * Quantity 	
	WHEN ProcedureCode = '90791' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 198.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 205.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 215.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 234, IIF(y.[ServiceDateFrom] < '2025-01-01'	,244    , 260))))) * Quantity 
	WHEN ProcedureCode = '90792' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 199.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 205.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 215.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 234, IIF(y.[ServiceDateFrom] < '2025-01-01'	,244    , 260))))) * Quantity 
	WHEN ProcedureCode = '90832' THEN IIF(y.[ServiceDateFrom] < '2021-05-01',  79.000000, IIF(y.[ServiceDateFrom] < '2022-01-01',  81.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31',  85.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 92	, IIF(y.[ServiceDateFrom] < '2025-01-01'    ,97     , 103))))) * Quantity 
	WHEN ProcedureCode = '90833' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 120.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 124.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 130.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 142, IIF(y.[ServiceDateFrom] < '2025-01-01'	,147	, 157))))) * Quantity 
	WHEN ProcedureCode = '90834' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 141.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 145.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 152.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 166, IIF(y.[ServiceDateFrom] < '2025-01-01'	,173	, 184))))) * Quantity 
	WHEN ProcedureCode = '90836' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 174.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 179.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 188.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 204, IIF(y.[ServiceDateFrom] < '2025-01-01'	,214	, 228))))) * Quantity
	WHEN ProcedureCode = '90837' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 212.620000, IIF(y.[ServiceDateFrom] < '2022-01-01', 218.3600000, IIF(y.[ServiceDateFrom] < '2023-03-31', 229.2780000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 249, IIF(y.[ServiceDateFrom] < '2025-01-01'	,260	, 277))))) * Quantity
	WHEN ProcedureCode = '90838' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 232.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 238.9600000, IIF(y.[ServiceDateFrom] < '2023-03-31', 250.9080000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 273, IIF(y.[ServiceDateFrom] < '2025-01-01'	,285	, 303))))) * Quantity
	WHEN ProcedureCode = '90839' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 145.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 149.3500000, IIF(y.[ServiceDateFrom] < '2023-03-31', 156.8175000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 170, IIF(y.[ServiceDateFrom] < '2025-01-01'	,178	, 190))))) * Quantity
	WHEN ProcedureCode = '90840' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 145.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 149.3500000, IIF(y.[ServiceDateFrom] < '2023-03-31', 156.8175000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 170, IIF(y.[ServiceDateFrom] < '2025-01-01'	,178	, 190))))) * Quantity
	WHEN ProcedureCode = '90846' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 133.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 136.9900000, IIF(y.[ServiceDateFrom] < '2023-03-31', 143.8395000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 156, IIF(y.[ServiceDateFrom] < '2025-01-01'	,163	, 174))))) * Quantity
	WHEN ProcedureCode = '90847' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 141.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 145.2300000, IIF(y.[ServiceDateFrom] < '2023-03-31', 152.4915000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 165, IIF(y.[ServiceDateFrom] < '2025-01-01'	,173	, 184))))) * Quantity
	WHEN ProcedureCode = '90849' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 124.440000, IIF(y.[ServiceDateFrom] < '2022-01-01', 128.1732000, IIF(y.[ServiceDateFrom] < '2023-03-31', 134.5818600, IIF(y.[ServiceDateFrom] < '2024-01-01' , 146, IIF(y.[ServiceDateFrom] < '2025-01-01'	,152	, 162))))) * Quantity
	WHEN ProcedureCode = '90853' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 100.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 103.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 108.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 118, IIF(y.[ServiceDateFrom] < '2025-01-01'	,123	, 131))))) * Quantity
	WHEN ProcedureCode = '90863' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 108.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 111.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 117.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 127, IIF(y.[ServiceDateFrom] < '2025-01-01'	,133	, 141))))) * Quantity
	WHEN ProcedureCode = '90901' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 144.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 148.3200000, IIF(y.[ServiceDateFrom] < '2023-03-31', 155.7360000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 169, IIF(y.[ServiceDateFrom] < '2025-01-01'	,177    , 188))))) * Quantity
	
	WHEN ProcedureCode = '99211' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 174.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 179.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 188.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 204 , IIF(y.[ServiceDateFrom] < '2025-01-01', 214, 228))))) * Quantity
	WHEN ProcedureCode = '99212' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 174.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 179.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 188.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 204 , IIF(y.[ServiceDateFrom] < '2025-01-01', 214, 228))))) * Quantity
	WHEN ProcedureCode = '99213' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 181.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 187.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 196.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 213 , IIF(y.[ServiceDateFrom] < '2025-01-01', 223, 237))))) * Quantity
	WHEN ProcedureCode = '99214' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 181.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 187.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 196.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 213 , IIF(y.[ServiceDateFrom] < '2025-01-01', 223, 237))))) * Quantity
	WHEN ProcedureCode = '99215' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', 181.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', 187.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', 196.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , 213 , IIF(y.[ServiceDateFrom] < '2025-01-01', 223, 237))))) * Quantity
	ELSE 0																																		
	END	



	, [Per_Unit] = CASE                                                                                                                                     
	WHEN ProcedureCode = '96105' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  170.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  179.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  188.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 204	, IIF(y.[ServiceDateFrom] < '2025-01-01', 214  , 228 )))))
	WHEN ProcedureCode = '96110' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  113.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  119.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  125.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 136	, IIF(y.[ServiceDateFrom] < '2025-01-01', 142  , 151 )))))
	WHEN ProcedureCode = '96112' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  206.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  216.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  227.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 247	, IIF(y.[ServiceDateFrom] < '2025-01-01', 258  , 275 )))))	
	WHEN ProcedureCode = '96113' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   94.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   99.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  104.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 113	, IIF(y.[ServiceDateFrom] < '2025-01-01', 118  , 126 )))))
	WHEN ProcedureCode = '96116' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  136.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  143.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  150.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 163	, IIF(y.[ServiceDateFrom] < '2025-01-01', 171  , 182 )))))	
	WHEN ProcedureCode = '96121' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  125.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  131.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  138.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 150	, IIF(y.[ServiceDateFrom] < '2025-01-01', 156  , 167 )))))
	WHEN ProcedureCode = '96125' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  180.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  189.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  198.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 216	, IIF(y.[ServiceDateFrom] < '2025-01-01', 226  , 240 )))))
	WHEN ProcedureCode = '96127' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *    9.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   10.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *   11.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 11	, IIF(y.[ServiceDateFrom] < '2025-01-01', 12   ,  12 )))))	
	WHEN ProcedureCode = '96130' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  174.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  183.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  192.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 209	, IIF(y.[ServiceDateFrom] < '2025-01-01', 218  , 232 )))))
	WHEN ProcedureCode = '96131' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  132.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  139.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  146.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 159	, IIF(y.[ServiceDateFrom] < '2025-01-01', 166  , 176 )))))	
	WHEN ProcedureCode = '96132' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  170.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  179.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  188.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 204	, IIF(y.[ServiceDateFrom] < '2025-01-01', 213  , 227 )))))
	WHEN ProcedureCode = '96133' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *  130.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *  137.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *  144.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 156	, IIF(y.[ServiceDateFrom] < '2025-01-01', 163  , 174 )))))
	WHEN ProcedureCode = '96136' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   40.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   42.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *   44.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 48	, IIF(y.[ServiceDateFrom] < '2025-01-01', 50   , 53  )))))
	WHEN ProcedureCode = '96137' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   31.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   32.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *   34.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 36	, IIF(y.[ServiceDateFrom] < '2025-01-01', 39   , 41  )))))	
	WHEN ProcedureCode = '96138' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   66.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   69.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *   72.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 79	, IIF(y.[ServiceDateFrom] < '2025-01-01', 83   , 88  )))))
	WHEN ProcedureCode = '96139' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *   66.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *   69.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *   72.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 79	, IIF(y.[ServiceDateFrom] < '2025-01-01', 83   , 88  )))))
	WHEN ProcedureCode = '96146' THEN IIF(y.[ServiceDateFrom] < '2021-05-01', Quantity *    4.000000, IIF(y.[ServiceDateFrom] < '2022-01-01', Quantity *    4.0000000, IIF(y.[ServiceDateFrom] < '2023-03-31', Quantity *    4.0000000, IIF(y.[ServiceDateFrom] < '2024-01-01' , Quantity * 5	, IIF(y.[ServiceDateFrom] < '2025-01-01', 5	   ,  5  )))))
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

	LEFT JOIN [Analytics].[dbo].[MedicareFeeSchedule_Locality_1]	as M1 on x.[ProcedureCode] = M1.[HCPCS] and M1.[MOD] = IIF(x.[Modifier1] is null or x.[Modifier1] NOT IN ('26','TC'), '00', x.[Modifier1]) and (y.ServiceDateFrom between M1.[StartDate] and M1.[EndDate])
	LEFT JOIN [Analytics].[dbo].[Medicare Lab Fee Schedule]			as LAB1 on LAB1.[HCPCS] = x.[ProcedureCode] and x.ServiceDateFrom between LAB1.[StartDate] AND LAB1.[EndDate] AND LAB1.[MOD] IS NULL
	LEFT JOIN [Analytics].[dbo].[MAC-Covid-19-Testing]				as COV on COV.[CPT_Code] = x.[ProcedureCode]

	LEFT JOIN [Analytics].[MCR].[ASP]								as ASP on ASP.[CPT] = x.[ProcedureCode] and (y.[ServiceDateFrom] between ASP.[StartDate] and ASP.[EndDate])

	LEFT JOIN [QNS].[FSG].[HIP_EPS_Commercial_Rates_2018]			as EPS on CAST(EPS.CPT AS nvarchar(50)) = x.[ProcedureCode]

ORDER BY [EncounterID], x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate], [RevenueCode], [ProcedureCode]
	
	, [OP_Default]						= IIF([ER]=0 and [AS]=0 and [Cardiac_Cath]=0 and [PTCA_Cardiac_Cath]=0 and [Vascular_Angioplasty]=0 and [EPS]=0 and [Gamma_Knife]=0 and [Blood]=0 and [Blood_Derivatives]=0 and [Dialysis]=0 and [Drugs]=0 and [Chemotherapy]=0 and [Lab]=0 and [Radiology]=0 and [Radiopharmaceuticals]=0 and [Radiation_Therapy]=0 and [PT/OT/ST]=0 and [Respiratory_Therapy]=0 and [Diagnostics]=0 and [IOP]=0 and [Psych]=0 and [ECT]=0 and [Per_Day]=0 and [Per_Unit]=0, [OP_Default], 0)
	, [ER]
	, [AS]								= IIF([Cardiac_Cath]=0 and [Vascular_Angioplasty]=0 and [PTCA_Cardiac_Cath]=0 and [EPS]=0 and [Gamma_Knife]=0, [AS], 0)
	, [Cardiac_Cath]
	, [PTCA_Cardiac_Cath]
	, [PTCA_Cardiac_Cath_Qualifier]
	, [Vascular_Angioplasty]
	, [EPS]
	, [Gamma_Knife]
	, [Blood]
	, [Blood_Derivatives]
	, [Dialysis]
	, [Drugs]							= IIF([Radiopharmaceuticals]=0 and (modifier1 not in ('FB','SL') or Modifier1 IS NULL), [Drugs], 0)
	, [Chemotherapy]
	, [Lab]
	, [Radiology]						= IIF([Radiation_Therapy]=0, [Radiology], 0)
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
	, [No_Payment]						= IIF([Per_Day]=0 and [Per_Unit]=0, [No_Payment], 0)
	, [COVID]
	, [Other OP]

Into #Step3
From #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]
	, sum([Other OP]) as [Other OP]
	, SUM([OP_Default])					as [OP_Default]
	, MAX([ER])							as [ER]
	, MAX([AS])							as [AS]
	, MAX([Cardiac_Cath])				as [Cardiac_Cath]
	, MAX([PTCA_Cardiac_Cath])			as [PTCA_Cardiac_Cath]	
	, MAX([PTCA_Cardiac_Cath_Qualifier])	as [PTCA_Cardiac_Cath_Qualifier]	
	, MAX([Vascular_Angioplasty])		as [Vascular_Angioplasty]
	, MAX([EPS])							as [EPS]	
	, MAX([Gamma_Knife])					as [Gamma_Knife]
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
	, MAX([Per_Day])						as [Per_Day]
	, SUM([Per_Unit])					as [Per_Unit]
	, MAX([No_Payment])					as [No_Payment]
	, MAX([COVID])						as [COVID]

INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, sum([Other OP]) as [Other OP]
	, SUM([OP_Default])					as [OP_Default]
	, MAX([ER])							as [ER]
	, MAX([AS])							as [AS]
	, MAX([Cardiac_Cath])				as [Cardiac_Cath]
	, MAX([PTCA_Cardiac_Cath])			as [PTCA_Cardiac_Cath]	
	, MAX([PTCA_Cardiac_Cath_Qualifier])	as [PTCA_Cardiac_Cath_Qualifier]	
	, MAX([Vascular_Angioplasty])		as [Vascular_Angioplasty]
	, SUM([EPS])							as [EPS]
	, MAX([Gamma_Knife])					as [Gamma_Knife]
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
	
	, [Blood_Derivatives]
	, [Drugs]						= IIF([Gamma_Knife]!=0 or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [AS]!=0 or [EPS]!=0 or [Dialysis]!=0 or [ER]!=0, 0, [Drugs])
	, [Radiopharmaceuticals]			= IIF([Radiology]=0, 0, [Radiopharmaceuticals])
	, [Gamma_Knife]
	, [PTCA_Cardiac_Cath]			= IIF([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1, [PTCA_Cardiac_Cath], 0)
	, [PTCA_Cardiac_Cath_Qualifier]		
	, [Vascular_Angioplasty]			= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1), 0, [Vascular_Angioplasty])	
	, [Cardiac_Cath]					= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0, 0, [Cardiac_Cath])
	, [EPS]							= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0, 0, [EPS])		
	, [AS]							= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0, 0, [AS])
	, [Dialysis]						= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0, 0, [Dialysis])
	, [Blood]						= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0, 0, [Blood])	
	, [ER]							= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0, 0, [ER])
	, [Chemotherapy]					= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0, 0, [Chemotherapy])
	, [ECT]							= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0, 0, [ECT])
	, [Psych]						= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0, 0, [Psych])
	, [IOP]							= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0, 0, [IOP])
	, [Per_Day]						= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0, 0, [Per_Day])	
	, [Per_Unit]						= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0, 0, [Per_Unit])	
	, [Lab]							= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Lab])
	, [Radiology]					= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Radiology])
	, [Radiation_Therapy]			= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Radiation_Therapy])
	, [PT/OT/ST]						= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [PT/OT/ST])
	, [Respiratory_Therapy]			= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Respiratory_Therapy])
	, [Diagnostics]					= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Diagnostics])
	, [No_Payment]					= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [No_Payment])	
	
	, [Other OP]						= IIF([Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [Other OP])
	

	, [OP_Default]					= IIF([Radiology]!=0 or [Radiopharmaceuticals]  !=0 or [Drugs] !=0 or [Other OP] !=0 or  [Diagnostics]!=0 or [Radiation_Therapy]!=0 or [Lab] !=0 or [Gamma_Knife]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [Vascular_Angioplasty]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Dialysis]!=0 or [Blood]!=0 or [ER]!=0 or [Chemotherapy]!=0 or [ECT]!=0 or [Psych]!=0 or [IOP]!=0 or [Per_Day]!=0 or [Per_Unit]!=0, 0, [OP_Default])
	
	
	, [COVID]

INTO #Step4
FROM #Step3_2

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (line-level pricing, post-inline suppression, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
--           #Step2 joined for Sequence, Amount, BillCharges, Quantity
--           (not present in #Step3 explicit column list).
--
-- CONFIRMED #Step3 COLUMNS:
--   EncounterID, ServiceDate, RevenueCode, ProcedureCode,
--   OP_Default, [Other OP], ER, AS, Cardiac_Cath, Vascular_Angioplasty,
--   PTCA_Cardiac_Cath, PTCA_Cardiac_Cath_Qualifier, EPS, Gamma_Knife,
--   Blood, Blood_Derivatives, Dialysis, Drugs, Chemotherapy, Lab,
--   Radiology, Radiopharmaceuticals, Radiation_Therapy, [PT/OT/ST],
--   Respiratory_Therapy, Diagnostics, IOP, Psych, ECT, Per_Day,
--   Per_Unit, No_Payment, COVID
--
-- ABSENT FROM #Step3 (recovered via LEFT JOIN #Step2 on EncounterID+ServiceDate):
--   Sequence, Amount, BillCharges, Quantity
--   NOTE: #Step3 has no WINDOW_REDUCTION slot columns (has_window_reduction=false)
--
-- MAX CATEGORIES (PARTITION BY EncounterID — one winner per encounter):
--   ER, AS, Cardiac_Cath, Vascular_Angioplasty, PTCA_Cardiac_Cath,
--   PTCA_Cardiac_Cath_Qualifier, Gamma_Knife, No_Payment
--
-- HYBRID CATEGORIES (MAX per ServiceDate in AGGREGATE_DATE, SUM across dates
--   in AGGREGATE_ENC; PARTITION BY EncounterID+ServiceDate — one winner per date):
--   EPS, Chemotherapy, ECT, Per_Day, Psych, IOP, Dialysis
--
-- SUM CATEGORIES (all matching lines pay, no rank check):
--   PT/OT/ST, Drugs, Radiology, OP_Default, Lab, Blood_Derivatives,
--   Diagnostics, Blood, Respiratory_Therapy, Radiopharmaceuticals,
--   Radiation_Therapy, [Other OP], Per_Unit
--
-- INDICATOR_FLAG CATEGORIES (binary 0/1, $0 LinePayment):
--   COVID
--
-- NO WINDOW_REDUCTION CATEGORIES (has_window_reduction = false)
-- NO #bSlots required
--
-- SUPPRESSION HIERARCHY (from #Step4 IIF chain, tier 1 = highest priority):
--   1.  Gamma_Knife
--   2.  PTCA_Cardiac_Cath (only when PTCA_Cardiac_Cath_Qualifier=1)
--   3.  Vascular_Angioplasty   (suppressed if Gamma_Knife OR PTCA_Cardiac_Cath+Qualifier != 0)
--   4.  Cardiac_Cath            (suppressed if Gamma_Knife OR PTCA_Cardiac_Cath+Qualifier OR Vascular_Angioplasty != 0)
--   5.  EPS                     (suppressed if any of 1-4 != 0)
--   6.  AS                      (suppressed if any of 1-5 != 0)
--   7.  Dialysis                (suppressed if any of 1-6 != 0)
--   8.  Blood                   (suppressed if any of 1-7 != 0)
--   9.  ER                      (suppressed if any of 1-8 != 0)
--  10.  Chemotherapy            (suppressed if any of 1-9 != 0)
--  11.  ECT                     (suppressed if any of 1-10 != 0)
--  12.  Psych                   (suppressed if any of 1-11 != 0)
--  13.  IOP                     (suppressed if any of 1-12 != 0)
--  14.  Per_Day                 (suppressed if any of 1-13 != 0)
--  15.  Per_Unit                (suppressed if any of 1-13 != 0)
--  16.  Lab                     (suppressed if any of 1-15 != 0)
--  17.  Radiology               (suppressed if any of 1-15 != 0)
--  18.  Radiation_Therapy       (suppressed if any of 1-15 != 0)
--  19.  PT/OT/ST                (suppressed if any of 1-15 != 0)
--  20.  Respiratory_Therapy     (suppressed if any of 1-15 != 0)
--  21.  Diagnostics             (suppressed if any of 1-15 != 0)
--  22.  No_Payment              (suppressed if any of 1-15 != 0)
--  23.  Other OP                (suppressed if any of 1-15 != 0)
--  Special: Drugs suppressed if Gamma_Knife OR Vascular_Angioplasty OR Cardiac_Cath
--             OR AS OR EPS OR Dialysis OR ER != 0
--           Radiopharmaceuticals suppressed if Radiology = 0
--           OP_Default suppressed if Radiology, Radiopharmaceuticals, Drugs, [Other OP],
--             Diagnostics, Radiation_Therapy, Lab, or any of 1-15 != 0
--           Blood_Derivatives: never suppressed in hierarchy (always pays)
--=======================================================================

-- BLOCK 1: #bRanked
-- ROW_NUMBER() count check:
--   MAX:           8  (ER, AS, Cardiac_Cath, Vascular_Angioplasty, PTCA_Cardiac_Cath,
--                      PTCA_Cardiac_Cath_Qualifier, Gamma_Knife, No_Payment)
--   HYBRID:        7  (EPS, Chemotherapy, ECT, Per_Day, Psych, IOP, Dialysis)
--   INDICATOR_FLAG:1  (COVID)
--   TOTAL:        16  ROW_NUMBER() lines
-- SOURCE: #Step3 — contains all pricing columns confirmed above.
-- Sequence, Amount are NOT in #Step3; ORDER BY uses EncounterID as tiebreak.
SELECT
    b.*
    -- ---- MAX categories: PARTITION BY EncounterID ----
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]                        DESC, b.[EncounterID] ASC) AS rn_ER
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[AS]                        DESC, b.[EncounterID] ASC) AS rn_AS
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Cath]              DESC, b.[EncounterID] ASC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Vascular_Angioplasty]      DESC, b.[EncounterID] ASC) AS rn_Vascular_Angioplasty
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA_Cardiac_Cath]         DESC, b.[EncounterID] ASC) AS rn_PTCA_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA_Cardiac_Cath_Qualifier] DESC, b.[EncounterID] ASC) AS rn_PTCA_Cardiac_Cath_Qualifier
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife]               DESC, b.[EncounterID] ASC) AS rn_Gamma_Knife
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[No_Payment]                DESC, b.[EncounterID] ASC) AS rn_No_Payment
    -- ---- HYBRID categories: PARTITION BY EncounterID, ServiceDate ----
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[EPS]                       DESC, b.[EncounterID] ASC) AS rn_EPS
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Chemotherapy]              DESC, b.[EncounterID] ASC) AS rn_Chemotherapy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[ECT]                       DESC, b.[EncounterID] ASC) AS rn_ECT
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Per_Day]                   DESC, b.[EncounterID] ASC) AS rn_Per_Day
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Psych]                     DESC, b.[EncounterID] ASC) AS rn_Psych
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[IOP]                       DESC, b.[EncounterID] ASC) AS rn_IOP
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Dialysis]                  DESC, b.[EncounterID] ASC) AS rn_Dialysis
    -- ---- INDICATOR_FLAG: PARTITION BY EncounterID (same as MAX), $0 LinePayment ----
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]                     DESC, b.[EncounterID] ASC) AS rn_COVID
INTO #bRanked
FROM #Step3 b;

-- NOTE: has_window_reduction = false — #bSlots is omitted entirely.

-- BLOCK 2: #LineBreakdown
-- One row per charge line. Sequence, Amount (BilledAmount), BillCharges, Quantity
-- are absent from #Step3 and are recovered via LEFT JOIN to #Step2 on
-- EncounterID + ServiceDate.
-- DISTINCT is applied because the join to #Step2 on EncounterID+ServiceDate
-- (without Sequence) could produce duplicates where multiple #Step2 lines share
-- the same EncounterID+ServiceDate; however #Step3 itself has one row per
-- EncounterID+ServiceDate combination (per the SELECT DISTINCT in its construction),
-- so the join to #Step2 must be careful. We JOIN #Step2 on EncounterID+ServiceDate
-- and rely on DISTINCT to collapse.
-- BillCharges is informational only (EPS already computed as IIF(EPS.[Rate]...) in #Step2,
-- and that computed dollar value is carried through #Step3). No payment recalculation needed.
SELECT
    b.[EncounterID]
    -- Recovered from #Step2 via LEFT JOIN; NULL if no matching row.
    , ISNULL(src.[Sequence],   0)                            AS [Sequence]
    , ISNULL(src.[ProcedureCode], b.[ProcedureCode])         AS [ProcedureCode]
    , ISNULL(src.[RevenueCode],   b.[RevenueCode])           AS [RevenueCode]
    , b.[ServiceDate]
    , CAST(ISNULL(src.[Amount],   NULL) AS DECIMAL(18,4))    AS [BilledAmount]
    , CAST(ISNULL(src.[Quantity], NULL) AS NUMERIC(18,4))    AS [Quantity]
    , CAST(ISNULL(src.[BillCharges], NULL) AS DECIMAL(12,2)) AS [BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Hierarchy order matches #Step4 IIF chain exactly.
    -- MAX:     IIF(rn=1, name, name_Non_Winner)
    -- HYBRID:  IIF(rn=1, name, name_Non_Winner) — rn partitioned by EncounterID+ServiceDate
    -- SUM:     flat label
    -- INDICATOR_FLAG: after all dollar and suppressed categories, $0
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- ---- TIER 1: Gamma_Knife (MAX) ----
        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN IIF(b.rn_Gamma_Knife = 1, 'Gamma_Knife', 'Gamma_Knife_Non_Winner')

        -- ---- TIER 2: PTCA_Cardiac_Cath + Qualifier (MAX) ----
        WHEN s4.[PTCA_Cardiac_Cath] != 0
         AND b.[PTCA_Cardiac_Cath] > 0
            THEN IIF(b.rn_PTCA_Cardiac_Cath = 1, 'PTCA_Cardiac_Cath', 'PTCA_Cardiac_Cath_Non_Winner')

        -- ---- TIER 2b: PTCA_Cardiac_Cath_Qualifier flag (MAX) ----
        WHEN s4.[PTCA_Cardiac_Cath_Qualifier] != 0
         AND b.[PTCA_Cardiac_Cath_Qualifier] > 0
            THEN IIF(b.rn_PTCA_Cardiac_Cath_Qualifier = 1, 'PTCA_Cardiac_Cath_Qualifier', 'PTCA_Cardiac_Cath_Qualifier_Non_Winner')

        -- ---- TIER 3: Vascular_Angioplasty (MAX) ----
        WHEN s4.[Vascular_Angioplasty] != 0
         AND b.[Vascular_Angioplasty] > 0
            THEN IIF(b.rn_Vascular_Angioplasty = 1, 'Vascular_Angioplasty', 'Vascular_Angioplasty_Non_Winner')

        -- ---- TIER 4: Cardiac_Cath (MAX) ----
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- ---- TIER 5: EPS (HYBRID) ----
        WHEN s4.[EPS] != 0
         AND b.[EPS] > 0
            THEN IIF(b.rn_EPS = 1, 'EPS', 'EPS_Non_Winner')

        -- ---- TIER 6: AS (MAX) ----
        WHEN s4.[AS] != 0
         AND b.[AS] > 0
            THEN IIF(b.rn_AS = 1, 'AS', 'AS_Non_Winner')

        -- ---- TIER 7: Dialysis (HYBRID) ----
        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN IIF(b.rn_Dialysis = 1, 'Dialysis', 'Dialysis_Non_Winner')

        -- ---- TIER 8: Blood (SUM) ----
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- ---- TIER 9: ER (MAX) ----
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- ---- TIER 10: Chemotherapy (HYBRID) ----
        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN IIF(b.rn_Chemotherapy = 1, 'Chemotherapy', 'Chemotherapy_Non_Winner')

        -- ---- TIER 11: ECT (HYBRID) ----
        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN IIF(b.rn_ECT = 1, 'ECT', 'ECT_Non_Winner')

        -- ---- TIER 12: Psych (HYBRID) ----
        WHEN s4.[Psych] != 0
         AND b.[Psych] > 0
            THEN IIF(b.rn_Psych = 1, 'Psych', 'Psych_Non_Winner')

        -- ---- TIER 13: IOP (HYBRID) ----
        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN IIF(b.rn_IOP = 1, 'IOP', 'IOP_Non_Winner')

        -- ---- TIER 14: Per_Day (HYBRID) ----
        WHEN s4.[Per_Day] != 0
         AND b.[Per_Day] > 0
            THEN IIF(b.rn_Per_Day = 1, 'Per_Day', 'Per_Day_Non_Winner')

        -- ---- TIER 15: Per_Unit (SUM) ----
        WHEN s4.[Per_Unit] != 0
         AND b.[Per_Unit] > 0
            THEN 'Per_Unit'

        -- ---- TIER 16: Lab (SUM) ----
        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Lab'

        -- ---- TIER 17: Radiology (SUM) ----
        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Radiology'

        -- ---- TIER 18: Radiation_Therapy (SUM) ----
        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'Radiation_Therapy'

        -- ---- TIER 19: PT/OT/ST (SUM) ----
        WHEN s4.[PT/OT/ST] != 0
         AND b.[PT/OT/ST] > 0
            THEN 'PT/OT/ST'

        -- ---- TIER 20: Respiratory_Therapy (SUM) ----
        WHEN s4.[Respiratory_Therapy] != 0
         AND b.[Respiratory_Therapy] > 0
            THEN 'Respiratory_Therapy'

        -- ---- TIER 21: Diagnostics (SUM) ----
        WHEN s4.[Diagnostics] != 0
         AND b.[Diagnostics] > 0
            THEN 'Diagnostics'

        -- ---- TIER 22: No_Payment (MAX) ----
        WHEN s4.[No_Payment] != 0
         AND b.[No_Payment] > 0
            THEN IIF(b.rn_No_Payment = 1, 'No_Payment', 'No_Payment_Non_Winner')

        -- ---- TIER 23: Other OP (SUM) ----
        WHEN s4.[Other OP] != 0
         AND b.[Other OP] > 0
            THEN 'Other_OP'

        -- ---- TIER 24: Drugs (SUM) — special suppression in #Step4 ----
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- ---- TIER 25: Radiopharmaceuticals (SUM) — only pays when Radiology != 0 ----
        WHEN s4.[Radiopharmaceuticals] != 0
         AND b.[Radiopharmaceuticals] > 0
            THEN 'Radiopharmaceuticals'

        -- ---- TIER 26: Blood_Derivatives (SUM) — never suppressed ----
        WHEN s4.[Blood_Derivatives] != 0
         AND b.[Blood_Derivatives] > 0
            THEN 'Blood_Derivatives'

        -- ---- TIER 27: OP_Default (SUM — catch-all) ----
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- ---- Suppressed: line had value but #Step4 hierarchy zeroed it ----
        WHEN (
              ISNULL(b.[ER],                    0)
            + ISNULL(b.[AS],                    0)
            + ISNULL(b.[Cardiac_Cath],          0)
            + ISNULL(b.[Vascular_Angioplasty],  0)
            + ISNULL(b.[PTCA_Cardiac_Cath],     0)
            + ISNULL(b.[PTCA_Cardiac_Cath_Qualifier], 0)
            + ISNULL(b.[Gamma_Knife],           0)
            + ISNULL(b.[No_Payment],            0)
            + ISNULL(b.[EPS],                   0)
            + ISNULL(b.[Chemotherapy],          0)
            + ISNULL(b.[ECT],                   0)
            + ISNULL(b.[Per_Day],               0)
            + ISNULL(b.[Psych],                 0)
            + ISNULL(b.[IOP],                   0)
            + ISNULL(b.[Dialysis],              0)
            + ISNULL(b.[Blood],                 0)
            + ISNULL(b.[Blood_Derivatives],     0)
            + ISNULL(b.[Drugs],                 0)
            + ISNULL(b.[Lab],                   0)
            + ISNULL(b.[Radiology],             0)
            + ISNULL(b.[Radiopharmaceuticals],  0)
            + ISNULL(b.[Radiation_Therapy],     0)
            + ISNULL(b.[PT/OT/ST],              0)
            + ISNULL(b.[Respiratory_Therapy],   0)
            + ISNULL(b.[Diagnostics],           0)
            + ISNULL(b.[Per_Unit],              0)
            + ISNULL(b.[Other OP],              0)
            + ISNULL(b.[OP_Default],            0)
            + ISNULL(b.[COVID],                 0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- ---- INDICATOR_FLAG: COVID (binary 0/1, $0, placed after suppressed) ----
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula for each category.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN 'Contracted flat rate per contract period (Gamma Knife Rev 333/339, CPT 61796-61800/63620/63621/77373/G0339)'

        WHEN s4.[PTCA_Cardiac_Cath] != 0
         AND b.[PTCA_Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period (PTCA/Cardiac Cath Rev 360/369/481/490-499, CPT 35450-35476/92920-92998/C9600-C9608) — qualifier (93451-93583) required for this rate'

        WHEN s4.[PTCA_Cardiac_Cath_Qualifier] != 0
         AND b.[PTCA_Cardiac_Cath_Qualifier] > 0
            THEN 'Binary qualifier flag (1=CPT in range 93451-93583) — enables PTCA_Cardiac_Cath rate; $0 direct contribution'

        WHEN s4.[Vascular_Angioplasty] != 0
         AND b.[Vascular_Angioplasty] > 0
            THEN 'Contracted flat rate per contract period (Vascular Angioplasty Rev 360/369/481/490-499, CPT 35450-35476/92920-92998/C9600-C9608) — no qualifier required'

        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period (Cardiac Cath Rev 481, CPT range 93451-93583)'

        WHEN s4.[EPS] != 0
         AND b.[EPS] > 0
            THEN 'EPS contracted rate from HIP_EPS_Commercial_Rates_2018 table (Rev 480, CPT in EPS list)'

        WHEN s4.[AS] != 0
         AND b.[AS] > 0
            THEN 'Contracted flat rate per contract period (Ambulatory Surgery Rev 360/361/362/369/481/490-499/750/790)'

        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN 'Contracted per diem per contract period (Dialysis Rev 820-825/829-835/839-845/849-855/859/870-874/880-882/889)'

        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Contracted flat rate per contract period (Blood transfusion Rev 390/391, CPT 36430)'

        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN 'Contracted flat rate per contract period — two tiers: CPT 99281 (low acuity) vs all other CPTs (Rev 450/451/452/456/459)'

        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN 'Contracted per diem per contract period (Chemotherapy Rev 260-264/269/330-332/335/940 + chemo CPT ranges 96360-96379/96401-96549)'

        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN 'Contracted flat rate per contract period (ECT Rev 901, CPT 90870)'

        WHEN s4.[Psych] != 0
         AND b.[Psych] > 0
            THEN 'Contracted per diem per contract period (Psych Rev 912/913/944/945, CPT 90899)'

        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN 'Contracted per diem per contract period (IOP Rev 905/906, CPT 90899)'

        WHEN s4.[Per_Day] != 0
         AND b.[Per_Day] > 0
            THEN 'Contracted rate x Quantity per specific therapy/psych CPT per contract period (CPT 90785/90791/90792/90832-90840/90846-90853/90863/90901/99211-99215)'

        WHEN s4.[Per_Unit] != 0
         AND b.[Per_Unit] > 0
            THEN 'Contracted rate x Quantity per specific neuropsychological testing CPT per contract period (CPT 96105-96146)'

        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Medicare Lab Fee Schedule Rate x period multiplier (1.46/1.50/0.70) — Rev 300-309/310-314/319/923-925'

        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Medicare Fee Schedule (TC modifier) x period multiplier (1.46/1.50/1.72/1.79/1.91) — Rev 320-329/330/340-352/359/400-404/409/610-612/614-616/618-619'

        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'Medicare Fee Schedule Rate x period multiplier x Quantity (2.77/2.85/3.25/3.39/3.62) — Rev 333 or Rev 330/339 + RT CPT ranges 77261-77399/77401-77435/77469-77525'

        WHEN s4.[PT/OT/ST] != 0
         AND b.[PT/OT/ST] > 0
            THEN 'Medicare Fee Schedule Rate x period multiplier x Quantity (3.64/3.75/4.28/4.47/4.77) — Rev 42x/43x/44x'

        WHEN s4.[Respiratory_Therapy] != 0
         AND b.[Respiratory_Therapy] > 0
            THEN 'Medicare Fee Schedule Rate x period multiplier x Quantity (3.64/3.75/4.28/4.47/4.77) — Rev 412'

        WHEN s4.[Diagnostics] != 0
         AND b.[Diagnostics] > 0
            THEN 'Medicare Fee Schedule Rate x period multiplier (1.46/1.50/1.79) — Rev 460/469-472/479-483/489/730-732/739-740/920-925/929'

        WHEN s4.[No_Payment] != 0
         AND b.[No_Payment] > 0
            THEN 'No Payment category — Rev codes 510-519/550-559/560-569/570-599/600-604/640-649/650-659/660-669/277/946-947 — fixed $0.01 placeholder'

        WHEN s4.[Other OP] != 0
         AND b.[Other OP] > 0
            THEN 'Pct of charges: Amount x 50% — specific CPT code list (Other OP catch-all)'

        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'ASP PaymentLimit / 1.06 x period multiplier (1.44/1.49/1.90) x Quantity (Drugs Rev 636 or Rev 25x; excl Modifier FB/SL; excl Radiopharmaceuticals)'

        WHEN s4.[Radiopharmaceuticals] != 0
         AND b.[Radiopharmaceuticals] > 0
            THEN 'Pct of charges: Amount x period multiplier (0.48/0.50) — Rev 340/341/343/636 + CPT A95x/A96x/A9700 — only paid when Radiology != 0'

        WHEN s4.[Blood_Derivatives] != 0
         AND b.[Blood_Derivatives] > 0
            THEN 'Pct of charges: Amount x 100% — Blood derivatives Rev 380-386/389 + specific J-codes for Rev 387'

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'Pct of charges: Amount x 50% — OP Default catch-all (no other category matched for this line)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag — binary 0/1 value, no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:     IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    -- HYBRID:  IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)  [same pattern as MAX]
    -- SUM:     IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- INDICATOR_FLAG: $0 — never add b.[COVID] to LinePayment
    -- No WINDOW_REDUCTION (has_window_reduction = false)
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1,              ISNULL(b.[Gamma_Knife], 0),           0), 0)
        + IIF(s4.[PTCA_Cardiac_Cath] != 0,
              IIF(b.rn_PTCA_Cardiac_Cath = 1,        ISNULL(b.[PTCA_Cardiac_Cath], 0),     0), 0)
        + IIF(s4.[Vascular_Angioplasty] != 0,
              IIF(b.rn_Vascular_Angioplasty = 1,     ISNULL(b.[Vascular_Angioplasty], 0),  0), 0)
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1,             ISNULL(b.[Cardiac_Cath], 0),           0), 0)
        + IIF(s4.[AS] != 0,
              IIF(b.rn_AS = 1,                       ISNULL(b.[AS], 0),                     0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1,                       ISNULL(b.[ER], 0),                     0), 0)
        + IIF(s4.[No_Payment] != 0,
              IIF(b.rn_No_Payment = 1,               ISNULL(b.[No_Payment], 0),             0), 0)
          -- PTCA_Cardiac_Cath_Qualifier is a binary flag — $0 direct contribution
        + 0
          -- HYBRID categories
        + IIF(s4.[EPS] != 0,
              IIF(b.rn_EPS = 1,                      ISNULL(b.[EPS], 0),                    0), 0)
        + IIF(s4.[Chemotherapy] != 0,
              IIF(b.rn_Chemotherapy = 1,             ISNULL(b.[Chemotherapy], 0),           0), 0)
        + IIF(s4.[ECT] != 0,
              IIF(b.rn_ECT = 1,                      ISNULL(b.[ECT], 0),                    0), 0)
        + IIF(s4.[Per_Day] != 0,
              IIF(b.rn_Per_Day = 1,                  ISNULL(b.[Per_Day], 0),                0), 0)
        + IIF(s4.[Psych] != 0,
              IIF(b.rn_Psych = 1,                    ISNULL(b.[Psych], 0),                  0), 0)
        + IIF(s4.[IOP] != 0,
              IIF(b.rn_IOP = 1,                      ISNULL(b.[IOP], 0),                    0), 0)
        + IIF(s4.[Dialysis] != 0,
              IIF(b.rn_Dialysis = 1,                 ISNULL(b.[Dialysis], 0),               0), 0)
          -- SUM categories
        + IIF(s4.[Blood] != 0,             ISNULL(b.[Blood], 0),             0)
        + IIF(s4.[Blood_Derivatives] != 0, ISNULL(b.[Blood_Derivatives], 0), 0)
        + IIF(s4.[Drugs] != 0,             ISNULL(b.[Drugs], 0),             0)
        + IIF(s4.[Lab] != 0,               ISNULL(b.[Lab], 0),               0)
        + IIF(s4.[Radiology] != 0,         ISNULL(b.[Radiology], 0),         0)
        + IIF(s4.[Radiopharmaceuticals] != 0, ISNULL(b.[Radiopharmaceuticals], 0), 0)
        + IIF(s4.[Radiation_Therapy] != 0, ISNULL(b.[Radiation_Therapy], 0), 0)
        + IIF(s4.[PT/OT/ST] != 0,         ISNULL(b.[PT/OT/ST], 0),          0)
        + IIF(s4.[Respiratory_Therapy] != 0, ISNULL(b.[Respiratory_Therapy], 0), 0)
        + IIF(s4.[Diagnostics] != 0,       ISNULL(b.[Diagnostics], 0),       0)
        + IIF(s4.[Per_Unit] != 0,          ISNULL(b.[Per_Unit], 0),           0)
        + IIF(s4.[Other OP] != 0,          ISNULL(b.[Other OP], 0),           0)
        + IIF(s4.[OP_Default] != 0,        ISNULL(b.[OP_Default], 0),         0)
          -- INDICATOR_FLAG: COVID — $0, never added to LinePayment
      , 2)

    -- NCCI BUNDLED FLAG: no NCCI bundle step in this script — always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4 s4  ON s4.[EncounterID] = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover Sequence, Amount, BillCharges, Quantity
-- which are absent from #Step3 (explicit narrow column list).
-- Join on EncounterID + ServiceDate (both confirmed present in #Step3/#bRanked).
LEFT  JOIN #Step2 src ON src.[EncounterID] = b.[EncounterID]
                      AND src.[ServiceDate]  = b.[ServiceDate]
ORDER BY b.[EncounterID], ISNULL(src.[Sequence], 0);



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	, [Blood]
	+[Blood_Derivatives]
	+[Radiopharmaceuticals]
	+[Drugs]
	+[Gamma_Knife] 
	+[PTCA_Cardiac_Cath]	
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
	+[OP_Default]
	+[No_Payment]
	+[Other OP]
	as Price

INTO #Step5
FROM #Step4

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select
	x.*
	, y.[Price]
	, y.[Blood]
	, y.[Blood_Derivatives]
	, y.[Radiopharmaceuticals]
	, y.[Drugs]
	, y.[Gamma_Knife] 
	, y.[Vascular_Angioplasty]
	, y.[PTCA_Cardiac_Cath]
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
	, y.[Other OP]

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
	, p.[expected_payment_analyst]
	  
	, Round([Price], 2) as ExpectedPrice
	, Round([Price] - (cast(x.[OriginalPayment] as float)), 2) as Diff
	, Round((cast(x.[OriginalPayment] as float)/[BillCharges]) * 100, 2) as [% paid]
	, DATEDIFF(DAY, x.[ServiceDateFrom], GETDATE()) - 365 as DaysLeft
	
	, IIF(ISNULL(x.[Blood]					,0) > 0,      'Blood - '					+ Cast(x.[Blood]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Blood_Derivatives]		,0) > 0,      'Blood_Derivatives - '		+ Cast(x.[Blood_Derivatives]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiopharmaceuticals]	,0) > 0,      'Radiopharmaceuticals - '		+ Cast(x.[Radiopharmaceuticals]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Drugs]					,0) > 0,      'Drugs - '					+ Cast(x.[Drugs]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Gamma_Knife] 			,0) > 0,      'Gamma_Knife  - '				+ Cast(x.[Gamma_Knife] 				as varchar) + ', ','')
	+IIF(ISNULL(x.[PTCA_Cardiac_Cath]		,0) > 0,      'PTCA_Cardiac_Cath - '		+ Cast(x.[PTCA_Cardiac_Cath]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Vascular_Angioplasty]	,0) > 0,      'Vascular_Angioplasty - '		+ Cast(x.[Vascular_Angioplasty]		as varchar) + ', ','')
	+IIF(ISNULL(x.[EPS]						,0) > 0,      'EPS - '						+ Cast(x.[EPS]						as varchar) + ', ','')
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
	+IIF(ISNULL(x.[Other OP]				,0) > 0,      'Other OP - '				+ Cast(x.[Other OP]				as varchar) + ', ','')
	
	as ExpectedDetailed



--	,p.[expected_payment_analyst]
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
			'Seq:'  + CAST(lb.[Sequence]        AS VARCHAR(MAX)) +
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

--where [ExpectedDetailed] like '%OP_Default%'
--where diff = 0  --127

--where [ExpectedPrice] > BillCharges

Order by Round(Diff, 2) desc

Select [Status], count(*)
From #StepFinal
Group by [Status]
order by count(*) desc

--======================================================================
-- *** [AUDITOR PRICE BREAKDOWN SUMMARY QUERIES - INSERTED SECTION] ***
-- Run these after the main script completes.
-- #LineBreakdown = one row per charge line (EncounterID + ServiceDate + recovered Sequence).
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
    , 'NYP_COL_HIP_EXCHNG_COM_OP'
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
    , p.[Price]                                      AS EncounterLevel_Price
    , (r.[LineBreakdown_Total] - p.[Price])           AS Discrepancy
FROM #recon_temp r
INNER JOIN #Step5 p ON r.[EncounterID] = p.[EncounterID]
WHERE ABS(r.[LineBreakdown_Total] - p.[Price]) > 1.00
ORDER BY ABS(r.[LineBreakdown_Total] - p.[Price]) DESC;



-- 		DECLARE @DBName SYSNAME = DB_NAME();
-- EXEC Analytics.dbo.InsertScriptsStepFinal
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_HIP_EXCHNG_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- -- EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;