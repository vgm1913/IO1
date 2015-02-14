use capital_system
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-13-2015
-- Description:	Based on parameters passed populates all Investment DIvision to either RP or PCX portfolios and their activities
-- =============================================
ALTER PROCEDURE pop_Portfolio_INVDIV_RP_or_PCX 
	-- Add the parameters for the stored procedure here
	@cutOffDate datetime
,	@RPflag char(1) = 'R'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL

	DECLARE @PREFIX varchar(4)
	DECLARE @myTypeName varchar(20)
	DECLARE @myType int 
	DECLARE @rp_indicator char(1)
	IF (@RPflag = 'R' or @RPflag = 'r')
	BEGIN
		SET @PREFIX = 'RP '
		SET @myTypeName =  'INVDIV-RP'
		SET @rp_indicator = 'R'
	END
	ELSE
	BEGIN
		SET @PREFIX = 'PCX '
		SET @myTypeName =  'INVDIV-PCX'
		SET @rp_indicator = 'P'
	END
	SET @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = @myTypeName)

	DECLARE @startDateCII datetime, @startDateCFII datetime
	SELECT @startDateCII = (SELECT CONVERT(datetime, a.StartDate) 
		FROM Portfolio a, PortfolioType b
		WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
		AND b.PortfolioTypeAbbr = 'INVESTDIV'
		AND a.PortfolioName like 'CII')

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
		AND a.PortfolioName like 'CFII')

	-- make sure start with a clean slate
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Relationship Portfolios: '+@myTypeName
	PRINT ' Generating CWI '+@PREFIX+'Relationship Portfolios'
	insert into Portfolio
	select distinct
		b.aggrid 
	,	@PREFIX+RTRIM(LTRIM(c.rppcxnum))+'-CWI' 
	,	@myType 
	,	bsecrncyid 
	,	convert(int, b.startdt) 
	,	RTRIM(LTRIM(convert(char, b.startdt, 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_rp_pcx c
	where
		b.enddt >= @cutOffDate
	and b.aggrtypcd = 'GR'
	and b.aggrnm like '%-GRP CWI%'
	and b.aggrid = a.rppcxgrpaggrid
	and a.rppcxaggrid = c.aggrid
	and c.rppcxind = @rp_indicator

	PRINT ' Generating CRGI '+@PREFIX+'Relationship Portfolios'
	insert into Portfolio
	select distinct
		b.aggrid 
	,	@PREFIX+RTRIM(LTRIM(c.rppcxnum))+'-CRGI' 
	,	@myType 
	,	bsecrncyid 
	,	convert(int, b.startdt) 
	,	RTRIM(LTRIM(convert(char, b.startdt, 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_rp_pcx c
	where
		b.enddt >= @cutOffDate
	and b.aggrtypcd = 'GR'
	and aggrnm like '%-GRP CRGI%'
	and b.aggrid = a.rppcxgrpaggrid
	and a.rppcxaggrid = c.aggrid
	and c.rppcxind = @rp_indicator

	PRINT ' Generating U (undefined investment division) to '+@PREFIX+'Relationship Portfolios'
	insert into Portfolio
	select distinct
		b.aggrid 
	,	@PREFIX+RTRIM(LTRIM(c.rppcxnum))+'-U' 
	,	@myType 
	,	bsecrncyid 
	,	convert(int, b.startdt) 
	,	RTRIM(LTRIM(convert(char, b.startdt, 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_rp_pcx c
	where
		b.enddt >= @cutOffDate
	and b.aggrtypcd = 'GR'
	and aggrnm like '%-GRP U%'
	and b.aggrid = a.rppcxgrpaggrid
	and a.rppcxaggrid = c.aggrid
	and c.rppcxind = @rp_indicator

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Inv-Div-RP or PCX Portfolios
	PRINT 'Populating PortfolioActivity records for CWI, CRGI, & U to '+@PREFIX
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myType)
	
	INSERT INTO PortfolioActivity
	SELECT DISTINCT
		b.PortfolioUid
	,	a.mbraggrid									AcctMgmtPortfolioUid
	,	convert(int, a.startdt)						StartDateIdx
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) StartDate
	,	convert(int, a.enddt)						EndDateIdx
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))	EndDate
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	Portfolio b
	where
		a.aggrid = b.PortfolioUid
	AND	b.PortfolioTypeUid = @myType 
	ORDER by b.PortfolioUid, a.mbraggrid

	-- generate CII Investment Division to every RP or PCX that's in a Super Group
	PRINT ' Generating CII '+@PREFIX+'Relationship Portfolios'
	CREATE TABLE #temp_CII (CII_PortfolioUid bigint, MARS_aggrid int, RPPCX_aggrid int)
	
	INSERT INTO #temp_CII
	select distinct
		-1 * a.aggrid, b.rppcxsprgrpaggrid, b.rppcxaggrid
	from
		mars_par_gap..pr_aggr a
	,	mars_par_gap..pr_acct_mgr_hist b
	,	mars_par_gap..pr_rp_pcx c
	where
		a.aggrtypcd = 'GR'
	and a.aggrid = b.rppcxsprgrpaggrid -- this makes sure we pick super groups
	and b.rppcxaggrid = c.aggrid
	and c.rppcxind = @rp_indicator
	AND a.enddt >= @startDateCII

	insert into Portfolio
	select distinct
		CII_PortfolioUid 
	,	@PREFIX+RTRIM(LTRIM(c.rppcxnum))+'-CII' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, dbo.get_LaterDate(b.startdt, @startDateCII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(b.startdt, @startDateCII), 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_CII a
	,	mars_par_gap..pr_rp_pcx c
	where
		a.MARS_aggrid = b.aggrid
	and c.aggrid = a.RPPCX_aggrid

	PRINT 'Populating PortfolioActivity records for CII '+@PREFIX+'Relationship Portfolios'
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT CII_PortfolioUid FROM #temp_CII)
	INSERT INTO PortfolioActivity
	SELECT
		d.CII_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, dbo.get_LaterDate(a.startdt, @startDateCII)) 	-- but for those who started after CII started - just use their start date if it is later
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(a.startdt, @startDateCII), 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	#temp_CII d
	where
		a.aggrid = d.MARS_aggrid

	-- now simulate GIG
	PRINT ' Generating GIG '+@PREFIX+'Relationship Portfolios'
	DECLARE @min_PortfolioID bigint
	SET @min_PortfolioID = (SELECT MIN(PortfolioUid) FROM Portfolio WHERE PortfolioUid < 0)
	CREATE TABLE #temp_GIG (GIG_PortfolioUid bigint, MARS_aggrid int, RPPCX_aggrid int)
	
	INSERT INTO #temp_GIG
	SELECT DISTINCT
		(-1 * b.rppcxsprgrpaggrid) + @min_PortfolioID, b.rppcxsprgrpaggrid,	b.rppcxaggrid
	FROM
		mars_par_gap..pr_aggr a
	,	mars_par_gap..pr_acct_mgr_hist b
	,	mars_par_gap..pr_rp_pcx c
	WHERE
		a.aggrtypcd = 'GR'
	AND a.aggrid = b.rppcxsprgrpaggrid -- this makes sure we pick super groups
	AND b.rppcxaggrid = c.aggrid
	AND b.rppcxaggrid > 0
	AND c.rppcxind = @rp_indicator
	AND b.enddt >= @startDateGIG -- only want those that exist after the start date of GIG
	AND b.startdt < @startDateCII -- and then filter out those that started after CII - GIG does not exist

	INSERT INTO Portfolio
	SELECT DISTINCT
		GIG_PortfolioUid
	,	@PREFIX+RTRIM(LTRIM(c.rppcxnum))+'-GIG' n
	,	@myType t
	,	b.bsecrncyid c
	,	convert(int, dbo.get_LaterDate(b.startdt,@startDateGIG)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(b.startdt,@startDateGIG), 107))) 
	,	convert(int, dbo.get_EarlierDate(b.enddt, @startDateCII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_EarlierDate(b.enddt, @startDateCII), 107))) 
	FROM
		mars_par_gap..pr_aggr b
	,	#temp_GIG a
	,	mars_par_gap..pr_rp_pcx c
	WHERE
		a.MARS_aggrid = b.aggrid
	and c.aggrid = a.RPPCX_aggrid
		
	PRINT 'Populating PortfolioActivity records for GIG '+@PREFIX+'Relationship Portfolios'
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT GIG_PortfolioUid FROM #temp_GIG)
	INSERT INTO PortfolioActivity
	SELECT DISTINCT
		d.GIG_PortfolioUid
	,	a.mbraggrid 
	,	convert(int, dbo.get_LaterDate(a.startdt,@startDateGIG)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(a.startdt,@startDateGIG), 107))) 
	,	convert(int, dbo.get_EarlierDate(a.enddt, @startDateCII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_EarlierDate(a.enddt, @startDateCII), 107))) 
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	#temp_GIG d
	where
		a.aggrid = d.MARS_aggrid

	-- generate CFII Investment Division to every FI RP or PCX (so FI Analysts is the trigger)
	PRINT 'Populating Portfolio records for CFII '+@PREFIX+'Relationship Portfolios'
	SET @min_PortfolioID = (SELECT MIN(PortfolioUid) FROM Portfolio WHERE PortfolioUid < 0)
	CREATE TABLE #temp_CFII (CFII_PortfolioUid bigint, MARS_aggrid int, RPPCX_aggrid int)

	INSERT INTO #temp_CFII
	SELECT distinct
		(-1 * b.rppcxsprgrpaggrid) + @min_PortfolioID, b.rppcxsprgrpaggrid,	b.rppcxaggrid
	FROM
		mars_par_gap..pr_aggr a
	,	mars_par_gap..pr_acct_mgr_hist b
	,	mars_par_gap..pr_rp_pcx c
	WHERE
		a.aggrtypcd = 'RX'
	and a.aggrid = b.rppcxaggrid 
	and b.mgrid in (select mgrid from mars_par_gap..pr_mgr where mgrtypcd = 'FI' and mgrrespcd = 'A') -- this makes sure we pick only RP's with FI Analysts
	and b.rppcxaggrid = c.aggrid
	and c.rppcxind = @rp_indicator
	and a.enddt >= @startDateCFII

	insert into Portfolio
	select distinct
		a.CFII_PortfolioUid
	,	@PREFIX+RTRIM(LTRIM(c.rppcxnum))+	'-CFII' 
	,	@myType 
	,	b.bsecrncyid 
	,	convert(int, dbo.get_LaterDate(b.startdt,@startDateCFII)) 
	,	RTRIM(LTRIM(convert(char, dbo.get_LaterDate(b.startdt,@startDateCFII), 107))) 
	,	convert(int, b.enddt) 
	,	RTRIM(LTRIM(convert(char, b.enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	,	#temp_CFII a
	,	mars_par_gap..pr_rp_pcx c
	where
		a.MARS_aggrid = c.aggrid
	and c.aggrid = a.RPPCX_aggrid
	
	PRINT 'Populating PortfolioActivity records for CFII '+@PREFIX+'Relationship Portfolios'
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT CFII_PortfolioUid FROM #temp_CFII)
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

	-- clean up
	DROP TABLE #temp_CII
	DROP TABLE #temp_CFII
	DROP TABLE #temp_GIG

	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL
END
GO
