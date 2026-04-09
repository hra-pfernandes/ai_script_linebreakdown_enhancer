
--- Updated 2025 contract rates Naveen Abboju 08.11.2025

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


	AND (((Payer01Name like '%GHI%') and (Payer01Name not like ('%CBP%')) or y.[Contract] IN ('GHI') and (y.[Plan] IN ('HMO','PPO')))
	and [Payer01Name] NOT IN ('EMBLEM HEALTH GHI/EMPIRE CBP','Ghi Cbp Maj Med Only','EMBLEM HEALTH GHI MEDICARE SUPPLEMENTAL','EMBLEM HEALTH GHI MEDICARE PPO')
	or Payer01Name in ('EMBLEM HEALTH GHI PPO/EPO'))

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
	--    and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	and y.[ServiceDateFrom] < '2026-01-01'

--and y.[AGE] < 65

--	and x.[EncounterID] IN ('500052813920')

Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric

INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x

where x.[EncounterID] in (Select [EncounterID]
from #Step1)

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select DISTINCT x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]


    , [Fs_Default] = CASE
    WHEN x.[ProcedureCode] IN ('J7060', 'J1815', '77386', '99213', '88305', '88342', '88341', '86920', 'J7120', 'J2270', 'J0690', 'J2704', 'J1885', 'J2250', 'J3010', 'J2405', '99214', '88300', 'J7050', 'Q9967', 'J0696', 'J1650', '94640', 'J7030', 'J3475', 'J7613', 'J1100', 'J7644', '88304', '88311', '97116', '97161', 'J0131', 'J1170', 'J1644', 'J0780', 'J7040', '94002', '90471', '97802', 'J2545', '90832', '97110', '93798', '94003', '86923', '90853', '90834', '88307', '88331', '90833', '97112', '97140', '88185', '88184', '88313', 'J0153', 'J2001', 'J2720', '90837', '97530', 'J0706', 'J7042', 'J2765', 'J1200', '90846', 'G0108', '36514', '88312', '90836', '97535', '88112', '92610', '92523', '97750', '37242', 'G0283', '59412', '97162', '77412', '90847', '96374', '90791', '92611', '90792', '96139', '96138', '92012', '96136', '96137', '94644', '31720', '99391', '90460', '90461', '88302', '99212', '88360', 'Q0144', '77387', '99215', '96133', '96132', '90849', '88309', '94626', '19281', '99195', '88173', '88172', '88177', '92526', '88333', '58300', '99205', '88182', '88364', '88365', '88334', '94660', '51600', '99393', 'S0190', 'S0191', '88108', '59320', '36512', 'J8499') and (y.[ServiceDateTo] between '2020-01-01' and '2024-12-31') THEN IIF(cbp_crn_2023.[RATE] is null, 0, Round(cbp_crn_2023.[RATE] * 3.25, 2)) * Quantity
    WHEN x.[ProcedureCode] IN ('J7060', 'J1815', '77386', '99213', '88305', '88342', '88341', '86920', 'J7120', 'J2270', 'J0690', 'J2704', 'J1885', 'J2250', 'J3010', 'J2405', '99214', '88300', 'J7050', 'Q9967', 'J0696', 'J1650', '94640', 'J7030', 'J3475', 'J7613', 'J1100', 'J7644', '88304', '88311', '97116', '97161', 'J0131', 'J1170', 'J1644', 'J0780', 'J7040', '94002', '90471', '97802', 'J2545', '90832', '97110', '93798', '94003', '86923', '90853', '90834', '88307', '88331', '90833', '97112', '97140', '88185', '88184', '88313', 'J0153', 'J2001', 'J2720', '90837', '97530', 'J0706', 'J7042', 'J2765', 'J1200', '90846', 'G0108', '36514', '88312', '90836', '97535', '88112', '92610', '92523', '97750', '37242', 'G0283', '59412', '97162', '77412', '90847', '96374', '90791', '92611', '90792', '96139', '96138', '92012', '96136', '96137', '94644', '31720', '99391', '90460', '90461', '88302', '99212', '88360', 'Q0144', '77387', '99215', '96133', '96132', '90849', '88309', '94626', '19281', '99195', '88173', '88172', '88177', '92526', '88333', '58300', '99205', '88182', '88364', '88365', '88334', '94660', '51600', '99393', 'S0190', 'S0191', '88108', '59320', '36512', 'J8499') and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31') THEN IIF(cbp_crn_2025.[RATE] is null, 0, Round(cbp_crn_2025.[RATE] * 3.75, 2)) * Quantity
	ELSE 0
	END


	, [OP_Default] = CASE
    WHEN 1=1  THEN  [Amount] * 0.82
	ELSE 0
	END




	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30') THEN 1661	
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31') THEN 1885
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31') THEN 1919	
    WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31') THEN 2087	
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31') THEN 2180 	
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31') THEN 2323 	
	ELSE 0
	END



	, [AS] = CASE
	WHEN RevenueCode IN ('360','361','362','369','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30') THEN  9718	
	WHEN RevenueCode IN ('360','361','362','369','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31') THEN 11030	
	WHEN RevenueCode IN ('360','361','362','369','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31') THEN 11228		
	WHEN RevenueCode IN ('360','361','362','369','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31') THEN 12212		
	WHEN RevenueCode IN ('360','361','362','369','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31') THEN 12752 		
	WHEN RevenueCode IN ('360','361','362','369','490','491','492','493','494','495','496','497','498','499','750','790') and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31') THEN 13590 		
	
	ELSE 0
	END



	, [Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30') THEN  9718	
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31') THEN 11030
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31') THEN 11228	
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31') THEN 12212	
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31') THEN 12752 	
	WHEN RevenueCode IN ('481') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31') THEN 13590 	
	ELSE 0
	END



	, [PTCA] = CASE
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and [ProcedureCode] IN ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30')  THEN 60888	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and [ProcedureCode] IN ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31')  THEN 69108
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and [ProcedureCode] IN ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31')  THEN 70350	
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and [ProcedureCode] IN ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31')  THEN 76512		
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and [ProcedureCode] IN ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31')  THEN 79897 
	WHEN RevenueCode IN ('360','369','481','490','491','492','493','494','495','496','497','498','499') and [ProcedureCode] IN ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31')  THEN 85147 
	
	ELSE 0
	END 



	, [Gamma_Knife] = CASE
	WHEN ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30') THEN  98541	
	WHEN ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31') THEN 111844	
	WHEN ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31') THEN 113855	
	WHEN ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31') THEN 123828	
	WHEN ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31') THEN 129306 
	WHEN ProcedureCode IN ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31') THEN 137802 

	ELSE 0
	END



	, [Implants] = CASE
	WHEN RevenueCode in ('274','275','276','278','279') AND x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') and (x.Amount > 1388) THEN Round(x.Amount * 0.36, 2)
	ELSE 0
	END



	, [Blood] = CASE
	WHEN RevenueCode in ('380','381','382','383','384','385','386','387','389','390','391','392','399')	THEN Round([Amount] * 1.00, 2)
	ELSE 0
	END



	, [Dialysis] = CASE
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30')  THEN 2430
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31')  THEN 2758	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31')  THEN 2807	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31')  THEN 3053		
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31')  THEN 3189 		
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31')  THEN 3398 		
	
	ELSE 0
	END



	, [Drugs] = CASE
	WHEN RevenueCode in ('636') THEN Round(x.Amount * 0.29, 2)
	ELSE 0
	END



	, [Chemotherapy] = CASE
	WHEN (RevenueCode IN ('280','289','330','331','332','335','339') or (RevenueCode IN ('260','760') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379)))) and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30') THEN 2435.060000		
	WHEN (RevenueCode IN ('280','289','330','331','332','335','339') or (RevenueCode IN ('260','760') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379)))) and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31') THEN 2763.793100
	WHEN (RevenueCode IN ('280','289','330','331','332','335','339') or (RevenueCode IN ('260','760') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379)))) and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31') THEN 2813.468324	
	WHEN (RevenueCode IN ('280','289','330','331','332','335','339') or (RevenueCode IN ('260','760') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379)))) and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31') THEN 3059.9281492		
	WHEN (RevenueCode IN ('280','289','330','331','332','335','339') or (RevenueCode IN ('260','760') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379)))) and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31') THEN 3195		
	WHEN (RevenueCode IN ('280','289','330','331','332','335','339') or (RevenueCode IN ('260','760') and ((ProcedureCodeNumeric between 96401 and 96549) or (ProcedureCodeNumeric between 96360 and 96379)))) and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31') THEN 3405		
	
	ELSE 0
	END



	, [Lab] = CASE
	WHEN y.[ServiceDateFrom] <  '2023-04-01' and RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319') THEN IIF(COV.[JK] is null or COV.[JK] = 0, Round([Amount] * 0.82, 2), Round(COV.[JK] * 1.00, 2))
	WHEN y.[ServiceDateFrom] >= '2023-04-01' and RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2023-01-01' and '2025-12-31') THEN IIF(LAB1.[RATE] is null or LAB1.[RATE] = 0, IIF(COV.[JK] is null or COV.[JK] = 0, 0, Round(COV.[JK] * 0.7, 2)), Round(LAB1.[RATE] * 0.7, 2)) 
	ELSE 0
	END




	, [Radiology] = CASE
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') THEN Round(x.[Amount] * 0.82, 2)
	ELSE 0
	END



	, [Radiation_Therapy] = CASE
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateTo] between '2020-01-01' and '2021-04-30') THEN IIF(M1.[RATE] is null, 0, Round(M1.[RATE] * 7.15 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateTo] between '2021-05-01' and '2021-12-31') THEN IIF(M1.[RATE] is null, 0, Round(M1.[RATE] * 8.84 * Quantity, 2))
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateTo] between '2022-01-01' and '2023-03-31') THEN IIF(M1.[RATE] is null, 0, Round(M1.[RATE] * 8.84 * Quantity, 2))	
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateTo] between '2023-04-01' and '2023-12-31') THEN IIF(M1.[RATE] is null, 0, Round(M1.[RATE] * 9.79 * Quantity, 2))		
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateTo] between '2024-01-01' and '2024-12-31') THEN IIF(M1.[RATE] is null, 0, Round(M1.[RATE] * 10.22 * Quantity, 2))		
	WHEN (RevenueCode IN ('333') or (RevenueCode IN ('330','339') and (ProcedureCodeNumeric between 77261 and 77399) or (ProcedureCodeNumeric between 77401 and 77435) or (ProcedureCodeNumeric between 77469 and 77525))) and (y.[ServiceDateTo] between '2025-01-01' and '2025-12-31') THEN IIF(M1.[RATE] is null, 0, Round(M1.[RATE] * 10.89 * Quantity, 2))		
	
	ELSE 0
	END



	, [Diagnostics] = CASE
	WHEN RevenueCode IN ('460','469','470','471','472','479','480','482','483','489','730','731','732','739','740','920','921','922','923','924','925','929') THEN Round(x.[Amount] * 0.82, 2)
	
	ELSE 0
	END



	, case
	WHEN (y.[ServiceDateTo] between '2020-01-27' and '2020-03-31') and [dp].[Dx] like '%B97.29%'	THEN 1
	WHEN (y.[ServiceDateTo] between '2020-04-01' and '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1
	WHEN (y.[ServiceDateTo] > '2020-11-01') and [dp].[Dx] like '%U07.1%'	THEN 1 --and [dp].[Px] is not null
	ELSE 0
	END As [COVID]



Into #Step2
From #Step1_Charges as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px] as dp on x.[EncounterID] = dp.[EncounterID] and x.[Sequence] = dp.[Sequence]

	LEFT JOIN [Analytics].[dbo].[MedicareFeeSchedule_Locality_1] as M1 on x.[ProcedureCode] = M1.[HCPCS] and M1.[MOD] = IIF(x.[Modifier1] is null or x.[Modifier1] NOT IN ('26','TC'), '00', x.[Modifier1]) and (y.ServiceDateTo between M1.[StartDate] and M1.[EndDate])
	LEFT JOIN [Analytics].[dbo].[MAC-Covid-19-Testing] as COV on COV.[CPT_Code] = x.[ProcedureCode]
	LEFT JOIN [Analytics].[dbo].[Medicare Lab Fee Schedule]			as LAB1 on LAB1.[HCPCS] = x.[ProcedureCode] and x.ServiceDateFrom between LAB1.[StartDate] AND LAB1.[EndDate] AND LAB1.[MOD] IS NULL




	LEFT JOIN [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2023]	as cbp_crn_2023 on cbp_crn_2023.[CPT4] = x.[ProcedureCode] and IIF(x.[Modifier1] is null or x.[Modifier1] NOT IN ('CS'), '00', x.[Modifier1]) = cbp_crn_2023.[Modifier]
	LEFT JOIN [Analytics].[dbo].[GHI_CBP_CRN_Fee_Schedule_2025]					as cbp_crn_2025 on cbp_crn_2025.[CPT4]	= x.[ProcedureCode] and (y.[ServiceDateFrom] between cbp_crn_2025.[StartDate] and cbp_crn_2025.[EndDate])


ORDER BY [EncounterID], x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate], [RevenueCode], [ProcedureCode], [OriginalPayment], [Amount]
	
	, [OP_Default]		= IIF([ER]=0 and [AS]=0 and [Cardiac_Cath]=0 and [PTCA]=0 and [Gamma_Knife]=0 and [Implants]=0 and [Blood]=0 and [Dialysis]=0 and [Drugs]=0 and [Chemotherapy]=0 and [Lab]=0 and [Radiology]=0 and [Radiation_Therapy]=0 and [Diagnostics]=0 and [Lab]= 0, [OP_Default], 0)
	, [ER]
	, [AS]				= IIF([Cardiac_Cath]=0 and [PTCA]=0 and [Gamma_Knife]=0, [AS], 0)
	, [Cardiac_Cath]
	, [PTCA]
	, [Gamma_Knife]
	, [Implants]
	, [Blood]
	, [Dialysis]
	, [Drugs]			= IIF( (modifier1 not in ('FB','SL') or Modifier1 IS NULL), [Drugs], 0)
	, [Chemotherapy]
	, [Lab]
	, [Radiology]			= IIF([Radiation_Therapy]=0, [Radiology], 0)
	, [Radiation_Therapy]
	, [Diagnostics]
	, [COVID]
	, [Fs_Default]
Into #Step3
From #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]

	, SUM([OP_Default])				as [OP_Default]
	, sum([Fs_Default]) as [Fs_Default]
	, MAX([ER])						as [ER]
	, MAX([AS])						as [AS]
	, MAX([Cardiac_Cath])			as [Cardiac_Cath]
	, MAX([PTCA])					as [PTCA]
	, MAX([Gamma_Knife])				as [Gamma_Knife]
	, SUM([Implants])				as [Implants]
	, SUM([Blood])					as [Blood]
	, MAX([Dialysis])				as [Dialysis]
	, SUM([Drugs])					as [Drugs]
	, MAX([Chemotherapy])			as [Chemotherapy]
	, SUM([Lab])						as [Lab]
	, SUM([Radiology])				as [Radiology]	
	, SUM([Radiation_Therapy])		as [Radiation_Therapy]
	, SUM([Diagnostics])				as [Diagnostics]
	, MAX([COVID])					as [COVID]

Into #Step3_1
From #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]

	, SUM([OP_Default])				as [OP_Default]
	, sum([Fs_Default]) as [Fs_Default]
	, MAX([ER])						as [ER]
	, MAX([AS])						as [AS]
	, MAX([Cardiac_Cath])			as [Cardiac_Cath]
	, MAX([Gamma_Knife])				as [Gamma_Knife]
	, SUM([Implants])				as [Implants]
	, SUM([Blood])					as [Blood]
	, SUM([Dialysis])				as [Dialysis]
	, SUM([Drugs])					as [Drugs]
	, SUM([Chemotherapy])			as [Chemotherapy]
	, SUM([Lab])						as [Lab]
	, SUM([Radiology])				as [Radiology]	
	, SUM([Radiation_Therapy])		as [Radiation_Therapy]
	, SUM([Diagnostics])				as [Diagnostics]
	, MAX([COVID])					as [COVID]

Into #Step3_2
From #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]

	, [Implants]
	, [Blood]					= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0, [Blood], 0)
	, [Drugs]
	, [Gamma_Knife]				
	, [Cardiac_Cath]				= IIF([Gamma_Knife]=0, [Cardiac_Cath], 0)
	, [AS]						= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0, [AS], 0)
	, [Chemotherapy]				= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0, [Chemotherapy], 0)
	, [Dialysis]					= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0, [Dialysis], 0)
	, [ER]						= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0 and [Dialysis]=0, [ER], 0)
	, [Diagnostics]				= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0 and [Dialysis]=0 and [ER]=0, [Diagnostics], 0)
	, [Radiology]				= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0 and [Dialysis]=0 and [ER]=0, [Radiology], 0)
	, [Lab]						= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0 and [Dialysis]=0 and [ER]=0 and [Diagnostics] = 0 , [Lab], 0)
	, [Radiation_Therapy]		= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0 and [Dialysis]=0 and [ER]=0, [Radiation_Therapy], 0)

	, [Fs_Default]				= IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0 and [Dialysis]=0 and [ER]=0 and [Lab] = 0, [Fs_Default], 0)
	
	, [OP_Default]				= IIF( [Implants] = 0 and [Blood] = 0 and [Drugs] = 0 and [Fs_Default] = 0 and [Gamma_Knife]=0 and [Cardiac_Cath]=0 and [AS]=0 and [Chemotherapy]=0 and [Dialysis]=0 and [ER]=0 and [Lab] = 0, [OP_Default], 0)

	, [COVID]

INTO #Step4
FROM #Step3_2

-- ============================================================================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE TABLE : #Step3 (explicit narrow column list — post-inline-suppression, no LEAD slots in this script)
-- HIERARCHY TABLE : #Step4 (encounter-level suppression outcomes)
-- TOTAL PRICE TABLE : #Step5
--
-- COLUMN SURVIVAL TRACE:
--   #Step3 is built with an EXPLICIT column list from #Step2.
--   Confirmed present in #Step3: EncounterID, ServiceDate, RevenueCode, ProcedureCode,
--     OriginalPayment, Amount, OP_Default, ER, AS, Cardiac_Cath, PTCA, Gamma_Knife,
--     Implants, Blood, Dialysis, Drugs, Chemotherapy, Lab, Radiology, Radiation_Therapy,
--     Diagnostics, COVID, Fs_Default.
--   NOT present in #Step3: Sequence, BillCharges, Quantity, ProcedureCodeNumeric,
--     Modifier1, Plan, Payer01Code, Payer01Name, ServiceDateFrom, ServiceDateTo.
--   Sequence, BillCharges, Quantity are recovered via LEFT JOIN to #Step2 on
--     EncounterID + ServiceDate. BillCharges and Quantity are display-only columns
--     (no payment formula in this script requires BillCharges at line level —
--     Drugs is Amount*0.29, Radiation_Therapy uses M1.RATE*multiplier*Quantity from
--     #Step2 pre-compute, all other formulas are self-contained in #Step3 columns).
--
-- HAS WINDOW REDUCTION: false — no LEAD() slot columns. #bSlots is omitted.
--
-- MAX CATEGORIES (one winner per encounter, PARTITION BY EncounterID):
--   ER, AS, Cardiac_Cath, Gamma_Knife, COVID (INDICATOR_FLAG)
--
-- HYBRID CATEGORIES (MAX in AGGREGATE_DATE, SUM in AGGREGATE_ENC;
--   one winner per EncounterID+ServiceDate, PARTITION BY EncounterID+ServiceDate):
--   Dialysis, Chemotherapy
--
-- NOTE ON PTCA: PTCA appears in #Step3 LINE_PRICING and #Step3 output but is NOT
--   present in #Step3_2 AGGREGATE_ENC (it was dropped from that GROUP BY).
--   PTCA IS present in #Step3_1 AGGREGATE_DATE (MAX). PTCA IS present in #Step4
--   (HIERARCHY). PTCA is confirmed in #Step3 column list. Classification:
--   agg_date=MAX, agg_enc=absent (dropped). #Step4 references [PTCA] directly.
--   Treat as MAX (one winner per encounter) — the encounter-level value in #Step4
--   comes from the MAX across dates in #Step3_1, then passed through to #Step3_2
--   implicitly via the #Step4 SELECT which reads from #Step3_2. Wait — re-trace:
--   #Step3_2 SELECT does NOT include PTCA (it was omitted). #Step4 SELECT reads from
--   #Step3_2 and also does NOT include PTCA explicitly, meaning #Step4.[PTCA] = 0
--   always (column would not exist). However the HIERARCHY step in #Step4 references
--   [PTCA] in IIF conditions for AS suppression: IIF([Gamma_Knife]=0 and [Cardiac_Cath]=0
--   and [AS]=0...). Since #Step3_2 does not include PTCA, #Step4 also does not include
--   PTCA as a standalone column. Therefore s4.[PTCA] cannot be referenced in
--   #LineBreakdown. PTCA is excluded from LinePayment and ServiceCategory joins.
--   PTCA values in #Step3 lines are still present and can be labeled for display.
--   ServiceCategory for PTCA: use b.[PTCA] directly (no s4.[PTCA] guard — use b.[PTCA]>0
--   as the condition, with rn_PTCA MAX classification, $0 LinePayment since it does
--   not appear in #Step5 Price sum either — confirmed: #Step5 sums do NOT include PTCA).
--   PTCA is treated as an INFORMATIONAL MAX category: labeled in ServiceCategory,
--   but LinePayment = $0 (not in the Price sum). This is consistent with the fact
--   that PTCA was dropped from #Step3_2 and #Step4 and #Step5.
--
-- SUM CATEGORIES (all matching lines contribute, PARTITION BY EncounterID for ranking only):
--   OP_Default, Fs_Default, Implants, Blood, Drugs, Lab, Radiology,
--   Radiation_Therapy, Diagnostics
--
-- INDICATOR_FLAG CATEGORIES (binary 0/1, $0 LinePayment):
--   COVID
--
-- SUPPRESSION HIERARCHY (from #Step4, tier 1 = highest priority):
--   1. Gamma_Knife      (unconditional)
--   2. Cardiac_Cath     (suppressed if Gamma_Knife != 0)
--   3. AS               (suppressed if Gamma_Knife OR Cardiac_Cath != 0)
--   4. Chemotherapy     (suppressed if Gamma_Knife OR Cardiac_Cath OR AS != 0)
--   5. Dialysis         (suppressed if Gamma_Knife OR Cardiac_Cath OR AS OR Chemotherapy != 0)
--   6. ER               (suppressed if Gamma_Knife OR Cardiac_Cath OR AS OR Chemotherapy OR Dialysis != 0)
--   7. Diagnostics      (suppressed if Gamma_Knife OR Cardiac_Cath OR AS OR Chemotherapy OR Dialysis OR ER != 0)
--   8. Radiology        (suppressed if Gamma_Knife OR Cardiac_Cath OR AS OR Chemotherapy OR Dialysis OR ER != 0)
--   9. Radiation_Therapy(suppressed if Gamma_Knife OR Cardiac_Cath OR AS OR Chemotherapy OR Dialysis OR ER != 0)
--  10. Lab              (suppressed if Gamma_Knife OR Cardiac_Cath OR AS OR Chemotherapy OR Dialysis OR ER OR Diagnostics != 0)
--  11. Fs_Default       (suppressed if Gamma_Knife OR Cardiac_Cath OR AS OR Chemotherapy OR Dialysis OR ER OR Lab != 0)
--  12. OP_Default       (suppressed if Implants OR Blood OR Drugs OR Fs_Default OR Gamma_Knife OR
--                         Cardiac_Cath OR AS OR Chemotherapy OR Dialysis OR ER OR Lab != 0)
--   Special: Blood suppressed if Gamma_Knife OR Cardiac_Cath OR AS != 0
--            Drugs: unconditional (but Modifier FB/SL zeroed in #Step3)
--            Implants: unconditional
--            PTCA: dropped after #Step3_1 — informational only, $0 LinePayment
-- ============================================================================================================================

-- ============================================================================================================================
-- BLOCK 1: #bRanked
-- One ROW_NUMBER() per MAX category (EncounterID partition),
-- one per HYBRID category (EncounterID+ServiceDate partition),
-- one per INDICATOR_FLAG category (EncounterID partition).
-- No WINDOW_REDUCTION categories in this script — no slot columns.
-- Count check:
--   MAX:            ER, AS, Cardiac_Cath, Gamma_Knife       = 4
--   PTCA (info):    PTCA                                    = 1
--   HYBRID:         Dialysis, Chemotherapy                  = 2
--   INDICATOR_FLAG: COVID                                   = 1
--   Total ROW_NUMBER() calls = 8
-- SOURCE: #Step3 — confirmed to contain all pricing category columns.
-- #Step3 does NOT contain Sequence or Amount at this level (explicit narrow list).
-- ORDER BY uses ServiceDate as tiebreaker (Sequence not available in #Step3).
-- ============================================================================================================================
SELECT
    b.*
    -- MAX categories: PARTITION BY EncounterID
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]          DESC, b.[ServiceDate] ASC) AS rn_ER
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID]
          ORDER BY b.[AS]          DESC, b.[ServiceDate] ASC) AS rn_AS
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Cath] DESC, b.[ServiceDate] ASC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife] DESC, b.[ServiceDate] ASC) AS rn_Gamma_Knife
    -- PTCA: informational MAX (not in #Step5 Price sum, not in #Step4 as standalone)
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA]        DESC, b.[ServiceDate] ASC) AS rn_PTCA
    -- HYBRID categories: PARTITION BY EncounterID + ServiceDate
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Dialysis]    DESC, b.[EncounterID] ASC) AS rn_Dialysis
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Chemotherapy] DESC, b.[EncounterID] ASC) AS rn_Chemotherapy
    -- INDICATOR_FLAG: COVID — binary 0/1, PARTITION BY EncounterID same as MAX
    , ROW_NUMBER() OVER (
          PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]       DESC, b.[ServiceDate] ASC) AS rn_COVID
INTO #bRanked
FROM #Step3 b;

-- ============================================================================================================================
-- NOTE: #bSlots is OMITTED — analysis.has_window_reduction = false.
-- There are no LEAD() slot columns (AS1-AS10, Rad1-Rad10, etc.) in this script.
-- ============================================================================================================================

-- ============================================================================================================================
-- BLOCK 3: #LineBreakdown
-- One row per charge line (EncounterID + ServiceDate granularity from #Step3).
-- #Step3 does not contain Sequence, BillCharges, or Quantity.
-- These are recovered via LEFT JOIN to #Step2 on EncounterID + ServiceDate.
-- Because one EncounterID+ServiceDate may have multiple lines in #Step2,
-- the join can produce fan-out. SELECT DISTINCT collapses this where safe.
-- However: since #Step3 itself was built SELECT DISTINCT from #Step2, each
-- (EncounterID, ServiceDate, RevenueCode, ProcedureCode) combination is unique
-- in #Step3 / #bRanked. The LEFT JOIN to #Step2 uses those four columns as the
-- join key to recover Sequence, BillCharges, Quantity without fan-out.
-- ============================================================================================================================
SELECT
    b.[EncounterID]
    , src.[Sequence]                                          AS [Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                              AS [BilledAmount]
    , src.[Quantity]                                          AS [Quantity]
    , src.[BillCharges]                                       AS [BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Hierarchy order exactly mirrors #Step4 suppression IIF chain.
    -- s4.[CAT] != 0 means the category survived for this encounter.
    -- For SUM categories, all lines with b.[CAT] > 0 receive the label.
    -- For MAX/HYBRID categories, only the rn=1 winner receives the label;
    -- rn>1 rows receive the _Non_Winner label.
    -- PTCA is informational — labeled even though $0 LinePayment.
    -- COVID INDICATOR_FLAG placed last, after Suppressed_By_Hierarchy.
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- TIER 1: Gamma_Knife (MAX)
        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN IIF(b.rn_Gamma_Knife = 1, 'Gamma_Knife', 'Gamma_Knife_Non_Winner')

        -- TIER 2: Cardiac_Cath (MAX)
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- TIER 3: AS (MAX)
        WHEN s4.[AS] != 0
         AND b.[AS] > 0
            THEN IIF(b.rn_AS = 1, 'AS', 'AS_Non_Winner')

        -- TIER 4: Chemotherapy (HYBRID)
        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN IIF(b.rn_Chemotherapy = 1, 'Chemotherapy', 'Chemotherapy_Non_Winner')

        -- TIER 5: Dialysis (HYBRID)
        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN IIF(b.rn_Dialysis = 1, 'Dialysis', 'Dialysis_Non_Winner')

        -- TIER 6: ER (MAX)
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- TIER 7: Diagnostics (SUM)
        WHEN s4.[Diagnostics] != 0
         AND b.[Diagnostics] > 0
            THEN 'Diagnostics'

        -- TIER 8: Radiology (SUM)
        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Radiology'

        -- TIER 9: Radiation_Therapy (SUM)
        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'Radiation_Therapy'

        -- TIER 10: Lab (SUM)
        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Lab'

        -- TIER 11: Fs_Default (SUM)
        WHEN s4.[Fs_Default] != 0
         AND b.[Fs_Default] > 0
            THEN 'Fs_Default'

        -- TIER 12: Implants (SUM — unconditional in hierarchy)
        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Implants'

        -- TIER 13: Blood (SUM — suppressed if Gamma_Knife/Cardiac_Cath/AS != 0)
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- TIER 14: Drugs (SUM — unconditional, Modifier FB/SL already zeroed)
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- TIER 15: OP_Default (SUM — catch-all, suppressed by most categories)
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- PTCA: informational label (dropped from #Step4 encounter aggregation;
        --       not in Price sum; label only, $0 LinePayment)
        WHEN b.[PTCA] > 0
            THEN IIF(b.rn_PTCA = 1, 'PTCA_Informational', 'PTCA_Informational_Non_Winner')

        -- Suppressed: line has a non-zero pricing value but #Step4 hierarchy zeroed it
        WHEN (
              ISNULL(b.[ER],              0)
            + ISNULL(b.[AS],              0)
            + ISNULL(b.[Cardiac_Cath],   0)
            + ISNULL(b.[Gamma_Knife],    0)
            + ISNULL(b.[PTCA],           0)
            + ISNULL(b.[Dialysis],       0)
            + ISNULL(b.[Chemotherapy],   0)
            + ISNULL(b.[Implants],       0)
            + ISNULL(b.[Blood],          0)
            + ISNULL(b.[Drugs],          0)
            + ISNULL(b.[Lab],            0)
            + ISNULL(b.[Radiology],      0)
            + ISNULL(b.[Radiation_Therapy], 0)
            + ISNULL(b.[Diagnostics],    0)
            + ISNULL(b.[Fs_Default],     0)
            + ISNULL(b.[OP_Default],     0)
            + ISNULL(b.[COVID],          0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- INDICATOR_FLAG: COVID — binary 0/1, placed after all dollar and suppressed labels
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN 'Contracted flat rate per contract period (Gamma Knife CPT list: 61796-61800/63620/63621/G0339/G0340)'

        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period (Cardiac Cath: Rev 481 with ProcedureCodeNumeric 93451-93583)'

        WHEN s4.[AS] != 0
         AND b.[AS] > 0
            THEN 'Contracted flat rate per contract period (Ambulatory Surgery: Rev 360/361/362/369/490-499/750/790)'

        WHEN s4.[Chemotherapy] != 0
         AND b.[Chemotherapy] > 0
            THEN 'Contracted per diem per contract period (Chemotherapy: Rev 280/289/330/331/332/335/339 or Rev 260/760 + chemo CPTs 96401-96549/96360-96379)'

        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN 'Contracted per diem per contract period (Dialysis: Rev 820-825/829/830-835/839/840-845/849/850-855/859/870-874/880-882/889)'

        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN 'Contracted flat rate per contract period (ER: Rev 450/451/452/456/459)'

        WHEN s4.[Diagnostics] != 0
         AND b.[Diagnostics] > 0
            THEN 'Pct of charges: Amount x 82% (Diagnostics: Rev 460/469/470-472/479/480/482/483/489/730-732/739/740/920-925/929)'

        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Pct of charges: Amount x 82% (Radiology: Rev 320-329/330/340-349/350-352/359/400-404/409/610-612/614-616/618/619)'

        WHEN s4.[Radiation_Therapy] != 0
         AND b.[Radiation_Therapy] > 0
            THEN 'RBRVS Rate (M1) x period multiplier (7.15-10.89) x Quantity (Radiation Therapy: Rev 333 or Rev 330/339 + CPT 77261-77399/77401-77435/77469-77525)'

        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Pre-2023-04-01: Amount x 82% or MAC COVID rate x 100%; 2023+: Medicare Lab FS x 70% or MAC COVID rate x 70% (Lab: Rev 300-312/314/319; 2023+ also Rev 923/924/925)'

        WHEN s4.[Fs_Default] != 0
         AND b.[Fs_Default] > 0
            THEN 'GHI CBP CRN Fee Schedule Rate x multiplier x Quantity (2020-2024: Rate x 3.25; 2025: Rate x 3.75 — specific CPT list)'

        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Pct of charges: Amount x 36% (Implants: Rev 274/275/276/278/279; Amount > 1388; excl device pass-through codes; no suppression condition in hierarchy)'

        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Pct of charges: Amount x 100% (Blood: Rev 380-387/389-392/399; suppressed if Gamma_Knife/Cardiac_Cath/AS != 0)'

        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Pct of charges: Amount x 29% (Drugs: Rev 636; excl Modifier FB/SL)'

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'Pct of charges: Amount x 82% — OP Default catch-all (all procedure codes; suppressed when any named category applies)'

        WHEN b.[PTCA] > 0
            THEN 'Contracted flat rate per contract period — INFORMATIONAL ONLY, $0 in Price sum (PTCA dropped from encounter aggregation in #Step3_2/#Step4; Rev 360/369/481/490-499 + PTCA CPT list)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag — binary 0/1 value, no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:    IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    -- HYBRID: IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    --         rn partitioned by EncounterID+ServiceDate; each date's
    --         winner (rn=1) contributes its value; rn>1 = $0.
    -- SUM:    IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- PTCA:   $0 — informational only (not in #Step5 Price sum)
    -- COVID:  $0 — binary flag, never add to LinePayment
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1, ISNULL(b.[Gamma_Knife], 0), 0), 0)
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1, ISNULL(b.[Cardiac_Cath], 0), 0), 0)
        + IIF(s4.[AS] != 0,
              IIF(b.rn_AS = 1, ISNULL(b.[AS], 0), 0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1, ISNULL(b.[ER], 0), 0), 0)
          -- HYBRID categories: IIF(rn=1) partitioned by EncounterID+ServiceDate
        + IIF(s4.[Chemotherapy] != 0,
              IIF(b.rn_Chemotherapy = 1, ISNULL(b.[Chemotherapy], 0), 0), 0)
        + IIF(s4.[Dialysis] != 0,
              IIF(b.rn_Dialysis = 1, ISNULL(b.[Dialysis], 0), 0), 0)
          -- SUM categories
        + IIF(s4.[Diagnostics] != 0,        ISNULL(b.[Diagnostics],       0), 0)
        + IIF(s4.[Radiology] != 0,          ISNULL(b.[Radiology],         0), 0)
        + IIF(s4.[Radiation_Therapy] != 0,  ISNULL(b.[Radiation_Therapy], 0), 0)
        + IIF(s4.[Lab] != 0,                ISNULL(b.[Lab],               0), 0)
        + IIF(s4.[Fs_Default] != 0,         ISNULL(b.[Fs_Default],        0), 0)
        + IIF(s4.[Implants] != 0,           ISNULL(b.[Implants],          0), 0)
        + IIF(s4.[Blood] != 0,              ISNULL(b.[Blood],             0), 0)
        + IIF(s4.[Drugs] != 0,              ISNULL(b.[Drugs],             0), 0)
        + IIF(s4.[OP_Default] != 0,         ISNULL(b.[OP_Default],        0), 0)
          -- PTCA: $0 contribution (informational only)
          -- COVID: $0 contribution (binary flag)
      , 2)

    -- No NCCI bundle step in this script
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4  ON s4.[EncounterID] = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover Sequence, BillCharges, Quantity not present in #Step3.
-- Join on EncounterID + ServiceDate + RevenueCode + ProcedureCode to avoid fan-out
-- (these four columns are the SELECT DISTINCT key used when building #Step3 from #Step2).
LEFT  JOIN #Step2  src ON  src.[EncounterID]   = b.[EncounterID]
                       AND src.[ServiceDate]    = b.[ServiceDate]
                       AND src.[RevenueCode]    = b.[RevenueCode]
                       AND src.[ProcedureCode]  = b.[ProcedureCode]
ORDER BY b.[EncounterID], src.[Sequence];
-- ============================================================================================================================
-- END PRICE BREAKDOWN INSERTED SECTION
-- ============================================================================================================================



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	, [Implants]
	+[Blood]
	+[Drugs]	
	+[Gamma_Knife]		    
	+[Cardiac_Cath]		    
	+[AS]				    
	+[Chemotherapy]		    
	+[Dialysis]			    
	+[ER]				    
	+[Lab]				    
	+[Radiology]		    
	+[Radiation_Therapy]    
	+[Diagnostics]
	+[OP_Default]
	+[Fs_Default]
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
	, y.[Gamma_Knife]		    
	, y.[Cardiac_Cath]		    
	, y.[AS]				    
	, y.[Chemotherapy]		    
	, y.[Dialysis]			    
	, y.[ER]				    
	, y.[Lab]				    
	, y.[Radiology]		    
	, y.[Radiation_Therapy]    
	, y.[Diagnostics]		    
	, y.[OP_Default]
	, y.[COVID]
	, y.[Fs_Default]

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
	, DATEDIFF(DAY, x.[ServiceDateTo], GETDATE()) - 365 as DaysLeft
	
	, IIF(ISNULL(x.[Implants]			,0) > 0,      'Implants - '				+ Cast(x.[Implants]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Blood]				,0) > 0,      'Blood - '				+ Cast(x.[Blood]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Drugs]				,0) > 0,      'Drugs - '				+ Cast(x.[Drugs]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Gamma_Knife]			,0) > 0,      'Gamma_Knife - '			+ Cast(x.[Gamma_Knife]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Cardiac_Cath]		,0) > 0,      'Cardiac_Cath - '			+ Cast(x.[Cardiac_Cath]			as varchar) + ', ','')
	+IIF(ISNULL(x.[AS]					,0) > 0,      'AS - '					+ Cast(x.[AS]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Chemotherapy]		,0) > 0,      'Chemotherapy - '			+ Cast(x.[Chemotherapy]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Dialysis]			,0) > 0,      'Dialysis - '				+ Cast(x.[Dialysis]				as varchar) + ', ','')
	+IIF(ISNULL(x.[ER]					,0) > 0,      'ER - '					+ Cast(x.[ER]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Lab]					,0) > 0,      'Lab - '					+ Cast(x.[Lab]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiology]			,0) > 0,      'Radiology - '			+ Cast(x.[Radiology]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiation_Therapy]  	,0) > 0,      'Radiation_Therapy - '	+ Cast(x.[Radiation_Therapy]	as varchar) + ', ','')
	+IIF(ISNULL(x.[Diagnostics]			,0) > 0,      'Diagnostics - '			+ Cast(x.[Diagnostics]			as varchar) + ', ','')
	+IIF(ISNULL(x.[OP_Default]			,0) > 0,      'OP_Default - '			+ Cast(x.[OP_Default]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Fs_Default]			,0) > 0,      'Fs_Default - '			+ Cast(x.[Fs_Default]			as varchar) + ', ','')
	as ExpectedDetailed



--,p.[expected_payment_analyst]
--	,x.[Implants]
--	,x.[Blood]
--	,x.[Drugs]	
--	,x.[Gamma_Knife]		    
--	,x.[Cardiac_Cath]		    
--	,x.[AS]				    
--	,x.[Chemotherapy]		    
--	,x.[Dialysis]			    
--	,x.[ER]				    
--	,x.[Lab]				    
--	,x.[Radiology]		    
--	,x.[Radiation_Therapy]    
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
			'Seq:'  + CAST(lb.[Sequence]       AS VARCHAR(MAX)) +
			' CPT:' + ISNULL(CAST(lb.[ProcedureCode]  AS VARCHAR(MAX)), '') +
			' Rev:' + ISNULL(CAST(lb.[RevenueCode]    AS VARCHAR(MAX)), '') +
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
-- #LineBreakdown = one row per charge line (EncounterID + ServiceDate +
--   RevenueCode + ProcedureCode granularity, joined to #Step2 for Sequence).
-- ServiceCategory = final hierarchy decision (from #Step4 suppression logic).
-- 'Suppressed_By_Hierarchy' = line matched a category but a higher-tier
--   category won for this encounter.
-- 'No_Payment_Category' = line did not match any pricing pattern.
-- 'PTCA_Informational' = PTCA line labeled for display only; $0 LinePayment
--   because PTCA was dropped from #Step3_2 / #Step4 / #Step5 Price sum.
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
    , 'NYP_COL_GHI_COM_OP'
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
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_GHI_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- -- EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;