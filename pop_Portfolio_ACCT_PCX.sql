USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_ACCT_PCX]    Script Date: 1/30/2015 5:38:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate RP in Account based Portfolios 
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_ACCT_PCX]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL

	DECLARE @myType int

	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-PCX')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Relationship Portfolios: ACCT-PCX'
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
		enddt >= @cutOffDate
	and b.aggrtypcd = 'AR'
	and b.aggrid in (select rppcxacctaggrid from mars_par_gap..pr_acct_mgr_hist where rppcxaggrid in (select aggrid from mars_par_gap..pr_rp_pcx where rppcxind = 'P'))

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Account-PCX Portfolios
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

	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
END
