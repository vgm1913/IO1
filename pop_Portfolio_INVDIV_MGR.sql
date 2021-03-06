USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_INVDIV_MGR]    Script Date: 2/13/2015 5:01:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Investment Division in Account based Portfolios 
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_INVDIV_MGR]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL

	DECLARE @startDateCII datetime, @startDateCFII datetime
	SELECT @startDateCII = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'CII%')

	DECLARE @startDateGIG datetime
	SET @startDateGIG = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'GIG')

	SELECT @startDateCFII = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'CFII%')

	-- make sure start with a clean slate
	DECLARE @myType int 
	SET @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-MGR')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myType)

	PRINT 'populate Relationship Portfolios: INVDIV-MGR'
	PRINT ' Generating CWI, CRGI, & U ("special group") Mgmt Resp Relationship Portfolios'
	insert into Portfolio
	select
		aggrid 
	,	aggrnm 
	,	@myType 
	,	bsecrncyid 
	,	convert(int, startdt) 
	,	RTRIM(LTRIM(convert(char, startdt, 107))) 
	,	convert(int, enddt) 
	,	RTRIM(LTRIM(convert(char, enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	where
		startdt < enddt
	and enddt >= @cutOffDate
	and b.aggrtypcd = 'GM'
	and (
		aggrnm like '%-GRP CWI%'
	or	aggrnm like '%-GRP CRGI%'
	or	aggrnm like '%-GRP U%')

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Inv-Div-MgmtResp Portfolios
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myType)
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

	-- insert CII portfolio relationships to all CII Mgmt Responsibilities
	PRINT ' Generating CII Mgmt Resp Relationship Portfolios'
	CREATE TABLE #temp_CII_MGR (CII_MGR_PortfolioUid bigint, MARS_aggrid int)

	INSERT INTO #temp_CII_MGR
	SELECT DISTINCT
		-1 * b.aggrid, b.aggrid 
	FROM
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_mgr c
	WHERE
		a.mgraggrid = b.aggrid
	AND	b.aggrtypcd = 'MG'
	AND c.aggrid = b.aggrid
	AND c.mgrtypcd = 'EQ'
	AND a.grpaggrid not in (select aggrid from mars_par_gap..pr_grp d where d.grpnum in ('CWI', 'CRGI', 'U'))
	AND a.grpaggrid > 0
	AND b.enddt >= @startDateCII -- only want those that exist after the start date of CII

	insert into Portfolio
	select distinct
		-1 * b.aggrid 
	,	RTRIM(LTRIM(c.mgrinit))+' '+RTRIM(LTRIM(c.mgrnum))+	'-CII' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, dbo.get_LaterDate(b.startdt, @startDateCII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(b.startdt, @startDateCII), 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_CII_MGR a
	,	mars_par_gap..pr_mgr c
	where
		a.MARS_aggrid = b.aggrid
	and c.aggrid = b.aggrid

	-- now for those who started earlier than CII - adjust their date to the start on the day CII our new Investment Division started
	INSERT INTO PortfolioActivity
	SELECT
		d.CII_MGR_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, dbo.get_LaterDate(a.startdt, @startDateCII)) 	-- but for those who started after CII started - just use their start date if it is later
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(a.startdt, @startDateCII), 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
--	,	mars_par_gap..pr_aggr c
--	,	Portfolio b
	,	#temp_CII_MGR d
	where
		a.aggrid = d.MARS_aggrid
--	AND b.PortfolioUid = d.CII_MGR_PortfolioUid
--	AND a.aggrid = c.aggrid
--	AND c.aggrtypcd = 'MG'
--	AND	b.PortfolioTypeUid = @myType 
--	AND b.PortfolioUid < 0

	-- now generate GIG to Mgmt Responsibility portfolios for the time before CII
	PRINT ' Generating GIG Mgmt Resp Relationship Portfolios'
	DECLARE @min_PortfolioID bigint
	SET @min_PortfolioID = (SELECT MIN(PortfolioUid) FROM Portfolio WHERE PortfolioUid < 0)
	CREATE TABLE #temp_GIG_MGR (GIG_MGR_PortfolioUid bigint, MARS_aggrid int)

	INSERT INTO #temp_GIG_MGR
	SELECT DISTINCT
		-1 * b.aggrid + @min_PortfolioID, b.aggrid
	FROM
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_mgr c
	WHERE
		a.mgraggrid = b.aggrid
	AND	b.aggrtypcd = 'MG'
	AND c.aggrid = b.aggrid
	AND c.mgrtypcd = 'EQ'
	AND a.grpaggrid not in (select aggrid from mars_par_gap..pr_grp d where d.grpnum in ('CWI', 'CRGI', 'U'))
	AND a.grpaggrid > 0
	AND b.enddt >= @startDateGIG -- only want those that exist after the start date of GIG
	AND b.startdt < @startDateCII -- and then filter out those that started after CII - GIG does not exist

	-- if the relationship is still active in MARS beyond the start date of CII - the use the CII date as end date for portfolios related to GIG
	insert into Portfolio
	select distinct
		a.GIG_MGR_PortfolioUid
	,	RTRIM(LTRIM(c.mgrinit))+' '+RTRIM(LTRIM(c.mgrnum))+	'-GIG' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, dbo.get_LaterDate(b.startdt,@startDateGIG)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(b.startdt,@startDateGIG), 107))) 
	,	convert(int, dbo.get_EarlierDate(b.enddt, @startDateCII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_EarlierDate(b.enddt, @startDateCII), 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_GIG_MGR a
	,	mars_par_gap..pr_mgr c
	where
		a.MARS_aggrid = b.aggrid
	AND c.aggrid = b.aggrid

	INSERT INTO PortfolioActivity
	SELECT
		d.GIG_MGR_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, dbo.get_LaterDate(a.startdt,@startDateGIG)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(a.startdt,@startDateGIG), 107))) 
	,	convert(int, dbo.get_EarlierDate(a.enddt, @startDateCII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_EarlierDate(a.enddt, @startDateCII), 107))) 
	FROM
		mars_par_gap..pr_aggr_mbr a
	--,	mars_par_gap..pr_aggr c
	--,	Portfolio b
	,	#temp_GIG_MGR d
	where
		a.aggrid = d.MARS_aggrid
	--AND b.PortfolioUid = d.GIG_MGR_PortfolioUid
	--AND a.aggrid = c.aggrid
	--AND c.aggrtypcd = 'MG'
	--AND b.PortfolioTypeUid = @myType 
	--AND b.PortfolioUid < 0
	
	-- insert CFII portfolio relationships to all FI Mgmt Responsibilities
	PRINT ' Generating CFII Mgmt Resp Relationship Portfolios'
	SET @min_PortfolioID = (SELECT MIN(PortfolioUid) FROM Portfolio WHERE PortfolioUid < 0)
	CREATE TABLE #temp_CFII_MGR (CFII_MGR_PortfolioUid bigint, MARS_aggrid int)

	INSERT INTO #temp_CFII_MGR
	select distinct
		(-1 * b.aggrid ) + @min_PortfolioID, b.aggrid
	from
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_mgr c
	where
		a.mgraggrid = b.aggrid
	and	b.aggrtypcd = 'MG'
	and c.aggrid = b.aggrid
	and c.mgrtypcd = 'FI'
	and a.grpaggrid <= 0 -- make sure it is not grouped
	and b.enddt >= @startDateCFII
	
	insert into Portfolio
	select distinct
		a.CFII_MGR_PortfolioUid
	,	RTRIM(LTRIM(c.mgrinit))+' '+RTRIM(LTRIM(c.mgrnum))+	'-CFII' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, dbo.get_LaterDate(b.startdt,@startDateCFII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(b.startdt,@startDateCFII), 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_CFII_MGR a
	,	mars_par_gap..pr_mgr c
	where
		a.MARS_aggrid = b.aggrid
	and c.aggrid = b.aggrid

	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT CFII_MGR_PortfolioUid FROM #temp_CFII_MGR)

	INSERT INTO PortfolioActivity
	SELECT
		b.PortfolioUid
	,	a.mbraggrid 
	,	convert(int, dbo.get_LaterDate(a.startdt,@startDateCFII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(a.startdt,@startDateCFII), 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	mars_par_gap..pr_aggr c
	,	Portfolio b
	,	#temp_CFII_MGR d
	where
		a.aggrid = d.MARS_aggrid
	AND d.CFII_MGR_PortfolioUid = b.PortfolioUid
	AND a.aggrid = c.aggrid
	AND c.aggrtypcd = 'MG'
	AND	b.PortfolioTypeUid = @myType 
	and b.PortfolioUid < 0

	-- clean up
	DROP TABLE #temp_CFII_MGR
	DROP TABLE #temp_CII_MGR
	DROP TABLE #temp_GIG_MGR
	
	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL

END
