USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_GROUP]    Script Date: 2/11/2015 11:25:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Group based Portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_GROUP] 
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	ALTER TABLE GroupMandate NOCHECK CONSTRAINT ALL
	--ALTER TABLE PortfolioAssociation DROP CONSTRAINT [FK_PortfolioAssociation_Portfolio1]

	DECLARE @myType int
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate GroupMandate Reference Table'
	DROP INDEX GroupMandate.Group1
	DROP INDEX GroupMandate.Group2
	DROP INDEX GroupMandate.Group3

	DELETE FROM GroupMandate

	INSERT INTO GroupMandate
	SELECT 
		CONVERT(bigint, aggrid)	PortfolioUid
	,	grpnum					GroupCode
	,	grpnm					GroupName
	,	grpshrtnm				GroupAbbrName
	FROM
		mars_par_gap..pr_grp
	WHERE
		sprgrpind != 'Y'
	and	grpnum not in ('CWI', 'CRGI', 'U')

	UPDATE GroupMandate
	SET GroupAbbrName = 'GRP '+GroupCode, GroupName = 'Group '+GroupCode
	WHERE RTRIM(GroupAbbrName) = ''
	
	create index Group1 on GroupMandate(GroupCode, PortfolioUid)
	create index Group2 on GroupMandate(GroupName, PortfolioUid)
	create index Group3 on GroupMandate(GroupAbbrName, PortfolioUid)
	
	PRINT 'populate Entity Portfolios: Groups - CII only'
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
	and b.aggrtypcd = 'GP'
	and b.aggrid in (select aggrid from mars_par_gap..pr_grp where grpnum not in ('CWI', 'CRGI', 'U'))

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the Group Portfolios
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
	ALTER TABLE GroupMandate CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL
END

