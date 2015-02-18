USE capital_system
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-17-2015
-- Description:	Return the associated portfolio rollup: ROLLUP for the Portfolio: PORT_ID on a given date: AS_OF_DATE
-- Parameters:	PORT_ID		(must be a valid PortfolioUid - if not procedures returns nothing)
--				ROLLUP		(must be a valid Rollup Code - if Rollup code does not match the type of Portfolio then raise error)
--			    AS_OF_DATE	(optional - must be a Date MM/dd/YYYY format)
--				JSON Flag	(optional 0|1)	Pass 1 to get output in JSON format - defalut is 0
-- =============================================
ALTER PROCEDURE [dbo].[CS_GetPortfolioRollup] 
	-- Add the parameters for the stored procedure here
	@PORT_ID bigint = NULL
,	@ROLLUP	 char(3) = NULL
,	@AS_OF_DATE datetime = NULL
,	@JSON int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	CREATE TABLE #rollupTypes (SelectedPortfolioTypeUid int)
	CREATE TABLE #assocPortfolios (AssocPortfolioUid bigint)
	CREATE TABLE #rollupPortfolios (AssocPortfolioUid bigint)
	CREATE TABLE #AcctMgmtPortfolios (AMPortfolioUid bigint)

	DECLARE @MaxRollupLevel int, @TopRollupTypeUid int
		
	IF (@PORT_ID IS NULL)	-- user passed nothing
	BEGIN
		PRINT 'usage: CG_GetAccountRollup @PORT_ID bigint, @ROLLUP char(3), [, @AS_OF_DATE date ] [, @JSON int ] - @PORT_ID must be a valid PortfolioUid'
		GOTO Branch_EXIT
	END

	IF (@ROLLUP IS NULL) OR (NOT EXISTS (SELECT * FROM [dbo].[Rollup] WHERE RollupCode = @ROLLUP AND @ROLLUP IS NOT NULL))
	BEGIN
		PRINT 'usage: CG_GetAccountRollup @PORT_ID bigint, @ROLLUP char(3), [, @AS_OF_DATE date ] [, @JSON int ] - @ROLLUP must be a valid Rollup Code'
		GOTO Branch_EXIT
	END
	ELSE
	BEGIN
		SET @MaxRollupLevel = (SELECT MAX(a.RollupLevel) FROM PortfolioRollupType a, [dbo].[Rollup] b
			WHERE a.RollupCode = b.RollupCode
			AND b.RollupCode = @ROLLUP)
		
		SET @TopRollupTypeUid = (SELECT PortfolioTypeUid FROM PortfolioRollupType WHERE RollupCode = @ROLLUP AND RollupLevel = @MaxRollupLevel)

		IF NOT EXISTS (SELECT * FROM Portfolio WHERE PortfolioUid = @PORT_ID AND PortfolioTypeUid = @TopRollupTypeUid)
		BEGIN
			PRINT 'usage: CG_GetAccountRollup @PORT_ID bigint, @ROLLUP char(3), [, @AS_OF_DATE date ] [, @JSON int ] - @ROLLUP must be a valid Rollup Code'
			GOTO Branch_EXIT
		END
	END
	
	IF (@AS_OF_DATE IS NULL)
		SET @AS_OF_DATE = GETDATE() -- if not passed use the latest date as Today (should really be passed it via caller)
	
	INSERT INTO #rollupTypes
	SELECT a.PortfolioTypeUid FROM PortfolioType a, PortfolioRollupType b
	WHERE a.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.RollupCode = @ROLLUP

	IF (@@ERROR != 0)	-- make sure no errors occured
		GOTO Branch_EXIT

	-- OK - we can begin; first thing setup all active Account Management Responsibilities active on the AS_OF_DATE
	INSERT INTO #AcctMgmtPortfolios
	SELECT AcctMgrPortfolioUid
	FROM PortfolioActivity
	WHERE @PORT_ID = PortfolioUid
	AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
	AND EndDateIdx > CONVERT(int, @AS_OF_DATE)

	-- based on Active Acct-Mgmt Portfolios - then pick which Entity Portfolios that are associated
	INSERT	INTO #assocPortfolios
	SELECT	DISTINCT b.AcctPortfolioUid PortfolioUid
	FROM	#AcctMgmtPortfolios a, PortfolioAssociation b
	WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
		AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND EndDateIdx > CONVERT(int, @AS_OF_DATE)
	UNION
	SELECT	DISTINCT b.MgmrRespPortfolioUid PortfolioUid
	FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
	WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
		AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND EndDateIdx > CONVERT(int, @AS_OF_DATE)
	UNION
	SELECT	DISTINCT b.GroupPortfolioUid PortfolioUid
	FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
	WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
		AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND EndDateIdx > CONVERT(int, @AS_OF_DATE)
		AND b.GroupPortfolioUid > 0
	UNION
	SELECT	DISTINCT b.SuperGroupPortfolioUid PortfolioUid
	FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
	WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
		AND b.SuperGroupPortfolioUid > 0
		AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND EndDateIdx > CONVERT(int, @AS_OF_DATE)
	UNION
	SELECT	DISTINCT b.RPPortfolioUid PortfolioUid
	FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
	WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
		AND b.RPPortfolioUid > 0
		AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND EndDateIdx > CONVERT(int, @AS_OF_DATE)
	UNION
	SELECT	DISTINCT b.PCXPortfolioUid PortfolioUid
	FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
	WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
		AND b.PCXPortfolioUid > 0
		AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND EndDateIdx > CONVERT(int, @AS_OF_DATE)
	UNION
	SELECT	DISTINCT b.InvestDivPortfolioUid PortfolioUid
	FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
	WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
		AND b.InvestDivPortfolioUid > 0
		AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
		AND EndDateIdx > CONVERT(int, @AS_OF_DATE)

	-- now using the entity associated portfolios selected the relationship portfolios active on the AS_OF_DATE 
	INSERT	INTO #rollupPortfolios
	SELECT	DISTINCT a.RelationshipPortfolioUid
	FROM	PortfolioRelationship a
	WHERE	a.PortfolioAUid = @PORT_ID
		AND a.PortfolioBUid in (SELECT AssocPortfolioUid FROM #assocPortfolios)
		AND a.PortfolioBUid in (SELECT b.PortfolioUid FROM PortfolioActivity b, #AcctMgmtPortfolios c
								WHERE	b.AcctMgrPortfolioUid = c.AMPortfolioUid
									AND b.StartDateIdx <= CONVERT(int, @AS_OF_DATE)
									AND b.EndDateIdx > CONVERT(int, @AS_OF_DATE))
	UNION
	SELECT	DISTINCT a.RelationshipPortfolioUid
	FROM	PortfolioRelationship a
	WHERE	a.PortfolioBUid = @PORT_ID
		AND a.PortfolioAUid in (SELECT AssocPortfolioUid FROM #assocPortfolios)
		AND a.PortfolioAUid in (SELECT b.PortfolioUid FROM PortfolioActivity b, #AcctMgmtPortfolios c
								WHERE	b.AcctMgrPortfolioUid = c.AMPortfolioUid
									AND b.StartDateIdx <= CONVERT(int, @AS_OF_DATE)
									AND b.EndDateIdx > CONVERT(int, @AS_OF_DATE))

	-- now the roll-up tree has as it's root the Portfolio with PORT_ID we started with - so make sure we include that it the result set
	INSERT INTO #rollupPortfolios
	SELECT @PORT_ID
	UNION
	SELECT AssocPortfolioUid FROM #assocPortfolios
	UNION
	SELECT AMPortfolioUid FROM #AcctMgmtPortfolios

	IF (@JSON IS NULL)
		SELECT	DISTINCT
				c.RollupLevel PortfolioLevel 
		,		PortfolioUid
		,		RTRIM(PortfolioName) PortfolioName
		,		a.PortfolioTypeUid
		,		PortfolioCurrencyUid
		,		StartDate
		,		EndDate
		FROM	Portfolio a, #rollupPortfolios b, PortfolioRollupType c, [dbo].[Rollup] d
		WHERE	a.PortfolioUid = b.AssocPortfolioUid
		AND		a.PortfolioTypeUid = c.PortfolioTypeUid
		AND		c.RollupCode = d.RollupCode
		AND		d.RollupCode = @ROLLUP
		AND		a.PortfolioTypeUid in (SELECT SelectedPortfolioTypeUid FROM #rollupTypes)
		ORDER BY c.RollupLevel desc, a.PortfolioTypeUid, PortfolioName, StartDate
	ELSE
	BEGIN
		DECLARE @mySQL varchar(MAX)
		SET @mySQL = 'SELECT DISTINCT PortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, StartDate,	EndDate '+
					' FROM	Portfolio a, #rollupPortfolios b, PortfolioRollupType c, [dbo].[Rollup] d '+
					' WHERE	a.PortfolioUid = b.AssocPortfolioUid '+
					' AND	a.PortfolioTypeUid = c.PortfolioTypeUid'+
					' AND	c.RollupCode = d.RollupCode'+
					' AND	d.RollupCode = '+CHAR(39)+RTRIM(LTRIM(@ROLLUP))+CHAR(39)+
					' AND	a.PortfolioTypeUid in (SELECT SelectedPortfolioTypeUid FROM #rollupTypes)'+
					' ORDER BY c.RollupLevel desc, a.PortfolioTypeUid, PortfolioName, StartDate'
		EXEC [dbo].[ToJSON] @mySQL
	END	

	Branch_EXIT:
		DROP TABLE #rollupTypes
		DROP TABLE #assocPortfolios
		DROP TABLE #rollupPortfolios
		DROP TABLE #AcctMgmtPortfolios
END
GO
