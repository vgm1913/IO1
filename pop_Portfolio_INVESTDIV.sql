USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_INVESTDIV]    Script Date: 2/12/2015 1:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Investment Division based Portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_INVESTDIV] 
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	ALTER TABLE InvestmentDivision NOCHECK CONSTRAINT ALL

	DECLARE @myType int
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVESTDIV')

	PRINT 'Stage 1.6 - populate Entity Portfolios: Invest Division'
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	insert into Portfolio
	select
		aggrid,	'CWI',	@myType, bsecrncyid, convert(int, startdt),	RTRIM(LTRIM(convert(char, startdt, 107))), convert(int, enddt),	RTRIM(LTRIM(convert(char, enddt, 107)))
	from
		mars_par_gap..pr_aggr b
	where
		startdt < enddt
	and enddt >= @cutOffDate
	and b.aggrtypcd = 'GP'
	and b.aggrid in (select aggrid from mars_par_gap..pr_grp where grpnum = 'CWI')

	insert into Portfolio
	select
		aggrid,	'CRGI',	@myType, bsecrncyid, convert(int, startdt),	RTRIM(LTRIM(convert(char, startdt, 107))), convert(int, enddt),	RTRIM(LTRIM(convert(char, enddt, 107)))
	from
		mars_par_gap..pr_aggr b
	where
		startdt < enddt
	and enddt >= @cutOffDate
	and b.aggrtypcd = 'GP'
	and b.aggrid in (select aggrid from mars_par_gap..pr_grp where grpnum = 'CRGI')

	insert into Portfolio
	select
		aggrid,	'U-Grp (special)',	@myType, bsecrncyid, convert(int, startdt),	RTRIM(LTRIM(convert(char, startdt, 107))), convert(int, enddt),	RTRIM(LTRIM(convert(char, enddt, 107)))
	from
		mars_par_gap..pr_aggr b
	where
		startdt < enddt
	and enddt >= @cutOffDate
	and b.aggrtypcd = 'GP'
	and b.aggrid in (select aggrid from mars_par_gap..pr_grp where grpnum = 'U')
	
	-- the next 2 are temporary hacks - until unique PortfoliUid generator is completed
	DECLARE @CII_port_id int, @CFII_port_id int, @GIG_port_id int
	DECLARE @CII_startdt datetime, @enddt datetime
	DECLARE @GIG_startdt datetime, @CFII_startdt datetime
	SET @CII_startdt = (select '01/01/2010') -- hardcode CII start to be start of 2010 - can be adjusted later
	SET @enddt = (select '06/06/2079')
	SET @GIG_startdt = (SELECT '01/01/1998')
	SET @CII_port_id = (SELECT min(aggrid) from mars_par_gap..pr_aggr) - 1
	PRINT ' Generating CII_port_id='+CONVERT(char, @CII_port_id)
	-- create a new CII portfolio to mimic CWI, CRGI Groups from MARS
	insert into Portfolio
	select	@CII_port_id, 'CII', @myType, 1, convert(int, @CII_startdt),	RTRIM(LTRIM(convert(char, @CII_startdt, 107))), convert(int, @enddt), RTRIM(LTRIM(convert(char, @enddt, 107)))

	SET @GIG_port_id = (SELECT @CII_port_id) - 1
	PRINT ' Generating GIG_port_id='+CONVERT(char, @GIG_port_id)

	-- create a new GIG portfolio to setup pre-XYZ world (not in MARS) - note: enddate for GIG is start date for CII
	insert into Portfolio
	select	@GIG_port_id, 'GIG', @myType, 1, convert(int, @GIG_startdt),	RTRIM(LTRIM(convert(char, @GIG_startdt, 107))), convert(int, @CII_startdt), RTRIM(LTRIM(convert(char, @CII_startdt, 107)))

	-- make CFII start same time as CWI (fix later)
	SET @CFII_startdt = (select convert(date, startdt) from mars_par_gap..pr_aggr where aggrid in (select aggrid from mars_par_gap..pr_grp where grpnum = 'CWI'))
	SET @CFII_port_id = (SELECT @GIG_port_id) - 1
	print ' Generating CFII_port_id='+CONVERT(char, @CFII_port_id)
	
	-- ok now create a new CFII portfolio
	insert into Portfolio
	select	@CFII_port_id, 'CFII', @myType, 1, convert(int, @CFII_startdt),	RTRIM(LTRIM(convert(char, @CFII_startdt, 107))), convert(int, @enddt), RTRIM(LTRIM(convert(char, @enddt, 107)))

	PRINT 'Poluate Investment Division reference table'
	DELETE FROM InvestmentDivision

	INSERT INTO InvestmentDivision
	SELECT
		CONVERT(bigint, aggrid)	PortfolioUid
	,	grpshrtnm InvestmentDivisionCode
	,	grpnum	InvestmentDivisionAbbr
	,	grpnm	InvestmentDivisionName
	FROM
		mars_par_gap..pr_grp
	WHERE
		sprgrpind != 'Y'
	AND	grpnum in ('CWI', 'CRGI', 'U')

	INSERT INTO InvestmentDivision
	SELECT
		PortfolioUid
	,	'F'
	,	'CFII'
	,	'Capital Global Fixed income Investors'
	FROM Portfolio
	WHERE PortfolioName like 'CFII%'
	AND PortfolioTypeUid in (Select PortfolioTypeUid from PortfolioType where PortfolioTypeAbbr = 'INVESTDIV')

	INSERT INTO InvestmentDivision
	SELECT
		PortfolioUid
	,	'C'
	,	'CII'
	,	'Capital International Investors'
	FROM Portfolio
	WHERE PortfolioName like 'CII%'
	AND PortfolioTypeUid in (Select PortfolioTypeUid from PortfolioType where PortfolioTypeAbbr = 'INVESTDIV')

	INSERT INTO InvestmentDivision
	SELECT
		PortfolioUid
	,	'I'
	,	'GIG'
	,	'Global Institutional Group'
	FROM Portfolio
	WHERE PortfolioName = 'GIG'
	AND PortfolioTypeUid in (Select PortfolioTypeUid from PortfolioType where PortfolioTypeAbbr = 'INVESTDIV')

	-- capture the activities based on MARS data
	DELETE FROM PortfolioActivity
	WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myType)

	INSERT INTO PortfolioActivity
	SELECT
		b.PortfolioUid
	,	a.mbraggrid 
	,	convert(int, a.startdt) 
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	Portfolio b
	where
		a.aggrid = b.PortfolioUid
	AND	b.PortfolioTypeUid = @myType 

	-- create activity data based on MARS Manager (pr_mgr) table in Accounts (pr_acct) based on simple Manager Role = FI or EQ and Account Type being trust (not Fund)
	SELECT DISTINCT
		@CII_port_id		PortfolioUid
	,	a.aggrid 
	,	convert(int, a.startdt)		StartIdx
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) StartDate
	,	convert(int, a.enddt) EndIdx
	,	RTRIM(LTRIM(convert(char, a.enddt, 107))) EndDate
	into #temp1
	FROM
		mars_par_gap..pr_aggr a
	,	mars_par_gap..pr_acct_mgr_hist c
	where
		a.aggrtypcd = 'AM'
	AND c.acctmgraggrid = a.aggrid
	AND c.mgrid in (select mgrid from mars_par_gap..pr_mgr where mgrtypcd = 'EQ')
	AND c.acctid in (select acctid from mars_par_gap..pr_account where acctdivsn = 'TRUS')
	AND	a.enddt > @CII_startdt
	
	INSERT INTO #temp1
	SELECT DISTINCT
		@GIG_port_id		PortfolioUid
	,	a.aggrid 
	,	convert(int, a.startdt)		StartIdx
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) StartDate
	,	convert(int, a.enddt) EndIdx
	,	RTRIM(LTRIM(convert(char, a.enddt, 107))) EndDate
	FROM
		mars_par_gap..pr_aggr a
	,	mars_par_gap..pr_acct_mgr_hist c
	where
		a.aggrtypcd = 'AM'
	AND c.acctmgraggrid = a.aggrid
	AND c.mgrid in (select mgrid from mars_par_gap..pr_mgr where mgrtypcd = 'EQ')
	AND c.acctid in (select acctid from mars_par_gap..pr_account where acctdivsn = 'TRUS')
	AND	a.enddt > @GIG_startdt
	AND a.enddt <= @CII_startdt

	INSERT INTO #temp1
	SELECT DISTINCT
		@CFII_port_id
	,	a.aggrid 
	,	convert(int, a.startdt) 
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr a
	,	Portfolio b
	,	mars_par_gap..pr_acct_mgr_hist c
	where
		a.aggrtypcd = 'AM'
	AND c.acctmgraggrid = a.aggrid
	AND c.mgrid in (select mgrid from mars_par_gap..pr_mgr where mgrtypcd = 'FI')
	AND c.acctid in (select acctid from mars_par_gap..pr_account where acctdivsn = 'TRUS')

	print ' Populating CII A-M level PortfolioActivity'
	DELETE FROM PortfolioActivity WHERE PortfolioUid = @CII_port_id
	INSERT INTO PortfolioActivity
	SELECT DISTINCT * FROM #temp1 WHERE PortfolioUid = @CII_port_id

	print ' Populating GIG A-M level PortfolioActivity'
	DELETE FROM PortfolioActivity WHERE PortfolioUid = @GIG_port_id
	INSERT INTO PortfolioActivity
	SELECT DISTINCT * FROM #temp1 WHERE PortfolioUid = @GIG_port_id

	print ' Populating CFII A-M level PortfolioActivity'
	DELETE FROM PortfolioActivity WHERE PortfolioUid = @CFII_port_id
	INSERT INTO PortfolioActivity
	SELECT DISTINCT * FROM #temp1 WHERE PortfolioUid = @CFII_port_id

	-- clean up and finish
	DROP TABLE #temp1	
	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL
	ALTER TABLE InvestmentDivision CHECK CONSTRAINT ALL
END

