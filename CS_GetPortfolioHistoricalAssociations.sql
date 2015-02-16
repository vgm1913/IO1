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
	IF EXISTS (SELECT * FROM PortfolioType WHERE PortfolioTypeUid = @A_PORT_TYPE AND RelationshipTypeFlag = 'N')
		exec CS_GetPortfolioAssociations @PORT_ID, NULL, @A_PORT_TYPE, @JSON
	ELSE
		exec CS_GetRelationshipPortfolioAssociations @PORT_ID, NULL, @A_PORT_TYPE, @JSON
END
GO
