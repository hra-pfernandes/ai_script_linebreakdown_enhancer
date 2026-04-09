
--Removed 'Other op default' and added cigna lab fs logic 2.20.2025 SC
--Added Cigna RBRVS 2022 FS for labs 4.1.2025 SC
--Added Laparoscopy 2023 rate 4.1.2025 SC 
--Updated rates for contract year 2025 by Naveen Abboju 07.18.2025 

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
	LEFT JOIN [PRS].[dbo].Underpayments AS p1 ON p.[patient_id_real] = p1.[patient_id_real]

where TypeOfBill = 'Outpatient'

	and Payer01Name in (
	 'APWU HEALTH PLAN CIGNA'
	,'CIGNA AFTRA HEALTH PLAN'
	,'CIGNA HMO/POS'
	,'CIGNA GLOBAL/INTERNATIONAL'
	,'CIGNA OPEN ACCESS PLUS'
	,'CIGNA PPO'
	,'CIGNA HEALTH PLAN'
	,'CIGNA SAMBA'
	,'CONNECTICUT GENERAL LIFE INS CO.'
	,'GREAT WEST HEALTHCARE'
	,'HEALTHPARTNERS'
	,'NALC HEALTH BENEFIT PLAN'
	,'TUFTS CARELINK'
	,'CIGNA TRUSTMARK'
	,'ALLIED BENEFIT'
	,'CIGNA GOLDMAN SACHS'
	,'WELLFLEET NYU STUDENT HEALTH'
	,'HEALTH ALLIANCE PLAN (HAP)'
	,'CIGNA LIFE SOURCE 2'
	,'CIGNA LIFE SOURCE 3'
	,'APWU HEALTH PLAN'
	,'MVP CIGNA'
	,'MSM CIGNA PPO'
	,'JUILLIARD SCHOOL CIGNA PPO'
	,'CIGNA LIFE SOURCE 1'
	)

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
	--    and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	--and y.[AGE] < 65

	AND x.[ServiceDateFrom] < '2026-01-01'

Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric


INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x


where x.[EncounterID] in (Select [EncounterID]
from #Step1)

--***********************************************************************************************************************************************************************************************************************************************************************************************************
select x.*
into #modifier
from #Step1_Charges x
WHERE RevenueCode IN ('360','361','369','490','499','750','759') and Modifier1 = '50'

--***********************************************************************************************************************************************************************************************************************************************************************************************************

insert into #Step1_Charges
select *
from #modifier;

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]


	, [OP_Default] = CASE
	WHEN (x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') OR ProcedureCode IS NULL) and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN Round([Amount] * 0.647, 2)
	WHEN (x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') OR ProcedureCode IS NULL) and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN Round([Amount] * 0.669, 2)
	WHEN (x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') OR ProcedureCode IS NULL) and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN Round([Amount] * 0.605, 2)
	WHEN (x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') OR ProcedureCode IS NULL) and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN Round([Amount] * 0.605, 2)	
	WHEN (x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') OR ProcedureCode IS NULL) and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN Round([Amount] * 0.589, 2)	
	WHEN (x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') OR ProcedureCode IS NULL) and (y.[ServiceDateFrom] between '2023-02-01' and '2025-12-31') THEN Round([Amount] * 0.571, 2)
	ELSE 0
	END



	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 1785	
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 1821
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 1821	
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 1912		
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 1912		
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 1954
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 2009
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 2082
	WHEN RevenueCode IN ('450','451','452','456','459') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 2069
	ELSE 0
	END




	, [AS] = CASE -- As per Ricardo's suggestion using 2023 Cigna ASC grouper and Incidental FS for 2025 07.17.2025			
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and ProcedureCode IN		(SELECT [CPT]
		FROM [QNS].[FSG].[Cigna_Grouper_V40_May_2022]
		WHERE [Grouper] IN ('79')) and y.[ServiceDateFrom] < '2023-02-01' THEN 547
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and ProcedureCode IN		(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]
		WHERE [Grouper] IN ('79')) and y.[ServiceDateFrom] between '2023-02-01' AND '2023-12-31' THEN 559
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and ProcedureCode IN		(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]
		WHERE [Grouper] IN ('79')) and y.[ServiceDateFrom] between '2024-01-01' AND '2025-01-31' THEN 575
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and ProcedureCode IN		(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]
		WHERE [Grouper] IN ('79')) and y.[ServiceDateFrom] between '2025-02-01' AND '2025-06-30' THEN 596
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and ProcedureCode IN		(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]
		WHERE [Grouper] IN ('79')) and y.[ServiceDateFrom] between '2025-07-01' AND '2025-12-31' THEN 592

	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and (ProcedureCode IN	(SELECT [CPT]
		FROM [QNS].[FSG].[Cigna_Grouper_V40_May_2022]) AND ProcedureCode NOT IN (SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Incidentals_2023])) and y.[ServiceDateFrom] < '2023-02-01' THEN 7333
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and (ProcedureCode IN	(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]) AND ProcedureCode NOT IN (SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Incidentals_2023])) and y.[ServiceDateFrom] between '2023-02-01' AND '2023-12-31' THEN 7496
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and (ProcedureCode IN	(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]  ) AND ProcedureCode NOT IN (SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Incidentals_2023])) and y.[ServiceDateFrom] between '2024-01-01' AND '2025-01-31' THEN 7707		
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and (ProcedureCode IN	(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]  ) AND ProcedureCode NOT IN (SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Incidentals_2023])) and y.[ServiceDateFrom] between '2025-02-01' AND '2025-06-30' THEN 7984		
	WHEN RevenueCode IN ('360','361','369','490','499','750','759') and (ProcedureCode IN	(SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Grouper_2023]  ) AND ProcedureCode NOT IN (SELECT [CPT]
		FROM [Analytics].[FSG].[Cigna_Incidentals_2023])) and y.[ServiceDateFrom] between '2025-07-01' AND '2025-12-31' THEN 7938		
	ELSE 0
	END	



	, [Laparoscopy] = CASE
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 12739	
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 12994
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 12994	
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 13376
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 13643	
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 13946	
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 14339
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 14855
	WHEN ProcedureCode IN ('47562','47563','47564') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 14769
	ELSE 0
	END



	, [Cardiac_Cath] = CASE
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 13535	
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 13806
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 13806	
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 14212
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 14212		
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 14818	
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 14904		
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 15441		
	WHEN RevenueCode IN ('481') and (ProcedureCode between '93451' and '93583') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 15351		
	ELSE 0
	END

	--,ptca.encounterid 			
	, [PTCA] = CASE																																																																																																																					
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 71103	
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 72525
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 72525	
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 74658
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (ProcedureCodeNumeric between 93451 and 93583) and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 76151	
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608')/* or (ProcedureCodeNumeric between 93451 and 93583)*/ and ptca.encounterid is not null and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 77842	
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608')/* or (ProcedureCodeNumeric between 93451 and 93583)*/ and ptca.encounterid is not null and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 80033
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608')/* or (ProcedureCodeNumeric between 93451 and 93583)*/ and ptca.encounterid is not null and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 82914
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608')/* or (ProcedureCodeNumeric between 93451 and 93583)*/ and ptca.encounterid is not null and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 82434
	ELSE 0
	END

	
	, [Vascular_Angioplasty] = CASE
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 16743	
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 17078
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 17078	
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 17580
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 17932	
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 18330		
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 18846		
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 19524		
	WHEN ProcedureCode in ('35450','35452','35458','35460','35471','35472','35473','35474','35475','35476','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92975','92977','92978','92979','92980','92981','92982','92983','92984','92985','92986','92987','92988','92989','92990','92991','92992','92993','92994','92995','92996','92997','92998','C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 19411		
	ELSE 0
	END
	   

	, [Lithotripsy] = CASE
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31')	THEN 16180	
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31')	THEN 16504
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31')	THEN 16504	
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14')	THEN 16989
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31')	THEN 17329		
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31')	THEN 17714
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31')	THEN 18212
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30')	THEN 18868
	WHEN Revenuecode in ('790','799') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31')	THEN 18758
	ELSE 0
	END

	
	, [Gamma_Knife] = CASE
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 102570	
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 104621
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 104621	
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 107699
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 109852	
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 112291		
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 115452		
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 119608		
	WHEN ProcedureCode in ('61796','61797','61798','61799','61800','63620','63621','G0339','G0340') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 118916		
	ELSE 0
	END

	, [Hip_Replacement] = CASE
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 40088	
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 40088
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 40890	
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 42934
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 42934	
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 43887	
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 45123
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 46747
	WHEN ProcedureCode in ('27130','27132') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 46477
	ELSE 0
	END
	
	, [Knee_Replacement] = CASE
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 40088	
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 40088
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 40890	
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 42934
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 42934	
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 43887	
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 45285
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 46916
	WHEN ProcedureCode in ('27437','27438','27440','27441','27445','27446','27447') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 46644
	ELSE 0
	END

	, [Shoulder_Replacement] = CASE
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 48717	
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 48717
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 49691	
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 52176
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 52176	
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 53334	
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 54836	
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 56810	
	WHEN ProcedureCode in ('23470','23472','23473','23474') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 56481	
	ELSE 0
	END


	, [Cardiac_Rehab] = CASE
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 395	
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 403
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 403	
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 423
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 423	
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 423	
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 445	
	WHEN RevenueCode in ('943') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 461	
	
	ELSE 0
	END


	, [Implants] = CASE
	WHEN RevenueCode in ('274','275','276','278') AND (x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') OR ProcedureCode IS NULL)THEN Round(Amount * 0.36, 2)
	ELSE 0
	END


	, [Blood] = CASE
	WHEN RevenueCode between 380 and 399 THEN Round(Amount * 1.00, 2) 
	ELSE 0
	END


	, [Dialysis] = CASE
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 1637
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 1670	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 1670	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 1719	
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 1753
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 1792
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 1843
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 1909
	WHEN Revenuecode IN ('820','821','822','823','824','825','829','830','831','832','833','834','835','839','840','841','842','843','844','845','849','850','851','852','853','854','855','859','870','871','872','873','874','880','881','882','889') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 1898
	ELSE 0
	END



 	, [Drugs] = CASE
	WHEN RevenueCode IN ('634','635','636') or ProcedureCode IN ('Q0136','Q4054','Q4055') THEN Round(Amount * 0.29, 2)
	ELSE 0
	END



	, [Lab] = CASE
--	WHEN ProcedureCode IN ('87635') THEN 51.31
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31')	THEN IIF(COV.[JK] is null or COV.[JK] = 0, Round([Amount] * 0.479, 2), Round(COV.[JK] * 1.000, 2))
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31')	THEN IIF(COV.[JK] is null or COV.[JK] = 0, Round([Amount] * 0.496, 2), Round(COV.[JK] * 1.000, 2))
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31')	THEN IIF(COV.[JK] is null or COV.[JK] = 0, Round([Amount] * 0.448, 2), Round(COV.[JK] * 1.000, 2))
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14')	THEN IIF(COV.[JK] is null or COV.[JK] = 0, Round([Amount] * 0.448, 2), Round(COV.[JK] * 1.000, 2))
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31')	THEN IIF(COV.[JK] is null or COV.[JK] = 0, Round([Amount] * 0.437, 2), Round(COV.[JK] * 1.000, 2))	
	WHEN RevenueCode IN ('300','301','302','303','304','305','306','307','308','309','310','311','312','314','319','923','924','925') and (y.[ServiceDateFrom] between '2023-02-01' and '2025-12-31')	THEN IIF(RBRVS.[RATE] is null or RBRVS.[RATE] = 0, 0, Round(RBRVS.[RATE] * 0.70, 2)) * Quantity
	ELSE 0
	END

	-- ,RBRVS.[rate]


	, [Radiology] = CASE --MRI, CT Scan, PET Scan, Nuclear Medicine
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31')	THEN Round([Amount] * 0.479, 2)
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31')	THEN Round([Amount] * 0.496, 2)
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN Round([Amount] * 0.448, 2)
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14')	THEN Round([Amount] * 0.448, 2)
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN Round([Amount] * 0.437, 2)	
	WHEN RevenueCode IN ('320','321','322','323','324','325','326','327','328','329','330','340','340','341','342','343','344','345','346','347','348','349','350','351','352','359','400','401','402','403','404','409','610','611','612','614','615','616','618','619') and (y.[ServiceDateFrom] between '2023-02-01' and '2025-12-31') THEN Round([Amount] * 0.424, 2)		
	ELSE 0
	END



	, [PT/OT/ST] = CASE
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31')	THEN 212 * Quantity
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31')	THEN 212 * Quantity
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31')	THEN 212 * Quantity	
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14')	THEN 223 * Quantity
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31')	THEN 227 * Quantity
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31')	THEN 232 * Quantity	
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31')	THEN 239 * Quantity
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30')	THEN 247 * Quantity
	WHEN RevenueCode IN ('420','421','422','423','424','429','430', '431', '432', '434', '439') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31')	THEN 246 * Quantity
	ELSE 0
	END

	
	, [ECT] = CASE                                     
	WHEN RevenueCode IN ('901') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 1774 * Quantity
	WHEN RevenueCode IN ('901') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 1864 * Quantity
	WHEN RevenueCode IN ('901') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 1931 * Quantity
	WHEN RevenueCode IN ('901') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 1920 * Quantity

	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2020-04-01' and '2020-12-31') THEN 724
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2021-01-01' and '2021-03-31') THEN 724
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2021-04-01' and '2021-12-31') THEN 724
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2022-01-01' and '2022-03-14') THEN 760
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2022-03-15' and '2023-01-31') THEN 775	
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2023-02-01' and '2023-12-31') THEN 792	
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2024-01-01' and '2025-01-31') THEN 815
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2025-02-01' and '2025-06-30') THEN 844
	WHEN ProcedureCode IN ('90870') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 839
	ELSE 0
	END
	
	, [IOP] = CASE                                     
	WHEN RevenueCode IN ('905','906') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-06-31') THEN 524 * Quantity
	WHEN RevenueCode IN ('905','906') and (y.[ServiceDateFrom] between '2025-07-01' and '2025-12-31') THEN 521 * Quantity
	ELSE 0
	END



	, [Miscellaneous] = CASE 
	WHEN ProcedureCode = '90785'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 108 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 113 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 115, IIF(y.[ServiceDateFrom] < '2024-01-01', 118, IIF(y.[ServiceDateFrom] < '2025-02-01', 121, IIF(y.[ServiceDateFrom] < '2025-07-01', 125, 125)))))) * x.[Quantity]
	WHEN ProcedureCode = '90791'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 396 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 416 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 424, IIF(y.[ServiceDateFrom] < '2024-01-01', 433, IIF(y.[ServiceDateFrom] < '2025-02-01', 445, IIF(y.[ServiceDateFrom] < '2025-07-01', 461, 459)))))) * x.[Quantity]
	WHEN ProcedureCode = '90792'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 396 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 416 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 424, IIF(y.[ServiceDateFrom] < '2024-01-01', 433, IIF(y.[ServiceDateFrom] < '2025-02-01', 445, IIF(y.[ServiceDateFrom] < '2025-07-01', 461, 459)))))) * x.[Quantity]
	WHEN ProcedureCode = '90832'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 167 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 175 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 179, IIF(y.[ServiceDateFrom] < '2024-01-01', 183, IIF(y.[ServiceDateFrom] < '2025-02-01', 188, IIF(y.[ServiceDateFrom] < '2025-07-01', 195, 194)))))) * x.[Quantity]
	WHEN ProcedureCode = '90833'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 249 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 261 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 266, IIF(y.[ServiceDateFrom] < '2024-01-01', 272, IIF(y.[ServiceDateFrom] < '2025-02-01', 280, IIF(y.[ServiceDateFrom] < '2025-07-01', 290, 288)))))) * x.[Quantity]
	WHEN ProcedureCode = '90834'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 305 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 320 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 326, IIF(y.[ServiceDateFrom] < '2024-01-01', 333, IIF(y.[ServiceDateFrom] < '2025-02-01', 343, IIF(y.[ServiceDateFrom] < '2025-07-01', 356, 354)))))) * x.[Quantity]
	WHEN ProcedureCode = '90836'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 372 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 391 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 399, IIF(y.[ServiceDateFrom] < '2024-01-01', 408, IIF(y.[ServiceDateFrom] < '2025-02-01', 419, IIF(y.[ServiceDateFrom] < '2025-07-01', 434, 432)))))) * x.[Quantity]
	WHEN ProcedureCode = '90837'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 305 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 320 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 326, IIF(y.[ServiceDateFrom] < '2024-01-01', 333, IIF(y.[ServiceDateFrom] < '2025-02-01', 343, IIF(y.[ServiceDateFrom] < '2025-07-01', 356, 354)))))) * x.[Quantity]
	WHEN ProcedureCode = '90838'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 372 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 391 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 399, IIF(y.[ServiceDateFrom] < '2024-01-01', 408, IIF(y.[ServiceDateFrom] < '2025-02-01', 419, IIF(y.[ServiceDateFrom] < '2025-07-01', 434, 432)))))) * x.[Quantity]
	WHEN ProcedureCode = '90839'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 215 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 226 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 231, IIF(y.[ServiceDateFrom] < '2024-01-01', 236, IIF(y.[ServiceDateFrom] < '2025-02-01', 242, IIF(y.[ServiceDateFrom] < '2025-07-01', 251, 250)))))) * x.[Quantity]
	WHEN ProcedureCode = '90840'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01',  80 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 84  ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 86 , IIF(y.[ServiceDateFrom] < '2024-01-01' , 88, IIF(y.[ServiceDateFrom] < '2025-02-01',  90, IIF(y.[ServiceDateFrom] < '2025-07-01',  93,  93)))))) * x.[Quantity]
	WHEN ProcedureCode = '90846'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 305 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 320 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 326, IIF(y.[ServiceDateFrom] < '2024-01-01', 333, IIF(y.[ServiceDateFrom] < '2025-02-01', 343, IIF(y.[ServiceDateFrom] < '2025-07-01', 356, 354)))))) * x.[Quantity]
	WHEN ProcedureCode = '90847'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 305 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 320 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 326, IIF(y.[ServiceDateFrom] < '2024-01-01', 333, IIF(y.[ServiceDateFrom] < '2025-02-01', 343, IIF(y.[ServiceDateFrom] < '2025-07-01', 356, 354)))))) * x.[Quantity]
	WHEN ProcedureCode = '90849'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 211 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 222 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 226, IIF(y.[ServiceDateFrom] < '2024-01-01', 231, IIF(y.[ServiceDateFrom] < '2025-02-01', 237, IIF(y.[ServiceDateFrom] < '2025-07-01', 246, 244)))))) * x.[Quantity]
	WHEN ProcedureCode = '90853'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 211 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 222 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 226, IIF(y.[ServiceDateFrom] < '2024-01-01', 231, IIF(y.[ServiceDateFrom] < '2025-02-01', 237, IIF(y.[ServiceDateFrom] < '2025-07-01', 246, 244)))))) * x.[Quantity]
	WHEN ProcedureCode = '90863'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 234 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 246 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 251, IIF(y.[ServiceDateFrom] < '2024-01-01', 257, IIF(y.[ServiceDateFrom] < '2025-02-01', 263, IIF(y.[ServiceDateFrom] < '2025-07-01', 273, 271)))))) * x.[Quantity]
	WHEN ProcedureCode = '90875'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 126 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 132 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 135, IIF(y.[ServiceDateFrom] < '2024-01-01', 138, IIF(y.[ServiceDateFrom] < '2025-02-01', 142, IIF(y.[ServiceDateFrom] < '2025-07-01', 147, 146)))))) * x.[Quantity]
	WHEN ProcedureCode = '90876'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 207 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 217 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 222, IIF(y.[ServiceDateFrom] < '2024-01-01', 227, IIF(y.[ServiceDateFrom] < '2025-02-01', 233, IIF(y.[ServiceDateFrom] < '2025-07-01', 241, 240)))))) * x.[Quantity]
	WHEN ProcedureCode = '90880'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 305 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 320 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 326, IIF(y.[ServiceDateFrom] < '2024-01-01', 333, IIF(y.[ServiceDateFrom] < '2025-02-01', 343, IIF(y.[ServiceDateFrom] < '2025-07-01', 356, 354)))))) * x.[Quantity]
	WHEN ProcedureCode = '90882'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 250 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 262 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 268, IIF(y.[ServiceDateFrom] < '2024-01-01', 274, IIF(y.[ServiceDateFrom] < '2025-02-01', 281, IIF(y.[ServiceDateFrom] < '2025-07-01', 291, 290)))))) * x.[Quantity]
	WHEN ProcedureCode = '90887'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 125 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 131 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 134, IIF(y.[ServiceDateFrom] < '2024-01-01', 137, IIF(y.[ServiceDateFrom] < '2025-02-01', 141, IIF(y.[ServiceDateFrom] < '2025-07-01', 146, 145)))))) * x.[Quantity]
	WHEN ProcedureCode = '90901'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 292 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 307 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 312, IIF(y.[ServiceDateFrom] < '2024-01-01', 319, IIF(y.[ServiceDateFrom] < '2025-02-01', 328, IIF(y.[ServiceDateFrom] < '2025-07-01', 340, 338)))))) * x.[Quantity]
	WHEN ProcedureCode = '96105'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 339 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 356 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 363, IIF(y.[ServiceDateFrom] < '2024-01-01', 371, IIF(y.[ServiceDateFrom] < '2025-02-01', 382, IIF(y.[ServiceDateFrom] < '2025-07-01', 395, 393)))))) * x.[Quantity]
	WHEN ProcedureCode = '96110'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 339 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 356 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 363, IIF(y.[ServiceDateFrom] < '2024-01-01', 371, IIF(y.[ServiceDateFrom] < '2025-02-01', 382, IIF(y.[ServiceDateFrom] < '2025-07-01', 395, 393)))))) * x.[Quantity]
	WHEN ProcedureCode = '96112'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 339 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 356 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 363, IIF(y.[ServiceDateFrom] < '2024-01-01', 371, IIF(y.[ServiceDateFrom] < '2025-02-01', 371, IIF(y.[ServiceDateFrom] < '2025-07-01', 395, 393)))))) * x.[Quantity]																			   					    
	WHEN ProcedureCode = '96113'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 170 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 179 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 179, IIF(y.[ServiceDateFrom] < '2024-01-01', 182, IIF(y.[ServiceDateFrom] < '2025-02-01', 191, IIF(y.[ServiceDateFrom] < '2025-07-01', 198, 197)))))) * x.[Quantity]
	WHEN ProcedureCode = '96116'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 339 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 356 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 363, IIF(y.[ServiceDateFrom] < '2024-01-01', 371, IIF(y.[ServiceDateFrom] < '2025-02-01', 382, IIF(y.[ServiceDateFrom] < '2025-07-01', 396, 393)))))) * x.[Quantity]
	WHEN ProcedureCode = '96121'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 339 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 356 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 363, IIF(y.[ServiceDateFrom] < '2024-01-01', 371, IIF(y.[ServiceDateFrom] < '2025-02-01', 382, IIF(y.[ServiceDateFrom] < '2025-07-01', 395, 393)))))) * x.[Quantity]
	WHEN ProcedureCode = '96125'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 339 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 356 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 363, IIF(y.[ServiceDateFrom] < '2024-01-01', 371, IIF(y.[ServiceDateFrom] < '2025-02-01', 382, IIF(y.[ServiceDateFrom] < '2025-07-01', 395, 393)))))) * x.[Quantity]
	WHEN ProcedureCode = '96127'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 339 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 356 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 363, IIF(y.[ServiceDateFrom] < '2024-01-01', 371, IIF(y.[ServiceDateFrom] < '2025-02-01', 382, IIF(y.[ServiceDateFrom] < '2025-07-01', 395, 393)))))) * x.[Quantity]
	WHEN ProcedureCode = '96130'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 254 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 267 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 272, IIF(y.[ServiceDateFrom] < '2024-01-01', 278, IIF(y.[ServiceDateFrom] < '2025-02-01', 286, IIF(y.[ServiceDateFrom] < '2025-07-01', 296, 294)))))) * x.[Quantity]
	WHEN ProcedureCode = '96131'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 314 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 330 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 336, IIF(y.[ServiceDateFrom] < '2024-01-01', 343, IIF(y.[ServiceDateFrom] < '2025-02-01', 286, IIF(y.[ServiceDateFrom] < '2025-07-01', 296, 294)))))) * x.[Quantity]
	WHEN ProcedureCode = '96132'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 314 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 330 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 336, IIF(y.[ServiceDateFrom] < '2024-01-01', 343, IIF(y.[ServiceDateFrom] < '2025-02-01', 353, IIF(y.[ServiceDateFrom] < '2025-07-01', 366, 364)))))) * x.[Quantity]
	WHEN ProcedureCode = '96133'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 314 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 330 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 336, IIF(y.[ServiceDateFrom] < '2024-01-01', 343, IIF(y.[ServiceDateFrom] < '2025-02-01', 353, IIF(y.[ServiceDateFrom] < '2025-07-01', 366, 364)))))) * x.[Quantity]
	WHEN ProcedureCode = '96136'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 157 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 165 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 165, IIF(y.[ServiceDateFrom] < '2024-01-01', 169, IIF(y.[ServiceDateFrom] < '2025-02-01', 177, IIF(y.[ServiceDateFrom] < '2025-07-01', 183, 182)))))) * x.[Quantity]
	WHEN ProcedureCode = '96137'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 157 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 165 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 165, IIF(y.[ServiceDateFrom] < '2024-01-01', 169, IIF(y.[ServiceDateFrom] < '2025-02-01', 177, IIF(y.[ServiceDateFrom] < '2025-07-01', 183, 182)))))) * x.[Quantity]
	WHEN ProcedureCode = '96138'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 122 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 128 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 128, IIF(y.[ServiceDateFrom] < '2024-01-01', 131, IIF(y.[ServiceDateFrom] < '2025-02-01', 137, IIF(y.[ServiceDateFrom] < '2025-07-01', 142, 141)))))) * x.[Quantity]
	WHEN ProcedureCode = '96139'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 122 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 128 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 128, IIF(y.[ServiceDateFrom] < '2024-01-01', 131, IIF(y.[ServiceDateFrom] < '2025-02-01', 131, IIF(y.[ServiceDateFrom] < '2025-07-01', 142, 141)))))) * x.[Quantity]
	WHEN ProcedureCode = '96146'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 244 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 256 ,  IIF(y.[ServiceDateFrom] < '2023-01-15', 256, IIF(y.[ServiceDateFrom] < '2024-01-01', 262, IIF(y.[ServiceDateFrom] < '2025-02-01', 275, IIF(y.[ServiceDateFrom] < '2025-07-01', 285, 283)))))) * x.[Quantity]
	WHEN ProcedureCode = '96152'	THEN 																																													   IIF(y.[ServiceDateFrom] < '2025-02-01', 149, IIF(y.[ServiceDateFrom] < '2025-07-01', 154, 153))     * x.[Quantity]
	WHEN ProcedureCode IN ('97151','0359T')	THEN 																																											   IIF(y.[ServiceDateFrom] < '2025-02-01',  72, IIF(y.[ServiceDateFrom] < '2025-07-01',  75,  74))	 * x.[Quantity]
	WHEN ProcedureCode IN ('97152','0360T','0361T')	THEN 																																									   IIF(y.[ServiceDateFrom] < '2025-02-01',  55, IIF(y.[ServiceDateFrom] < '2025-07-01',  57,  57))	 * x.[Quantity]
	WHEN ProcedureCode IN ('0362T')	THEN 																																													   IIF(y.[ServiceDateFrom] < '2025-02-01',  65, IIF(y.[ServiceDateFrom] < '2025-07-01',  68,  67))	 * x.[Quantity]
	WHEN ProcedureCode IN ('0373T')	THEN 																																													   IIF(y.[ServiceDateFrom] < '2025-02-01',  59, IIF(y.[ServiceDateFrom] < '2025-07-01',  61,  60))	 * x.[Quantity]
	WHEN ProcedureCode IN ('99080')	THEN 																																													   IIF(y.[ServiceDateFrom] < '2025-02-01',  92, IIF(y.[ServiceDateFrom] < '2025-07-01',  96,  95))	 * x.[Quantity]
	WHEN ProcedureCode IN ('99211') AND x.[RevenueCode] IN ('914')	THEN 	 																																				   IIF(y.[ServiceDateFrom] < '2025-02-01', 290, IIF(y.[ServiceDateFrom] < '2025-07-01', 300, 299))	 * x.[Quantity]
	WHEN ProcedureCode IN ('99212') AND x.[RevenueCode] IN ('914')	THEN																																					   IIF(y.[ServiceDateFrom] < '2025-02-01', 290, IIF(y.[ServiceDateFrom] < '2025-07-01', 300, 299))	 * x.[Quantity]
	WHEN ProcedureCode IN ('99213') AND x.[RevenueCode] IN ('914')	THEN 																																					   IIF(y.[ServiceDateFrom] < '2025-02-01', 362, IIF(y.[ServiceDateFrom] < '2025-07-01', 375, 373))	 * x.[Quantity]
	WHEN ProcedureCode IN ('99214') 								THEN 																																					   IIF(y.[ServiceDateFrom] < '2025-02-01', 362, IIF(y.[ServiceDateFrom] < '2025-07-01', 375, 373))	 * x.[Quantity]
	WHEN ProcedureCode IN ('99214') AND x.[RevenueCode] IN ('914')	THEN 																																					   IIF(y.[ServiceDateFrom] < '2025-02-01', 322, IIF(y.[ServiceDateFrom] < '2025-07-01', 322, 373))	 * x.[Quantity]
	WHEN ProcedureCode IN ('99215')	THEN 																																													   IIF(y.[ServiceDateFrom] < '2025-02-01', 362, IIF(y.[ServiceDateFrom] < '2025-07-01', 375, 373))	 * x.[Quantity]
	WHEN ProcedureCode = 'EAP01'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 403 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 423, IIF(y.[ServiceDateFrom] < '2023-01-01', 432, IIF(y.[ServiceDateFrom] < '2024-01-01', 442,   IIF(y.[ServiceDateFrom] < '2025-02-01', 454, IIF(y.[ServiceDateFrom] < '2025-07-01', 470, 476)))))) * x.[Quantity]
	WHEN ProcedureCode = 'EAP02'	THEN IIF(y.[ServiceDateFrom] < '2022-01-01', 303 ,IIF(y.[ServiceDateFrom] < '2022-03-15', 318, IIF(y.[ServiceDateFrom] < '2023-01-01', 324, IIF(y.[ServiceDateFrom] < '2024-01-01', 331,   IIF(y.[ServiceDateFrom] < '2025-02-01', 341, IIF(y.[ServiceDateFrom] < '2025-07-01', 353, 351)))))) * x.[Quantity]
	WHEN ProcedureCode IN ('99244')	THEN 																																													   IIF(y.[ServiceDateFrom] < '2025-02-01', 1261,IIF(y.[ServiceDateFrom] < '2025-07-01', 1307, 1299))   * x.[Quantity]

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




Into #Step2
From #Step1_Charges as x


	LEFT JOIN [COL].[Data].[Demo]											as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px]											as dp on x.[EncounterID] = dp.[EncounterID] and x.[Sequence] = dp.[Sequence]

	LEFT JOIN [Analytics].[dbo].[Medicare Lab Fee Schedule] 				as LAB on LAB.[HCPCS] = x.[ProcedureCode] and x.ServiceDateFrom between LAB.[StartDate] AND LAB.[EndDate] AND LAB.[MOD] IS NULL
	left join [Analytics].[FSG].[Cigna_2022_RBRVS]							as RBRVS on RBRVS.[CPT] = x.[ProcedureCode]
	LEFT JOIN [QNS].[FSG].[Cigna_Grouper_79_Incidentals_January_2018]		as c on x.[ProcedureCode] = c.[CPT]
	LEFT JOIN [QNS].[FSG].[Cigna_Grouper_January_2021]						as d on x.[ProcedureCode] = d.[CPT]
	LEFT JOIN [QNS].[FSG].[Cigna_Grouper_V40_May_2022]						as e on x.[ProcedureCode] = e.[CPT]
	LEFT JOIN [Analytics].[FSG].[Cigna_Incidentals_2023]					as NonReimbursables on x.[ProcedureCode] = NonReimbursables.[CPT]
	LEFT JOIN [Analytics].[FSG].[Cigna_Grouper_2023]						as Grouper on x.[ProcedureCode] = Grouper.[CPT]

	left join (select encounterid
	from #Step1_Charges
	where (ProcedureCodeNumeric between 93451 and  93581 or ProcedureCodeNumeric in ( 93582, 93583))
	group by encounterid) ptca on ptca.encounterid = x.encounterid

	LEFT JOIN [Analytics].[dbo].[MAC-Covid-19-Testing]						as COV on COV.[CPT_Code] = x.[ProcedureCode]

ORDER BY x.[EncounterID], x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate], [RevenueCode], [ProcedureCode], [Modifier1], [Sequence], [Amount], [BillCharges], [OriginalPayment]

	, [OP_Default] = IIF([ER]=0 and [AS]=0 and [Laparoscopy]=0 and [Cardiac_Cath]=0 and [PTCA]=0 and [Lithotripsy]=0 and [Cardiac_Rehab]=0 and [Hip_Replacement]=0 and [Shoulder_Replacement]=0 and [Gamma_Knife]=0 and [Vascular_Angioplasty]=0 and [Implants]=0 and [Blood]=0 and [Dialysis]=0 and [Drugs]=0 and [Lab]=0 and [Radiology]=0 and [PT/OT/ST]=0 and [ECT]=0 and [Miscellaneous]=0 and [Clinic]=0, [OP_Default], 0)
	, [ER]
	
	--AS
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
	
	, [Laparoscopy]
	, [Cardiac_Cath]
	, [PTCA]
	, [Lithotripsy]
	, [Cardiac_Rehab]
	, [Hip_Replacement]
	, [Knee_Replacement]
	, [Shoulder_Replacement]
	, [Gamma_Knife]
	, [Vascular_Angioplasty]
	, [Implants]
	, [Blood]
	, [Dialysis]
	, [Drugs]			=IIF( (modifier1 not in ('FB','SL') or Modifier1 IS NULL), [Drugs], 0)
	, [Lab]
	, [Radiology]
	, [PT/OT/ST]
	, [ECT]
	, [Miscellaneous]
	, [Clinic]			= IIF([Miscellaneous]=0, [Clinic], 0)
	, [COVID]
	, [IOP]

Into #Step3
FROM #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]

	, SUM([OP_Default])				as [OP_Default]
	, MAX([ER])						as [ER]
	, MAX(AS1)+MAX(AS2)+MAX(AS3)+MAX(AS4)+MAX(AS5)+MAX(AS6)+MAX(AS7)+MAX(AS8)+MAX(AS9)+MAX(AS10) as [AS]
	, MAX([Laparoscopy])				as [Laparoscopy]
	, MAX([Cardiac_Cath])			as [Cardiac_Cath]
	, MAX([PTCA])					as [PTCA]
	, MAX([Lithotripsy])				as [Lithotripsy]	
	, MAX([Cardiac_Rehab])			as [Cardiac_Rehab]
	, MAX([Hip_Replacement])			as [Hip_Replacement]
	, MAX([Knee_Replacement])		as [Knee_Replacement]
	, MAX([Shoulder_Replacement])	as [Shoulder_Replacement]
	, MAX([Gamma_Knife])				as [Gamma_Knife]	
	, MAX([Vascular_Angioplasty])	as [Vascular_Angioplasty]	
	, SUM([Implants])				as [Implants]
	, SUM([Blood])					as [Blood]
	, MAX([Dialysis])				as [Dialysis]
	, SUM([Drugs])					as [Drugs]
	, SUM([Lab])						as [Lab]	
	, SUM([Radiology])				as [Radiology]
	, SUM([PT/OT/ST])				as [PT/OT/ST]
	, MAX([ECT])						as [ECT]
	, MAX([IOP])						as [IOP]
	, SUM([Miscellaneous])			as [Miscellaneous]
	, MAX([COVID])					as [COVID]
	, MAX([Clinic])					as [Clinic]

INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]

	, SUM([OP_Default])				as [OP_Default]
	, MAX([ER])						as [ER]
	, MAX([AS])						as [AS]
	, MAX([Laparoscopy])				as [Laparoscopy]
	, MAX([Cardiac_Cath])			as [Cardiac_Cath]
	, MAX([PTCA])					as [PTCA]
	, MAX([Lithotripsy])				as [Lithotripsy]
	, MAX([Cardiac_Rehab])			as [Cardiac_Rehab]
	, MAX([Hip_Replacement])			as [Hip_Replacement]
	, MAX([Knee_Replacement])		as [Knee_Replacement]
	, MAX([Shoulder_Replacement])	as [Shoulder_Replacement]
	, MAX([Gamma_Knife])				as [Gamma_Knife]
	, MAX([Vascular_Angioplasty])	as [Vascular_Angioplasty]	
	, SUM([Implants])				as [Implants]
	, SUM([Blood])					as [Blood]
	, SUM([Dialysis])				as [Dialysis]
	, SUM([Drugs])					as [Drugs]
	, SUM([Lab])						as [Lab]	
	, SUM([Radiology])				as [Radiology]
	, SUM([PT/OT/ST])				as [PT/OT/ST]
	, SUM([ECT])						as [ECT]
	, SUM([IOP])						as [IOP]
	, SUM([Miscellaneous])			as [Miscellaneous]
	, MAX([COVID])					as [COVID]
	, MAX([Clinic])					as [Clinic]

INTO #Step3_2
FROM #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, [Implants]
	, [Blood]
	, [Drugs]				= IIF([ECT] !=0, 0, [Drugs])
	, [Gamma_Knife]
	, [PTCA]					= IIF([Gamma_Knife]!=0, 0,IIF([PTCA]!=0, [PTCA], 0))
	, [Shoulder_Replacement] = IIF([Gamma_Knife]!=0 or ([PTCA]!=0), 0, [Shoulder_Replacement])
	, [Knee_Replacement]     = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0, 0, [Knee_Replacement])
	, [Hip_Replacement]		= IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0, 0, [Hip_Replacement])	
	, [Vascular_Angioplasty] = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0, 0, [Vascular_Angioplasty])	
	, [Lithotripsy]		    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0, 0, [Lithotripsy])
	, [Cardiac_Cath]		    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0, 0, [Cardiac_Cath])
	, [Laparoscopy]		    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0, 0, [Laparoscopy])
	, [AS]				    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0, 0, [AS])
	, [ER]				    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0, 0, [ER])
	, [Dialysis]			    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0, 0, [Dialysis])
	, [ECT]				    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0, 0, [ECT])
	, [IOP]				    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0, 0, [IOP])
	, [Cardiac_Rehab]	    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0 or [IOP]!=0, 0, [Cardiac_Rehab])
	, [PT/OT/ST]			    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0 or [IOP]!=0 or [Cardiac_Rehab]!=0, 0, [PT/OT/ST])
	, [Miscellaneous]	    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0 or [IOP]!=0 or [Cardiac_Rehab]!=0 or [PT/OT/ST]!=0, 0, [Miscellaneous])
	, [Lab]				    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0 or [IOP]!=0 or [Cardiac_Rehab]!=0 or [PT/OT/ST]!=0, 0, [Lab])
	, [Radiology]		    = IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0 or [IOP]!=0 or [Cardiac_Rehab]!=0 or [PT/OT/ST]!=0, 0, [Radiology])
	, [Clinic]				= IIF([Gamma_Knife]!=0 or ([PTCA]!=0) or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0 or [IOP]!=0 or [Cardiac_Rehab]!=0 or [PT/OT/ST]!=0, 0, [Clinic])
	
	
	, [OP_Default]		    = IIF([Gamma_Knife]!=0 or [PTCA]!=0 or [Shoulder_Replacement]!=0 or [Knee_Replacement] !=0 or [Hip_Replacement]!=0 or [Vascular_Angioplasty]!=0 or [Lithotripsy]!=0 or [Cardiac_Cath]!=0 or [Laparoscopy]!=0 or [AS]!=0 or [ER]!=0 or [Dialysis]!=0 or [ECT]!=0 or [IOP]!=0 or [Cardiac_Rehab]!=0 or [PT/OT/ST]!=0 or [Miscellaneous] != 0, 0, [OP_Default])
	
	, [COVID]

INTO #Step4
FROM #Step3_2

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (post-LEAD slot computation, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
--
-- MAX CATEGORIES (one winner per encounter, PARTITION BY EncounterID):
--   ER, Gamma_Knife, Laparoscopy, Cardiac_Cath, PTCA, Lithotripsy,
--   Cardiac_Rehab, Hip_Replacement, Knee_Replacement, Shoulder_Replacement,
--   Vascular_Angioplasty, Clinic
--   NOTE: Per aggregation evidence all of the above are MAX in both
--   AGGREGATE_DATE and AGGREGATE_ENC. Clinic is MAX in both steps.
--
-- HYBRID CATEGORIES (MAX per ServiceDate in AGGREGATE_DATE, SUM in AGGREGATE_ENC;
--   one winner per EncounterID+ServiceDate, PARTITION BY EncounterID+ServiceDate):
--   Dialysis, ECT, IOP
--
-- SUM CATEGORIES (all matching lines pay):
--   OP_Default, Implants, Blood, Drugs, Lab, Radiology, PT/OT/ST,
--   Miscellaneous
--
-- WINDOW_REDUCTION CATEGORIES (slot-based payment via LEAD pivot):
--   AS : slots AS1-AS10  (LEAD PARTITION BY EncounterID only)
--
-- INDICATOR_FLAG CATEGORIES (binary 0/1, $0 LinePayment):
--   COVID
--
-- SUPPRESSION HIERARCHY (from #Step4 IIF chain, tier 1 = highest priority):
--   1.  Gamma_Knife
--   2.  PTCA                (suppressed if Gamma_Knife != 0)
--   3.  Shoulder_Replacement (suppressed if Gamma_Knife OR PTCA != 0)
--   4.  Knee_Replacement    (suppressed if Gamma_Knife OR PTCA OR Shoulder_Replacement != 0)
--   5.  Hip_Replacement     (suppressed if Gamma_Knife OR PTCA OR Shoulder_Replacement OR Knee_Replacement != 0)
--   6.  Vascular_Angioplasty(suppressed if Gamma_Knife OR PTCA OR Shoulder_Replacement OR Knee_Replacement OR Hip_Replacement != 0)
--   7.  Lithotripsy         (suppressed if Gamma_Knife OR PTCA OR Shoulder_Replacement OR Knee_Replacement OR Hip_Replacement OR Vascular_Angioplasty != 0)
--   8.  Cardiac_Cath        (suppressed if Gamma_Knife OR PTCA OR Shoulder_Replacement OR Knee_Replacement OR Hip_Replacement OR Vascular_Angioplasty OR Lithotripsy != 0)
--   9.  Laparoscopy         (suppressed if Gamma_Knife OR PTCA OR ... OR Cardiac_Cath != 0)
--  10.  AS                  (suppressed if Gamma_Knife OR PTCA OR ... OR Laparoscopy != 0)
--  11.  ER                  (suppressed if Gamma_Knife OR PTCA OR ... OR AS != 0)
--  12.  Dialysis            (suppressed if Gamma_Knife OR PTCA OR ... OR ER != 0)
--  13.  ECT                 (suppressed if Gamma_Knife OR PTCA OR ... OR Dialysis != 0)
--  14.  IOP                 (suppressed if Gamma_Knife OR PTCA OR ... OR ECT != 0)
--  15.  Cardiac_Rehab       (suppressed if Gamma_Knife OR PTCA OR ... OR IOP != 0)
--  16.  PT/OT/ST            (suppressed if Gamma_Knife OR PTCA OR ... OR Cardiac_Rehab != 0)
--  17.  Miscellaneous       (suppressed if Gamma_Knife OR PTCA OR ... OR PT/OT/ST != 0)
--  18.  Lab                 (suppressed if Gamma_Knife OR PTCA OR ... OR PT/OT/ST != 0)
--  19.  Radiology           (suppressed if Gamma_Knife OR PTCA OR ... OR PT/OT/ST != 0)
--  20.  Clinic              (suppressed if Gamma_Knife OR PTCA OR ... OR PT/OT/ST != 0)
--  21.  OP_Default          (suppressed if Gamma_Knife OR PTCA OR ... OR Miscellaneous != 0)
--  Special: Implants, Blood not explicitly suppressed by hierarchy in #Step4.
--           Drugs suppressed if ECT != 0.
--=======================================================================

-- COLUMN SURVIVAL TRACE:
-- #Step3 is built with an explicit column list from #Step2.
-- Confirmed present in #Step3:
--   EncounterID, ServiceDate, RevenueCode, ProcedureCode, Modifier1, Sequence,
--   Amount, BillCharges, OriginalPayment,
--   OP_Default, ER,
--   AS1, AS2, AS3, AS4, AS5, AS6, AS7, AS8, AS9, AS10,
--   Laparoscopy, Cardiac_Cath, PTCA, Lithotripsy, Cardiac_Rehab,
--   Hip_Replacement, Knee_Replacement, Shoulder_Replacement,
--   Gamma_Knife, Vascular_Angioplasty,
--   Implants, Blood, Dialysis, Drugs, Lab, Radiology, [PT/OT/ST],
--   ECT, Miscellaneous, Clinic, COVID, IOP
-- NOT present in #Step3: Quantity (present in #Step2 only)
-- Quantity is recovered via LEFT JOIN to #Step2 on EncounterID + Sequence.
-- BillCharges IS confirmed present in #Step3 (passed through from #Step2).
--=======================================================================

-- ROW_NUMBER() COUNT CHECK:
-- MAX categories (12):  ER, Gamma_Knife, Laparoscopy, Cardiac_Cath, PTCA,
--   Lithotripsy, Cardiac_Rehab, Hip_Replacement, Knee_Replacement,
--   Shoulder_Replacement, Vascular_Angioplasty, Clinic
-- HYBRID categories (3): Dialysis, ECT, IOP
-- WINDOW_REDUCTION (1):  AS
-- INDICATOR_FLAG (1):    COVID
-- TOTAL ROW_NUMBER() calls = 12 + 3 + 1 + 1 = 17
--=======================================================================

-- BLOCK 1: #bRanked
SELECT
    b.*
    -- MAX categories: PARTITION BY EncounterID
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]                   DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_ER
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife]           DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Gamma_Knife
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Laparoscopy]           DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Laparoscopy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Cath]          DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA]                  DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_PTCA
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Lithotripsy]           DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Lithotripsy
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Rehab]         DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Cardiac_Rehab
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Hip_Replacement]       DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Hip_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Knee_Replacement]      DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Knee_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Shoulder_Replacement]  DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Shoulder_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Vascular_Angioplasty]  DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Vascular_Angioplasty
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Clinic]                DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Clinic
    -- HYBRID categories: PARTITION BY EncounterID, ServiceDate
    -- One winner per encounter per service date.
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[Dialysis]              DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_Dialysis
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[ECT]                   DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_ECT
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID], b.[ServiceDate]
          ORDER BY b.[IOP]                   DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_IOP
    -- WINDOW_REDUCTION: AS — LEAD PARTITION BY EncounterID only
    -- ORDER BY SUM of ALL slot columns AS1-AS10
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY (  ISNULL(b.[AS1], 0) + ISNULL(b.[AS2], 0) + ISNULL(b.[AS3], 0)
                    + ISNULL(b.[AS4], 0) + ISNULL(b.[AS5], 0) + ISNULL(b.[AS6], 0)
                    + ISNULL(b.[AS7], 0) + ISNULL(b.[AS8], 0) + ISNULL(b.[AS9], 0)
                    + ISNULL(b.[AS10], 0)) DESC
                  , b.[Amount] DESC, b.[Sequence] ASC) AS rn_AS
    -- INDICATOR_FLAG: COVID — binary 0/1, $0 LinePayment
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]                 DESC, b.[Amount] DESC, b.[Sequence] ASC) AS rn_COVID
INTO #bRanked
FROM #Step3 b;

-- BLOCK 2: #bSlots
-- Extracts slot values from the rank-1 AS row per encounter.
-- LEAD for AS is PARTITION BY EncounterID only => GROUP BY EncounterID only.
-- Uses GROUP BY + MAX(CASE...) to avoid duplicate rows.
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
-- One row per charge line.
-- Quantity is NOT present in #Step3 (explicit narrow column list).
-- Recovered via LEFT JOIN to #Step2 on EncounterID + Sequence.
-- BillCharges IS confirmed present in #Step3 and read directly from b.
SELECT
    b.[EncounterID]
    , b.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                    AS [BilledAmount]
    , src.[Quantity]                                AS [Quantity]
    , b.[BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Hierarchy order exactly matches #Step4 IIF chain.
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- TIER 1: Gamma_Knife (MAX)
        WHEN s4.[Gamma_Knife] != 0
         AND b.[Gamma_Knife] > 0
            THEN IIF(b.rn_Gamma_Knife = 1, 'Gamma_Knife', 'Gamma_Knife_Non_Winner')

        -- TIER 2: PTCA (MAX)
        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN IIF(b.rn_PTCA = 1, 'PTCA', 'PTCA_Non_Winner')

        -- TIER 3: Shoulder_Replacement (MAX)
        WHEN s4.[Shoulder_Replacement] != 0
         AND b.[Shoulder_Replacement] > 0
            THEN IIF(b.rn_Shoulder_Replacement = 1, 'Shoulder_Replacement', 'Shoulder_Replacement_Non_Winner')

        -- TIER 4: Knee_Replacement (MAX)
        WHEN s4.[Knee_Replacement] != 0
         AND b.[Knee_Replacement] > 0
            THEN IIF(b.rn_Knee_Replacement = 1, 'Knee_Replacement', 'Knee_Replacement_Non_Winner')

        -- TIER 5: Hip_Replacement (MAX)
        WHEN s4.[Hip_Replacement] != 0
         AND b.[Hip_Replacement] > 0
            THEN IIF(b.rn_Hip_Replacement = 1, 'Hip_Replacement', 'Hip_Replacement_Non_Winner')

        -- TIER 6: Vascular_Angioplasty (MAX)
        WHEN s4.[Vascular_Angioplasty] != 0
         AND b.[Vascular_Angioplasty] > 0
            THEN IIF(b.rn_Vascular_Angioplasty = 1, 'Vascular_Angioplasty', 'Vascular_Angioplasty_Non_Winner')

        -- TIER 7: Lithotripsy (MAX)
        WHEN s4.[Lithotripsy] != 0
         AND b.[Lithotripsy] > 0
            THEN IIF(b.rn_Lithotripsy = 1, 'Lithotripsy', 'Lithotripsy_Non_Winner')

        -- TIER 8: Cardiac_Cath (MAX)
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- TIER 9: Laparoscopy (MAX)
        WHEN s4.[Laparoscopy] != 0
         AND b.[Laparoscopy] > 0
            THEN IIF(b.rn_Laparoscopy = 1, 'Laparoscopy', 'Laparoscopy_Non_Winner')

        -- TIER 10: AS (WINDOW_REDUCTION via AS1-AS10 slots)
        WHEN s4.[AS] != 0
         AND (  ISNULL(b.[AS1], 0) + ISNULL(b.[AS2], 0) + ISNULL(b.[AS3], 0)
              + ISNULL(b.[AS4], 0) + ISNULL(b.[AS5], 0) + ISNULL(b.[AS6], 0)
              + ISNULL(b.[AS7], 0) + ISNULL(b.[AS8], 0) + ISNULL(b.[AS9], 0)
              + ISNULL(b.[AS10], 0)) > 0
            THEN CASE
                    WHEN b.rn_AS BETWEEN 1 AND 10 THEN 'AS_Ambulatory_Surgery'
                    ELSE 'AS_Ambulatory_Surgery_Beyond_Max'
                 END

        -- TIER 11: ER (MAX)
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- TIER 12: Dialysis (HYBRID)
        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN IIF(b.rn_Dialysis = 1, 'Dialysis', 'Dialysis_Non_Winner')

        -- TIER 13: ECT (HYBRID)
        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN IIF(b.rn_ECT = 1, 'ECT', 'ECT_Non_Winner')

        -- TIER 14: IOP (HYBRID)
        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN IIF(b.rn_IOP = 1, 'IOP', 'IOP_Non_Winner')

        -- TIER 15: Cardiac_Rehab (MAX)
        WHEN s4.[Cardiac_Rehab] != 0
         AND b.[Cardiac_Rehab] > 0
            THEN IIF(b.rn_Cardiac_Rehab = 1, 'Cardiac_Rehab', 'Cardiac_Rehab_Non_Winner')

        -- TIER 16: PT/OT/ST (SUM)
        WHEN s4.[PT/OT/ST] != 0
         AND b.[PT/OT/ST] > 0
            THEN 'PT/OT/ST'

        -- TIER 17: Miscellaneous (SUM)
        WHEN s4.[Miscellaneous] != 0
         AND b.[Miscellaneous] > 0
            THEN 'Miscellaneous'

        -- TIER 18: Lab (SUM)
        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Lab'

        -- TIER 19: Radiology (SUM)
        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Radiology'

        -- TIER 20: Clinic (MAX)
        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN IIF(b.rn_Clinic = 1, 'Clinic', 'Clinic_Non_Winner')

        -- TIER 21: Drugs (SUM)
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- TIER 22: Implants (SUM)
        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Implants'

        -- TIER 23: Blood (SUM)
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- TIER 24: OP_Default (SUM — catch-all)
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- Suppressed: line matched a category but #Step4 hierarchy zeroed it out
        WHEN (
              ISNULL(b.[ER], 0)
            + ISNULL(b.[Gamma_Knife], 0)
            + ISNULL(b.[Laparoscopy], 0)
            + ISNULL(b.[Cardiac_Cath], 0)
            + ISNULL(b.[PTCA], 0)
            + ISNULL(b.[Lithotripsy], 0)
            + ISNULL(b.[Cardiac_Rehab], 0)
            + ISNULL(b.[Hip_Replacement], 0)
            + ISNULL(b.[Knee_Replacement], 0)
            + ISNULL(b.[Shoulder_Replacement], 0)
            + ISNULL(b.[Vascular_Angioplasty], 0)
            + ISNULL(b.[Implants], 0)
            + ISNULL(b.[Blood], 0)
            + ISNULL(b.[Dialysis], 0)
            + ISNULL(b.[Drugs], 0)
            + ISNULL(b.[Lab], 0)
            + ISNULL(b.[Radiology], 0)
            + ISNULL(b.[PT/OT/ST], 0)
            + ISNULL(b.[ECT], 0)
            + ISNULL(b.[IOP], 0)
            + ISNULL(b.[Miscellaneous], 0)
            + ISNULL(b.[Clinic], 0)
            + ISNULL(b.[OP_Default], 0)
            + ISNULL(b.[COVID], 0)
            + ISNULL(b.[AS1], 0)  + ISNULL(b.[AS2], 0)  + ISNULL(b.[AS3], 0)
            + ISNULL(b.[AS4], 0)  + ISNULL(b.[AS5], 0)  + ISNULL(b.[AS6], 0)
            + ISNULL(b.[AS7], 0)  + ISNULL(b.[AS8], 0)  + ISNULL(b.[AS9], 0)
            + ISNULL(b.[AS10], 0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- INDICATOR_FLAG: COVID — binary 0/1, placed after all dollar and suppressed categories
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
            THEN 'Contracted flat rate per contract period (Gamma Knife CPT list: 61796-61800/63620/63621/G0339/G0340)'

        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN 'Contracted flat rate per contract period (PTCA CPT list: 35450-35476/92920-92998/C9600-C9608 with Cardiac Cath CPT qualifier or ptca encounter flag)'

        WHEN s4.[Shoulder_Replacement] != 0
         AND b.[Shoulder_Replacement] > 0
            THEN 'Contracted flat rate per contract period (Shoulder Replacement CPT list: 23470/23472/23473/23474)'

        WHEN s4.[Knee_Replacement] != 0
         AND b.[Knee_Replacement] > 0
            THEN 'Contracted flat rate per contract period (Knee Replacement CPT list: 27437/27438/27440/27441/27445/27446/27447)'

        WHEN s4.[Hip_Replacement] != 0
         AND b.[Hip_Replacement] > 0
            THEN 'Contracted flat rate per contract period (Hip Replacement CPT list: 27130/27132)'

        WHEN s4.[Vascular_Angioplasty] != 0
         AND b.[Vascular_Angioplasty] > 0
            THEN 'Contracted flat rate per contract period (Vascular Angioplasty CPT list: 35450-35476/92920-92998/C9600-C9608)'

        WHEN s4.[Lithotripsy] != 0
         AND b.[Lithotripsy] > 0
            THEN 'Contracted flat rate per contract period (Lithotripsy Rev 790/799)'

        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period (Cardiac Cath Rev 481 + CPT 93451-93583)'

        WHEN s4.[Laparoscopy] != 0
         AND b.[Laparoscopy] > 0
            THEN 'Contracted flat rate per contract period (Laparoscopy CPT list: 47562/47563/47564)'

        WHEN s4.[AS] != 0
         AND (  ISNULL(b.[AS1], 0) + ISNULL(b.[AS2], 0) + ISNULL(b.[AS3], 0)
              + ISNULL(b.[AS4], 0) + ISNULL(b.[AS5], 0) + ISNULL(b.[AS6], 0)
              + ISNULL(b.[AS7], 0) + ISNULL(b.[AS8], 0) + ISNULL(b.[AS9], 0)
              + ISNULL(b.[AS10], 0)) > 0
            THEN CASE
                    WHEN b.rn_AS = 1  THEN 'Cigna ASC grouper flat rate — 1st AS procedure, full rate (Rev 360/361/369/490/499/750/759; Grouper 79 = incidental rate 547-596; other grouped CPT = flat rate 7333-7984)'
                    WHEN b.rn_AS = 2  THEN 'Cigna ASC grouper flat rate / 2 — 2nd AS procedure reduction'
                    WHEN b.rn_AS BETWEEN 3 AND 10
                                      THEN 'Cigna ASC grouper flat rate / 2 — 3rd+ AS procedure reduction'
                    ELSE 'Beyond 10th AS procedure in encounter — $0'
                 END

        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN 'Contracted flat rate per contract period (ER Rev 450/451/452/456/459)'

        WHEN s4.[Dialysis] != 0
         AND b.[Dialysis] > 0
            THEN 'Contracted per diem per contract period (Dialysis Rev 820-825/829-835/839-845/849-855/859/870-874/880-882/889)'

        WHEN s4.[ECT] != 0
         AND b.[ECT] > 0
            THEN 'Contracted flat rate per contract period (ECT Rev 901 x Quantity, or CPT 90870 flat rate)'

        WHEN s4.[IOP] != 0
         AND b.[IOP] > 0
            THEN 'Contracted per diem x Quantity per contract period (IOP Rev 905/906)'

        WHEN s4.[Cardiac_Rehab] != 0
         AND b.[Cardiac_Rehab] > 0
            THEN 'Contracted flat rate per contract period (Cardiac Rehab Rev 943)'

        WHEN s4.[PT/OT/ST] != 0
         AND b.[PT/OT/ST] > 0
            THEN 'Contracted per-unit rate x Quantity per contract period (PT/OT/ST Rev 420-424/429/430/431/432/434/439)'

        WHEN s4.[Miscellaneous] != 0
         AND b.[Miscellaneous] > 0
            THEN 'Contracted per-CPT rate x Quantity per contract period (Miscellaneous — specific psych/E&M/behavioral health CPTs with period-banded rates)'

        WHEN s4.[Lab] != 0
         AND b.[Lab] > 0
            THEN 'Pct of charges or RBRVS-based rate x period multiplier (Lab Rev 300-312/314/319/923-925; pre-2023: Amount x pct; 2023+: Cigna RBRVS Rate x 70% x Quantity)'

        WHEN s4.[Radiology] != 0
         AND b.[Radiology] > 0
            THEN 'Pct of charges per contract period (Radiology Rev 320-329/330/340-349/350-352/359/400-404/409/610-612/614-616/618-619; Amount x pct by period)'

        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN 'Clinic indicator — $0.01 per line (Rev 510-529; placeholder/marker category)'

        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Pct of charges: Amount x 29% (Drugs Rev 634/635/636 or CPT Q0136/Q4054/Q4055; excl Modifier FB/SL)'

        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Pct of charges: Amount x 36% (Implants Rev 274/275/276/278; excl device pass-through CPT codes)'

        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Pct of charges: Amount x 100% (Blood Rev 380-399)'

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'Pct of charges: Amount x period-banded pct (OP Default catch-all; excl device pass-through codes; rates range 57.1%-66.9% by period)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag — binary 0/1 value, no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:     IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    -- HYBRID:  IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)  [same as MAX]
    -- SUM:     IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- WINDOW_REDUCTION: slot-pivot from #bSlots keyed by EncounterID
    -- INDICATOR_FLAG: $0 — never add b.[COVID] to LinePayment
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1, ISNULL(b.[Gamma_Knife], 0), 0), 0)
        + IIF(s4.[PTCA] != 0,
              IIF(b.rn_PTCA = 1, ISNULL(b.[PTCA], 0), 0), 0)
        + IIF(s4.[Shoulder_Replacement] != 0,
              IIF(b.rn_Shoulder_Replacement = 1, ISNULL(b.[Shoulder_Replacement], 0), 0), 0)
        + IIF(s4.[Knee_Replacement] != 0,
              IIF(b.rn_Knee_Replacement = 1, ISNULL(b.[Knee_Replacement], 0), 0), 0)
        + IIF(s4.[Hip_Replacement] != 0,
              IIF(b.rn_Hip_Replacement = 1, ISNULL(b.[Hip_Replacement], 0), 0), 0)
        + IIF(s4.[Vascular_Angioplasty] != 0,
              IIF(b.rn_Vascular_Angioplasty = 1, ISNULL(b.[Vascular_Angioplasty], 0), 0), 0)
        + IIF(s4.[Lithotripsy] != 0,
              IIF(b.rn_Lithotripsy = 1, ISNULL(b.[Lithotripsy], 0), 0), 0)
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1, ISNULL(b.[Cardiac_Cath], 0), 0), 0)
        + IIF(s4.[Laparoscopy] != 0,
              IIF(b.rn_Laparoscopy = 1, ISNULL(b.[Laparoscopy], 0), 0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1, ISNULL(b.[ER], 0), 0), 0)
        + IIF(s4.[Cardiac_Rehab] != 0,
              IIF(b.rn_Cardiac_Rehab = 1, ISNULL(b.[Cardiac_Rehab], 0), 0), 0)
        + IIF(s4.[Clinic] != 0,
              IIF(b.rn_Clinic = 1, ISNULL(b.[Clinic], 0), 0), 0)
          -- HYBRID categories: IIF(rn=1) partitioned by EncounterID+ServiceDate
        + IIF(s4.[Dialysis] != 0,
              IIF(b.rn_Dialysis = 1, ISNULL(b.[Dialysis], 0), 0), 0)
        + IIF(s4.[ECT] != 0,
              IIF(b.rn_ECT = 1, ISNULL(b.[ECT], 0), 0), 0)
        + IIF(s4.[IOP] != 0,
              IIF(b.rn_IOP = 1, ISNULL(b.[IOP], 0), 0), 0)
          -- SUM categories
        + IIF(s4.[PT/OT/ST] != 0,     ISNULL(b.[PT/OT/ST], 0),     0)
        + IIF(s4.[Miscellaneous] != 0, ISNULL(b.[Miscellaneous], 0), 0)
        + IIF(s4.[Lab] != 0,           ISNULL(b.[Lab], 0),           0)
        + IIF(s4.[Radiology] != 0,     ISNULL(b.[Radiology], 0),     0)
        + IIF(s4.[Drugs] != 0,         ISNULL(b.[Drugs], 0),         0)
        + IIF(s4.[Implants] != 0,      ISNULL(b.[Implants], 0),      0)
        + IIF(s4.[Blood] != 0,         ISNULL(b.[Blood], 0),         0)
        + IIF(s4.[OP_Default] != 0,    ISNULL(b.[OP_Default], 0),    0)
          -- WINDOW_REDUCTION: AS — each row gets its own rank's slot value from #bSlots
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
          -- INDICATOR_FLAG: COVID — $0, never added to LinePayment
      , 2)

    -- NCCI BUNDLED FLAG: no NCCI bundle step in this script — always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4  ON s4.[EncounterID] = b.[EncounterID]
LEFT  JOIN #bSlots rd  ON rd.[EncounterID] = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover Quantity (not present in #Step3 explicit column list)
LEFT  JOIN #Step2  src ON src.[EncounterID] = b.[EncounterID]
                       AND src.[Sequence]   = b.[Sequence]
ORDER BY b.[EncounterID], b.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	, [Implants]
	+[Blood]
	+[Drugs]
	+[Gamma_Knife]
	+[PTCA]
	+[Shoulder_Replacement] 
	+[Knee_Replacement]
	+[Hip_Replacement] 
	+[Lithotripsy]		    
	+[Cardiac_Cath]		    
	+[Laparoscopy]	
	+[Vascular_Angioplasty]
	+[AS]				    
	+[ER]				    
	+[Dialysis]			    		    
	+[ECT]				    			    
	+[Cardiac_Rehab]	    
	+[PT/OT/ST]			    
	+[Miscellaneous]	    
	+[Lab]				    
	+[Radiology]
	+[Clinic]
	+[IOP]
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
	, y.[Gamma_Knife]
	, y.[PTCA]
	, y.[Shoulder_Replacement] 
	, y.[Knee_Replacement]
	, y.[Hip_Replacement] 
	, y.[Lithotripsy]		    
	, y.[Cardiac_Cath]		    
	, y.[Laparoscopy]
	, y.[Vascular_Angioplasty]
	, y.[AS]				    
	, y.[ER]				    
	, y.[Dialysis]			    		    
	, y.[ECT]				    				    
	, y.[Cardiac_Rehab]	    
	, y.[PT/OT/ST]			    
	, y.[Miscellaneous]	    
	, y.[Lab]				    
	, y.[Radiology]		    
	, y.[OP_Default]	
	, y.[Clinic]
	, y.[COVID]
	, y.[IOP]

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

	, IIF(ISNULL(x.[Implants]				,0) > 0,      'Implants - '					+ Cast(x.[Implants]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Blood]					,0) > 0,      'Blood - '					+ Cast(x.[Blood]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Drugs]					,0) > 0,      'Drugs - '					+ Cast(x.[Drugs]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Gamma_Knife]				,0) > 0,      'Gamma_Knife - '				+ Cast(x.[Gamma_Knife]				as varchar) + ', ','')
	+IIF(ISNULL(x.[PTCA]					,0) > 0,      'PTCA - '						+ Cast(x.[PTCA]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Shoulder_Replacement]	,0) > 0,      'Shoulder_Replacement - '		+ Cast(x.[Shoulder_Replacement]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Knee_Replacement]		,0) > 0,      'Knee_Replacement - '			+ Cast(x.[Knee_Replacement]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Hip_Replacement]			,0) > 0,      'Hip_Replacement - '			+ Cast(x.[Hip_Replacement]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Lithotripsy]				,0) > 0,      'Lithotripsy - '				+ Cast(x.[Lithotripsy]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Cardiac_Cath]			,0) > 0,      'Cardiac_Cath - '				+ Cast(x.[Cardiac_Cath]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Laparoscopy]				,0) > 0,      'Laparoscopy - '				+ Cast(x.[Laparoscopy]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Vascular_Angioplasty]	,0) > 0,      'Vascular_Angioplasty - '		+ Cast(x.[Vascular_Angioplasty]		as varchar) + ', ','')
	+IIF(ISNULL(x.[AS]						,0) > 0,      'AS - '						+ Cast(x.[AS]						as varchar) + ', ','')
	+IIF(ISNULL(x.[ER]						,0) > 0,      'ER - '						+ Cast(x.[ER]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Dialysis]				,0) > 0,      'Dialysis - '					+ Cast(x.[Dialysis]					as varchar) + ', ','')
	+IIF(ISNULL(x.[ECT]						,0) > 0,      'ECT - '						+ Cast(x.[ECT]						as varchar) + ', ','')
	+IIF(ISNULL(x.[IOP]						,0) > 0,      'IOP - '						+ Cast(x.[IOP]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Cardiac_Rehab]			,0) > 0,      'Cardiac_Rehab - '			+ Cast(x.[Cardiac_Rehab]			as varchar) + ', ','')
	+IIF(ISNULL(x.[PT/OT/ST]				,0) > 0,      'PT/OT/ST - '					+ Cast(x.[PT/OT/ST]					as varchar) + ', ','')
	+IIF(ISNULL(x.[Miscellaneous]			,0) > 0,      'Miscellaneous - '			+ Cast(x.[Miscellaneous]			as varchar) + ', ','')
	+IIF(ISNULL(x.[Lab]						,0) > 0,      'Lab - '						+ Cast(x.[Lab]						as varchar) + ', ','')
	+IIF(ISNULL(x.[Radiology]				,0) > 0,      'Radiology - '				+ Cast(x.[Radiology]				as varchar) + ', ','')
	+IIF(ISNULL(x.[OP_Default]				,0) > 0,      'OP_Default - '				+ Cast(x.[OP_Default]				as varchar) + ', ','')
	+IIF(ISNULL(x.[Clinic]					,0) > 0,      'Clinic - '					+ Cast(x.[Clinic]					as varchar) + ', ','')	
	
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
			'Seq:'  + CAST(lb.[Sequence]        AS VARCHAR(MAX)) +
			' CPT:' + ISNULL(CAST(lb.[ProcedureCode]  AS VARCHAR(MAX)), '') +
			' Rev:' + ISNULL(CAST(lb.[RevenueCode]    AS VARCHAR(MAX)), '') +
			' | Cat:'     + CAST(lb.[ServiceCategory]   AS VARCHAR(MAX)) +
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
    , 'NYP_COL_CIGNA_COM_OP'
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



-- 	DECLARE @DBName SYSNAME = DB_NAME();
-- EXEC Analytics.dbo.InsertScriptsStepFinal
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_CIGNA_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- -- EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;