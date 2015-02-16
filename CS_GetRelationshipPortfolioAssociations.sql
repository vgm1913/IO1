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
	DECLARE @myDateIdx int
	
	IF (@PORT_ID = 0)	-- user passed nothing
	BEGIN
		PRINT 'usage: CS_GetRelationshipPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		RETURN
	END
	IF (SELECT a.RelationshipTypeFlag FROM PortfolioType a, Portfolio b WHERE PortfolioUid = @PORT_ID AND a.PortfolioTypeUid = b.PortfolioTypeUid) != 'Y'
	BEGIN
		PRINT 'usage: CS_GetRelationshipPortfolioAssociations @PORT_ID bigint, @AS_OF_DATE date [, @A_PORT_TYPE int] [,	@JSON int ]'
		PRINT '@PORT_ID='+RTRIM(CONVERT(CHAR, @PORT_ID))+' must be a Relationship type Portfolio'
		RETURN
	END
	IF (@AS_OF_DATE IS NULL)
		SET @myDateIdx = CONVERT(int,GETDATE())
	ELSE
		SET @myDateIdx = CONVERT(int,@AS_OF_DATE)

	IF (@@ERROR = 0)	-- make sure no errors occured
	BEGIN
		SELECT @PORT_ID
	END

	DECLARE @ACCT_Type int, @MGMT_Type int, @RP_Type int, @PCX_Type int, @GRP_Type int, @SGRP_Type int, @INVDIV_Type int
	SELECT @ACCT_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT')
	SELECT @MGMT_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'MGR')
	SELECT @RP_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP')
	SELECT @PCX_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'PCX')
	SELECT @GRP_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP')
	SELECT @SGRP_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SUPERGROUP')
	SELECT @INVDIV_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVESTDIV')


	IF (SELECT PortfolioTypeUid FROM Portfolio WHERE PortfolioUid = @PORT_ID) = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-MGR')
		GOTO Branch_ACCT_MGR    
	/*
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-RP') = @portfolioTypeUid
		GOTO Branch_ACCT_RP     
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT-PCX') = @portfolioTypeUid
		GOTO Branch_ACCT_PCX    

	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GRP-MGR') = @portfolioTypeUid
		GOTO Branch_GRP_MGR     
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP-MGR') = @portfolioTypeUid
		GOTO Branch_RP_MGR      
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SGRP-MGR') = @portfolioTypeUid
		GOTO Branch_SGRP_MGR    
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'PCX-MGR') = @portfolioTypeUid
		GOTO Branch_PCX_MGR     
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
	*/
		GOTO Branch_END

    Branch_ACCT_MGR:
		DECLARE @ACCT_PortfolioUid bigint
		SET @ACCT_PortfolioUid = (SELECT * FROM PortfolioRelationship a WHERE a.RelationshipPortfolioUid = @PORT_ID
		AND  
        exec CS_GetAccountRelationships @PORT_ID, @AS_OF_DATE, @A_PORT_TYPE, @JSON   
		GOTO Branch_EXIT;
    /*
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

	*/

	Branch_EXIT:

END
GO
