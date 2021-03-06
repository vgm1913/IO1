USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_INVDIV_ACCT]    Script Date: 2/12/2015 2:27:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Investment Division in Account based Portfolios 
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_INVDIV_ACCT]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL

	DECLARE @myType int 
	DECLARE @startDateCII datetime, @startDateCFII datetime, @startDateGIG datetime
	SELECT @startDateCII = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'CII%')
	SELECT @startDateGIG = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'GIG%')
	SELECT @startDateCFII = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'CFII%')
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-ACCT')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Relationship Portfolios: INVDIV-ACCT'
	insert into Portfolio
	select
		aggrid 
	,	substring(aggrnm, 1, CHARINDEX('-', aggrnm, 1) -1)+'-CWI' 
	,	@myType 
	,	bsecrncyid 
	,	convert(int, startdt) 
	,	RTRIM(LTRIM(convert(char, startdt, 107))) 
	,	convert(int, enddt) 
	,	RTRIM(LTRIM(convert(char, enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	where
		enddt >= @cutOffDate
	and b.aggrtypcd = 'GA'
	and aggrnm like '%-GRP CWI%'
	union
		select
		aggrid 
	,	substring(aggrnm, 1, CHARINDEX('-', aggrnm, 1) - 1)+'-CRGI' 
	,	@myType 
	,	bsecrncyid 
	,	convert(int, startdt) 
	,	RTRIM(LTRIM(convert(char, startdt, 107))) 
	,	convert(int, enddt) 
	,	RTRIM(LTRIM(convert(char, enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	where
		enddt >= @cutOffDate
	and b.aggrtypcd = 'GA'
	and aggrnm like '%-GRP CRGI%'
	union
		select
		aggrid 
	,	substring(aggrnm, 1, CHARINDEX('-', aggrnm, 1) -1)+'-GRP U' 
	,	@myType 
	,	bsecrncyid 
	,	convert(int, startdt) 
	,	RTRIM(LTRIM(convert(char, startdt, 107))) 
	,	convert(int, enddt) 
	,	RTRIM(LTRIM(convert(char, enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	where
		enddt >= @cutOffDate
	and b.aggrtypcd = 'GA'
	and aggrnm like '%-GRP U%'

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Inv-Div-Account Portfolios
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

	-- *********************************************************************
	-- * Special logic - for CII - to Accounts managed by EQ managers ONLY *
	-- *********************************************************************
	select distinct
		-1 * b.aggrid CII_PortfolioUid, b.aggrid MARS_aggrid
	INTO
		#temp_CII
	from
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	where
		a.grpacctaggrid = b.aggrid
	and a.grpaggrid not in (select aggrid from mars_par_gap..pr_grp d where d.grpnum in ('CWI', 'CRGI', 'U'))
	and a.grpaggrid not in (select aggrid from mars_par_gap..pr_grp d where d.sprgrpind = 'Y')
	and a.grpaggrid > 0
	and b.aggrtypcd = 'GA'
	and b.enddt >= @startDateCII
	
	insert into Portfolio
	select distinct
		a.CII_PortfolioUid
	,	substring(aggrnm, 1, CHARINDEX('-', aggrnm, 1) -1)+	'-CII' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, @startDateCII) 
	,	RTRIM(LTRIM(convert(char, @startDateCII, 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_CII a
	where
		a.MARS_aggrid = b.aggrid
	and b.enddt > @startDateCII
	and b.startdt <= @startDateCII

	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT CII_PortfolioUid FROM #temp_CII)

	INSERT INTO PortfolioActivity
	SELECT distinct
		b.CII_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, a.startdt) 
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	#temp_CII b
	WHERE
		a.aggrid = b.MARS_aggrid

	-- *********************************************************************
	-- * Special logic - for GIG - to Accounts managed by EQ managers ONLY *
	-- *********************************************************************
	DECLARE @min_CII_PortfolioID bigint
	SELECT @min_CII_PortfolioID = (SELECT MIN(CII_PortfolioUid) FROM #temp_CII)

	-- Special logic - for GIG - to Accounts managed by EQ managers ONLY
	select distinct
		-10 * CONVERT(bigint, b.aggrid) GIG_PortfolioUid, b.aggrid MARS_aggrid
	INTO
		#temp_GIG
	from
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	where
		a.grpacctaggrid = b.aggrid
	and a.grpaggrid not in (select aggrid from mars_par_gap..pr_grp d where d.grpnum in ('CWI', 'CRGI', 'U'))
	and a.grpaggrid not in (select aggrid from mars_par_gap..pr_grp d where d.sprgrpind = 'Y')
	and a.grpaggrid > 0
	and b.aggrtypcd = 'GA'
	and b.enddt >= @startDateGIG
	and b.startdt <= @startDateCII

	insert into Portfolio
	select distinct
		a.GIG_PortfolioUid
	,	substring(aggrnm, 1, CHARINDEX('-', aggrnm, 1) -1)+	'-GIG' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, b.startdt) 
	,	RTRIM(LTRIM(convert(char, b.startdt, 107))) 
	,	convert(int, @startDateGIG) 
	,	RTRIM(LTRIM(convert(char, @startDateGIG, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_GIG a
	where
		a.MARS_aggrid = b.aggrid
	and b.enddt >= @startDateCII
	and b.startdt <= @startDateGIG
	UNION
	select distinct
		a.GIG_PortfolioUid
	,	substring(aggrnm, 1, CHARINDEX('-', aggrnm, 1) -1)+	'-GIG' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, @startDateGIG) 
	,	RTRIM(LTRIM(convert(char, @startDateGIG, 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_GIG a
	where
		a.MARS_aggrid = b.aggrid
	and b.enddt < @startDateCII
	and b.startdt <= @startDateGIG
	
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT GIG_PortfolioUid FROM #temp_GIG)

	INSERT INTO PortfolioActivity
	SELECT distinct
		b.GIG_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, a.startdt) 
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	#temp_GIG b
	where
		a.aggrid = b.MARS_aggrid

	-- *********************************************************************
	-- * Special logic - for CFII - to Accounts managed by EQ managers ONLY *
	-- *********************************************************************
	-- we must Handle CFII separatley
	select distinct
		-1 * b.aggrid CFII_PortfolioUid, b.aggrid MARS_aggrid
	INTO
		#temp_CFII
	from
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_account c
	where
		a.acctaggrid = b.aggrid
	and	b.aggrtypcd = 'AA'
	and c.aggrid = b.aggrid
	and a.mgrid in (select mgrid from mars_par_gap..pr_mgr where mgrtypcd = 'FI')
	and a.grpaggrid < 0
	and b.enddt >= @startDateCFII

	insert into Portfolio
	select distinct
		-1 * b.aggrid 
	,	RTRIM(LTRIM(c.acctabbr))+	'-CFII' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, @startDateCFII) 
	,	RTRIM(LTRIM(convert(char, @startDateCFII, 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_CFII a
	,	mars_par_gap..pr_account c
	where
		a.MARS_aggrid = b.aggrid
	and	b.aggrtypcd = 'AA'
	and c.aggrid = b.aggrid
	and b.enddt >= @startDateCFII

	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT CFII_PortfolioUid FROM #temp_CFII)

	INSERT INTO PortfolioActivity
	SELECT distinct
		b.CFII_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, a.startdt) 
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	#temp_CFII b
	where
		a.aggrid = b.MARS_aggrid
	
	DROP TABLE 	#temp_CII
	DROP TABLE 	#temp_GIG
	DROP TABLE	#temp_CFII
	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL


END
