USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[CS_GetSuperGroupAssociations]    Script Date: 2/11/2015 6:23:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-11-2015
-- Description:	Gets Portfolios Associated to a SuperGroup Portfolio
-- Parameters:	PORT_ID		(must be a valid PortfolioUid - if not procedures returns nothing)
--				A_PORT_TYPE (0|or a valid portfolio Type) Pass 0 for all Portfolios, Pass a valid PortfolioTypeUid for just Portfolios of that type
--				JSON Flag   (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE [dbo].[CS_GetSuperGroupAssociations] 
	@SUPERGROUP_PORT_ID bigint = 0
,	@AS_OF_DATE datetime = NULL
,	@A_PORT_TYPE int = 0
,	@JSON int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	CREATE TABLE #myPortTypes (SelectedPortfolioTypeUid int)
	CREATE TABLE #assocPortfolios (AssocPortfolioUid bigint)
	CREATE TABLE #periods (StartDateIdx int, EndDateIdx int, StartDate varchar(20), EndDate varchar(20))
	CREATE TABLE #assocRelationshipPortfolios (AssocPortfolioUid bigint)

	DECLARE @SUPERGROUP_TYPE_ID int
	
	SET @SUPERGROUP_TYPE_ID = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SUPERGROUP')
	IF (@SUPERGROUP_PORT_ID = 0)	-- user passed nothing
	BEGIN
		PRINT 'usage: CG_GetSuperGroupAssociations @SUPERGROUP_PORT_ID bigint, [, @AS_OF_DATE date ] [, @A_PORT_TYPE int] [, @JSON int ]'
		GOTO Branch_EXIT
	END
	IF (@AS_OF_DATE IS NOT NULL)
		INSERT INTO #periods
		SELECT DISTINCT StartDateIdx, EndDateIdx, StartDate, EndDate FROM PortfolioAssociation a
		WHERE a.StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND a.EndDateIdx > CONVERT(int, @AS_OF_DATE)
		AND a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
	ELSE
		INSERT INTO #periods
		SELECT DISTINCT StartDateIdx, EndDateIdx, StartDate, EndDate FROM PortfolioAssociation a
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
	
	IF (@A_PORT_TYPE = 0)
		INSERT INTO #myPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeUid != @SUPERGROUP_TYPE_ID
	ELSE
		INSERT INTO #myPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeUid = @A_PORT_TYPE AND PortfolioTypeUid != @SUPERGROUP_TYPE_ID

	IF (SELECT COUNT(*) FROM #myPortTypes) = 0
	BEGIN
		PRINT 'usage: CS_GetPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		PRINT '@A_PORT_TYPE='+RTRIM(CONVERT(CHAR, @A_PORT_TYPE))+' must be a valid EntityType or zero for all associated Portfolio'
		GOTO Branch_EXIT
	END
	
	IF (@@ERROR = 0)	-- make sure no errors occured
	BEGIN
		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.AcctPortfolioUid
		FROM PortfolioAssociation a, #periods b, Portfolio c, #myPortTypes d
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND a.StartDateIdx = b.StartDateIdx
		AND a.EndDateIdx = b.EndDateIdx
		AND c.PortfolioUid = AcctPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.MgmrRespPortfolioUid
		FROM PortfolioAssociation a, #periods b, Portfolio c, #myPortTypes d
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND a.StartDateIdx = b.StartDateIdx
		AND a.EndDateIdx = b.EndDateIdx
		AND c.PortfolioUid = MgmrRespPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.RPPortfolioUid
		FROM PortfolioAssociation a, #periods b, Portfolio c, #myPortTypes d
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND a.StartDateIdx = b.StartDateIdx
		AND a.EndDateIdx = b.EndDateIdx
		AND c.PortfolioUid = RPPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.PCXPortfolioUid
		FROM PortfolioAssociation a, #periods b, Portfolio c, #myPortTypes d
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND a.StartDateIdx = b.StartDateIdx
		AND a.EndDateIdx = b.EndDateIdx
		AND c.PortfolioUid = a.PCXPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.GroupPortfolioUid
		FROM PortfolioAssociation a, #periods b, Portfolio c, #myPortTypes d
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND a.StartDateIdx = b.StartDateIdx
		AND a.EndDateIdx = b.EndDateIdx
		AND c.PortfolioUid = a.GroupPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.InvestDivPortfolioUid
		FROM PortfolioAssociation a, #periods b, Portfolio c, #myPortTypes d
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND a.StartDateIdx = b.StartDateIdx
		AND a.EndDateIdx = b.EndDateIdx
		AND c.PortfolioUid = a.InvestDivPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			a.AcctMgmtPortfolioUid
		FROM PortfolioAssociation a, #periods b, Portfolio c, #myPortTypes d
		WHERE a.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND a.StartDateIdx = b.StartDateIdx
		AND a.EndDateIdx = b.EndDateIdx
		AND c.PortfolioUid = a.AcctMgmtPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			a.RelationshipPortfolioUid
		FROM PortfolioRelationship a, #assocPortfolios b, #periods c, #myPortTypes d, PortfolioAssociation e
		WHERE 
			a.PortfolioBUid = @SUPERGROUP_PORT_ID
		AND a.PortfolioBUid = e.SuperGroupPortfolioUid
		AND a.PortfolioAUid = b.AssocPortfolioUid
		AND a.PortfolioATypeUid = d.SelectedPortfolioTypeUid
		AND e.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND e.StartDateIdx = c.StartDateIdx
		AND e.EndDateIdx = c.EndDateIdx
		AND (e.AcctPortfolioUid = a.PortfolioAUid
		OR	e.MgmrRespPortfolioUid = a.PortfolioAUid
		OR	e.GroupPortfolioUid = a.PortfolioAUid
		OR	e.RPPortfolioUid = a.PortfolioAUid
		OR	e.PCXPortfolioUid = a.PortfolioAUid)

		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			a.RelationshipPortfolioUid
		FROM PortfolioRelationship a, #assocPortfolios b, #periods c, #myPortTypes d, PortfolioAssociation e
		WHERE 
			a.PortfolioAUid = @SUPERGROUP_PORT_ID
		AND a.PortfolioAUid = e.SuperGroupPortfolioUid
		AND a.PortfolioBUid = b.AssocPortfolioUid
		AND a.PortfolioBTypeUid = d.SelectedPortfolioTypeUid
		AND e.SuperGroupPortfolioUid = @SUPERGROUP_PORT_ID
		AND e.StartDateIdx = c.StartDateIdx
		AND e.EndDateIdx = c.EndDateIdx
		AND e.InvestDivPortfolioUid = a.PortfolioBUid

		INSERT INTO #assocPortfolios
		SELECT AssocPortfolioUid FROM #assocRelationshipPortfolios

		IF (@JSON = 0)
				SELECT	DISTINCT
						PortfolioUid
				,		RTRIM(PortfolioName) PortfolioName
				,		PortfolioTypeUid
				,		PortfolioCurrencyUid
				,		StartDate
				,		EndDate
				FROM	Portfolio a, #assocPortfolios b
				WHERE	a.PortfolioUid = b.AssocPortfolioUid
				ORDER BY PortfolioTypeUid, PortfolioName, StartDate
			ELSE
			BEGIN
				DECLARE @mySQL varchar(MAX)
				SET @mySQL = 'SELECT DISTINCT PortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, StartDate,	EndDate '+
							 'FROM	 Portfolio  a, #assocPortfolios b'+
							' WHERE	 a.PortfolioUid = b.AssocPortfolioUid'+
							' ORDER BY PortfolioTypeUid, PortfolioName, StartDate'
				EXEC [dbo].[ToJSON] @mySQL
			END	
	END
	Branch_EXIT:
		DROP TABLE #myPortTypes
		DROP TABLE #assocPortfolios
END
