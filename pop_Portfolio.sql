USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio]    Script Date: 2/11/2015 5:27:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		vgm
-- Create date: 01-16-2015
-- Description:	populate Portfolio Table based on PortfolioTypeID passed
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio] 
	-- Add the parameters for the stored procedure here
	@portfolioTypeUid int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE Currency NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioRelationship NOCHECK CONSTRAINT ALL
	
	DECLARE @CutOffDate datetime
	SELECT @CutOffDate = (select '01/01/1969')		-- for sprint challenge we prune relationships that existed before MARS went live all end date must be greater than CutOffDate

	--
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT') = @portfolioTypeUid 
		GOTO Branch_ACCT
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'MGR') = @portfolioTypeUid 
		GOTO Branch_MGR
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP') = @portfolioTypeUid 
		GOTO Branch_RP
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'PCX') = @portfolioTypeUid 
		GOTO Branch_PCX
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP') = @portfolioTypeUid 
		GOTO Branch_GROUP
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SUPERGROUP') = @portfolioTypeUid 
		GOTO Branch_SUPERGROUP
	IF (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVESTDIV') = @portfolioTypeUid 
		GOTO Branch_INVESTDIV
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
	
	GOTO Branch_END;

	Branch_ACCT:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_ACC Time:'+CONVERT(varchar, GETDATE())
		exec pop_Portfolio_ACCT @CutOffDate
		GOTO Branch_END;
    Branch_MGR:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_MGR Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_MGR @CutOffDate    
		GOTO Branch_END;
    Branch_RP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_RP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_RP  @CutOffDate        
		GOTO Branch_END;
    Branch_PCX:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_PCX Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_PCX @CutOffDate        
		GOTO Branch_END;
    Branch_GROUP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_GROUP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_GROUP @CutOffDate      
		GOTO Branch_END;
    Branch_SUPERGROUP:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_SUPERGROUP Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_SUPERGROUP @CutOffDate 
		GOTO Branch_END;
    Branch_INVESTDIV:
    	PRINT '------------------------------------------'
		PRINT 'Entering Proc: pop_Portfolio_INVESTDIV Time:'+CONVERT(varchar, GETDATE())
        exec pop_Portfolio_INVESTDIV @CutOffDate  
		GOTO Branch_END;
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

	-- re-enable constraint checking
	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE Currency CHECK CONSTRAINT ALL
END

