USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[CS_GetPortfolioAssociations]    Script Date: 2/15/2015 10:59:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-10-2015
-- Description:	Returns a list of Portfolios associated to a Portfolio on a Date
-- Parameters:	PORT_ID		(must be a valid PortfolioUid - if not procedures returns nothing)
--				AS_OF_DATE  (valid date MM/dd/YYYY format) - will return nothing if is date is invalid or invalid format
--				A_PORT_TYPE (0|or a valid portfolio Type) Pass 0 for all Portfolios, Pass a valid PortfolioTypeUid for just Portfolios of that type
--				JSON Flag   (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE [dbo].[CS_GetPortfolioAssociations] 
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
	DECLARE @myDateIdx int
	DECLARE @mySQL varchar(MAX)
	CREATE TABLE #myPortTypes (SelectedPortfolioTypeUid int)
	CREATE TABLE #assocPortfolios (AssocPortfolioUid bigint)

	IF (@PORT_ID = 0)	-- user passed nothing
	BEGIN
		PRINT 'usage: CS_GetPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		GOTO Branch_EXIT
	END
	
	IF (@A_PORT_TYPE = 0)
		INSERT INTO #myPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType WHERE RelationshipTypeFlag = 'N'
	ELSE
		INSERT INTO #myPortTypes
		SELECT PortfolioTypeUid FROM PortfolioType WHERE RelationshipTypeFlag = 'N' AND PortfolioTypeUid = @A_PORT_TYPE
	
	IF (SELECT COUNT(*) FROM #myPortTypes) = 0
	BEGIN
		PRINT 'usage: CS_GetPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		PRINT '@A_PORT_TYPE='+RTRIM(CONVERT(CHAR, @A_PORT_TYPE))+' must be a valid EntityType or zero for all associated Portfolio'
		GOTO Branch_EXIT
	END
	
	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT')
		GOTO Branch_ACCT
	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'MGR')
		GOTO Branch_MGR
	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP')
		GOTO Branch_RP
	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'PCX')
		GOTO Branch_PCX
	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP')
		GOTO Branch_GROUP
	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SUPERGROUP')
		GOTO Branch_SUPERGROUP
	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVESTDIV')
		GOTO Branch_INVESTDIV
	/*
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-MGR') = @portfolioTypeUid
		GOTO Branch_ACCT_MGR    
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GRP-MGR') = @portfolioTypeUid
		GOTO Branch_GRP_MGR     
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP-MGR') = @portfolioTypeUid
		GOTO Branch_RP_MGR      
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SGRP-MGR') = @portfolioTypeUid
		GOTO Branch_SGRP_MGR    
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'PCX-MGR') = @portfolioTypeUid
		GOTO Branch_PCX_MGR     
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-RP') = @portfolioTypeUid
		GOTO Branch_ACCT_RP     
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-PCX') = @portfolioTypeUid
		GOTO Branch_ACCT_PCX    
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP-ACCT') = @portfolioTypeUid
		GOTO Branch_GROUP_ACCT  
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP-RP') = @portfolioTypeUid
		GOTO Branch_GROUP_RP    
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP-PCX') = @portfolioTypeUid
		GOTO Branch_GROUP_PCX
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SGRP-RP') = @portfolioTypeUid
		GOTO Branch_SGRP_RP     
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SGRP-PCX') = @portfolioTypeUid
		GOTO Branch_SGRP_PCX    
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-ACCT') = @portfolioTypeUid
		GOTO Branch_INVDIV_ACCT 
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-MGR') = @portfolioTypeUid
		GOTO Branch_INVDIV_MGR  
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-RP') = @portfolioTypeUid
		GOTO Branch_INVDIV_RP   
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-PCX') = @portfolioTypeUid
		GOTO Branch_INVDIV_PCX  
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-GRP') = @portfolioTypeUid
		GOTO Branch_INVDIV_GRP  
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVDIV-SGRP') = @portfolioTypeUid
		GOTO Branch_INVDIV_SGRP 
	
		GOTO Branch_END

    Branch_ACCT_MGR:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_ACCT_MGR Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_ACCT_MGR @CutOffDate   
		GOTO Branch_END;
    Branch_GRP_MGR:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_GRP_MGR Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_GRP_MGR @CutOffDate    
		GOTO Branch_END;
    Branch_RP_MGR:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_RP_MGR Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_RP_MGR @CutOffDate     
		GOTO Branch_END;
    Branch_SGRP_MGR:
       	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_SGRP_MGR Time:'+CONVERT(varchar, GETDATE())
		exec pop_Portfolio_SGRP_MGR @CutOffDate   
		GOTO Branch_END;
    Branch_PCX_MGR:
       	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_PCX_MGR Time:'+CONVERT(varchar, GETDATE())
		exec pop_Portfolio_PCX_MGR @CutOffDate    
		GOTO Branch_END;
    Branch_ACCT_RP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_ACCT_RP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_ACCT_RP @CutOffDate    
		GOTO Branch_END;
    Branch_ACCT_PCX:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_ACCT_PCX Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_ACCT_PCX @CutOffDate   
		GOTO Branch_END;
    Branch_GROUP_ACCT:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_GROUP_ACCT Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_GROUP_ACCT @CutOffDate 
		GOTO Branch_END;
    Branch_GROUP_RP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_GROUP_RP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_GROUP_RP @CutOffDate   
		GOTO Branch_END;
    Branch_GROUP_PCX:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_GROUP_PCX Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_GROUP_PCX @CutOffDate  
		GOTO Branch_END;
    Branch_SGRP_RP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_SGRP_RP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_SGRP_RP @CutOffDate    
		GOTO Branch_END;
    Branch_SGRP_PCX:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_SGRP_PCX Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_SGRP_PCX @CutOffDate   
		GOTO Branch_END;
    Branch_INVDIV_ACCT:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_INVDIV_ACCT Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_INVDIV_ACCT @CutOffDate
		GOTO Branch_END;
    Branch_INVDIV_MGR:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_INVDIV_MGR Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_INVDIV_MGR @CutOffDate 
		GOTO Branch_END;
    Branch_INVDIV_RP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_INVDIV_RP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_INVDIV_RP @CutOffDate  
		GOTO Branch_END;
    Branch_INVDIV_PCX:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_INVDIV_PCX Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_INVDIV_PCX @CutOffDate 
		GOTO Branch_END;
    Branch_INVDIV_GRP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_INVDIV_GRP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_INVDIV_GRP @CutOffDate 
		GOTO Branch_END;
    Branch_INVDIV_SGRP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_INVDIV_SGRP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_INVDIV_SGRP @CutOffDate
		GOTO Branch_END;

	Branch_END:
	-- minor clean up - for now if there is no currency specified for the portfolio then defalut it to USD
	UPDATE Portfolio
	SET PortfolioCurrencyUid = 1
	WHERE PortfolioCurrencyUid < 0

	*/
	Branch_ACCT:
		exec CS_GetAccountAssociations @PORT_ID,	@AS_OF_DATE, @A_PORT_TYPE,	@JSON
		GOTO Branch_EXIT;
    Branch_MGR:
    	exec CS_GetMgmtRespAssociations @PORT_ID,	@AS_OF_DATE, @A_PORT_TYPE,	@JSON
		GOTO Branch_EXIT;
    Branch_RP:
    	exec CS_GetRPAssociations @PORT_ID,	@AS_OF_DATE, @A_PORT_TYPE,	@JSON
		GOTO Branch_EXIT;
    Branch_PCX:
		exec CS_GetPCXAssociations @PORT_ID,	@AS_OF_DATE, @A_PORT_TYPE,	@JSON
		GOTO Branch_EXIT;
    Branch_GROUP:
		exec CS_GetGroupAssociations @PORT_ID,	@AS_OF_DATE, @A_PORT_TYPE,	@JSON
		GOTO Branch_EXIT;
    Branch_SUPERGROUP:
		exec CS_GetSuperGroupAssociations @PORT_ID,	@AS_OF_DATE, @A_PORT_TYPE,	@JSON
		GOTO Branch_EXIT;
    Branch_INVESTDIV:
		exec CS_GetInvestDivisionAssociations @PORT_ID,	@AS_OF_DATE, @A_PORT_TYPE,	@JSON
		GOTO Branch_EXIT;


	Branch_End:
	IF (@AS_OF_DATE IS NULL)
	BEGIN
		exec CS_GetPortfolioHistoricalAssociations @PORT_ID, @A_PORT_TYPE, @JSON
		GOTO Branch_EXIT
	END
	ELSE
		SET @myDateIdx = CONVERT(int,@AS_OF_DATE)
	
	IF (@@ERROR = 0)	-- make sure no errors occured
	BEGIN
		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.AcctPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND a.StartDateIdx <= @myDateIdx
		AND a.EndDateIdx > @myDateIdx
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = AcctPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.MgmrRespPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND a.StartDateIdx <= @myDateIdx
		AND a.EndDateIdx > @myDateIdx
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = MgmrRespPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.RPPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND a.StartDateIdx <= @myDateIdx
		AND a.EndDateIdx > @myDateIdx
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = RPPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.PCXPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND a.StartDateIdx <= @myDateIdx
		AND a.EndDateIdx > @myDateIdx
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.PCXPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.GroupPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND a.StartDateIdx <= @myDateIdx
		AND a.EndDateIdx > @myDateIdx
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.GroupPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.SuperGroupPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND a.StartDateIdx <= @myDateIdx
		AND a.EndDateIdx > @myDateIdx
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.SuperGroupPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocPortfolios
		SELECT DISTINCT
			a.InvestDivPortfolioUid
		FROM PortfolioAssociation a, PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND a.StartDateIdx <= @myDateIdx
		AND a.EndDateIdx > @myDateIdx
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND	a.AcctMgmtPortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioUid = a.InvestDivPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			b.AcctMgrPortfolioUid
		FROM PortfolioActivity b, Portfolio c, #myPortTypes d
		WHERE b.PortfolioUid = @PORT_ID
		AND b.StartDateIdx <= @myDateIdx
		AND b.EndDateIdx > @myDateIdx
		AND c.PortfolioUid = b.AcctMgrPortfolioUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			a.RelationshipPortfolioUid
		FROM PortfolioRelationship a, #assocPortfolios b, Portfolio c, #myPortTypes d
		WHERE a.PortfolioAUid = @PORT_ID
		AND c.StartDateIdx <= @myDateIdx
		AND c.EndDateIdx > @myDateIdx
		AND a.PortfolioBUid = b.AssocPortfolioUid
		AND c.PortfolioUid = a.PortfolioBUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid
		
		INSERT INTO #assocRelationshipPortfolios
		SELECT DISTINCT
			a.RelationshipPortfolioUid
		FROM PortfolioRelationship a, #assocPortfolios b, Portfolio c, #myPortTypes d
		WHERE a.PortfolioBUid = @PORT_ID
		AND c.StartDateIdx <= @myDateIdx
		AND c.EndDateIdx > @myDateIdx
		AND a.PortfolioAUid = b.AssocPortfolioUid
		AND c.PortfolioUid = a.PortfolioAUid
		AND c.PortfolioTypeUid = d.SelectedPortfolioTypeUid

		IF (@JSON = 0)
				SELECT	PortfolioUid
				,		RTRIM(PortfolioName) PortfolioName
				,		PortfolioTypeUid
				,		PortfolioCurrencyUid
				,		StartDate
				,		EndDate
				FROM	Portfolio a, #assocPortfolios b
				WHERE	StartDateIdx <= @myDateIdx
				AND		EndDateIdx > @myDateIdx
				AND		a.PortfolioUid = b.AssocPortfolioUid
			ELSE
			BEGIN
				SET @mySQL = 'SELECT PortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, StartDate,	EndDate '+
							 'FROM	 Portfolio  a, #assocPortfolios b'+
							' WHERE	 StartDateIdx <= '+RTRIM(CONVERT(int,@myDateIdx))+
							' AND	 EndDateIdx > '++RTRIM(CONVERT(int,@myDateIdx))+
							' AND    a.PortfolioUid = b.AssocPortfolioUid'
				EXEC [dbo].[ToJSON] @mySQL
			END	
	END
	Branch_EXIT:
		DROP TABLE #myPortTypes
		DROP TABLE #assocPortfolios
END
