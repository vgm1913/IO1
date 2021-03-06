USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[CS_GetPortfolioMemberActivity]    Script Date: 2/10/2015 1:28:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-10-2015
-- Description:	Returns a list of Lowest level Account-Mgmt.Resp. Portfolios that form (or are members of) the Portfolio passed on a Date
-- Parameters:	PORT_ID		(must be a valid PortfolioUid - if not procedures returns nothing)
--				AS_OF_DATE  (valid date MM/dd/YYYY format) - will return nothing if is date is invalid or invalid format
--				JSON Flag   (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE [dbo].[CS_GetPortfolioMemberActivity] 
	-- Add the parameters for the stored procedure here
	@PORT_ID bigint = 0
,	@AS_OF_DATE datetime = null
,	@JSON int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @myDateIdx int
	DECLARE @mySQL varchar(MAX)

	IF (@PORT_ID = 0)	-- user passed nothing
	BEGIN
		PRINT 'usage: CS_GetPortfolioMemberActivity @PORT_ID bigint, @AS_OF_DATE date [, @JSON int ]'
		RETURN
	END

	IF (@AS_OF_DATE IS NULL)
		SET @myDateIdx = 0
	ELSE
		SET @myDateIdx = CONVERT(int,@AS_OF_DATE)
	
	IF (@@ERROR = 0)	-- make sure no errors occured
	BEGIN
		IF (@JSON = 0 AND @myDateIdx > 0)
			SELECT	b.AcctMgrPortfolioUid
			,		RTRIM(PortfolioName) PortfolioName
			,		PortfolioTypeUid
			,		PortfolioCurrencyUid
			,		c.StartDate
			,		c.EndDate
			FROM PortfolioActivity b, Portfolio c
			WHERE
			    b.StartDateIdx <= @myDateIdx
			AND b.EndDateIdx > @myDateIdx
			AND b.PortfolioUid = @PORT_ID
			AND b.AcctMgrPortfolioUid = c.PortfolioUid
		ELSE IF (@JSON = 0 AND @myDateIdx = 0)
			SELECT	b.AcctMgrPortfolioUid
			,		RTRIM(PortfolioName) PortfolioName
			,		PortfolioTypeUid
			,		PortfolioCurrencyUid
			,		c.StartDate
			,		c.EndDate
			FROM PortfolioActivity b, Portfolio c
			WHERE
				b.PortfolioUid = @PORT_ID
			AND b.AcctMgrPortfolioUid = c.PortfolioUid
		ELSE IF (@JSON != 0 AND @myDateIdx = 0)
		BEGIN
			SET @mySQL = 'SELECT	b.AcctMgrPortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, c.StartDate, c.EndDate '+
						' FROM	 PortfolioActivity b, Portfolio c'+
						' WHERE	 b.PortfolioUid = '+RTRIM(CONVERT(char,@PORT_ID))+
						' AND b.AcctMgrPortfolioUid = c.PortfolioUid'
			EXEC [dbo].[ToJSON] @mySQL
		END
		BEGIN
			SET @mySQL = 'SELECT	b.AcctMgrPortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, c.StartDate, c.EndDate '+
						' FROM	 PortfolioActivity b, Portfolio c'+
						' WHERE	 b.StartDateIdx <= '+RTRIM(CONVERT(char,@myDateIdx))+
						' AND	 b.EndDateIdx > '+RTRIM(CONVERT(char,@myDateIdx))+
						' AND	 b.PortfolioUid = '+RTRIM(CONVERT(char,@PORT_ID))+
						' AND b.AcctMgrPortfolioUid = c.PortfolioUid'
			EXEC [dbo].[ToJSON] @mySQL
		END	
	END
END
