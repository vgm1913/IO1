USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_RP]    Script Date: 1/30/2015 3:11:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate RP based Portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_RP] 
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	ALTER TABLE RP NOCHECK CONSTRAINT ALL
	--ALTER TABLE RP DROP CONSTRAINT FK_RP_Portfolio

	DECLARE @myType int
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP')

	-- make sure we clean up RP table first
	DELETE FROM RP

	-- now capture the RP records out of MARS pr_rp_pcx table
	INSERT INTO RP
	SELECT
		aggrid
	,	rppcxnum
	,	rppcxnm
	,	rppcxind
	,	resptypcd
	FROM
		mars_par_gap..pr_rp_pcx
	WHERE
		rppcxind != 'P'

	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Entity Portfolios: Research Portfolios'
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
	and b.aggrid in (select aggrid from mars_par_gap..pr_rp_pcx where rppcxind = 'R')

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the RP Portfolios
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
	ALTER TABLE RP CHECK CONSTRAINT ALL

END

