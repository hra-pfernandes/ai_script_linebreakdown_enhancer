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
	set @Payor_Codes = 'H73'

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

	INTO #Step1
	FROM [COL].[Data].[Charges] as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.EncounterID = y.EncounterID
	LEFT JOIN [PRS].[dbo].[PRS_Data] as p on x.[EncounterID] = p.[patient_id_real]	

	where TypeOfBill = 'Outpatient'

	and ((Payer01Name like '%Magna%') or Payer01Name IN ('AMALGAMATED LIFE INS','CAREPOINT HEALTH','CROSSROADS HEALTHCARE','INDEPENDENT CARE PLUS','PENSION HOSPITALIZATION BENEFIT') or (y.[Contract] IN ('Magncare','Magnahealth') and (y.[Plan] IN ('COM','HMO','HMO/PPO','PPO'))))

	and p.[hospital] = 'NYP Columbia' and p.[audit_by] is null and p.[audit_date] is null and p.[employee_type] = 'Analyst'

    --and y.[AGE] < 65

	and y.[ServiceDateFrom] < '2026-01-01'

--	and x.[EncounterID] IN ('V00049368095')
	
	Group by x.[EncounterID], [TypeOfBill], [RevenueCode], [ProcedureCode], [Payer01Name], [Payer01Code], y.[Contract], y.[Plan], p.[AuditorName], p.[employee_type], p.[audit_by], p.[audit_date]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.*
	
	,IIF(SUBSTRING(ProcedureCode, 1, 1) LIKE '[A-Za-z]%' or SUBSTRING(ProcedureCode, LEN(ProcedureCode), 1) LIKE '[A-Za-z]%' or ProcedureCode = '', 0, CAST(ProcedureCode as numeric)) as ProcedureCodeNumeric


	INTO #Step1_Charges
	FROM [COL].[Data].[Charges] as x

	LEFT JOIN [COL].[Data].[Demo] as y on x.EncounterID = y.EncounterID	

	where x.[EncounterID] in (Select [EncounterID] from #Step1)

	ORDER BY [Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select x.[EncounterID], [RevenueCode], [ProcedureCode], [ProcedureCodeNumeric], [Modifier1], x.[Sequence], y.[ServiceDateFrom], y.[ServiceDateTo], ISNULL(x.[ServiceDateFrom], y.[ServiceDateTo]) as [ServiceDate], [OriginalPayment], [Amount], [BillCharges], [Quantity], [Plan], [Payer01Code], [Payer01Name]

	,[OP_Default] = CASE
	WHEN DATEDIFF(DAY, y.[ServiceDateFrom], y.[PaidDate]) < 15				THEN ROUND(Amount * 0.76, 2)
	WHEN DATEDIFF(DAY, y.[ServiceDateFrom], y.[PaidDate]) BETWEEN 15 and 45	THEN ROUND(Amount * 0.85, 2)
	WHEN DATEDIFF(DAY, y.[ServiceDateFrom], y.[PaidDate]) > 45				THEN ROUND(Amount * 1.00, 2)
	ELSE 0
	END

	--,[OP_Default] = Round(Amount * 1.00, 2)

	,[Clinic] = CASE
	WHEN (RevenueCode between 510 and 529) THEN 0.01
	ELSE 0
	END



	,case
	WHEN (y.[ServiceDateFrom] between '2020-01-27' and '2020-03-31')	and [dp].[Dx] like '%B97.29%'	THEN 1
	WHEN (y.[ServiceDateFrom] between '2020-04-01' and '2020-11-01')	and [dp].[Dx] like '%U07.1%'	THEN 1
	WHEN (y.[ServiceDateFrom] > '2020-11-01')							and [dp].[Dx] like '%U07.1%'	THEN 1 --and [dp].[Px] is not null
	ELSE 0
	END As [COVID]



	Into #Step2
	From #Step1_Charges as x
	
	LEFT JOIN [COL].[Data].[Demo] as y on x.[EncounterID] = y.[EncounterID]
	LEFT JOIN [COL].[Data].[Dx_Px] as dp on x.[EncounterID] = dp.[EncounterID] and x.[Sequence] = dp.[Sequence]	

	ORDER BY x.[Sequence]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID], [ServiceDate]
	
	,[OP_Default] = IIF([Clinic]=0, [OP_Default], 0)
	,[Clinic]
	,[COVID]
	
	INTO #Step3
	FROM #Step2

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID], [ServiceDate]
	,SUM([OP_Default])	as [OP_Default]
	,MAX([COVID])		as [COVID]	
	,MAX([Clinic])		as [Clinic]
	
	INTO #Step3_1
	FROM #Step3
	
	GROUP BY [EncounterID], [ServiceDate]

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID]
	,SUM([OP_Default])	as [OP_Default]
	,MAX([COVID])		as [COVID]		
	,MAX([Clinic])		as [Clinic]

	INTO #Step3_2
	FROM #Step3_1
	
	GROUP BY EncounterID

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select [EncounterID]
	,[OP_Default]
	,[Clinic]
	,[COVID]

	INTO #Step4
	FROM #Step3_2

-- ============================================================================================================================
-- *** [PRICE BREAKDOWN - INSERTED SECTION] ***
-- SOURCE       : #Step3 (explicit narrow column list: EncounterID, ServiceDate, OP_Default, Clinic, COVID)
--                joined to #Step4 for encounter-level suppression decisions.
--                joined to #Step2 for line-level display columns not present in #Step3
--                (Sequence, ProcedureCode, RevenueCode, Amount, BillCharges, Quantity).
--
-- COLUMN SURVIVAL TRACE:
--   #Step3 is built from #Step2 with an EXPLICIT column list:
--     EncounterID, ServiceDate, OP_Default (IIF Clinic=0), Clinic, COVID
--   Columns NOT present in #Step3: Sequence, ProcedureCode, RevenueCode,
--     Amount, BillCharges, Quantity, Modifier1, Plan, Payer01Code, Payer01Name.
--   These are recovered via LEFT JOIN to #Step2 in #LineBreakdown.
--
-- MAX CATEGORIES (one winner per encounter):
--   COVID (binary 0/1 INDICATOR_FLAG, $0 LinePayment)
--   Clinic (MAX in both AGGREGATE_DATE and AGGREGATE_ENC)
--
-- SUM CATEGORIES (all matching lines pay):
--   OP_Default (SUM in both AGGREGATE_DATE and AGGREGATE_ENC)
--
-- HYBRID CATEGORIES: none
-- WINDOW_REDUCTION CATEGORIES: none
-- INDICATOR_FLAG CATEGORIES: COVID (binary 0/1, never dollars)
--
-- SUPPRESSION HIERARCHY (from #Step4 / #Step3_2 pass-through):
--   #Step4 is a direct SELECT of EncounterID, OP_Default, Clinic, COVID
--   from #Step3_2 with NO IIF suppression applied between categories.
--   OP_Default already has IIF(Clinic=0, OP_Default, 0) applied in #Step3.
--   So at the encounter level, if Clinic > 0 then OP_Default is zeroed.
--   Effective suppression: Clinic suppresses OP_Default (Clinic wins).
--
-- ROW_NUMBER() count check:
--   MAX: Clinic (1) + INDICATOR_FLAG: COVID (1) = 2 ROW_NUMBER() calls.
--   SUM: OP_Default = 0 ROW_NUMBER() calls (SUM categories need none).
--   Total: 2 ROW_NUMBER() calls in #bRanked.
-- ============================================================================================================================

-- BLOCK 1: #bRanked
-- #Step3 has only: EncounterID, ServiceDate, OP_Default, Clinic, COVID.
-- No Sequence, ProcedureCode, RevenueCode, Amount, or Quantity.
-- #bRanked is built from #Step3 as the line-level source (contains all
-- pricing columns). Sequence/ProcedureCode/RevenueCode are absent here;
-- they are recovered via LEFT JOIN to #Step2 in #LineBreakdown.
-- NOTE: #Step3 has one row per EncounterID+ServiceDate combination
-- (it is already collapsed to that grain from #Step2 by the explicit
-- SELECT in the construction step). There is no Sequence column in #Step3.
-- We use EncounterID+ServiceDate as the grain identifier throughout.
SELECT
    b.*
    -- MAX category: Clinic (PARTITION BY EncounterID)
    , ROW_NUMBER() OVER (
        PARTITION BY b.[EncounterID]
        ORDER BY b.[Clinic] DESC, b.[ServiceDate] ASC
      ) AS rn_Clinic
    -- INDICATOR_FLAG category: COVID (PARTITION BY EncounterID, $0 LinePayment)
    , ROW_NUMBER() OVER (
        PARTITION BY b.[EncounterID]
        ORDER BY b.[COVID] DESC, b.[ServiceDate] ASC
      ) AS rn_COVID
INTO #bRanked
FROM #Step3 b;

-- NOTE: has_window_reduction = false, so #bSlots is omitted entirely.

-- BLOCK 2: #LineBreakdown
-- One row per EncounterID+ServiceDate (the grain of #Step3).
-- Sequence, ProcedureCode, RevenueCode, Amount, BillCharges, Quantity
-- are NOT present in #Step3. They are recovered via LEFT JOIN to #Step2
-- on EncounterID + ServiceDate.
-- Because one EncounterID+ServiceDate may have multiple #Step2 rows
-- (one per charge line), this join fans out to line-level granularity.
-- ServiceCategory and LinePayment are determined by the #Step3/#Step4
-- pricing columns; the #Step2 join adds display columns only.
-- BillCharges is display-only here (OP_Default uses Amount, not BillCharges;
-- Clinic is $0.01 flat; no payment formula requires BillCharges).
SELECT
    b.[EncounterID]
    -- Line-level display columns recovered from #Step2 (not present in #Step3).
    -- LEFT JOIN on EncounterID+ServiceDate fans out to one row per charge line.
    , src.[Sequence]
    , src.[ProcedureCode]
    , src.[RevenueCode]
    , b.[ServiceDate]
    , src.[Amount]                              AS [BilledAmount]
    , src.[Quantity]
    , src.[BillCharges]

    -- ----------------------------------------------------------------
    -- SERVICE CATEGORY
    -- Hierarchy from #Step4 (pass-through of #Step3_2):
    --   Clinic suppresses OP_Default (OP_Default was zeroed in #Step3
    --   wherever Clinic != 0, so s4.[OP_Default] will already be 0
    --   for any encounter where s4.[Clinic] != 0).
    --   COVID is an INDICATOR_FLAG; it is placed after all dollar
    --   categories and the Suppressed_By_Hierarchy catch.
    -- ----------------------------------------------------------------
    , [ServiceCategory] = CASE

        -- ---- TIER 1: Clinic (MAX) ----
        -- Clinic is MAX in both aggregation steps (wins encounter-level).
        -- IIF(rn=1) picks one representative line per encounter.
        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN IIF(b.rn_Clinic = 1, 'Clinic', 'Clinic_Non_Winner')

        -- ---- TIER 2: OP_Default (SUM) ----
        -- OP_Default is SUM in both aggregation steps; all matching
        -- lines contribute. s4.[OP_Default] is already zeroed when
        -- Clinic > 0 (applied in #Step3 IIF logic).
        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN 'OP_Default'

        -- ---- Suppressed: line had a dollar value but #Step4 zeroed it ----
        -- This covers OP_Default lines that were suppressed because
        -- Clinic > 0 for the encounter.
        WHEN (
              ISNULL(b.[Clinic],   0)
            + ISNULL(b.[OP_Default], 0)
            + ISNULL(b.[COVID],    0)
        ) > 0
            THEN 'Suppressed_By_Hierarchy'

        -- ---- INDICATOR_FLAG: COVID (binary 0/1, $0 LinePayment) ----
        -- Placed after all dollar categories and Suppressed_By_Hierarchy.
        -- Only surfaces for lines with no dollar category match.
        WHEN b.[COVID] != 0
            THEN IIF(b.rn_COVID = 1, 'COVID_Flag', 'COVID_Flag_Non_Winner')

        ELSE 'No_Payment_Category'
    END

    -- ----------------------------------------------------------------
    -- PRICING METHOD
    -- Human-readable description of the rate formula.
    -- ----------------------------------------------------------------
    , [PricingMethod] = CASE

        WHEN s4.[Clinic] != 0
         AND b.[Clinic] > 0
            THEN 'Clinic flat indicator: $0.01 per line with Rev code 510-529 (used as category trigger, not a dollar payment)'

        WHEN s4.[OP_Default] != 0
         AND b.[OP_Default] > 0
            THEN CASE
                    WHEN src.[Amount] IS NULL
                        THEN 'OP_Default: Amount is NULL, $0'
                    ELSE
                        'Pct of charges based on payment speed: '
                        + 'Amount x 76% (paid < 15 days) | '
                        + 'Amount x 85% (15-45 days) | '
                        + 'Amount x 100% (> 45 days from ServiceDateFrom to PaidDate)'
                 END

        WHEN (
              ISNULL(b.[Clinic],   0)
            + ISNULL(b.[OP_Default], 0)
            + ISNULL(b.[COVID],    0)
        ) > 0
            THEN 'Category suppressed by encounter hierarchy (Clinic suppresses OP_Default) - $0'

        WHEN b.[COVID] != 0
            THEN 'COVID indicator flag - binary 0/1 value, no dollar payment'

        ELSE 'No pricing pattern matched for this line - $0'
    END

    -- ----------------------------------------------------------------
    -- LINE PAYMENT
    -- MAX:   IIF(s4.[CAT]!=0, IIF(b.rn_CAT=1, value, 0), 0)
    -- SUM:   IIF(s4.[CAT]!=0, ISNULL(b.[CAT], 0), 0)
    -- INDICATOR_FLAG: $0 - never add b.[COVID] to LinePayment.
    --
    -- NOTE: Clinic in LINE_PRICING = 0.01 (a trigger value, not a real
    -- payment dollar). The contract logic uses Clinic as a flag to
    -- suppress OP_Default. The encounter Price = OP_Default + Clinic
    -- (from #Step5). To reconcile correctly we must include the Clinic
    -- contribution (0.01 per winning Clinic line) in LinePayment.
    -- MAX logic: only rn_Clinic=1 pays, matching how MAX aggregation
    -- selects a single Clinic value at the encounter level.
    -- ----------------------------------------------------------------
    , [LinePayment] = ROUND(
          -- MAX: Clinic
          IIF(s4.[Clinic] != 0,
              IIF(b.rn_Clinic = 1, ISNULL(b.[Clinic], 0), 0),
              0)
          -- SUM: OP_Default
        + IIF(s4.[OP_Default] != 0, ISNULL(b.[OP_Default], 0), 0)
          -- INDICATOR_FLAG: COVID - $0, never added
      , 2)

    -- NCCI BUNDLED FLAG: no NCCI bundle step in this script
    , [BundledByNCCI] = CAST(0 AS TINYINT)

INTO #LineBreakdown
FROM #bRanked b
INNER JOIN #Step4  s4  ON s4.[EncounterID] = b.[EncounterID]
-- LEFT JOIN to #Step2 to recover line-level display and payment columns
-- not present in #Step3. Join on EncounterID + ServiceDate.
-- This fans out from one #Step3 row per date to one row per charge line.
LEFT  JOIN #Step2  src ON src.[EncounterID] = b.[EncounterID]
                       AND src.[ServiceDate] = b.[ServiceDate]
ORDER BY b.[EncounterID], src.[Sequence];



--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select *
	,[OP_Default] + [Clinic] as Price

	INTO #Step5
	FROM #Step4

--***********************************************************************************************************************************************************************************************************************************************************************************************************
	Select 
	 x.*

	,y.[Price]
	,y.[OP_Default]
	,y.[Clinic]
	,y.[COVID]

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
	,Round((cast(x.[OriginalPayment] as float)/[BillCharges]) * 100, 2) as [% paid]
	,DATEDIFF(DAY, x.[ServiceDateFrom], GETDATE()) - 365 as DaysLeft
	
	,IIF(ISNULL(x.[OP_Default]	, 0) > 0,  'OP_Default - '	+ Cast(x.[OP_Default]	as varchar) + ', ','')
	+IIF(ISNULL(x.[Clinic]		, 0) > 0,  'Clinic - '		+ Cast(x.[Clinic]		as varchar) + ', ','')		
	as ExpectedDetailed	
	
--	,x.[OP_Default]
--	,x.[Clinic]
--	,x.[COVID]

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

--	WHERE [Status] LIKE '%Errors%'

--	where [AuditorName] like 'Isabe%'

	Order by Round(Diff, 2) desc


	Select [Status], count(*)
	From #StepFinal
	Group by [Status]
	order by count(*) desc

--======================================================================
-- *** [AUDITOR PRICE BREAKDOWN SUMMARY QUERIES - INSERTED SECTION] ***
-- Run these after the main script completes.
-- #LineBreakdown = one row per charge line (EncounterID + ServiceDate + Sequence).
-- ServiceCategory = final hierarchy decision based on #Step4 suppression logic.
-- 'Suppressed_By_Hierarchy' = line matched a category but a higher-tier
--   category won for this encounter (Clinic suppresses OP_Default).
-- 'No_Payment_Category' = line did not match any pricing pattern.
-- BundledByNCCI = 0 (no NCCI bundle step in this script).
-- ContractYearFrom / ContractYearTo are NOT present in #LineBreakdown
--   for this script (no date-banded categories required them); those
--   columns are excluded from all queries below.
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
    , lb.[BillCharges]
    , lb.[ServiceCategory]
    , lb.[PricingMethod]
    , lb.[LinePayment]      AS [ContractualPayment_Line]
    , lb.[BundledByNCCI]   AS [ZeroedByNCCI_Flag]
FROM #LineBreakdown lb
ORDER BY lb.[EncounterID], lb.[Sequence];

-- INSERT line-level results into persistent audit table for reporting and tracking.
-- ScriptName identifies this specific contract script for cross-run comparisons.
INSERT INTO [Automation].[dbo].[LineBreakdown_Results]
    (EncounterID, Sequence, ProcedureCode, RevenueCode, ServiceDate,
     BilledAmount, Quantity, BillCharges,
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
    , lb.[BillCharges]
    , lb.[ServiceCategory]
    , lb.[PricingMethod]
    , lb.[LinePayment]
    , lb.[BundledByNCCI]
    , 'NYP_COL_Magnacare_COM_OP'
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
    , p.[Price]                                    AS EncounterLevel_Price
    , (r.[LineBreakdown_Total] - p.[Price])         AS Discrepancy
FROM #recon_temp r
INNER JOIN #Step5 p ON r.[EncounterID] = p.[EncounterID]
WHERE ABS(r.[LineBreakdown_Total] - p.[Price]) > 1.00
ORDER BY ABS(r.[LineBreakdown_Total] - p.[Price]) DESC;



-- 		DECLARE @DBName SYSNAME = DB_NAME();
-- EXEC Analytics.dbo.InsertScriptsStepFinal
--     @TargetDB  = @DBName,  @ScriptName = 'NYP_COL_Magnacare_COM_OP';   -- Replace with actual script name
 
-- /***********************************************************************************************
-- *** ONLY UNCOMMENT AND RUN THE COMMIT STEP WHEN YOU ARE READY FOR THE ACCOUNTS TO BE SENT
-- *** TO PRS FOR AUTOMATED PROCESSING. ONCE COMMITTED, THE WORKFLOW CANNOT BE UNDONE.
-- ***********************************************************************************************/
-- -- EXEC Analytics.dbo.CommitScriptsStepFinal  @TargetDB = @DBName;