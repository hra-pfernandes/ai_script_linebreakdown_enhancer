-- Script Created by SC 4.1.2025
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

	AND Payer01Code IN ('T63')

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'
	--    and (p.account_status = 'HAA' and p1.close_date is null and p1.status not in ('Write Off Requested', 'Payor said paid'))

	--and y.[AGE] < 65

	and y.[ServiceDateFrom] < '2026-01-01'

Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.*
	
	, IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric


INTO #Step1_Charges
FROM [COL].[Data].[Charges] as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.EncounterID = y.EncounterID

where x.[EncounterID] in (Select [EncounterID]
from #Step1)

ORDER BY [Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], [Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]

	, [OP_Default] = CASE
	WHEN 1=1 THEN ROUND(BillCharges * 0.72, 2)
	ELSE 0
	END


Into #Step2
From #Step1_Charges as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.[EncounterID] = y.[EncounterID]

ORDER BY [Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]	
	, [OP_Default]

INTO #Step3
FROM #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID], [ServiceDate]
	, MAX([OP_Default])	as [OP_Default]

INTO #Step3_1
FROM #Step3

GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, MAX([OP_Default])	as [OP_Default]

INTO #Step3_2
FROM #Step3_1

GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select [EncounterID]
	, [OP_Default]


INTO #Step4
FROM #Step3_2

--======================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- PURPOSE : Produce a LINE-LEVEL price breakdown for auditor review.
--           One row per charge line (EncounterID + Sequence + ProcedureCode).
-- SOURCE  : #Step2 (line-level pricing table, pre-hierarchy)
--           joined to #Step4 for encounter-level suppression decisions.
--
-- COLUMN SURVIVAL TRACE:
--   #Step4 <- #Step3_2 (SELECT [EncounterID], [OP_Default])
--          <- #Step3_1 (SELECT [EncounterID], [ServiceDate], MAX([OP_Default]))
--          <- #Step3   (SELECT [EncounterID], [ServiceDate], [OP_Default])
--          <- #Step2   (explicit column list confirmed below)
--   #Step2 explicit columns confirmed:
--     EncounterID, RevenueCode, ProcedureCode, ProcedureCodeNumeric,
--     Modifier1, Sequence, ServiceDateFrom, ServiceDateTo, ServiceDate,
--     OriginalPayment, Amount, BillCharges, Quantity, Plan,
--     Payer01Code, Payer01Name, OP_Default
--
-- MAX CATEGORIES  (only the highest-value line per encounter pays): none
-- SUM CATEGORIES  (all matching lines pay): OP_Default
-- WINDOW_REDUCTION CATEGORIES: none
-- SUPPRESSION HIERARCHY: single category, no suppression tiers
--   1. OP_Default (only category; catch-all = BillCharges x 72%)
--
-- NOTE: This script has a single pricing category (OP_Default).
--   No NCCI bundle step exists — BundledByNCCI is hardcoded to 0.
--   No WINDOW_REDUCTION categories exist — #bSlots is omitted.
--   Quantity IS confirmed present in #Step2 and is carried through.
--======================================================================

-- BLOCK 1: #bRanked
-- No MAX categories exist in this script (OP_Default is SUM).
-- ROW_NUMBER is included as a structural placeholder; it is not used
-- to filter winners since OP_Default is a SUM category.
SELECT *
    , ROW_NUMBER() OVER (PARTITION BY [EncounterID] ORDER BY [OP_Default] DESC, [Amount] DESC, [Sequence] ASC) AS rn_OP_Default
INTO #bRanked
FROM #Step2;

-- BLOCK 2: #bSlots
-- OMITTED — no WINDOW_REDUCTION categories exist in this script.

-- BLOCK 3: #LineBreakdown
-- One row per charge line.
-- ServiceCategory: only OP_Default exists; all lines with OP_Default > 0
--   and s4.[OP_Default] != 0 are categorized as OP_Default.
-- LinePayment: SUM category — every matching line pays its own value.
-- BundledByNCCI: hardcoded 0 — no NCCI bundle step in this script.
-- Quantity: confirmed present in #Step2, carried through directly.
SELECT DISTINCT
    b.[EncounterID]
    , b.[Sequence]
    , b.[ProcedureCode]
    , b.[RevenueCode]
    , b.[ServiceDate]
    , b.[Amount]                        AS [BilledAmount]
    , b.[Quantity]

    -- Contract period boundaries from LINE_PRICING step in #Step2.
    -- Only one date range exists: open-ended (no upper date boundary in WHEN 1=1).
    -- ServiceDate is used as the reference date (ISNULL(x.ServiceDateFrom, y.ServiceDateTo)).
    -- Since the single WHEN clause is WHEN 1=1 with no date band, all lines
    -- fall into a single unbounded period. ContractYearFrom/To reflect this.
    , [ContractYearFrom] = CAST(NULL AS DATE)
    , [ContractYearTo]   = CAST(NULL AS DATE)

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Single category: OP_Default (SUM, catch-all BillCharges x 72%).
    -- s4.[OP_Default] != 0 confirms the category survived at encounter level.
    -- b.[OP_Default] > 0 confirms this line matched the pricing pattern.
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- OP_Default: SUM category, last (and only) named category
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- Suppressed: line matched the pattern but encounter-level #Step4
        -- zeroed the category (should not occur with single-category script
        -- but retained for correctness)
        WHEN ISNULL(b.[OP_Default], 0) > 0
            THEN 'Suppressed_By_Hierarchy'

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'Pct of charges: BillCharges x 72.0% — OP Default catch-all (single-category contract; rate = ROUND(BillCharges * 0.72, 2))'

        WHEN ISNULL(b.[OP_Default], 0) > 0
            THEN 'Category suppressed by encounter hierarchy — $0'

        ELSE 'No pricing pattern matched for this line — $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- OP_Default is a SUM category: every line pays its own value
    -- when the category survived in #Step4.
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          IIF(s4.[OP_Default] != 0, ISNULL(b.[OP_Default], 0), 0)
      , 2)

    -- No NCCI bundle step in this script — hardcoded to 0.
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4 s4 ON s4.[EncounterID] = b.[EncounterID]
ORDER BY b.[EncounterID], b.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select *
	, [OP_Default] as Price

INTO #Step5
FROM #Step4

--***********************************************************************************************************************************************************************************************************************************************************************************************************
Select
	x.*

	, y.[Price]
	, y.[OP_Default]

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
	, [PaidDate] = null	
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
	
	, IIF(ISNULL(x.[OP_Default]	, 0) > 0,   'OP_Default - '		+ Cast(x.[OP_Default]	as varchar) + ', ','')
	as ExpectedDetailed

--	,x.[OP_Default]

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
			' | Paid:$'   + CAST(CONVERT(DECIMAL(12,2), ISNULL(lb.[LinePayment],   0)) AS VARCHAR(MAX)) +
			CASE WHEN lb.[BundledByNCCI] = 1 THEN ' [NCCI-BUNDLED]' ELSE '' END
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
    WHEN([% paid] LIKE ('72%')) THEN 'Paid Correctly'
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
-- Run after the main script completes.
-- #LineBreakdown = one row per charge line (EncounterID + Sequence + ProcedureCode).
-- ServiceCategory = final hierarchy decision (from #Step4 suppression logic).
-- 'Suppressed_By_Hierarchy' = line matched a category but a higher-tier
--   category won for this encounter.
-- 'No_Payment_Category' = line did not match any pricing pattern.
-- BundledByNCCI = 1 means this line was zeroed by NCCI bundling.
--======================================================================

-- QUERY 1: Full line-level detail for all claims.
SELECT
    lb.[EncounterID]
    , lb.[Sequence]
    , lb.[ProcedureCode]
    , lb.[RevenueCode]
    , lb.[ServiceDate]
    , lb.[BilledAmount]
    , lb.[Quantity]
    , lb.[ContractYearFrom]
    , lb.[ContractYearTo]
    , lb.[ServiceCategory]
    , lb.[PricingMethod]
    , lb.[LinePayment]       AS [ContractualPayment_Line]
    , lb.[BundledByNCCI]     AS [ZeroedByNCCI_Flag]
FROM #LineBreakdown lb
ORDER BY lb.[EncounterID], lb.[Sequence];

-- INSERT results into persistent table for cross-run analysis.
INSERT INTO [Automation].[dbo].[LineBreakdown_Results]
    (EncounterID, Sequence, ProcedureCode, RevenueCode, ServiceDate,
     BilledAmount, Quantity, ContractYearFrom, ContractYearTo,
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
    , lb.[ContractYearFrom]
    , lb.[ContractYearTo]
    , lb.[ServiceCategory]
    , lb.[PricingMethod]
    , lb.[LinePayment]
    , lb.[BundledByNCCI]
    , 'NYP_COL_T63_OP'
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
    , p.[Price]                                  AS EncounterLevel_Price
    , (r.[LineBreakdown_Total] - p.[Price])       AS Discrepancy
FROM #recon_temp r
INNER JOIN #Step5 p ON r.[EncounterID] = p.[EncounterID]
WHERE ABS(r.[LineBreakdown_Total] - p.[Price]) > 1.00
ORDER BY ABS(r.[LineBreakdown_Total] - p.[Price]) DESC;

