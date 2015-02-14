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
	DECLARE @mySQL varchar(MAX)
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

END
GO
