USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_INVDIV_SGRP]    Script Date: 2/12/2015 2:32:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Investment Division to Super Group - only a CII concept portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_INVDIV_SGRP]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL

	PRINT 'populate Relationship Portfolios: INVDIV-SGRP'

	DECLARE @startDateCII datetime
	SELECT @startDateCII = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'CII')

	DECLARE @startDateGIG datetime
	SELECT @startDateGIG = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'GIG')

	DECLARE @myType int 
	SET @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-SGRP')
	-- make sure we start with a clean slate
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myType)
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	INSERT INTO Portfolio
	SELECT
			-1 * aggrid		-- temporary method to create unique UID 
		,	RTRIM(LTRIM(aggrnm))+'-CII'
		,	@myType 
		,	bsecrncyid 
		,	convert(int, @startDateCII) 
		,	RTRIM(LTRIM(convert(char, @startDateCII, 107))) 
		,	convert(int, enddt) 
		,	RTRIM(LTRIM(convert(char, enddt, 107))) 
	from
		mars_par_gap..pr_aggr
	where aggrtypcd = 'SG'
	and startdt <= @startDateCII
	and enddt > @startDateCII

	DECLARE @min_CII_PortfolioID bigint
	SET @min_CII_PortfolioID = (SELECT MIN(PortfolioUid) FROM Portfolio WHERE PortfolioUid < 0)

	-- now simulate GIG
	INSERT INTO Portfolio
	SELECT
			-1 * aggrid	+ @min_CII_PortfolioID	-- temporary method to create unique UID 
		,	RTRIM(LTRIM(aggrnm))+'-GIG'
		,	@myType 
		,	bsecrncyid 
		,	convert(int, startdt) 
		,	RTRIM(LTRIM(convert(char, startdt, 107))) 
		,	convert(int, @startDateGIG) 
		,	RTRIM(LTRIM(convert(char, @startDateGIG, 107))) 
	from
		mars_par_gap..pr_aggr
	where aggrtypcd = 'SG'
	and startdt <= @startDateGIG
	and enddt > @startDateCII

	INSERT INTO Portfolio
	SELECT
			-1 * aggrid	+ @min_CII_PortfolioID	-- temporary method to create unique UID 
		,	RTRIM(LTRIM(aggrnm))+'-GIG'
		,	@myType 
		,	bsecrncyid 
		,	convert(int, startdt) 
		,	RTRIM(LTRIM(convert(char, startdt, 107))) 
		,	convert(int, enddt) 
		,	RTRIM(LTRIM(convert(char, enddt, 107))) 
	from
		mars_par_gap..pr_aggr
	where aggrtypcd = 'SG'
	and startdt <= @startDateGIG
	and enddt <= @startDateCII
	
	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Inv-Div-SuperGroup Portfolios
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myType)

	INSERT INTO PortfolioActivity
	SELECT
		b.PortfolioUid
	,	a.acctmgraggrid 
	,	convert(int, @startDateCII) 
	,	RTRIM(LTRIM(convert(char, @startDateCII, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_acct_mgr_hist a
	,	Portfolio b
	,	mars_par_gap..pr_mgr c
	where
		(-1 * a.grpaggrid) = b.PortfolioUid
	AND	b.PortfolioTypeUid = @myType 
	AND	a.mgrid = c.mgrid
	AND	c.mgrtypcd != 'EQ'
	AND a.enddt >= @startDateCII

	INSERT INTO PortfolioActivity
	SELECT
		b.PortfolioUid
	,	a.acctmgraggrid 
	,	convert(int, startdt) 
	,	RTRIM(LTRIM(convert(char, startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_acct_mgr_hist a
	,	Portfolio b
	,	mars_par_gap..pr_mgr c
	where
		(-1 * a.grpaggrid) = b.PortfolioUid
	AND	b.PortfolioTypeUid = @myType 
	AND	a.mgrid = c.mgrid
	AND	c.mgrtypcd != 'EQ'
	AND a.enddt < @startDateCII
	AND startdt >= @startDateGIG

	INSERT INTO PortfolioActivity
	SELECT
		b.PortfolioUid
	,	a.acctmgraggrid 
	,	convert(int, startdt) 
	,	RTRIM(LTRIM(convert(char, startdt, 107))) 
	,	convert(int, @startDateGIG)
	,	RTRIM(LTRIM(convert(char, @startDateGIG, 107)))
	FROM
		mars_par_gap..pr_acct_mgr_hist a
	,	Portfolio b
	,	mars_par_gap..pr_mgr c
	where
		(-1 * a.grpaggrid) = b.PortfolioUid
	AND	b.PortfolioTypeUid = @myType 
	AND	a.mgrid = c.mgrid
	AND	c.mgrtypcd != 'EQ'
	AND a.enddt >= @startDateCII
	AND startdt >= @startDateGIG

	-- generate CFII Investment Division to every GROUP (so FI Analysts is the trigger)
	PRINT 'Populating Portfolio records for CFII-SuperGroup Relationship Portfolios'
	DECLARE @startDateCFII datetime
	SELECT @startDateCFII = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'CFII')

	DECLARE @min_PortfolioID bigint
	SET @min_PortfolioID = (SELECT MIN(PortfolioUid) FROM Portfolio WHERE PortfolioUid < 0)

	CREATE TABLE #temp_CFII (CFII_PortfolioUid bigint, MARS_aggrid int, Group_aggrid int)

	INSERT INTO #temp_CFII
	SELECT distinct
		(-1 * b.sprgrpaggrid) + @min_PortfolioID, b.sprgrpaggrid,	b.sprgrpaggrid
	FROM
		mars_par_gap..pr_aggr a
	,	mars_par_gap..pr_acct_mgr_hist b
	,	mars_par_gap..pr_grp c
	WHERE
		a.aggrtypcd = 'SG'
	and a.aggrid = b.grpaggrid 
	and b.mgrid in (select mgrid from mars_par_gap..pr_mgr where mgrtypcd = 'FI') -- this makes sure we pick only RP's with FI Analysts
	and b.grpaggrid = c.aggrid
	and c.sprgrpind = 'Y'
	and a.enddt >= @startDateCFII

	insert into Portfolio
	select distinct
		a.CFII_PortfolioUid
	,	'GROUP '+RTRIM(LTRIM(c.grpnum))+'-CFII' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, dbo.get_LaterDate(b.startdt,@startDateCFII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(b.startdt,@startDateCFII), 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_CFII a
	,	mars_par_gap..pr_grp c
	where
		a.MARS_aggrid = c.aggrid
	and c.aggrid = a.Group_aggrid
	and b.aggrid = c.aggrid
	
	PRINT 'Populating PortfolioActivity records for CFII-SuperGroup Relationship Portfolios'

	INSERT INTO PortfolioActivity
	SELECT DISTINCT
		d.CFII_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, dbo.get_LaterDate(a.startdt,@startDateCFII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(a.startdt,@startDateCFII), 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	mars_par_gap..pr_acct_mgr_hist b
	,	#temp_CFII d
	where
		a.aggrid = d.MARS_aggrid
	and b.acctmgraggrid = a.mbraggrid
	and b.mgrid in (select mgrid from mars_par_gap..pr_mgr where mgrtypcd = 'FI')


	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL

END

