USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_ACCT]    Script Date: 2/11/2015 2:14:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	populate Account based Portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_ACCT]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL 
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	ALTER TABLE Account NOCHECK CONSTRAINT ALL
	
	DECLARE @myPortfolioTypeUid int
	SELECT @myPortfolioTypeUid = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT')
	-- first create the portfolio records
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myPortfolioTypeUid

	PRINT 'populate Account reference table'
	DROP INDEX Account.Account1
	DROP INDEX Account.Account2
	DROP INDEX Account.Account3

	DELETE FROM Account

	INSERT INTO Account
	SELECT
		CONVERT(bigint, aggrid)	PortfolioUid
	,	conum					AccountingCompanyNumber
	,	acctminornum			AccountNumber
	,	acctdivsn				AccountType
	,	acctshortnm				AccountName
	,	acctabbr				AccountAbbrName
	,	bsecrncyid				AccountBaseCurrency
	,	acctlegalnm1			AccountLegalName
	,	fiscalyrend				AccountFiscalMonthYear
	,	convert(date,incpdt)	AccountInceptionDate
	,	convert(date,termdt)	AccountTerminationDate
	FROM
		mars_par_gap..pr_account

	create index Account1 on Account(AccountName, PortfolioUid)
	create index Account2 on Account(AccountAbbrName, PortfolioUid)
	create index Account3 on Account(AccountNumber, PortfolioUid)
	
	PRINT 'populate Entity Portfolios: Accounts'
	INSERT INTO Portfolio
	select distinct
		aggrid 
	,	aggrnm 
	,	@myPortfolioTypeUid
	,	bsecrncyid 
	,	convert(int, startdt) 
	,	RTRIM(LTRIM(convert(char, startdt, 107))) 
	,	convert(int, enddt) 
	,	RTRIM(LTRIM(convert(char, enddt, 107))) 
	from
		mars_par_gap..pr_aggr b
	where
		enddt >= @cutOffDate
	and aggrtypcd = 'AA'

	-- final stage - Populate PortfolioAssociation table with all Account to other Portfolio
	CREATE TABLE #temp_AcctAssoc (
		acctaggrid	int
	,	otheraggrid int
	,	startdt		datetime
	,	enddt		datetime
	)

	-- Account to RP
	INSERT INTO #temp_AcctAssoc
	SELECT
		acctaggrid
	,	rppcxaggrid
	,	min(startdt) 
	,	max(enddt) 
	FROM
		mars_par_gap..pr_acct_mgr_hist
	WHERE 
		rppcxaggrid IN (select aggrid from mars_par_gap..pr_rp_pcx where rppcxind != 'P')
	AND rppcxacctaggrid > 0
	AND acctaggrid in (select PortfolioUid from Portfolio where PortfolioTypeUid = @myPortfolioTypeUid)
	GROUP BY
		acctaggrid, rppcxaggrid

	-- Account to PCX
	INSERT INTO #temp_AcctAssoc
	SELECT
		acctaggrid
	,	rppcxaggrid
	,	min(startdt) 
	,	max(enddt) 
	FROM
		mars_par_gap..pr_acct_mgr_hist
	WHERE 
		rppcxaggrid IN (select aggrid from mars_par_gap..pr_rp_pcx where rppcxind = 'P')
	AND rppcxacctaggrid > 0
	AND acctaggrid in (select PortfolioUid from Portfolio where PortfolioTypeUid = @myPortfolioTypeUid)
	GROUP BY
		acctaggrid, rppcxaggrid

	-- Account to GroupMandate
	INSERT INTO #temp_AcctAssoc
	SELECT 
		acctaggrid
	,	grpaggrid
	,	min(startdt) 
	,	max(enddt) 
	FROM
		mars_par_gap..pr_acct_mgr_hist
	WHERE 
		grpaggrid IN (select aggrid from mars_par_gap..pr_grp where sprgrpind != 'S' and grpnum not in('CWI', 'CRGI', 'U'))
	AND grpaggrid > 0
	AND acctaggrid in (select PortfolioUid from Portfolio where PortfolioTypeUid = @myPortfolioTypeUid)
	GROUP BY
		acctaggrid, grpaggrid

	-- Account to SuperGroupMandate
	INSERT INTO #temp_AcctAssoc
	SELECT
		acctaggrid
	,	sprgrpaggrid
	,	min(startdt) 
	,	max(enddt) 
	FROM
		mars_par_gap..pr_acct_mgr_hist
	WHERE 
		sprgrpaggrid IN (select aggrid from mars_par_gap..pr_grp where sprgrpind = 'S')
	AND sprgrpaggrid > 0
	AND acctaggrid in (select PortfolioUid from Portfolio where PortfolioTypeUid = @myPortfolioTypeUid)
	GROUP BY
		acctaggrid, sprgrpaggrid

	-- Account to Investment Division
	INSERT INTO #temp_AcctAssoc
	SELECT
		acctaggrid
	,	grpaggrid
	,	min(startdt) 
	,	max(enddt) 
	FROM
		mars_par_gap..pr_acct_mgr_hist
	WHERE 
		grpaggrid IN (select aggrid from mars_par_gap..pr_grp where sprgrpind != 'S' and grpnum in('CWI', 'CRGI', 'U'))
	AND grpaggrid > 0
	AND acctaggrid in (select PortfolioUid from Portfolio where PortfolioTypeUid = @myPortfolioTypeUid)
	GROUP BY
		acctaggrid, grpaggrid

	-- TODO: this is a hack for now the unique ID generator is not created for this IO1 sprint challenge DB
	DECLARE @CII_port_id int, @startDateCII datetime
	SELECT @startDateCII = (SELECT '01/01/2010')
	select @CII_port_id = (SELECT min(aggrid) from mars_par_gap..pr_aggr) - 1
	INSERT INTO #temp_AcctAssoc
	SELECT
		a.acctaggrid
	,	@CII_port_id
	,	min(a.startdt) 
	,	max(a.enddt) 
	FROM
		mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_mgr c
	where
		c.mgrid = a.mgrid
	and c.mgrtypcd = 'EQ'
	and a.grpaggrid in (select aggrid from mars_par_gap..pr_grp where grpnum not in ('CWI', 'CRGI', 'U') and sprgrpind != 'S')
	and a.grpaggrid > 0
	and a.enddt >= @startDateCII
	GROUP BY
		a.acctaggrid
	-- make sure we do not setup any Account to CII relationship that's earlier than when CII division went live
	UPDATE #temp_AcctAssoc
	SET startdt = @startDateCII
	WHERE otheraggrid = @CII_port_id
	AND startdt < @startDateCII

	-- TODO: this is a hack for now the unique ID generator is not created for this IO1 sprint challenge DB
	-- create the Account to CFII associations based on FI managers that are not grouped
	-- for CFII - make the assumption for the start date to be the same as CWI
	DECLARE @CFII_port_id int, @startDateCFII datetime
	SELECT @startDateCFII = (select convert(date, startdt) from mars_par_gap..pr_aggr where aggrid in (select aggrid from mars_par_gap..pr_grp where grpnum = 'CWI'))
	select @CFII_port_id = (SELECT @CII_port_id - 1)
	INSERT INTO #temp_AcctAssoc
	SELECT
		a.acctaggrid
	,	@CFII_port_id
	,	min(a.startdt) 
	,	max(a.enddt) 
	FROM
		mars_par_gap..pr_acct_mgr_hist a
	,	mars_par_gap..pr_mgr c
	where
		c.mgrid = a.mgrid
	and c.mgrtypcd = 'FI'
	and a.grpaggrid < 0
	and a.enddt >= @startDateCFII
	GROUP BY
		a.acctaggrid

	-- make sure we do not setup any Account to CFII relationship that's earlier than when CFII division went live
	UPDATE #temp_AcctAssoc
	SET startdt = @startDateCFII
	WHERE otheraggrid = @CFII_port_id
	AND startdt < @startDateCFII

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Account Portfolios
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myPortfolioTypeUid)

	INSERT INTO PortfolioActivity
	SELECT DISTINCT
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
	AND	b.PortfolioTypeUid = @myPortfolioTypeUid 

	-- final step - cleanup
	DROP TABLE #temp_AcctAssoc

	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL
	ALTER TABLE Account CHECK CONSTRAINT ALL

END

