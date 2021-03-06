USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_PCX]    Script Date: 2/4/2015 6:58:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Mgmt Resp Rollups (PCX) based Portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_PCX]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PCX_ManagementResponsibilityRollup NOCHECK CONSTRAINT ALL
	ALTER TABLE RP NOCHECK CONSTRAINT ALL
	
	DECLARE @myType int 
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'PCX')

	-- make sure we clean up RP table first
	DELETE FROM PCX_ManagementResponsibilityRollup
	-- now capture the RP records out of MARS pr_rp_pcx table
	INSERT INTO PCX_ManagementResponsibilityRollup
	SELECT
		aggrid		PortfolioUid
	,	rppcxnum	PCXNumber
	,	rppcxnm		PCXName
	,	resptypcd	PCXType
	FROM
		mars_par_gap..pr_rp_pcx
	WHERE
		rppcxind = 'P'

	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Entity Portfolios: Mgmt Resp Roll-ups (PCX) portfolio type id: '+CONVERT(CHAR,@myType)
	insert into Portfolio
	select distinct
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
	and b.aggrtypcd = 'RX'
	and b.aggrid in (select aggrid from mars_par_gap..pr_rp_pcx where rppcxind != 'R')

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the PCX Portfolios
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
	ALTER TABLE PCX_ManagementResponsibilityRollup CHECK CONSTRAINT ALL
	ALTER TABLE RP CHECK CONSTRAINT ALL
	
END

