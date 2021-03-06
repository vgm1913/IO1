USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_ACCT_MGR]    Script Date: 2/7/2015 8:35:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Account - Mgmt Resp based Portfolios - lowest level portfolios of Capital System
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_ACCT_MGR]
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL

	DECLARE @myType int
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-MGR')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate Relationship Portfolios: ACCT-MGR'
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
	and b.aggrtypcd = 'AM'

	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioRelationship CHECK CONSTRAINT ALL
END

