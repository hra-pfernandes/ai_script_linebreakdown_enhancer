	--created by Silvana Chain  2.18.2026
	
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
	IF OBJECT_ID('tempdb..#StepFINal') IS NOT NULL DROP TABLE #StepFINal

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

  	AND Payer01Name IN ('UHC CHP','Chp Uhc Comm Plan By United')

	AND p.[audit_by] IS NULL AND p.[audit_date] IS NULL AND p.[employee_type] = 'Analyst'

	and x.servicedatefrom < '2026-01-01'

	Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.*
	
	,IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric	

	INTO #Step1_Charges
	FROM [COL].[Data].[Charges] as x
	
	where x.[EncounterID] IN (Select [EncounterID] from #Step1)

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]


	,[OP_Default] = Round(BillCharges * 0.85 ,0)


	Into #Step2
	From #Step1_Charges as x
	
	
	LEFT JOIN [COL].[Data].[Demo] 															as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px] 															as dp on x.[EncounterID] = dp.[EncounterID] AND x.[Sequence] = dp.[Sequence]		

	ORDER BY [EncounterID], x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
     Select [EncounterID], [ServiceDate], [RevenueCode], [ProcedureCode], [Amount], [OriginalPayment]
	,[OP_Default]	
	INto #Step3
	From #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID], [ServiceDate]

	,MAX([OP_Default])				as [OP_Default]

	INTO #Step3_1
	FROM #Step3
	
	GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID]
	,MAX([OP_Default])			as [OP_Default]

	INTO #Step3_2
	FROM #Step3_1
	
	GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID]
	
	,[OP_Default]			

	INTO #Step4
	FROM #Step3_2

--======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- PURPOSE : Produce a LINE-LEVEL price breakdown for auditor review.
--           One row per charge line (EncounterID + ServiceDate + ProcedureCode).
-- SOURCE  : #Step3 (line-level, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
-- MAX CATEGORIES (only the highest-value line per encounter pays):
--   NONE — this contract has only one category.
-- SUM CATEGORIES (all matching lines pay):
--   OP_Default
-- WINDOW_REDUCTION CATEGORIES:
--   NONE
-- SUPPRESSION HIERARCHY (tier 1 = highest priority, from #Step4):
--   1. OP_Default (only category; no suppression tiers apply)
-- NOTE: #Step3 does not carry Sequence, Modifier1, BillCharges, or Quantity
--       through its explicit SELECT list. NULL placeholders are used for absent
--       columns. OP_Default is the only pricing category present.
-- NOTE: No NCCI bundle step exists in this script. BundledByNCCI = 0 hardcoded.
--======================================================================

-- BLOCK 1: #bRanked
-- OP_Default is a SUM category (MAX per ServiceDate in #Step3_1, then MAX
-- per EncounterID in #Step3_2). There are no MAX categories requiring
-- ROW_NUMBER ranking for winner selection, and no WINDOW_REDUCTION categories.
-- We still build #bRanked from #Step3 (the line-level source) so that one row
-- per charge line is preserved for the breakdown. A single ROW_NUMBER is added
-- as a structural placeholder; it is not used in LinePayment logic.
SELECT
    [EncounterID]
    , CAST(NULL AS INT)              AS [Sequence]
    , [ProcedureCode]
    , [RevenueCode]
    , [ServiceDate]
    , [Amount]
    , [OriginalPayment]
    , [OP_Default]
    , ROW_NUMBER() OVER (
        PARTITION BY [EncounterID]
        ORDER BY [OP_Default] DESC, [Amount] DESC
      ) AS rn_OP_Default
INTO #bRanked
FROM #Step3;

-- BLOCK 2: #bSlots
-- OMITTED: has_window_reduction = false. No slot pivot table required.

-- BLOCK 3: #LineBreakdown
-- Main line-level breakdown. One row per charge line (EncounterID + row from #Step3).
-- ServiceCategory reflects the final hierarchy decision from #Step4.
-- LinePayment is the contractual dollar amount for this line.
-- BundledByNCCI = 0 hardcoded (no NCCI bundle step in this script).
--
-- COLUMN SURVIVAL NOTES:
--   #Step3 explicit SELECT list: EncounterID, ServiceDate, RevenueCode,
--   ProcedureCode, Amount, OriginalPayment, OP_Default.
--   Sequence is NOT present in #Step3 — NULL placeholder used.
--   Quantity is NOT present in #Step3 — NULL placeholder used.
--   BillCharges is NOT present in #Step3 — BilledAmount uses Amount.
--   NeedsCorrectedClaim does NOT exist — BundledByNCCI hardcoded to 0.
--
-- CONTRACT PERIOD:
--   OP_Default = BillCharges * 0.85 (from #Step2). No date banding —
--   single flat percentage applies across the full contract span.
--   ContractYearFrom/To reflect the script's only date boundary: < 2026-01-01.
--   Because no explicit date ranges are defined in the pricing logic,
--   ContractYearFrom and ContractYearTo are set to the script's
--   effective period boundaries (open start → 2025-12-31).
SELECT DISTINCT
    b.[EncounterID]
    , b.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                            AS [BilledAmount]
    , CAST(NULL AS NUMERIC(18,4))           AS [Quantity]

    -- Contract period: single open-ended period (no date banding in pricing logic)
    , [ContractYearFrom] = CASE
        WHEN b.[ServiceDate] <= '2025-12-31'
            THEN CAST(NULL AS DATE)   -- No explicit contract start date in script
        ELSE NULL
      END

    , [ContractYearTo] = CASE
        WHEN b.[ServiceDate] <= '2025-12-31'
            THEN CAST('2025-12-31' AS DATE)
        ELSE NULL
      END

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Only one pricing category exists: OP_Default (SUM).
    -- All lines in this contract price at 85% of BillCharges.
    -- If s4.[OP_Default] != 0, the category survived (no suppression tiers
    -- exist to override it). If the line's own OP_Default > 0, it pays.
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- OP_Default (SUM — all matching lines pay)
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- Suppressed: line had a category value but hierarchy zeroed it.
        -- (In this script there are no suppression tiers above OP_Default,
        --  so this branch is reached only if s4.[OP_Default] = 0 for the
        --  encounter yet the line has a value — effectively no payment.)
        WHEN ISNULL(b.[OP_Default], 0) > 0
            THEN 'Suppressed_By_Hierarchy'

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula for this line.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'Pct of charges: BillCharges x 85% — OP Default (UHC CHP outpatient contract)'

        WHEN ISNULL(b.[OP_Default], 0) > 0
            THEN 'Category suppressed by encounter hierarchy — $0'

        ELSE 'No pricing pattern matched — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- OP_Default is a SUM category: all matching lines pay their own
    -- computed OP_Default value from the line-level source.
    -- (OP_Default was already computed as Round(BillCharges * 0.85, 0)
    --  in #Step2 at the line level and flows through unchanged into #Step3.)
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          IIF(s4.[OP_Default] != 0, ISNULL(b.[OP_Default], 0), 0)
      , 2)

    -- No NCCI bundle step exists in this script.
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4 s4 ON s4.[EncounterID] = b.[EncounterID]
ORDER BY b.[EncounterID], b.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select *
	,[OP_Default]		
	as Price

	INTO #Step5
	FROM #Step4

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select 
	 x.*

	,y.[Price]
	,y.[OP_Default]	

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
	
	INto #Step6
	From [COL].[Data].[Demo] as x
	
	INner joIN #Step5 as y on x.[EncounterID] = y.[EncounterID]
	left joIN [COL].[Data].[Charges_With_CPT] as z on x.[EncounterID] = z.[EncounterID]	
	
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
	,x.[PaidDate]	
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
	,Round((cast(x.[OriginalPayment] as float)/NULLIF([BillCharges], 0)) * 100, 2) as [% paid]
	,DATEDIFF(DAY, x.[ServiceDateFrom], GETDATE()) - 365 as DaysLeft
	
	,IIF(ISNULL(x.[OP_Default]			,0) > 0,      '85% of Charges - '			+ Cast(x.[OP_Default]			as varchar) + ', ','')
	as ExpectedDetailed


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
			'Seq:'  + CAST(lb.[Sequence]      AS VARCHAR(MAX)) +
			' CPT:' + ISNULL(CAST(lb.[ProcedureCode] AS VARCHAR(MAX)), '') +
			' Rev:' + ISNULL(CAST(lb.[RevenueCode]   AS VARCHAR(MAX)), '') +
			' | Cat:'     + CAST(lb.[ServiceCategory]  AS VARCHAR(MAX)) +
			' | Billed:$' + CAST(CONVERT(DECIMAL(12,2), ISNULL(lb.[BilledAmount], 0)) AS VARCHAR(MAX)) +
			' | Paid:$'   + CAST(CONVERT(DECIMAL(12,2), ISNULL(lb.[LinePayment],   0)) AS VARCHAR(MAX)) +
			CASE WHEN lb.[BundledByNCCI] = 1 THEN ' [NCCI-BUNDLED]' ELSE '' END
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

  ,[Status] = CASE
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
	Select * FROM #StepFinal
	Order by Round(Diff, 2) desc

	Select [Status], count(*)
	From #StepFinal
	Group by [Status]
	order by count(*) desc

--======================================================================
-- *** [AUDITOR PRICE BREAKDOWN SUMMARY QUERIES - INSERTED SECTION] ***
-- Run after the main script completes.
-- #LineBreakdown = one row per charge line (EncounterID + row from #Step3).
-- ServiceCategory = final hierarchy decision (from #Step4 suppression logic).
-- 'Suppressed_By_Hierarchy' = line matched a category but a higher-tier
--   category won for this encounter.
-- 'No_Payment_Category' = line did not match any pricing pattern.
-- BundledByNCCI = 1 means this line was zeroed by NCCI bundling.
--   (This script has no NCCI bundle step; BundledByNCCI is always 0.)
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
     BilledAmount, Quantity, ServiceCategory, PricingMethod,
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
    , 'NYP_COL_UHC_CHP_OP'
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
    , p.[Price]                                 AS EncounterLevel_Price
    , (r.[LineBreakdown_Total] - p.[Price])      AS Discrepancy
FROM #recon_temp r
INNER JOIN #Step5 p ON r.[EncounterID] = p.[EncounterID]
WHERE ABS(r.[LineBreakdown_Total] - p.[Price]) > 1.00
ORDER BY ABS(r.[LineBreakdown_Total] - p.[Price]) DESC;

