USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[CS_GetPortfolios]    Script Date: 2/9/2015 4:40:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02/09/2015
-- Description:	Returns a lits of Portfolios
-- Parameters:	AS_OF_DATE  (valid date MM/dd/YYYY format) - will return nothing if is date is invalid or invalid format
--				A_PORT_TYPE (0|or a valid portfolio Type) Pass 0 for all Portfolios, Pass a valid PortfolioTypeUid for just Portfolios of that type
--				JSON Flag   (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE [dbo].[CS_GetPortfolios] 
	@AS_OF_DATE		datetime = NULL
,	@A_PORT_TYPE	int = 0
,	@JSON_OUTPUT	int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @myDateIdx int
	DECLARE @mySQL varchar(MAX)
	IF (@AS_OF_DATE IS NULL)
		SET @myDateIdx = CONVERT(int,GETDATE())
	ELSE
		SET @myDateIdx = CONVERT(int,@AS_OF_DATE)

	IF (@@ERROR = 0)	-- make sure no errors occured
	BEGIN
		IF (@A_PORT_TYPE = 0)
		BEGIN
			IF (@JSON_OUTPUT = 0)
				SELECT	PortfolioUid
				,		RTRIM(PortfolioName) PortfolioName
				,		PortfolioTypeUid
				,		PortfolioCurrencyUid
				,		StartDate
				,		EndDate
				FROM	Portfolio
				WHERE	StartDateIdx <= @myDateIdx
				AND		EndDateIdx > @myDateIdx
			ELSE
			BEGIN
				SET @mySQL = 'SELECT PortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, StartDate,	EndDate '+
							 'FROM	 Portfolio '+
							' WHERE	 StartDateIdx <= '+RTRIM(CONVERT(int,@myDateIdx))+
							' AND	 EndDateIdx > '++RTRIM(CONVERT(int,@myDateIdx))
				EXEC [dbo].[ToJSON] @mySQL
			END
		END
		ELSE
			IF (@JSON_OUTPUT = 0)
				SELECT	PortfolioUid
				,		RTRIM(PortfolioName) PortfolioName
				,		PortfolioTypeUid
				,		PortfolioCurrencyUid
				,		StartDate
				,		EndDate
				FROM	Portfolio
				WHERE	StartDateIdx <= @myDateIdx
				AND		EndDateIdx > @myDateIdx
				AND		PortfolioTypeUid = @A_PORT_TYPE
			ELSE
			BEGIN
				SET @mySQL = 'SELECT PortfolioUid, RTRIM(PortfolioName) PortfolioName, PortfolioTypeUid, PortfolioCurrencyUid, StartDate,	EndDate '+
							 'FROM	 Portfolio '+
							' WHERE	 StartDateIdx <= '+RTRIM(CONVERT(int,@myDateIdx))+
							' AND	 EndDateIdx > '++RTRIM(CONVERT(int,@myDateIdx))+
							' AND	 PortfolioTypeUid = '+RTRIM(CONVERT(int,@A_PORT_TYPE))
				EXEC [dbo].[ToJSON] @mySQL
			END
	END
END
