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
	CREATE TABLE #myPortTypes (SelectedPortfolioTypeUid int)

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

	Branch_EXIT:
		DROP TABLE #myPortTypes
END
