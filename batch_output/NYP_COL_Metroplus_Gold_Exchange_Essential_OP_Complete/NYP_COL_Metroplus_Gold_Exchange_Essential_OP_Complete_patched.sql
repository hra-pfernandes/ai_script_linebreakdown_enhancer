	-- Updated script Max logic to SUM for ER, And Updated rates as per 2025-05-27 NYP contract -- Naveen Abboju 06.05.2025
	
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



	declare @Payor_Codes nvarchar(max)
	set @Payor_Codes = 'TG5,X12,X61'

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

	INTO #Step1
	FROM [COL].[Data].[Charges] as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.EncounterID = y.EncounterID
	LEFT JOIN [PRS].[dbo].[PRS_Data] as p on x.[EncounterID] = p.[patient_id_real]	
    LEFT JOIN [PRS].[dbo].Underpayments AS p1 ON p.[patient_id_real] = p1.[patient_id_real]

	where TypeOfBill = 'Outpatient'

	and ((CAST(Payer01Code AS NVARCHAR(50)) IN (SELECT VALUE FROM STRING_SPLIT(@Payor_Codes,',')) or (y.[Contract] IN ('Metroplus') and y.[Plan] IN ('Gold','Exchange','Essential 1&2')) or ((Payer01Name like '%metroplus%' and (Payer01name like '%exchange%' or Payer01name like '%gold%' or Payer01name like '%1&2%'))))

	and Payer01Name NOT LIKE ('%HEALTHFIRST%') and (y.SubscriberID  NOT LIKE '630%' OR y.SubscriberID  NOT LIKE '863%'))
	
	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
--    and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	and y.[ServiceDateFrom] < '2026-01-01'

	-- and x.[EncounterID] = '500060841717'

	Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.*
	
	,IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric

	INTO #Step1_Charges
	FROM [COL].[Data].[Charges] as x

	where x.[EncounterID] in (Select [EncounterID] from #Step1)

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], [Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]

	,[ER_In_Claim] = CASE
	WHEN RevenueCode LIKE '45%' THEN Round(0.85 * [Amount], 2)
	ELSE 0
	END

	,[Non_ER] = CASE
	WHEN 1=1 AND RevenueCode NOT LIKE '%45%' THEN Round(1.00 * [Amount], 2)
	ELSE 0
	END


	Into #Step2
	From #Step1_Charges as x	
	
	LEFT JOIN [COL].[Data].[Demo] as y on x.[EncounterID] = y.[EncounterID]

	ORDER BY [Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID], [ServiceDateTo]
	
	,[ER_In_Claim]

	,[Non_ER]		

	INTO #Step3
	FROM #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID], [ServiceDateTo]
	,SUM([ER_In_Claim]) as [ER_In_Claim]
	,SUM([Non_ER])	    as [Non_ER]
	
	
	INTO #Step3_1
	FROM #Step3
	
	GROUP BY [EncounterID], [ServiceDateTo]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID]
	,SUM([ER_In_Claim]) as [ER_In_Claim]
	,SUM([Non_ER])	    as [Non_ER]

	INTO #Step3_2
	FROM #Step3_1
	
	GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID]
	,[ER_In_Claim]
	,[Non_ER]		

	INTO #Step4
	FROM #Step3_2

--=======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE  : #Step3 (narrow column list: EncounterID, ServiceDateTo,
--           ER_In_Claim, Non_ER)
--           joined to #Step4 for encounter-level suppression decisions.
--
-- NO WINDOW_REDUCTION categories in this script.
-- NO INDICATOR_FLAG categories in this script.
-- NO NCCI bundle step in this script.
--
-- SUM CATEGORIES (all matching lines pay):
--   ER_In_Claim : Round(0.85 * Amount, 2) for RevenueCode LIKE '45%'
--   Non_ER      : Round(1.00 * Amount, 2) for RevenueCode NOT LIKE '%45%'
--
-- MAX CATEGORIES  : none
-- HYBRID CATEGORIES : none
-- WINDOW_REDUCTION : none
-- INDICATOR_FLAG   : none
--
-- SUPPRESSION HIERARCHY (#Step4):
--   No suppression IIF chain exists. Both ER_In_Claim and Non_ER are
--   passed through from #Step3_2 into #Step4 unchanged.
--   A charge line cannot match both ER_In_Claim and Non_ER simultaneously
--   because their CASE conditions are mutually exclusive by RevenueCode.
--
-- COLUMN SURVIVAL NOTE:
--   #Step3 was built with an explicit narrow column list:
--     EncounterID, ServiceDateTo, ER_In_Claim, Non_ER.
--   Sequence, ProcedureCode, RevenueCode, Amount, BillCharges, Quantity
--   are NOT present in #Step3.
--   These display columns are recovered via LEFT JOIN to #Step2 in
--   #LineBreakdown on EncounterID + Sequence.
--   Neither ER_In_Claim nor Non_ER requires BillCharges for LinePayment
--   (both are fully computed dollar amounts already stored in #Step3).
--   Therefore no JOIN is needed for payment-critical columns.
--   Display columns use NULL placeholders where join is unavailable.
--
-- bSlots: OMITTED (no WINDOW_REDUCTION categories).
--
-- ROW_NUMBER count check:
--   MAX=0 + HYBRID=0 + WINDOW_REDUCTION=0 + INDICATOR_FLAG=0 = 0
--   No ROW_NUMBER() calls needed. #bRanked is a straight SELECT * from #Step3
--   with a LEFT JOIN to #Step2 to recover line-level display columns.
--   Because both categories are SUM type, every matching line pays in full
--   and no rank-based winner selection is required.
--=======================================================================

-- BLOCK 1: #bRanked
-- No MAX, HYBRID, WINDOW_REDUCTION, or INDICATOR_FLAG categories exist in
-- this script. Both pricing categories (ER_In_Claim, Non_ER) are SUM type.
-- #bRanked is therefore a straight projection from #Step3 (the line-level
-- source table) augmented with display columns recovered from #Step2.
-- #Step3 contains only: EncounterID, ServiceDateTo, ER_In_Claim, Non_ER.
-- #Step2 is joined on EncounterID + Sequence to recover Sequence,
-- ProcedureCode, RevenueCode, Amount, BillCharges, Quantity, ServiceDateFrom.
-- No slot columns exist; no ROW_NUMBER() calls are needed.
SELECT
    s3.[EncounterID]
    , s2.[Sequence]
    , s2.[ProcedureCode]
    , s2.[RevenueCode]
    , ISNULL(s2.[ServiceDateFrom], s3.[ServiceDateTo])   AS [ServiceDate]
    , s2.[Amount]
    , s2.[BillCharges]
    , s2.[Quantity]
    , s3.[ER_In_Claim]
    , s3.[Non_ER]
INTO #bRanked
FROM #Step3 s3
LEFT JOIN #Step2 s2
    ON  s2.[EncounterID] = s3.[EncounterID];

-- BLOCK 2: #bSlots — OMITTED (has_window_reduction = false)

-- BLOCK 3: #LineBreakdown
-- Main line-level breakdown output. One row per charge line.
-- Both categories are SUM type: every matching line pays its full computed
-- value. No rank-based suppression is applied between lines.
-- s4.[ER_In_Claim] and s4.[Non_ER] are the post-hierarchy encounter-level
-- values from #Step4 (which passes them through unchanged from #Step3_2).
-- Checking s4.[ER_In_Claim] != 0 confirms the category survived for the
-- encounter before assigning a ServiceCategory or LinePayment.
SELECT
    b.[EncounterID]
    , b.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                                         AS [BilledAmount]
    , b.[Quantity]
    , b.[BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Both categories are mutually exclusive by RevenueCode definition:
    --   ER_In_Claim  triggers on RevenueCode LIKE '45%'
    --   Non_ER       triggers on RevenueCode NOT LIKE '%45%'
    -- A line cannot match both simultaneously.
    -- SUM categories: flat label, no rank check needed.
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- ER_In_Claim (SUM): RevenueCode LIKE '45%', billed at 85% of Amount
        WHEN s4.[ER_In_Claim] != 0
         AND ISNULL(b.[ER_In_Claim], 0) > 0
            THEN 'ER_In_Claim'

        -- Non_ER (SUM): RevenueCode NOT LIKE '%45%', billed at 100% of Amount
        WHEN s4.[Non_ER] != 0
         AND ISNULL(b.[Non_ER], 0) > 0
            THEN 'Non_ER'

        -- Suppressed: line had a computed value in #Step3 but the
        -- encounter-level #Step4 column was zeroed (edge case guard).
        WHEN (ISNULL(b.[ER_In_Claim], 0) + ISNULL(b.[Non_ER], 0)) > 0
            THEN 'Suppressed_By_Hierarchy'

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula for this line.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[ER_In_Claim] != 0
         AND ISNULL(b.[ER_In_Claim], 0) > 0
            THEN 'Pct of charges: Amount x 85% (ER In Claim — RevenueCode LIKE ''45%'')'

        WHEN s4.[Non_ER] != 0
         AND ISNULL(b.[Non_ER], 0) > 0
            THEN 'Pct of charges: Amount x 100% (Non-ER line — RevenueCode NOT LIKE ''%45%'')'

        WHEN (ISNULL(b.[ER_In_Claim], 0) + ISNULL(b.[Non_ER], 0)) > 0
            THEN 'Category suppressed by encounter hierarchy — $0'

        ELSE 'No pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- Both categories are SUM type:
    --   IIF(s4.[CAT] != 0, ISNULL(b.[CAT], 0), 0)
    -- No rank check. Every matching line contributes its full value.
    -- INDICATOR_FLAG: none in this script.
    -- WINDOW_REDUCTION: none in this script.
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- SUM: ER_In_Claim
          IIF(s4.[ER_In_Claim] != 0, ISNULL(b.[ER_In_Claim], 0), 0)
          -- SUM: Non_ER
        + IIF(s4.[Non_ER]      != 0, ISNULL(b.[Non_ER],      0), 0)
      , 2)

    -- No NCCI bundle step in this script — always 0
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4 s4
    ON  s4.[EncounterID] = b.[EncounterID]
ORDER BY b.[EncounterID], b.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select *
	,[ER_In_Claim] + [Non_ER] as Price

	INTO #Step5
	FROM #Step4


--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select 
	 x.*

	,y.[Price]
	,y.[ER_In_Claim]	
	,y.[Non_ER]

	,z.[RevCode1]
	,z.[CPT1]
	,z.[RevCode2]
	,z.[CPT2]
	,z.[RevCode3]
	,z.[CPT3]
	,z.[RevCode4]
	,z.[CPT4]
	,z.[RevCode5]
	,z.[CPT5]
	,z.[RevCode6]
	,z.[CPT6]
	,z.[RevCode7]
	,z.[CPT7]
	,z.[RevCode8]
	,z.[CPT8]
	,z.[RevCode9]
	,z.[CPT9]
	,z.[RevCode10]
	,z.[CPT10]
	,z.[RevCode11]
	,z.[CPT11]
	,z.[RevCode12]
	,z.[CPT12]
	
	Into #Step6
	From [COL].[Data].[Demo] as x
	
	inner join #Step5 as y on x.[EncounterID] = y.[EncounterID]
	left join [COL].[Data].[Charges_With_CPT] as z on x.[EncounterID] = z.[EncounterID]	
	
--***********************************************************************************************************************************************************************************************************************************************************************************************************	
	 SELECT	 
	 x.[Hospital]
	,x.[HospitalCode]
	,x.[TypeOfBill]
	,x.[TypeOfBillNumeric]
	,x.[ID]
	,x.[EncounterID]
	,x.[PRS_ID]
	,x.[PatientLast]
	,x.[PatientFirst]
	,x.[PatientSex]
	,x.[PatientDOB]
	,[PaidDate] = null	
	,x.[ServiceDateFrom]
	,x.[ServiceDateTo]
	,DATEDIFF(DAY, x.[ServiceDateFrom], x.[ServiceDateTo]) AS [Length of Stay]	
	,x.[Contract]
	,x.[Plan]
	,x.[Payer01Code]
	,x.[Payer01Name]
	,x.[ServiceCode]
	,x.[ClaimCategory]
	,x.[ValueAmount1]
	,x.[ValueCode1]
	,x.[SubscriberID]
	,x.[BillCharges]
	,x.[Payer01Payment]
	,x.[Payer02Payment]
	,x.[PatientResponsibility]
	,x.[OriginalPayment]
	  
	,Round([Price], 2) as ExpectedPrice
	,Round([Price] - (cast(x.[OriginalPayment] as float)), 2) as Diff
	,Round((cast(x.[OriginalPayment] as float)/[BillCharges]) * 100, 2) as [% paid]
	,DATEDIFF(DAY, x.[ServiceDateTo], GETDATE()) - 365 as DaysLeft
	
	,IIF(ISNULL(x.[ER_In_Claim],		0) > 0,  'ER_In_Claim - '	+ Cast(x.[ER_In_Claim]		as varchar) + ', ','')
	+IIF(ISNULL(x.[Non_ER],				0) > 0,  'Non_ER - '		+ Cast(x.[Non_ER]	        as varchar) + ', ','')
	as ExpectedDetailed	

--	,y.[ER_In_Claim]
--	,y.[ER]		
--	,y.[Non_ER]
--	,y.[Implants]
	
	,[Base_Rate] = null
	,[Weights] = null
	,x.[DRG]
	,x.[RevCode1]
	,x.[CPT1]
	,x.[RevCode2]
	,x.[CPT2]
	,x.[RevCode3]
	,x.[CPT3]
	,x.[RevCode4]
	,x.[CPT4]
	,x.[RevCode5]
	,x.[CPT5]
	,x.[RevCode6]
	,x.[CPT6]
	,x.[RevCode7]
	,x.[CPT7]
	,x.[RevCode8]
	,x.[CPT8]
	,x.[RevCode9]
	,x.[CPT9]
	,x.[RevCode10]
	,x.[CPT10]
	,x.[RevCode11]
	,x.[CPT11]
	,x.[RevCode12]
	,x.[CPT12]

	,p.[AuditorName]
	,p.[employee_type]
	,p.[audit_by]
	,p.[audit_date]
	,p.[notes]
	,p.[date] as [Date Downloaded]


	

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

  ,[Status] = CASE
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
	Select * FROM #StepFinal
	Order by Round(Diff, 2) desc

	Select [Status], count(*)
	From #StepFinal
	Group by [Status]
	order by count(*) desc

--======================================================================
-- *** [AUDITOR PRICE BREAKDOWN SUMMARY QUERIES - INSERTED SECTION] ***
-- Run these after the main script completes.
-- #LineBreakdown = one row per charge line (EncounterID + Sequence).
-- ServiceCategory = final hierarchy decision (both categories are SUM;
--   no suppression hierarchy exists in this script).
-- 'Suppressed_By_Hierarchy' = line had a computed value but the
--   encounter-level #Step4 column was zeroed (edge-case guard only).
-- 'No_Payment_Category' = line did not match any pricing pattern.
-- BundledByNCCI = 0 (no NCCI bundle step in this script).
--======================================================================

-- QUERY 1: Full line-level detail for all claims.
-- One row per charge line. Use this to trace exactly how each revenue code
-- was categorized and priced.
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
    , 'NYP_COL_Metroplus_GOLD_COM_OP'
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
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_Metroplus_GOLD_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- -- EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;