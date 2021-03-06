USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_MGR]    Script Date: 1/25/2015 11:10:05 PM ******/
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

	DELETE FROM Portfolio WHERE PortfolioTypeUid = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'MGR')

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
	create table #mgr_port_xref (
		PortfolioID	int
	,	MgrPortfolioID int
	,	MgrInit char(8)
	,	MgrNum	char(4))

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

	-- and a.mgrnum in ('8884', '4501', '3988') -- to fix bad data in MARS
	
	insert into #mgr_port_xref
	select distinct a.port_id, b.aggrid, b.mgrinit, b.mgrnum
	from #mgr_resp a, mars_par_gap..pr_mgr b
	where a.mgrinit = b.mgrinit
	and a.mgrnum = b.mgrnum

	select * from #mgr_resp
	select * from #mgr_port_xref

	insert into Portfolio
	select distinct
		a.port_id
	,	RTRIM(LTRIM(a.mgrinit))+' '+RTRIM(LTRIM(a.mgrnum))
	,	2 
	,	1 
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

	drop table #mgr_port_xref
	drop table #portfolio
	drop table #mgr_resp
END

