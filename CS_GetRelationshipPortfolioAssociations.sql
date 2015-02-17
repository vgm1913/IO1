USE capital_system
GO
/****** Object:  StoredProcedure [dbo].[CS_GetRelationshipPortfolioAssociations]    Script Date: 2/10/2015 10:13:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-10-2015
-- Description:	Returns a list of Portfolios associated to a Relationship Portfolio on a Date
-- Parameters:	PORT_ID		(must be a valid PortfolioUid - if not procedures returns nothing)
--				AS_OF_DATE  (valid date MM/dd/YYYY format) - will return nothing if is date is invalid or invalid format
--				A_PORT_TYPE (0|or a valid portfolio Type) Pass 0 for all Portfolios, Pass a valid PortfolioTypeUid for just Portfolios of that type
--				JSON Flag   (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE CS_GetRelationshipPortfolioAssociations 
	-- Add the parameters for the stored procedure here
	@PORT_ID bigint = 0
,	@AS_OF_DATE datetime = null
,	@A_PORT_TYPE int = 0
,	@JSON int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @myDateIdx int, @myPortType int
	CREATE TABLE #requestedPortTypes (SelectedPortfolioTypeUid int)
	CREATE TABLE #assocPortfolios (AssocPortfolioUid bigint)
	CREATE TABLE #relationshipPortfolios (RelationshipPortfolioUid bigint)
	CREATE TABLE #AcctMgmtPortfolios (AMPortfolioUid bigint)

	IF (@PORT_ID = 0)	-- user passed nothing
	BEGIN
		PRINT 'usage: CS_GetRelationshipPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		GOTO Branch_EXIT
	END
	IF (SELECT a.RelationshipTypeFlag FROM PortfolioType a, Portfolio b WHERE PortfolioUid = @PORT_ID AND a.PortfolioTypeUid = b.PortfolioTypeUid) != 'Y'
	BEGIN
		PRINT 'usage: CS_GetRelationshipPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		PRINT '@PORT_ID='+RTRIM(CONVERT(CHAR, @PORT_ID))+' must be a Relationship type Portfolio'
		GOTO Branch_EXIT
	END
	SET @myPortType = (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID)

	-- store the portfolio types requested except your own portfolio type (@PORT_ID's portfolio type)
	IF (@A_PORT_TYPE = 0)
		INSERT INTO #requestedPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeUid != @myPortType
	ELSE
		INSERT INTO #requestedPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeUid = @A_PORT_TYPE AND PortfolioTypeUid != @myPortType

	IF (SELECT COUNT(*) FROM #requestedPortTypes) = 0
	BEGIN
		PRINT 'usage: CS_GetRelationshipPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		PRINT '@A_PORT_TYPE='+RTRIM(CONVERT(CHAR, @A_PORT_TYPE))+' must be a valid Portfolio Type UID other than the portfolio type of @PORT_ID or zero for all associated Portfolios'
		GOTO Branch_EXIT
	END

	IF (@@ERROR = 0)	-- make sure no errors occured
	BEGIN
		IF @myPortType = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-MGR')
			INSERT INTO #AcctMgmtPortfolios -- date does not filter out yourself - if portfolio passed is the core relationship type
			SELECT @PORT_ID
		ELSE
		BEGIN
			IF (@AS_OF_DATE IS NULL)		-- if no specific date selected, pick everything
				INSERT INTO #AcctMgmtPortfolios
				SELECT AcctMgrPortfolioUid
				FROM PortfolioActivity
				WHERE @PORT_ID = PortfolioUid
			ELSE
				INSERT INTO #AcctMgmtPortfolios
				SELECT AcctMgrPortfolioUid
				FROM PortfolioActivity
				WHERE @PORT_ID = PortfolioUid
				AND StartDateIdx <= CONVERT(int, @AS_OF_DATE)
				AND EndDateIdx > CONVERT(int, @AS_OF_DATE)
		END

		IF (@AS_OF_DATE IS NULL)		-- if no specific date selected, pick everything
		BEGIN
			INSERT	INTO #assocPortfolios
			SELECT	DISTINCT b.AcctPortfolioUid PortfolioUid
			FROM	#AcctMgmtPortfolios a, PortfolioAssociation b
			WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
			UNION
			SELECT	DISTINCT b.MgmrRespPortfolioUid PortfolioUid
			FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
			WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
			UNION
			SELECT	DISTINCT b.GroupPortfolioUid PortfolioUid
			FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
			WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
				AND b.GroupPortfolioUid > 0
			UNION
			SELECT	DISTINCT b.SuperGroupPortfolioUid PortfolioUid
			FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
			WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
				AND b.SuperGroupPortfolioUid > 0
			UNION
			SELECT	DISTINCT b.RPPortfolioUid PortfolioUid
			FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
			WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
				AND	b.RPPortfolioUid > 0
			UNION
			SELECT	DISTINCT b.PCXPortfolioUid PortfolioUid
			FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
			WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
				AND	b.PCXPortfolioUid > 0
			UNION
			SELECT	DISTINCT b.InvestDivPortfolioUid PortfolioUid
			FROM	#AcctMgmtPortfolios a,	PortfolioAssociation b
			WHERE	a.AMPortfolioUid = b.AcctMgmtPortfolioUid
				AND	b.InvestDivPortfolioUid > 0

			INSERT	INTO #relationshipPortfolios
			SELECT	DISTINCT RelationshipPortfolioUid
			FROM	PortfolioRelationship a, PortfolioActivity b, #AcctMgmtPortfolios c
			WHERE	a.RelationshipPortfolioUid = b.PortfolioUid
				AND	c.AMPortfolioUid = b.AcctMgrPortfolioUid
				AND	a.PortfolioAUid in (SELECT AssocPortfolioUid FROM #assocPortfolios)
				AND a.PortfolioBUid in (SELECT AssocPortfolioUid FROM #assocPortfolios)
		END
		ELSE
		BEGIN
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

			INSERT	INTO #relationshipPortfolios
			SELECT	DISTINCT a.PortfolioAUid
			FROM	PortfolioRelationship a
			WHERE	a.PortfolioAUid in (SELECT AssocPortfolioUid FROM #assocPortfolios)
				AND a.PortfolioBUid in (SELECT AssocPortfolioUid FROM #assocPortfolios)
				AND a.PortfolioAUid in (SELECT b.PortfolioUid FROM PortfolioActivity b, #AcctMgmtPortfolios c
										WHERE	b.AcctMgrPortfolioUid = c.AMPortfolioUid
											AND	b.PortfolioUid = a.PortfolioBUid
											AND b.StartDateIdx <= CONVERT(int, @AS_OF_DATE)
											AND b.EndDateIdx > CONVERT(int, @AS_OF_DATE))
				AND a.PortfolioBUid in (SELECT b.PortfolioUid FROM PortfolioActivity b, #AcctMgmtPortfolios c
										WHERE	b.AcctMgrPortfolioUid = c.AMPortfolioUid
											AND	b.PortfolioUid = a.PortfolioAUid
											AND b.StartDateIdx <= CONVERT(int, @AS_OF_DATE)
											AND b.EndDateIdx > CONVERT(int, @AS_OF_DATE))
		END
	END

	INSERT INTO #assocPortfolios
	SELECT #relationshipPortfolios.RelationshipPortfolioUid FROM #relationshipPortfolios

	IF (@JSON = 0)
		SELECT	DISTINCT
					PortfolioUid
			,		RTRIM(PortfolioName) PortfolioName
			,		PortfolioTypeUid
			,		PortfolioCurrencyUid
			,		StartDate
			,		EndDate
			FROM	Portfolio a, #assocPortfolios b, #requestedPortTypes c
			WHERE	a.PortfolioUid = b.AssocPortfolioUid
			AND		a.PortfolioTypeUid = c.SelectedPortfolioTypeUid
			ORDER BY PortfolioTypeUid, PortfolioName, StartDate
	ELSE
		BEGIN
			DECLARE @mySQL varchar(MAX)
			SET @mySQL = 'SELECT DISTINCT PortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, StartDate,	EndDate '+
						 'FROM	 Portfolio  a, #assocPortfolios b'+
						' WHERE	 a.PortfolioUid = b.AssocPortfolioUid'+
						'	AND	 a.PortfolioTypeUid = c.SelectedPortfolioTypeUid'+
						' ORDER BY PortfolioTypeUid, PortfolioName, StartDate'
			EXEC [dbo].[ToJSON] @mySQL
		END	

	Branch_EXIT:
		DROP TABLE #requestedPortTypes
		DROP TABLE #assocPortfolios
		DROP TABLE #relationshipPortfolios
END
GO
