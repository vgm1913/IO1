USE [cmps_2]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_RP_MGR]    Script Date: 1/21/2015 10:08:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate RP - Mgmt Resp based Portfolios 
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_RP_MGR]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL

	DECLARE @myType int 
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP-MGR')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Relationship Portfolios: RP-MGR'
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
	and b.aggrtypcd = 'RM'
	and b.aggrnm not like '% PCX%'

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the RP-MgmtResp Portfolios
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
