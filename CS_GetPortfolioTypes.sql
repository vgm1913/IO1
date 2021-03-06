USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[CS_GetPortfolioTypes]    Script Date: 2/8/2015 5:03:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02/03/2015
-- Description:	Returns a lits of PortfolioType
-- Parameters:	Brief Format (0|1)	Pass 1 to get the brief number of columns
--				Entities Only (0|1)	Pass 1 to get only Portfolio Types for Capital System Entities
--				JSON Flag (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE [dbo].[CS_GetPortfolioTypes] 
	@BRIEF_FORM		int = 0
,	@ENTITIES_ONLY	int = 0
,	@JSON_OUTPUT	int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mySQL varchar(1000) 
	IF (@BRIEF_FORM = 0)
		IF (@ENTITIES_ONLY = 0)
		BEGIN
			IF (@JSON_OUTPUT = 0)
				SELECT PortfolioTypeUid, RTRIM(PortfolioTypeAbbr) PortfolioTypeAbbr, RTRIM(PortfolioTypeName) PortfolioTypeName, RelationshipTypeFlag, PortfolioATypeUid, PortfolioBTypeUid, ParentType FROM PortfolioType
			ELSE
				EXEC [dbo].[ToJSON] 'SELECT PortfolioTypeUid, RTRIM(PortfolioTypeAbbr) PortfolioTypeAbbr, RTRIM(PortfolioTypeName) PortfolioTypeName, RelationshipTypeFlag, PortfolioATypeUid, PortfolioBTypeUid, ParentType FROM PortfolioType'
		END
		ELSE
			IF (@JSON_OUTPUT = 0)
				SELECT PortfolioTypeUid, RTRIM(PortfolioTypeAbbr) PortfolioTypeAbbr, RTRIM(PortfolioTypeName) PortfolioTypeName, RelationshipTypeFlag, PortfolioATypeUid, PortfolioBTypeUid, ParentType FROM PortfolioType a WHERE a.RelationshipTypeFlag = 'N'
			ELSE
			BEGIN
				SELECT @mySQL = (SELECT 'SELECT PortfolioTypeUid, RTRIM(PortfolioTypeAbbr) PortfolioTypeAbbr, RTRIM(PortfolioTypeName) PortfolioTypeName, RelationshipTypeFlag, PortfolioATypeUid, PortfolioBTypeUid, ParentType FROM PortfolioType a WHERE a.RelationshipTypeFlag = '+CHAR(39)+'N'+CHAR(39))
				EXEC [dbo].[ToJSON] @mySQL
			END
	ELSE
		IF (@ENTITIES_ONLY = 0)
		BEGIN
			IF (@JSON_OUTPUT = 0)
				SELECT a.PortfolioTypeUid, a.PortfolioTypeAbbr, a.PortfolioTypeName, a.RelationshipTypeFlag FROM PortfolioType a
			ELSE
				EXEC [dbo].[ToJSON] 'SELECT PortfolioTypeUid, RTRIM(PortfolioTypeAbbr) PortfolioTypeAbbr, RTRIM(PortfolioTypeName) PortfolioTypeName, RelationshipTypeFlag FROM PortfolioType'
		END
		ELSE
			IF (@JSON_OUTPUT = 0)
				SELECT a.PortfolioTypeUid, a.PortfolioTypeAbbr, a.PortfolioTypeName, a.RelationshipTypeFlag FROM PortfolioType a
				WHERE a.RelationshipTypeFlag = 'N'
			ELSE
			BEGIN
				SELECT @mySQL = (SELECT 'SELECT PortfolioTypeUid, RTRIM(PortfolioTypeAbbr) PortfolioTypeAbbr, RTRIM(PortfolioTypeName) PortfolioTypeName, RelationshipTypeFlag FROM PortfolioType a WHERE a.RelationshipTypeFlag = '+CHAR(39)+'N'+CHAR(39))
				EXEC [dbo].[ToJSON] @mySQL
			END
END
