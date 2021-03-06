USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_MGR]    Script Date: 2/4/2015 6:57:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	populate Management Responsibility based Portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_MGR]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	ALTER TABLE InvestmentProfessional NOCHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibilityType NOCHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibilityAssetClassCategory NOCHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibility_MARS_xref NOCHECK CONSTRAINT ALL
	--ALTER TABLE ManagementResponsibility DROP CONSTRAINT [FK_ManagementResponsibility_InvestmentProfessional]
	--ALTER TABLE ManagementResponsibility DROP CONSTRAINT [FK_ManagementResponsibility_ManagementResponsibilityAssetClassCategory]
	ALTER TABLE ManagementResponsibility NOCHECK CONSTRAINT ALL

	DECLARE @myPortfolioTypeUid int
	SELECT @myPortfolioTypeUid = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'MGR')
	-- first create the portfolio records
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myPortfolioTypeUid
	DELETE FROM InvestmentProfessional
	DELETE FROM ManagementResponsibilityType
	DELETE FROM ManagementResponsibilityAssetClassCategory
	DELETE FROM ManagementResponsibility

	PRINT 'populate Entity Portfolios: Management Responsibilities'
	create table #portfolio (
		PortfolioID	int
	,	mgrinit char(8)
	,	mgrnum	char(4)
	,	startdt	datetime
	,	enddt	datetime)

	insert into #portfolio
	select distinct
		a.aggrid 
	,	a.mgrinit
	,	a.mgrnum
	,	b.startdt
	,	b.enddt
	from
		mars_par_gap..pr_mgr a
	,	mars_par_gap..pr_aggr b
	where
		a.aggrid = b.aggrid
	and	b.aggrtypcd = 'MG'
	and	b.enddt >= @cutOffDate
	order by a.mgrinit, a.mgrnum, a.aggrid

	-- now that we got all MARS Managers captured - time to remove the effect of accounting company number
	create table #mgr_resp (
		mgrinit char(8)
	,	mgrnum	char(4)
	,	port_id	int)
	create table #mgr_resp_start (
		mgrinit char(8)
	,	mgrnum	char(4)
	,	startdt	datetime)
	create table #mgr_resp_end (
		mgrinit char(8)
	,	mgrnum	char(4)
	,	enddt	datetime)

	create index portfolio0 on #portfolio (mgrinit, mgrnum, PortfolioId)

	insert into #mgr_resp
	select a.mgrinit, a.mgrnum, min(b.PortfolioId)
	from mars_par_gap..pr_mgr a, #portfolio b, mars_par_gap..pr_aggr c
	where b.PortfolioID = a.aggrid
	-- and a.mgrnum not in ('8884', '4501', '3988') -- to fix bad data in MARS
	group by a.mgrinit, a.mgrnum

	insert into #mgr_resp_start
	select a.mgrinit, a.mgrnum, min(b.startdt)
	from mars_par_gap..pr_mgr a, #portfolio b, mars_par_gap..pr_aggr c
	where b.PortfolioID = a.aggrid
	-- and a.mgrnum not in ('8884', '4501', '3988') -- to fix bad data in MARS
	group by a.mgrinit, a.mgrnum

	insert into #mgr_resp_end
	select a.mgrinit, a.mgrnum, max(b.enddt)
	from mars_par_gap..pr_mgr a, #portfolio b, mars_par_gap..pr_aggr c
	where b.PortfolioID = a.aggrid
	group by a.mgrinit, a.mgrnum

	-- store MARS mgrid from pr_mgr into a xref table with new ManagementResponsibility IDs that eliminate the effect of co_num
	DELETE FROM ManagementResponsibility_MARS_xref

	INSERT INTO ManagementResponsibility_MARS_xref
	select distinct a.port_id, b.aggrid, b.mgrinit, b.mgrnum
	from #mgr_resp a, mars_par_gap..pr_mgr b
	where a.mgrinit = b.mgrinit
	and a.mgrnum = b.mgrnum

	-- now create Portfolio records - one per ManagementRespobsibility number
	insert into Portfolio
	select distinct
		a.port_id
	,	RTRIM(LTRIM(a.mgrinit))+' '+RTRIM(LTRIM(a.mgrnum))
	,	2 
	,	1 -- set to default to USD
	,	CONVERT(int, b.startdt)
	,	RTRIM(LTRIM(CONVERT(varchar, b.startdt, 107)))
	,	CONVERT(int, c.enddt) 
	,	RTRIM(LTRIM(CONVERT(varchar, c.enddt, 107)))
	from
		#mgr_resp a
	,	#mgr_resp_start b
	,	#mgr_resp_end c
	where
		enddt >= @cutOffDate
	and a.mgrinit = b.mgrinit
	and a.mgrnum = b.mgrnum
	and a.mgrinit = c.mgrinit
	and a.mgrnum = c.mgrnum
	and b.mgrinit = c.mgrinit
	and c.mgrnum = b.mgrnum

	-- create InvestmentProfessional from cmps design study DB
	INSERT INTO InvestmentProfessional
	select
		InvestorID InvestorUid			
	,	InvestorAbbr
	,	IndividualFlag
	,	TestFlag
	,	InvestorDescription
	,	EmployeeID
	FROM
		cmps..InvestmentProfessional

	-- create the default role - ID = 0
	INSERT INTO InvestmentProfessional
	VALUES (0,	'UNDEF', 'N', 'N', 'Not Defined or N/A', null)

	-- create ManagementResponsibilityType table from cmps design study DB (code table)
	INSERT INTO ManagementResponsibilityType
	SELECT MgmtRespTypeID, MgmtRespTypeCode, MgmtRespSubTypeCode, MgmtRespTypeDescription, MARS_acctmgrtypcd MgmtRespRoleCode
	FROM cmps..ManagementResponsibilityType

	-- create ManagementResponsibilityAssetClassCategory table from cmps design study DB (code table)
	INSERT INTO ManagementResponsibilityAssetClassCategory
	SELECT * FROM cmps..MgmtRespAssetClassCategory

	-- create ManagementResponsibility table using the PortfolioID setup in #portfolio and MARS pr_mgr table 
	INSERT INTO ManagementResponsibility
	SELECT DISTINCT
		p.port_id	PortfolioUid
	,	m.mgrnum	ManagementNumber	
	,	m.mgrinit	ManagementAbbr
	,	m.mgrnm		ManagementDescription
	,	0			MgmtRespAssetClassID
	,	0			InvestorUid			
	,	0			MgmtRespTypeID
	FROM
		#mgr_resp p
	,	mars_par_gap..pr_mgr m
	WHERE
		p.mgrinit = m.mgrinit
	AND p.mgrnum = m.mgrnum

	UPDATE ManagementResponsibility
	SET InvestorUid = i.InvestorUid
	FROM ManagementResponsibility a, InvestmentProfessional i
	WHERE i.InvestorAbbr = a.ManagementAbbr

	UPDATE ManagementResponsibility
	SET MgmtRespAssetClassID = d.MgmtRespAssetClassID
	FROM ManagementResponsibility a, ManagementResponsibilityAssetClassCategory d, mars_par_gap..pr_mgr m
	WHERE m.mgrtypcd = d.MgmtRespAssetClassCode
	AND	a.ManagementAbbr = m.mgrinit
	AND a.ManagementNumber = m.mgrnum

	UPDATE ManagementResponsibility
	SET MgmtRespTypeID = d.MgmtRespTypeID
	FROM ManagementResponsibility a, ManagementResponsibilityType d, mars_par_gap..pr_mgr m
	WHERE m.mgrrespcd = d.MgmtRespRoleCode
	AND	a.ManagementAbbr = m.mgrinit
	AND a.ManagementNumber = m.mgrnum

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the ManagementResponsibility Portfolio (active A-M's in a MgmtResp Portfolio)
	DELETE FROM PortfolioActivity WHERE PortfolioUid in (SELECT PortfolioUid FROM Portfolio WHERE PortfolioTypeUid = @myPortfolioTypeUid)

	INSERT INTO PortfolioActivity
	SELECT distinct
		MgmtRespPortfolioUid
	,	a.mbraggrid 
	,	convert(int, a.startdt) 
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	FROM
		mars_par_gap..pr_aggr_mbr a
	,	ManagementResponsibility_MARS_xref c
	where
		a.aggrid = c.MARS_mgraggrid

	-- clean up & finish
	DROP TABLE #portfolio
	DROP TABLE #mgr_resp

	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibility CHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibilityAssetClassCategory CHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibility_MARS_xref CHECK CONSTRAINT ALL
	ALTER TABLE InvestmentProfessional CHECK CONSTRAINT ALL
END

