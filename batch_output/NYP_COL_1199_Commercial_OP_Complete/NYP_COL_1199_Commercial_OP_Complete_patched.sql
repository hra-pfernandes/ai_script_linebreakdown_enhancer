
-- updated logic and rates. uploaded fee. MR 10/10/24
--Arturo Presa fixed the FS to not price twice with other rates
--Fixed Scripts 12.11.2024 SC
--Updated 2025 Contract Rates & added logic for Feeschedule(Per Visit & 100% Charges) by Naveen Abboju 07.10.2025
--Updated Drugs FB Modifier, as per Ricardo's feedback 07.22.2025
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
Select x.[EncounterID], y.[TypeOfBill], x.[RevenueCode], x.[ProcedureCode], y.[Payer01Name], y.[Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type] as [Employee], p.[audit_by], p.[audit_date], y.[AGE]

INTO #Step1
FROM [Data].[Charges] as x

	LEFT JOIN [Data].[Demo] as y on x.EncounterID = y.EncounterID
	LEFT JOIN [PRS].[dbo].[PRS_Data] as p on x.[EncounterID] = p.[patient_id_real]
	LEFT JOIN [PRS].[dbo].Underpayments AS p1 ON p.[patient_id_real] = p1.[patient_id_real]

where TypeOfBill = 'Outpatient'

	and ((Payer01Name like '%1199%') or (y.[Contract] IN ('1199') and (y.[Plan] IN ('MMC'))))

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
	--    and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	--and y.[AGE] < 65

	--and x.EncounterID = '500044647834'
	AND x.[ServiceDateFrom] < '2026-01-01'

Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date], y.[AGE]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric

INTO #Step1_Charges
FROM [Data].[Charges] as x

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
Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], IIF(y.[ServiceDateTo] < '2021-01-01', G1.[ASC_GROUP], IIF(y.[ServiceDateTo] < '2022-01-01', G2.[ASC_GROUP], G3.[ASC_GROUP])) as Grouper, [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]

	-- Need 1199 Psych Fee Schedule


	, [OP_Default] = CASE
	WHEN 1=1 THEN Round(x.Amount * 0.50, 2)
	ELSE 0
	END


	, [Fee_Schedule] = CASE
	WHEN (RevenueCode not between 420 and 449) and (RevenueCode not between 360 and 369) and (RevenueCode not between 490 and 499) and (RevenueCode not between 750 and 759) and (RevenueCode not between 790 and 799) and (RevenueCode not between 380 and 399) and (ProcedureCode NOT LIKE 'J9%' and ProcedureCode NOT IN ('Q5107','C9042','C9044','C9045','C9050','C9049','Q5112','Q5113','Q5114','Q5115')) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2020]) and (y.[ServiceDateFrom] <  '2021-01-01') THEN IIF(FEE1.[Fee] is null, 0, FEE1.[Fee] * IIF(Quantity is null, 1, Quantity))
	WHEN (RevenueCode not between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2021]) and ((ProcedureCode NOT LIKE 'J%') and ProcedureCode NOT IN ('Q5107','C9042','C9044','C9045','C9050','C9049','Q5112','Q5113','Q5114','Q5115')) and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN IIF(FEE2.[Fee] is null, 0, FEE2.[Fee] * IIF(Quantity is null, 1, Quantity))
	WHEN (RevenueCode not between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2022]) and ((ProcedureCode NOT LIKE 'J%') and ProcedureCode NOT IN ('Q5107','C9042','C9044','C9045','C9050','C9049','Q5112','Q5113','Q5114','Q5115')) and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN IIF(FEE3.[Fee] is null, 0, FEE3.[Fee] * IIF(Quantity is null, 1, Quantity))	
	WHEN (RevenueCode not between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2023]) and ((ProcedureCode NOT LIKE 'J%') and ProcedureCode NOT IN ('Q5107','C9042','C9044','C9045','C9050','C9049','Q5112','Q5113','Q5114','Q5115')) and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN IIF(FEE4.[Fee] is null, 0, FEE4.[Fee] * IIF(Quantity is null, 1, Quantity))	
	WHEN (RevenueCode not between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2024]) and ((ProcedureCode NOT LIKE 'J%') and ProcedureCode NOT IN ('Q5107','C9042','C9044','C9045','C9050','C9049','Q5112','Q5113','Q5114','Q5115')) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31')	THEN IIF(FEE5.[Fee] is null, 0, FEE5.[Fee] * IIF(Quantity is null, 1, Quantity))
	WHEN (RevenueCode not between 420 and 449) and ProcedureCode IS NOT NULL AND FEE.[Code_ID] IS NOT NULL and ((ProcedureCode NOT LIKE 'J%') AND x.[ProcedureCode] not in ('97010' ,'97012' ,'97014' ,'97016' ,'97018' ,'97022' ,'97024' ,'97026' ,'97028' ,'97032' ,'97033' ,'97034' ,'97035' ,'97036' ,'97037' ,'97039' ,'97110' ,'97112' ,'97113' ,'97116' ,'97124' ,'97129' ,'97130' ,'97139' ,'97140' ,'97150' ,'97161' ,'97162' ,'97163' ,'97164' ,'97165' ,'97166' ,'97167' ,'97168' ,'97530' ,'97532' ,'97533' ,'97535' ,'97537' ,'97542' ,'97545' ,'97546' ,'98940' ,'98941' ,'98942' ,'98943', 'C9081','C9098','J1411','J1412','J1413') and ProcedureCode NOT IN ('Q5107','C9042','C9044','C9045','C9050','C9049','Q5112','Q5113','Q5114','Q5115')) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31')	THEN IIF(FEE.[Fee] is null, 0, FEE.[Fee] * IIF(Quantity is null, 1, Quantity))  --- Excluding Pervisit & 100% charges CPT's 
	ELSE 0 
	END  

	, [Fee_Schedule1] = CASE -- Pervisit CPT's 
	WHEN x.[ProcedureCode] in ('97010' ,'97012' ,'97014' ,'97016' ,'97018' ,'97022' ,'97024' ,'97026' ,'97028' ,'97032' ,'97033' ,'97034' ,'97035' ,'97036' ,'97037' ,'97039' ,'97110' ,'97112' ,'97113' ,'97116' ,'97124' ,'97129' ,'97130' ,'97139' ,'97140' ,'97150' ,'97161' ,'97162' ,'97163' ,'97164' ,'97165' ,'97166' ,'97167' ,'97168' ,'97530' ,'97532' ,'97533' ,'97535' ,'97537' ,'97542' ,'97545' ,'97546' ,'98940' ,'98941' ,'98942' ,'98943') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN FEE.[Fee]  --- Excluding Pervisit & 100% charges CPT's 
	ELSE 0 
	END  
	
	, [Fee_Schedule2] = CASE -- 100% Charges 
	WHEN x.[ProcedureCode] in ('C9081','C9098','J1411','J1412','J1413') and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31') THEN x.[Amount]  --- Excluding Pervisit & 100% charges CPT's 
	ELSE 0 
	END  


	, [ER] = CASE
	WHEN RevenueCode IN ('450','451','456','459') and y.[ServiceDateFrom] <  '2021-01-01' THEN 714
	WHEN RevenueCode IN ('450','451','456','459') and y.[ServiceDateFrom] >= '2021-01-01' THEN 767		
	ELSE 0
	END


	, [AS] = CASE 
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '1' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  1456
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '2' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  1961
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '3' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  2245
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '4' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  2759
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '5' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  3168
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '6' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  3616
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '7' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  4371
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '8' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  4242
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '9' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  5835
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '10' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  15536
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '11' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  20501
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '12' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  27638
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = '13' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  41274
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = 'MP 1' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  316
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2019]) and G1.[ASC_GROUP] = 'MP 2' and (y.[ServiceDateFrom] <  '2021-01-01')						THEN  722
																																			
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '01' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  1564
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '02' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  2107
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '03' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  2412
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '04' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  2965
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '05' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  3404
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '06' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  3885
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '07' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  4697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '08' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  4558
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '09' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  6270
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '10' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  16693
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '11' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  22028
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '12' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  29697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = '13' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  44349
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = 'MP 1' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  340
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2021]) and G2.[ASC_GROUP] = 'MP 2' and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN  776
	 
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '01' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  1564
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '02' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  2107
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '03' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  2412
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '04' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  2965
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '05' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  3404
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '06' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  3885
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '07' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  4697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '08' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  4558
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '09' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN  6270
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '10' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN 16693
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '11' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN 22028
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '12' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN 29697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = '13' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN 44349
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = 'MP 1' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN   340
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2022]) and G2.[ASC_GROUP] = 'MP 2' and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN   776

	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '01' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  1564
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '02' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  2107
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '03' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  2412
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '04' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  2965
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '05' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  3404
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '06' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  3885
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '07' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  4697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '08' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  4558
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '09' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN  6270
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '10' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN 16693
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '11' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN 22028
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '12' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN 29697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '13' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN 44349
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = 'MP 1' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN   340
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = 'MP 2' and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN   776

	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '01' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 1564
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '02' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 2107
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '03' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 2412
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '04' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 2965
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '05' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 3404
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '06' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 3885
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '07' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 4697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '08' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 4558
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '09' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 6270
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '10' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 16693
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '11' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 22028
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '12' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 29697
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = '13' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 44349
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = 'MP 1' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 340
	WHEN ((RevenueCode between 360 and 369) or (RevenueCode between 490 and 499) or (RevenueCode between 750 and 759) or (RevenueCode between 790 and 799)) and ProcedureCode IN (SELECT [CPT_CODE]
		FROM [QNS].[FSG].[1199_ASC_Grouper_January_2023]) and G4.[ASC_GROUP] = 'MP 2' and (y.[ServiceDateFrom] between '2024-01-01' and '2025-12-31')	THEN 776	
	ELSE 0
	END
	
	
	
	, [Cardiac_Cath] = CASE
	WHEN [ProcedureCode] IN ('93451','93452','93453','93454','93455','93456','93457','93458','93459','93460','93461','93462','93463','93464','93503','93505','93530','93531','93532','93533','93561','93562','93563','93564','93565','93566','93567','93568','93571','93572','93580','93581','93582','93583') and y.[ServiceDateFrom] <  '2021-01-01' THEN 7490	
	WHEN [ProcedureCode] IN ('93451','93452','93453','93454','93455','93456','93457','93458','93459','93460','93461','93462','93463','93464','93503','93505','93530','93531','93532','93533','93561','93562','93563','93564','93565','93566','93567','93568','93571','93572','93580','93581','93582','93583') and y.[ServiceDateFrom] >= '2021-01-01' THEN 8048
	ELSE 0
	END
	
	
	
	, [PTCA] = CASE
	WHEN [ProcedureCode] IN ('C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','35475','35476','36902','36903','36904','36905','36906','36907','37246','37247','37248','37249','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92986','92987','92990','92992','92993','92997','92998') and y.[ServiceDateFrom] <  '2021-01-01' THEN 15282
	WHEN [ProcedureCode] IN ('C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','35475','35476','36902','36903','36904','36905','36906','36907','37246','37247','37248','37249','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92986','92987','92990','92992','92993','92997','92998') and y.[ServiceDateFrom] >= '2021-01-01' THEN 16420
	ELSE 0
	END
	
	
	
	, [PTCA_Cardiac_Cath] = CASE
	WHEN [ProcedureCode] IN ('93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93463','93464','93503','93505','93530','93531','93532','93533','93561','93562','93563','93564','93565','93566','93567','93568','93571','93572','93580','93581','93582','93583') and y.[ServiceDateFrom] <  '2021-01-01' THEN 21404
	WHEN [ProcedureCode] IN ('93451','93452','93453','93454','93456','93457','93458','93459','93460','93461','93462','93463','93464','93503','93505','93530','93531','93532','93533','93561','93562','93563','93564','93565','93566','93567','93568','93571','93572','93580','93581','93582','93583') and y.[ServiceDateFrom] >= '2021-01-01' THEN 22998
	ELSE 0
	END
	
	
	
	, [PTCA_Cardiac_Cath_Qualifier] = CASE
	WHEN [ProcedureCode] IN ('C9600','C9601','C9602','C9603','C9604','C9605','C9606','C9607','C9608','35475','35476','36902','36903','36904','36905','36906','36907','37246','37247','37248','37249','92920','92921','92924','92925','92928','92929','92933','92934','92937','92938','92941','92943','92944','92973','92974','92986','92987','92990','92992','92993','92997','92998') THEN 1
	ELSE 0
	END
	
	
	
	, [EPS] = CASE
	WHEN ProcedureCode in ('92920','93600','93602','93603','93609','93610','93612','93613','93615','93616','93618','93619','93620','93621','93622','93623','93624','93631','93640','93642','93650','93653','93654','93655','93656','93657','93660','93662') and y.[ServiceDateFrom] <  '2021-01-01' THEN 7490
	WHEN ProcedureCode in ('92920','93600','93602','93603','93609','93610','93612','93613','93615','93616','93618','93619','93620','93621','93622','93623','93624','93631','93640','93642','93650','93653','93654','93655','93656','93657','93660','93662') and y.[ServiceDateFrom] >= '2021-01-01' THEN 8048
	ELSE 0
	END



	, [Gamma_Knife] = CASE
	WHEN ProcedureCode IN ('G0339','G0340','61796','61797','61798','61799','61800','63620','63621','77371','77372','77373','77432','77435') and y.[ServiceDateFrom] <  '2021-01-01' THEN 49224
	WHEN ProcedureCode IN ('G0339','G0340','61796','61797','61798','61799','61800','63620','63621','77371','77372','77373','77432','77435') and y.[ServiceDateFrom] >= '2021-01-01' THEN 52891
	ELSE 0
	END
	
	
	
	, [Hip_Replacement] = CASE
	WHEN ProcedureCode in ('27130') and y.[ServiceDateFrom] >= '2021-01-01' THEN 30454
	ELSE 0
	END
	
	
	
	, [Knee_Replacement] = CASE
	WHEN ProcedureCode in ('27446') and y.[ServiceDateFrom] >= '2021-01-01' THEN 30454
	ELSE 0
	END
	
	
	
	, [Shoulder_Replacement] = CASE
	WHEN ProcedureCode in ('23470','23473') and y.[ServiceDateFrom] >= '2021-01-01' THEN 38251
	ELSE 0
	END
	
	
	, ASP1.PaymentLimit * Quantity * 1.40 as [140%ProjectedDrugs]
	, ASP1.PaymentLimit * Quantity  as [100%ProjectedDrugs]

	, [Drugs] = CASE
	WHEN RevenueCode IN ('634','635','636') AND (x.[Modifier1] != 'FB' OR x.[Modifier1] IS NULL) THEN IIF(ASP1.PaymentLimit is null, 0, Round(ASP1.Paymentlimit * 1.40 * Quantity, 2))
	ELSE 0
	END

   , ASP1.PaymentLimit


	, [Blood] = CASE
	WHEN RevenueCode IN ('380','381','382','383','384','385','386','387','388','389','390','391','392','393','394','395','396','397','398','399') THEN Round(x.Amount * 0.50, 2) -- Added on January 26, 2023 (requested by Theresa)
	ELSE 0
	END
	


	, [Implants] = CASE
	WHEN RevenueCode IN ('272','274','275','276','277','278') AND x.ProcedureCode not in ('C1724','C1725','C1726','C1727','C1728','C1729','C1730','C1731','C1732','C1733','C1753','C1754','C1755','C1756','C1757','C1758','C1759','C1765','C1766','C1769','C1773','C1782','C1819','C1884','C1885','C1887','C1892','C1893','C1894','C2614','C2615','C2618','C2628','C2629','C2630') THEN 0.01
	ELSE 0
	END
	
	

	, [Sleep_Studies] = CASE
	WHEN ProcedureCode IN ('95805','95806','95807','95808','95810','95811') and y.[ServiceDateFrom] <  '2021-01-01' THEN 2724
	WHEN ProcedureCode IN ('95805','95806','95807','95808','95810','95811') and y.[ServiceDateFrom] >= '2021-01-01' THEN 2927
	
	WHEN ProcedureCode IN ('95951') and y.[ServiceDateFrom] <  '2021-01-01' THEN 4087
	WHEN ProcedureCode IN ('95951') and y.[ServiceDateFrom] >= '2021-01-01' THEN 4391
	ELSE 0
	END

	

	, [PT/OT/ST] = CASE
	WHEN (RevenueCode between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2020]) and (y.[ServiceDateFrom] <  '2021-01-01')						THEN IIF(FEE1.[Fee] is null, 0, FEE1.[Fee])
	WHEN (RevenueCode between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2021]) and (y.[ServiceDateFrom] between '2021-01-01' and '2021-12-31')	THEN IIF(FEE2.[Fee] is null, 0, FEE2.[Fee])	
	WHEN (RevenueCode between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2022]) and (y.[ServiceDateFrom] between '2022-01-01' and '2022-12-31')	THEN IIF(FEE3.[Fee] is null, 0, FEE3.[Fee])	
	WHEN (RevenueCode between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2023]) and (y.[ServiceDateFrom] between '2023-01-01' and '2023-12-31')	THEN IIF(FEE4.[Fee] is null, 0, FEE4.[Fee])	
	WHEN (RevenueCode between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [QNS].[FSG].[1199_OP_Fee_Schedule_January_2024]) and (y.[ServiceDateFrom] between '2024-01-01' and '2024-12-31')	THEN IIF(FEE5.[Fee] is null, 0, FEE5.[Fee])	
	WHEN (RevenueCode between 420 and 449) and ProcedureCode IN (SELECT [Code_ID]
		FROM [Analytics].[FSG].[NYP_1199_OP_Fee_Schedule]) and (y.[ServiceDateFrom] between '2025-01-01' and '2025-12-31')	THEN IIF(FEE.[Fee]  is null, 0, FEE.[Fee] )	
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

	LEFT JOIN [Data].[Demo] as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [Data].[Dx_Px] as dp on x.[EncounterID] = dp.[EncounterID] and x.[Sequence] = dp.[Sequence]

	LEFT JOIN [QNS].[FSG].[1199_OP_Fee_Schedule_January_2020]			as FEE1 on x.[ProcedureCode] = FEE1.[Code_ID] -- October 2019 until December 2020
	LEFT JOIN [QNS].[FSG].[1199_OP_Fee_Schedule_January_2021]			as FEE2 on x.[ProcedureCode] = FEE2.[Code_ID] and FEE2.[MODIFIER] IS NULL -- January 2021 until December 2021
	LEFT JOIN [QNS].[FSG].[1199_OP_Fee_Schedule_January_2022]			as FEE3 on x.[ProcedureCode] = FEE3.[code_ID] -- January 2022 until December 2022	
	LEFT JOIN [QNS].[FSG].[1199_OP_Fee_Schedule_January_2023]			as FEE4 on x.[ProcedureCode] = FEE4.[code_ID] -- January 2023 until December 2023
	LEFT JOIN [QNS].[FSG].[1199_OP_Fee_Schedule_January_2024]			as FEE5 on x.[ProcedureCode] = FEE5.[code_ID] -- January 2024 until December 2024	
	LEFT JOIN [Analytics].[FSG].[NYP_1199_OP_Fee_Schedule]			    as FEE on x.[ProcedureCode] = FEE.[code_ID] and (y.[ServiceDateFrom] BETWEEN [FEE].[StartDate] AND FEE.[EndDate])

	LEFT JOIN [QNS].[FSG].[1199_ASC_Grouper_January_2019]				as G1 on x.[ProcedureCode] = G1.[CPT_CODE] -- Effective on Jan. 2019 until December 2020
	LEFT JOIN [QNS].[FSG].[1199_ASC_Grouper_January_2021]				as G2 on x.[ProcedureCode] = G2.[CPT_CODE] -- Effective on Jan. 2021 until December 2021
	LEFT JOIN [QNS].[FSG].[1199_ASC_Grouper_January_2022]				as G3 on x.[ProcedureCode] = G3.[CPT_CODE] -- Effective on Jan. 2022 until December 2022
	LEFT JOIN [QNS].[FSG].[1199_ASC_Grouper_January_2023]				as G4 on x.[ProcedureCode] = G4.[CPT_CODE] -- Effective on Jan. 2023 until December 2025, 

	LEFT JOIN [Analytics].[MCR].[ASP]									as ASP1 on ASP1.[CPT] = x.[ProcedureCode] and (y.[ServiceDateFrom] between ASP1.[StartDate] and ASP1.[EndDate])

ORDER BY x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate], [ProcedureCode], [RevenueCode], [Amount], [OriginalPayment]	
	, [OP_Default] 	= IIF([Fee_Schedule]=0 and [Fee_Schedule1]=0 and [Fee_Schedule2]=0 and [AS]=0 and [ER]=0 and [PTCA_Cardiac_Cath]=0 and [Cardiac_Cath]=0 and [PTCA]=0 and [EPS]=0 and [Gamma_Knife]=0 and [Hip_Replacement]=0 and [Knee_Replacement]=0 and [Shoulder_Replacement]=0 and [Drugs]=0 and [Blood]=0 and [Sleep_Studies]=0 and [PT/OT/ST]=0 and [Implants]=0, [OP_Default], 0)
	, [PT/OT/ST]
	, [Fee_Schedule] =  IIF([PT/OT/ST] = 0 AND [Drugs]=0, [Fee_Schedule], 0)
	, [Fee_Schedule1] = IIF([PT/OT/ST] = 0 AND [Drugs]=0, [Fee_Schedule1], 0)
	, [Fee_Schedule2] = IIF([PT/OT/ST] = 0 AND [Drugs]=0, [Fee_Schedule2], 0)
	, [ER]
	
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

	, [PTCA_Cardiac_Cath]
	, [PTCA_Cardiac_Cath_Qualifier]
	, [Cardiac_Cath]
	, [PTCA]
	, [EPS]
	, [Gamma_Knife]
	, [Hip_Replacement]
	, [Knee_Replacement]
	, [Shoulder_Replacement]
	, [Drugs]	=iif((modifier1 not in ('FB','SL') or Modifier1 IS NULL),[drugs],0)
	, [Blood]
	, [Implants]
	, [Sleep_Studies]
	, [COVID]


INTO #Step3
FROM #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]
	, SUM([OP_Default])					as [OP_Default]	
	, SUM([Fee_Schedule])				as [Fee_Schedule]
	, MAX([Fee_Schedule1])				as [Fee_Schedule1]   -- Per Visit
	, SUM([Fee_Schedule2])				as [Fee_Schedule2]   -- 100% Charges
	, SUM([PT/OT/ST])					as [PT/OT/ST]	
	, MAX([ER])							as [ER]	
	, MAX(AS1)+MAX(AS2)+MAX(AS3)+MAX(AS4)+MAX(AS5)+MAX(AS6)+MAX(AS7)+MAX(AS8)+MAX(AS9)+MAX(AS10) as [AS]
	, MAX([PTCA_Cardiac_Cath])			as [PTCA_Cardiac_Cath]	
	, MAX([PTCA_Cardiac_Cath_Qualifier])	as [PTCA_Cardiac_Cath_Qualifier]	
	, MAX([Cardiac_Cath])				as [Cardiac_Cath]
	, MAX([PTCA])						as [PTCA]
	, MAX([EPS])							as [EPS]
	, MAX([Gamma_Knife])					as [Gamma_Knife]
	, MAX([Hip_Replacement])				as [Hip_Replacement]
	, MAX([Knee_Replacement])			as [Knee_Replacement]	
	, MAX([Shoulder_Replacement])		as [Shoulder_Replacement]
	, SUM([Drugs])					    as [Drugs]	
	, SUM([Blood])					    as [Blood]		
	, SUM([Implants])					as [Implants]		
	, MAX([Sleep_Studies])				as [Sleep_Studies]
	, MAX([COVID])						as [COVID]

INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]


--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, SUM([Fee_Schedule]) + SUM([Fee_Schedule1]) + SUM([Fee_Schedule2])		as [Fee_Schedule]  ---Combining all Fee Schedules
	, SUM([OP_Default])					as [OP_Default]
	, SUM([PT/OT/ST])					as [PT/OT/ST]		
	, MAX([ER])							as [ER]	
	, MAX([AS])							as [AS]
	, MAX([PTCA_Cardiac_Cath])			as [PTCA_Cardiac_Cath]	
	, MAX([PTCA_Cardiac_Cath_Qualifier])	as [PTCA_Cardiac_Cath_Qualifier]	
	, MAX([Cardiac_Cath])				as [Cardiac_Cath]
	, MAX([PTCA])						as [PTCA]
	, MAX([EPS])							as [EPS]
	, MAX([Gamma_Knife])					as [Gamma_Knife]
	, MAX([Hip_Replacement])				as [Hip_Replacement]
	, MAX([Knee_Replacement])			as [Knee_Replacement]	
	, MAX([Shoulder_Replacement])		as [Shoulder_Replacement]	
	, SUM([Drugs])						as [Drugs]
	, SUM([Blood])					    as [Blood]		
	, SUM([Implants])					as [Implants]		
	, MAX([Sleep_Studies])				as [Sleep_Studies]
	, MAX([COVID])						as [COVID]

INTO #Step3_2
FROM #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, [Drugs]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [ER]!=0 or [PT/OT/ST]!=0, 0, [Drugs])			
	, [Blood]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [ER]!=0 or [PT/OT/ST]!=0, 0, [Blood])	
	, [Implants]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [ER]!=0 or [PT/OT/ST]!=0, 0, [Implants])							 

	, [Gamma_Knife]	
	, [Shoulder_Replacement]			= IIF([Gamma_Knife]!=0, 0, [Shoulder_Replacement])
	, [Hip_Replacement]				= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0, 0, [Hip_Replacement])
	, [Knee_Replacement]				= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0, 0, [Knee_Replacement])	
	, [PTCA_Cardiac_Cath]			= IIF([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1, [PTCA_Cardiac_Cath], 0)
	, [PTCA_Cardiac_Cath_Qualifier]
	, [PTCA]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1), 0, [PTCA])
	, [Cardiac_Cath]					= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0, 0, [Cardiac_Cath])
	, [EPS]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0, 0, [EPS])
	, [AS]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0, 0, [AS])
	, [Sleep_Studies]				= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0, 0, [Sleep_Studies])
	, [ER]							= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Sleep_Studies]!=0, 0, [ER])
	, [PT/OT/ST]						= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Sleep_Studies]!=0 or [ER]!=0, 0, [PT/OT/ST])	
	
	, [Fee_Schedule]					= IIF([Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Sleep_Studies]!=0 or [ER]!=0, 0, [Fee_Schedule])
	, [OP_Default]					= IIF ( [Gamma_Knife]!=0 or [Shoulder_Replacement]!=0 or [Hip_Replacement]!=0 or [Knee_Replacement]!=0 or ([PTCA_Cardiac_Cath]!=0 and [PTCA_Cardiac_Cath_Qualifier]=1) or [PTCA]!=0 or [Cardiac_Cath]!=0 or [EPS]!=0 or [AS]!=0 or [Sleep_Studies]!=0 or [ER]!=0 or [PT/OT/ST]!=0, 0, [OP_Default])	
	, [COVID]

INTO #Step4
FROM #Step3_2

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (post-LEAD slot computation, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
--           #Step2 joined for Sequence, Quantity, BillCharges (not in #Step3).
--
-- MAX CATEGORIES (one winner per encounter, PARTITION BY EncounterID):
--   ER, EPS, Gamma_Knife, Hip_Replacement, Knee_Replacement,
--   Shoulder_Replacement, PTCA_Cardiac_Cath, PTCA_Cardiac_Cath_Qualifier,
--   Sleep_Studies
--
-- MAX CATEGORIES that are also present but effectively flat-rate per encounter:
--   PTCA, Cardiac_Cath  (MAX in both agg steps -> MAX)
--
-- SUM CATEGORIES (all matching lines pay):
--   OP_Default, Fee_Schedule (combined Fee_Schedule+Fee_Schedule1+Fee_Schedule2
--   in #Step4, but individual sub-columns exist in #Step3),
--   PT/OT/ST, Drugs, Blood, Implants
--
-- WINDOW_REDUCTION CATEGORIES (slot-based payment via LEAD pivot):
--   AS : slots AS1-AS10 (PARTITION BY EncounterID only)
--
-- INDICATOR_FLAG CATEGORIES (binary 0/1, $0 LinePayment):
--   COVID
--
-- SUPPRESSION HIERARCHY (tier 1 = highest priority, read from #Step4):
--   1.  Gamma_Knife
--   2.  Shoulder_Replacement     (suppressed if Gamma_Knife != 0)
--   3.  Hip_Replacement          (suppressed if Gamma_Knife OR Shoulder_Replacement != 0)
--   4.  Knee_Replacement         (suppressed if Gamma_Knife OR Shoulder_Replacement != 0)
--   5.  PTCA_Cardiac_Cath        (active only if PTCA_Cardiac_Cath_Qualifier = 1)
--   6.  PTCA                     (suppressed if Gamma_Knife/SR/HR/KR/PTCA_CC_Qual != 0)
--   7.  Cardiac_Cath             (suppressed if above OR PTCA != 0)
--   8.  EPS                      (suppressed if above OR PTCA != 0)
--   9.  AS                       (suppressed if above OR Cardiac_Cath OR EPS != 0)
--  10.  Sleep_Studies            (suppressed if above OR AS != 0)
--  11.  ER                       (suppressed if above OR Sleep_Studies != 0)
--  12.  PT/OT/ST                 (suppressed if above OR ER != 0)
--  13.  Fee_Schedule             (suppressed if above OR ER != 0)
--  14.  OP_Default               (suppressed if above OR PT/OT/ST != 0)
--  Special: Drugs/Blood/Implants suppressed if any of the main categories != 0
--           (Gamma_Knife/SR/HR/KR/PTCA/Cardiac_Cath/EPS/AS/ER/PT_OT_ST != 0)
--  COVID: INDICATOR_FLAG, always $0
--=======================================================================

-- -----------------------------------------------------------------------
-- BLOCK 1: #bRanked
-- One ROW_NUMBER() per:
--   MAX categories (9): ER, EPS, Gamma_Knife, Hip_Replacement, Knee_Replacement,
--                        Shoulder_Replacement, PTCA, Cardiac_Cath,
--                        PTCA_Cardiac_Cath, PTCA_Cardiac_Cath_Qualifier, Sleep_Studies
--   WINDOW_REDUCTION (1): AS (PARTITION BY EncounterID only)
--   INDICATOR_FLAG (1): COVID
-- NOTE: #Step3 explicit column list does NOT include Sequence, Quantity,
--       BillCharges. These are recovered via LEFT JOIN to #Step2 in #LineBreakdown.
--       #Step3 DOES contain all LEAD slot columns AS1-AS10 and all pricing columns.
-- NOTE: Fee_Schedule in #Step3 has THREE sub-columns: Fee_Schedule, Fee_Schedule1,
--       Fee_Schedule2. PT/OT/ST is a separate SUM column.
-- COUNT CHECK: 11 MAX + 1 WINDOW_REDUCTION + 1 INDICATOR_FLAG = 13 ROW_NUMBER() calls.
-- -----------------------------------------------------------------------
SELECT
    b.*
    -- MAX categories: PARTITION BY EncounterID
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[ER]                        DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_ER
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[EPS]                       DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_EPS
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Gamma_Knife]               DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Gamma_Knife
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Hip_Replacement]           DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Hip_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Knee_Replacement]          DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Knee_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Shoulder_Replacement]      DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Shoulder_Replacement
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA]                      DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_PTCA
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Cardiac_Cath]              DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA_Cardiac_Cath]         DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_PTCA_Cardiac_Cath
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[PTCA_Cardiac_Cath_Qualifier] DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_PTCA_Cardiac_Cath_Qualifier
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[Sleep_Studies]             DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_Sleep_Studies
    -- WINDOW_REDUCTION: AS (LEAD PARTITION BY EncounterID only)
    -- ORDER BY SUM of ALL slot columns AS1-AS10
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY (  ISNULL(b.[AS1],0)  + ISNULL(b.[AS2],0)  + ISNULL(b.[AS3],0)
                    + ISNULL(b.[AS4],0)  + ISNULL(b.[AS5],0)  + ISNULL(b.[AS6],0)
                    + ISNULL(b.[AS7],0)  + ISNULL(b.[AS8],0)  + ISNULL(b.[AS9],0)
                    + ISNULL(b.[AS10],0)) DESC
                  , b.[Amount] DESC, b.[EncounterID] ASC) AS rn_AS
    -- INDICATOR_FLAG: COVID (binary 0/1, PARTITION BY EncounterID same as MAX)
    , ROW_NUMBER() OVER (PARTITION BY b.[EncounterID]
          ORDER BY b.[COVID]                     DESC, b.[Amount] DESC, b.[EncounterID] ASC) AS rn_COVID
INTO #bRanked
FROM #Step3 b;

-- -----------------------------------------------------------------------
-- BLOCK 2: #bSlots
-- Extracts slot values for WINDOW_REDUCTION category AS.
-- LEAD partition for AS = EncounterID_only => GROUP BY EncounterID only.
-- Uses GROUP BY + MAX(CASE...) pattern (no WHERE rn=1).
-- -----------------------------------------------------------------------
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

-- -----------------------------------------------------------------------
-- BLOCK 3: #LineBreakdown
-- Main line-level breakdown. One row per charge line.
-- #Step3 does NOT contain: Sequence, Quantity, BillCharges.
-- These are recovered via LEFT JOIN to #Step2 on EncounterID + ServiceDate.
-- NOTE: #Step2 may have multiple rows per EncounterID+ServiceDate.
-- We join on EncounterID + ServiceDate as the narrowest available key from #Step3.
-- Fee_Schedule in #Step3 has sub-columns Fee_Schedule, Fee_Schedule1, Fee_Schedule2.
-- In #Step4, these are collapsed to a single [Fee_Schedule] column
-- (SUM(Fee_Schedule)+SUM(Fee_Schedule1)+SUM(Fee_Schedule2)).
-- For ServiceCategory and LinePayment, we check all three sub-columns.
-- -----------------------------------------------------------------------
SELECT
    b.[EncounterID]
    -- Sequence, ProcedureCode, RevenueCode, Amount, BillCharges, Quantity
    -- not present in #Step3. Recovered from #Step2 via LEFT JOIN.
    , src.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                                AS [BilledAmount]
    , src.[Quantity]
    , CAST(NULL AS DECIMAL(12,2))                               AS [BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Hierarchy order exactly matches #Step4 IIF chain.
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

        -- TIER 3: Hip_Replacement (MAX)
        WHEN s4.[Hip_Replacement] != 0
         AND b.[Hip_Replacement] > 0
            THEN IIF(b.rn_Hip_Replacement = 1, 'Hip_Replacement', 'Hip_Replacement_Non_Winner')

        -- TIER 4: Knee_Replacement (MAX)
        WHEN s4.[Knee_Replacement] != 0
         AND b.[Knee_Replacement] > 0
            THEN IIF(b.rn_Knee_Replacement = 1, 'Knee_Replacement', 'Knee_Replacement_Non_Winner')

        -- TIER 5: PTCA_Cardiac_Cath (MAX, active only when PTCA_Cardiac_Cath_Qualifier=1)
        WHEN s4.[PTCA_Cardiac_Cath] != 0
         AND b.[PTCA_Cardiac_Cath] > 0
            THEN IIF(b.rn_PTCA_Cardiac_Cath = 1, 'PTCA_Cardiac_Cath', 'PTCA_Cardiac_Cath_Non_Winner')

        -- TIER 6: PTCA (MAX)
        WHEN s4.[PTCA] != 0
         AND b.[PTCA] > 0
            THEN IIF(b.rn_PTCA = 1, 'PTCA', 'PTCA_Non_Winner')

        -- TIER 7: Cardiac_Cath (MAX)
        WHEN s4.[Cardiac_Cath] != 0
         AND b.[Cardiac_Cath] > 0
            THEN IIF(b.rn_Cardiac_Cath = 1, 'Cardiac_Cath', 'Cardiac_Cath_Non_Winner')

        -- TIER 8: EPS (MAX)
        WHEN s4.[EPS] != 0
         AND b.[EPS] > 0
            THEN IIF(b.rn_EPS = 1, 'EPS', 'EPS_Non_Winner')

        -- TIER 9: AS (WINDOW_REDUCTION via AS1-AS10 slots, PARTITION BY EncounterID)
        WHEN s4.[AS] != 0
         AND (  ISNULL(b.[AS1],0) + ISNULL(b.[AS2],0) + ISNULL(b.[AS3],0)
              + ISNULL(b.[AS4],0) + ISNULL(b.[AS5],0) + ISNULL(b.[AS6],0)
              + ISNULL(b.[AS7],0) + ISNULL(b.[AS8],0) + ISNULL(b.[AS9],0)
              + ISNULL(b.[AS10],0)) > 0
            THEN CASE
                    WHEN b.rn_AS BETWEEN 1 AND 10 THEN 'AS_Ambulatory_Surgery'
                    ELSE 'AS_Ambulatory_Surgery_Beyond_Max'
                 END

        -- TIER 10: Sleep_Studies (MAX)
        WHEN s4.[Sleep_Studies] != 0
         AND b.[Sleep_Studies] > 0
            THEN IIF(b.rn_Sleep_Studies = 1, 'Sleep_Studies', 'Sleep_Studies_Non_Winner')

        -- TIER 11: ER (MAX)
        WHEN s4.[ER] != 0
         AND b.[ER] > 0
            THEN IIF(b.rn_ER = 1, 'ER', 'ER_Non_Winner')

        -- TIER 12: PT/OT/ST (SUM)
        WHEN s4.[PT/OT/ST] != 0
         AND b.[PT/OT/ST] > 0
            THEN 'PT_OT_ST'

        -- TIER 13: Fee_Schedule (SUM — sub-columns Fee_Schedule, Fee_Schedule1, Fee_Schedule2)
        WHEN s4.[Fee_Schedule] != 0
         AND (ISNULL(b.[Fee_Schedule],0) + ISNULL(b.[Fee_Schedule1],0) + ISNULL(b.[Fee_Schedule2],0)) > 0
            THEN CASE
                    WHEN ISNULL(b.[Fee_Schedule1],0) > 0 THEN 'Fee_Schedule_PerVisit'
                    WHEN ISNULL(b.[Fee_Schedule2],0) > 0 THEN 'Fee_Schedule_100Pct_Charges'
                    ELSE 'Fee_Schedule'
                 END

        -- TIER 14: Drugs (SUM)
        WHEN s4.[Drugs] != 0
         AND b.[Drugs] > 0
            THEN 'Drugs'

        -- TIER 15: Blood (SUM)
        WHEN s4.[Blood] != 0
         AND b.[Blood] > 0
            THEN 'Blood'

        -- TIER 16: Implants (SUM)
        WHEN s4.[Implants] != 0
         AND b.[Implants] > 0
            THEN 'Implants'

        -- TIER 17: OP_Default (SUM — catch-all)
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- Suppressed: line matched a category but #Step4 hierarchy zeroed it
        WHEN (
              ISNULL(b.[ER],0)
            + ISNULL(b.[EPS],0)
            + ISNULL(b.[Gamma_Knife],0)
            + ISNULL(b.[Hip_Replacement],0)
            + ISNULL(b.[Knee_Replacement],0)
            + ISNULL(b.[Shoulder_Replacement],0)
            + ISNULL(b.[PTCA],0)
            + ISNULL(b.[Cardiac_Cath],0)
            + ISNULL(b.[PTCA_Cardiac_Cath],0)
            + ISNULL(b.[PTCA_Cardiac_Cath_Qualifier],0)
            + ISNULL(b.[Sleep_Studies],0)
            + ISNULL(b.[PT/OT/ST],0)
            + ISNULL(b.[Fee_Schedule],0)
            + ISNULL(b.[Fee_Schedule1],0)
            + ISNULL(b.[Fee_Schedule2],0)
            + ISNULL(b.[Drugs],0)
            + ISNULL(b.[Blood],0)
            + ISNULL(b.[Implants],0)
            + ISNULL(b.[OP_Default],0)
            + ISNULL(b.[COVID],0)
            + ISNULL(b.[AS1],0)  + ISNULL(b.[AS2],0)  + ISNULL(b.[AS3],0)
            + ISNULL(b.[AS4],0)  + ISNULL(b.[AS5],0)  + ISNULL(b.[AS6],0)
            + ISNULL(b.[AS7],0)  + ISNULL(b.[AS8],0)  + ISNULL(b.[AS9],0)
            + ISNULL(b.[AS10],0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- INDICATOR_FLAG: COVID (binary 0/1, placed after all dollar and suppressed categories)
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Gamma_Knife] != 0 AND b.[Gamma_Knife] > 0
            THEN 'Contracted flat rate per contract period (Gamma Knife CPT list: G0339/G0340/61796-61800/63620/63621/77371-77373/77432/77435)'

        WHEN s4.[Shoulder_Replacement] != 0 AND b.[Shoulder_Replacement] > 0
            THEN 'Contracted flat rate $38,251 (2021+) (Shoulder Replacement CPT: 23470/23473)'

        WHEN s4.[Hip_Replacement] != 0 AND b.[Hip_Replacement] > 0
            THEN 'Contracted flat rate $30,454 (2021+) (Hip Replacement CPT: 27130)'

        WHEN s4.[Knee_Replacement] != 0 AND b.[Knee_Replacement] > 0
            THEN 'Contracted flat rate $30,454 (2021+) (Knee Replacement CPT: 27446)'

        WHEN s4.[PTCA_Cardiac_Cath] != 0 AND b.[PTCA_Cardiac_Cath] > 0
            THEN 'Contracted flat rate for PTCA+Cardiac Cath combined (active only when PTCA_Cardiac_Cath_Qualifier=1; CPT overlap list)'

        WHEN s4.[PTCA] != 0 AND b.[PTCA] > 0
            THEN 'Contracted flat rate per contract period (PTCA CPT list: C9600-C9608/35475/35476/36902-36907/37246-37249/92920-92944/92973/92974/92986/92987/92990/92992/92993/92997/92998)'

        WHEN s4.[Cardiac_Cath] != 0 AND b.[Cardiac_Cath] > 0
            THEN 'Contracted flat rate per contract period (Cardiac Cath CPT list: 93451-93583 and related codes)'

        WHEN s4.[EPS] != 0 AND b.[EPS] > 0
            THEN 'Contracted flat rate per contract period (EPS CPT list: 92920/93600-93662)'

        WHEN s4.[AS] != 0
         AND (ISNULL(b.[AS1],0)+ISNULL(b.[AS2],0)+ISNULL(b.[AS3],0)+ISNULL(b.[AS4],0)+ISNULL(b.[AS5],0)
             +ISNULL(b.[AS6],0)+ISNULL(b.[AS7],0)+ISNULL(b.[AS8],0)+ISNULL(b.[AS9],0)+ISNULL(b.[AS10],0)) > 0
            THEN CASE
                    WHEN b.rn_AS = 1  THEN 'Contracted grouper-based flat rate — 1st AS procedure, full rate (Rev 36x/49x/75x/79x)'
                    WHEN b.rn_AS = 2  THEN 'Contracted grouper-based flat rate / 2 — 2nd AS procedure reduction'
                    WHEN b.rn_AS BETWEEN 3 AND 10
                                      THEN 'Contracted grouper-based flat rate / 2 — 3rd+ AS procedure reduction'
                    ELSE 'Beyond 10th AS procedure in encounter — $0'
                 END

        WHEN s4.[Sleep_Studies] != 0 AND b.[Sleep_Studies] > 0
            THEN 'Contracted flat rate per contract period (Sleep Studies CPT: 95805-95811/95951)'

        WHEN s4.[ER] != 0 AND b.[ER] > 0
            THEN 'Contracted flat rate per contract period (ER Rev 450/451/456/459; $714 pre-2021, $767 2021+)'

        WHEN s4.[PT/OT/ST] != 0 AND b.[PT/OT/ST] > 0
            THEN '1199 OP Fee Schedule rate (per visit, no Quantity multiplier) — PT/OT/ST Rev 420-449'

        WHEN s4.[Fee_Schedule] != 0
         AND (ISNULL(b.[Fee_Schedule],0)+ISNULL(b.[Fee_Schedule1],0)+ISNULL(b.[Fee_Schedule2],0)) > 0
            THEN CASE
                    WHEN ISNULL(b.[Fee_Schedule1],0) > 0
                        THEN '1199 OP Fee Schedule — Per Visit rate (2025 PT/OT/ST CPT subset; no Quantity multiplier)'
                    WHEN ISNULL(b.[Fee_Schedule2],0) > 0
                        THEN '100% of Charges (Amount) — specific CPTs: C9081/C9098/J1411/J1412/J1413 (2025+)'
                    ELSE '1199 OP Fee Schedule rate x Quantity — CPT in fee schedule for applicable contract year'
                 END

        WHEN s4.[Drugs] != 0 AND b.[Drugs] > 0
            THEN 'ASP PaymentLimit x 1.40 x Quantity (Drugs Rev 634/635/636; excl Modifier FB/SL); $0 if no ASP match'

        WHEN s4.[Blood] != 0 AND b.[Blood] > 0
            THEN 'Pct of charges: Amount x 50% (Blood Rev 380-399)'

        WHEN s4.[Implants] != 0 AND b.[Implants] > 0
            THEN 'Flat rate $0.01 per unit (Implants Rev 272/274-278; excl device pass-through HCPCS codes)'

        WHEN s4.[OP_Default] != 0 AND b.[OP_Default] > 0
            THEN 'Pct of charges: Amount x 50% — OP Default catch-all (no other category matched)'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag — binary 0/1 value, no dollar payment'

        ELSE 'Category suppressed by encounter hierarchy or no pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:              IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    -- SUM:              IIF(s4.[CAT]!=0, ISNULL(b.[CAT],0), 0)
    -- WINDOW_REDUCTION: slot-pivot from #bSlots keyed by EncounterID
    -- INDICATOR_FLAG:   $0 — never add b.[COVID] to LinePayment
    -- Fee_Schedule uses all three sub-columns summed.
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX categories
          IIF(s4.[Gamma_Knife] != 0,
              IIF(b.rn_Gamma_Knife = 1, ISNULL(b.[Gamma_Knife], 0), 0), 0)
        + IIF(s4.[Shoulder_Replacement] != 0,
              IIF(b.rn_Shoulder_Replacement = 1, ISNULL(b.[Shoulder_Replacement], 0), 0), 0)
        + IIF(s4.[Hip_Replacement] != 0,
              IIF(b.rn_Hip_Replacement = 1, ISNULL(b.[Hip_Replacement], 0), 0), 0)
        + IIF(s4.[Knee_Replacement] != 0,
              IIF(b.rn_Knee_Replacement = 1, ISNULL(b.[Knee_Replacement], 0), 0), 0)
        + IIF(s4.[PTCA_Cardiac_Cath] != 0,
              IIF(b.rn_PTCA_Cardiac_Cath = 1, ISNULL(b.[PTCA_Cardiac_Cath], 0), 0), 0)
        + IIF(s4.[PTCA] != 0,
              IIF(b.rn_PTCA = 1, ISNULL(b.[PTCA], 0), 0), 0)
        + IIF(s4.[Cardiac_Cath] != 0,
              IIF(b.rn_Cardiac_Cath = 1, ISNULL(b.[Cardiac_Cath], 0), 0), 0)
        + IIF(s4.[EPS] != 0,
              IIF(b.rn_EPS = 1, ISNULL(b.[EPS], 0), 0), 0)
        + IIF(s4.[Sleep_Studies] != 0,
              IIF(b.rn_Sleep_Studies = 1, ISNULL(b.[Sleep_Studies], 0), 0), 0)
        + IIF(s4.[ER] != 0,
              IIF(b.rn_ER = 1, ISNULL(b.[ER], 0), 0), 0)
          -- SUM categories
        + IIF(s4.[PT/OT/ST] != 0,         ISNULL(b.[PT/OT/ST], 0),    0)
        + IIF(s4.[Fee_Schedule] != 0,
              ISNULL(b.[Fee_Schedule],0) + ISNULL(b.[Fee_Schedule1],0) + ISNULL(b.[Fee_Schedule2],0),
              0)
        + IIF(s4.[Drugs] != 0,            ISNULL(b.[Drugs], 0),        0)
        + IIF(s4.[Blood] != 0,            ISNULL(b.[Blood], 0),        0)
        + IIF(s4.[Implants] != 0,         ISNULL(b.[Implants], 0),     0)
        + IIF(s4.[OP_Default] != 0,       ISNULL(b.[OP_Default], 0),   0)
          -- WINDOW_REDUCTION: AS — each row gets its rank's slot value from #bSlots pivot
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
          -- INDICATOR_FLAG: COVID — $0, never add b.[COVID] to LinePayment
      , 2)

    -- NCCI BUNDLED FLAG: no NCCI bundle step in this script — always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4  ON  s4.[EncounterID] = b.[EncounterID]
LEFT  JOIN #bSlots rd  ON  rd.[EncounterID] = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover Sequence and Quantity not present in #Step3.
-- Join on EncounterID + ServiceDate (both present in #Step3 / #bRanked).
-- Where multiple #Step2 rows share EncounterID+ServiceDate, ProcedureCode
-- tie-breaks to the matching line; DISTINCT in the outer SELECT collapses residual duplication.
LEFT  JOIN #Step2  src ON  src.[EncounterID]  = b.[EncounterID]
                       AND src.[ServiceDate]   = b.[ServiceDate]
                       AND src.[ProcedureCode] = b.[ProcedureCode]
ORDER BY b.[EncounterID], src.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	, [OP_Default] 
	+[Fee_Schedule] 
	+[ER] 
	+[AS]  
	+[Cardiac_Cath] 
	+[PTCA] 
	+[PTCA_Cardiac_Cath] 
	+[PTCA_Cardiac_Cath_Qualifier] 
	+[EPS] 
	+[Gamma_Knife] 
	+[Hip_Replacement] 
	+[Knee_Replacement] 
	+[Shoulder_Replacement] 
	+[Drugs] 
	+[Blood] 
	+[Implants] 
	+[Sleep_Studies] 
	+[PT/OT/ST] 
	+[COVID]

	as Price


INTO #Step5
FROM #Step4

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select
	x.*
	
	, y.[Price]
	, y.[Drugs]	
	, y.[Blood]
	, y.[Implants]
	, y.[Gamma_Knife]	
	, y.[Shoulder_Replacement]	
	, y.[Hip_Replacement]
	, y.[Knee_Replacement]
	, y.[PTCA]	
	, y.[PTCA_Cardiac_Cath]
	, y.[PTCA_Cardiac_Cath_Qualifier]
	, y.[Cardiac_Cath]			
	, y.[EPS]					
	, y.[AS]					
	, y.[Sleep_Studies]		
	, y.[ER]		
	, y.[PT/OT/ST]
	, y.[Fee_Schedule]			
	, y.[OP_Default]
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
From [Data].[Demo] as x

	inner join #Step5 as y on x.[EncounterID] = y.[EncounterID]
	left join [Data].[Charges_With_CPT] as z on x.[EncounterID] = z.[EncounterID]

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
	, Round((cast(x.[OriginalPayment] as float)/IIF([BillCharges]=0, 1, [BillCharges])) * 100, 2) as [% paid]
	, Case 
	When Price - (cast(x.[OriginalPayment] as float))> 10000 Then DATEDIFF(DAY, IsNULL(PaidDate,x.[ServiceDateTo]), GETDATE()) - 365 -30
	Else DATEDIFF(DAY, IsNULL(PaidDate,x.[ServiceDateTo]), GETDATE()) - 365
	End as DaysLeft	
	
	, IIF(ISNULL(x.[OP_Default] 						,0) > 0,      	'OP_Default - '						+ Cast(x.[OP_Default] 					as varchar) + ', ','')
	+IIF(ISNULL(x.[Fee_Schedule] 					,0) > 0,      	'Fee_Schedule - '					+ Cast(x.[Fee_Schedule] 				as varchar) + ', ','')
	+IIF(ISNULL(x.[ER] 								,0) > 0,      	'ER - '								+ Cast(x.[ER] 							as varchar) + ', ','')	
	+IIF(ISNULL(x.[AS]  							,0) > 0,      	'AS - '	 							+ Cast(x.[AS]  							as varchar) + ', ','')
	+IIF(ISNULL(x.[Cardiac_Cath] 					,0) > 0,      	'Cardiac_Cath - '	 				+ Cast(x.[Cardiac_Cath] 				as varchar) + ', ','')
	+IIF(ISNULL(x.[PTCA] 							,0) > 0,      	'PTCA - '							+ Cast(x.[PTCA] 						as varchar) + ', ','')
	+IIF(ISNULL(x.[PTCA_Cardiac_Cath] 				,0) > 0,      	'PTCA_Cardiac_Cath - '	 			+ Cast(x.[PTCA_Cardiac_Cath] 			as varchar) + ', ','')	
	+IIF(ISNULL(x.[PTCA_Cardiac_Cath_Qualifier] 	,0) > 0,      	'PTCA_Cardiac_Cath_Qualifier - '	+ Cast(x.[PTCA_Cardiac_Cath_Qualifier] 	as varchar) + ', ','')
	+IIF(ISNULL(x.[EPS] 							,0) > 0,      	'EPS - '							+ Cast(x.[EPS] 							as varchar) + ', ','')	
	+IIF(ISNULL(x.[Gamma_Knife] 					,0) > 0,      	'Gamma_Knife - '	 				+ Cast(x.[Gamma_Knife] 					as varchar) + ', ','')
	+IIF(ISNULL(x.[Hip_Replacement] 				,0) > 0,      	'Hip_Replacement - '	 			+ Cast(x.[Hip_Replacement] 				as varchar) + ', ','')
	+IIF(ISNULL(x.[Knee_Replacement] 				,0) > 0,      	'Knee_Replacement - '	 			+ Cast(x.[Knee_Replacement] 			as varchar) + ', ','')
	+IIF(ISNULL(x.[Shoulder_Replacement] 			,0) > 0,      	'Shoulder_Replacement - '	 		+ Cast(x.[Shoulder_Replacement] 		as varchar) + ', ','')	
	+IIF(ISNULL(x.[Drugs] 							,0) > 0,      	'Drugs - '							+ Cast(x.[Drugs] 						as varchar) + ', ','')	
	+IIF(ISNULL(x.[Blood] 							,0) > 0,      	'Blood - '	 						+ Cast(x.[Blood] 						as varchar) + ', ','')	
	+IIF(ISNULL(x.[Implants] 						,0) > 0,      	'Implants - '	 					+ Cast(x.[Implants] 					as varchar) + ', ','')
	+IIF(ISNULL(x.[Sleep_Studies] 					,0) > 0,      	'Sleep_Studies - '	 				+ Cast(x.[Sleep_Studies] 				as varchar) + ', ','')
	+IIF(ISNULL(x.[PT/OT/ST] 						,0) > 0,      	'PT/OT/ST - '	 					+ Cast(x.[PT/OT/ST] 					as varchar) + ', ','')
	+IIF(ISNULL(x.[COVID]							,0) > 0,      	'COVID - '							+ Cast(x.[COVID]						as varchar) + ', ','')
	
	
	as ExpectedDetailed	



--	,x.[Drugs]	
--	,x.[Blood]
--	,x.[Implants]
--	,x.[Gamma_Knife]	
--	,x.[Shoulder_Replacement]	
--	,x.[Hip_Replacement]
--	,x.[Knee_Replacement]
--	,x.[PTCA]	
--	,x.[PTCA_Cardiac_Cath]
--	,x.[PTCA_Cardiac_Cath_Qualifier]
--	,x.[Cardiac_Cath]			
--	,x.[EPS]					
--	,x.[AS]					
--	,x.[Sleep_Studies]		
--	,x.[ER]		
--	,x.[PT/OT/ST]
--	,x.[Fee_Schedule]			
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
    , 'NYP_COL_1199_OP_COM'
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
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_1199_OP_COM';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- --EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;