USE capital_system
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-10-2015
-- Description:	Get all historical Portfolio Associations for a given Portfolio (optionally filter by type)
-- Parameters:	PORT_ID		(must be a valid PortfolioUid - if not procedures returns nothing)
--				A_PORT_TYPE (0|or a valid portfolio Type) Pass 0 for all Portfolios, Pass a valid PortfolioTypeUid for just Portfolios of that type
--				JSON Flag   (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE CS_GetPortfolioHistoricalAssociations 
		-- Add the parameters for the stored procedure here
	@PORT_ID bigint = 0
,	@A_PORT_TYPE int = 0
,	@JSON int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	CREATE TABLE #myPortTypes (SelectedPortfolioTypeUid int)
	CREATE TABLE #assocPortfolios (AssocPortfolioUid bigint)
	CREATE TABLE #assocRelationshipPortfolios (AssocPortfolioUid bigint)

	IF (@PORT_ID = 0)	-- user passed nothing
	BEGIN
		PRINT 'usage: CS_GetPortfolioHistoricalAssociations @PORT_ID bigint, [, @A_PORT_TYPE int] [, @JSON int ]'
		GOTO Branch_EXIT
	END
	IF (@A_PORT_TYPE = 0)
		INSERT INTO #myPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType 
	ELSE
		INSERT INTO #myPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeUid = @A_PORT_TYPE
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
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = AcctPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.MgmrRespPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = MgmrRespPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.RPPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = RPPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.PCXPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.PCXPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.GroupPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.GroupPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.SuperGroupPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.SuperGroupPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.InvestDivPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.InvestDivPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			b.AcctMgrPortfolioUid
		FROM PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND c.PortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			a.RelationshipPortfolioUid
		FROM PortfolioRelationship a, #assocPortfolios b, Portfolio c, #myPortTypes d, PortfolioAssociation e
		WHERE a.PortfolioAUid = @PORT_ID
		AND a.PortfolioBUid = b.AssocPortfolioUid
		AND c.PortfolioUid = a.PortfolioBUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid
		AND e.AcctPortfolioUid = a.PortfolioAUid
		
		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			a.RelationshipPortfolioUid
		FROM PortfolioRelationship a, #assocPortfolios b, Portfolio c, #myPortTypes d
		WHERE a.PortfolioBUid = @PORT_ID
		AND a.PortfolioAUid = b.AssocPortfolioUid
		AND c.PortfolioUid = a.PortfolioAUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

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
				ORDER BY PortfolioTypeUid, StartDate
			ELSE
			BEGIN
				DECLARE @mySQL varchar(MAX)
				SET @mySQL = 'SELECT DISTINCT PortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, StartDate,	EndDate '+
							 'FROM	 Portfolio  a, #assocPortfolios b'+
							' WHERE	 a.PortfolioUid = b.AssocPortfolioUid'+
							' ORDER BY PortfolioTypeUid, StartDate'
				EXEC [dbo].[ToJSON] @mySQL
			END	
	END
	Branch_EXIT:
		DROP TABLE #myPortTypes
		DROP TABLE #assocPortfolios
END
GO
