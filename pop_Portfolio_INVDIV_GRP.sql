USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_INVDIV_GRP]    Script Date: 2/14/2015 9:48:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Investment Division to Group - only a CII concept portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_INVDIV_GRP]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	--ALTER TABLE PortfolioAssociation DROP CONSTRAINT [FK_PortfolioAssociation_Portfolio1]

	DECLARE @myType int 
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-GRP')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Relationship Portfolios: INVDIV-GRP'

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

	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-GRP')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType
	-- first handle CII
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
	where aggrtypcd = 'GP'
	and startdt <= @startDateCII
	and enddt > @startDateCII
	and aggrnm not like '%P S%'
	and aggrnm not like '%P CWI'
	and aggrnm not like '%P CRGI'
	and aggrnm not like '%P U'

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
	where aggrtypcd = 'GP'
	and startdt <= @startDateGIG
	and enddt > @startDateCII
	and aggrnm not like '%P S%'
	and aggrnm not like '%P CWI'
	and aggrnm not like '%P CRGI'
	and aggrnm not like '%P U'
	
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
	where aggrtypcd = 'GP'
	and startdt <= @startDateGIG
	and enddt <= @startDateCII
	and aggrnm not like '%P S%'
	and aggrnm not like '%P CWI'
	and aggrnm not like '%P CRGI'
	and aggrnm not like '%P U'

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Inv-Div-Group Portfolios
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
	AND	c.mgrtypcd = 'EQ'
	AND a.enddt >= @startDateCII

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
		((-1 * a.grpaggrid) + @min_CII_PortfolioID) = b.PortfolioUid
	AND	b.PortfolioTypeUid = @myType 
	AND	a.mgrid = c.mgrid
	AND	c.mgrtypcd = 'EQ'
	AND a.enddt > @startDateGIG
	AND a.startdt <= @startDateGIG

	INSERT INTO PortfolioActivity
	SELECT
		b.PortfolioUid
	,	a.acctmgraggrid 
	,	convert(int, startdt)
	,	RTRIM(LTRIM(convert(char, startdt, 107)))
	,	convert(int, enddt)
	,	RTRIM(LTRIM(convert(char, enddt, 107)))
	FROM
		mars_par_gap..pr_acct_mgr_hist a
	,	Portfolio b
	,	mars_par_gap..pr_mgr c
	where
		((-1 * a.grpaggrid) + @min_CII_PortfolioID) = b.PortfolioUid
	AND	b.PortfolioTypeUid = @myType 
	AND	a.mgrid = c.mgrid
	AND	c.mgrtypcd = 'EQ'
	AND a.enddt <= @startDateGIG
	AND a.startdt <= @startDateGIG

	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL

END

