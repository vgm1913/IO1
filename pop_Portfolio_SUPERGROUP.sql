USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_SUPERGROUP]    Script Date: 1/29/2015 9:44:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Super Group based Portfolios
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_SUPERGROUP] 
	@cutOffDate datetime
AS
BEGIN
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE SuperGroupMandate NOCHECK CONSTRAINT ALL
	ALTER TABLE SuperGroupMembers NOCHECK CONSTRAINT ALL
	ALTER TABLE GroupMandate NOCHECK CONSTRAINT ALL

	DECLARE @myType int
	SELECT @myType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SUPERGROUP')
	DELETE FROM Portfolio WHERE PortfolioTypeUid = @myType

	PRINT 'populate SuperGroupMandate Reference Table'
	DROP INDEX SuperGroupMandate.SuperGroup1
	DROP INDEX SuperGroupMandate.SuperGroup2
	DROP INDEX SuperGroupMandate.SuperGroup3

	DELETE FROM SuperGroupMandate

	INSERT INTO SuperGroupMandate
	SELECT 
		CONVERT(bigint, aggrid)	PortfolioUid
	,	grpnum					SuperGroupCode
	,	grpnm					SuperGroupName
	,	grpshrtnm				SuperGroupAbbrName
	FROM
		mars_par_gap..pr_grp
	WHERE
		sprgrpind = 'Y'

	UPDATE SuperGroupMandate
	SET SuperGroupAbbrName = 'GRP '+SuperGroupCode, SuperGroupName = 'Group '+SuperGroupCode
	WHERE RTRIM(SuperGroupAbbrName) = ''

	CREATE INDEX SuperGroup1 on SuperGroupMandate(SuperGroupCode, PortfolioUid)
	CREATE INDEX SuperGroup2 on SuperGroupMandate(SuperGroupName, PortfolioUid)
	CREATE INDEX SuperGroup3 on SuperGroupMandate(SuperGroupAbbrName, PortfolioUid)

	DELETE FROM SuperGroupMembers
	INSERT INTO	SuperGroupMembers
	SELECT 
		CONVERT(bigint, aggrid)	PortfolioUid
	,	CONVERT(bigint, mbrid)	ChildPortfolioUid
	,	CONVERT(int, startdt)	StartDateIdx
	,	RTRIM(LTRIM(convert(char, startdt, 107))) StartDate
	,	CONVERT(int, enddt)		EndDateIdx
	,	RTRIM(LTRIM(convert(char, enddt, 107))) EndDate
	from
		mars_par_gap..pr_supgrp_mbr a
	,	mars_par_gap..pr_grp b
	WHERE
		a.grpid = b.grpid

	PRINT 'populate Entity Portfolios: SuperGroups - CII only'
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
	and b.aggrtypcd = 'SG'

	-- now populate the ACCT-MGR portfolios that are aggregated together to form the SuperGroup Portfolios
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
	ALTER TABLE SuperGroupMandate CHECK CONSTRAINT ALL
	ALTER TABLE SuperGroupMembers CHECK CONSTRAINT ALL

END

