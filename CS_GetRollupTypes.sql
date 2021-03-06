USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[CS_GetRollupTypes]    Script Date: 2/8/2015 4:23:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02/03/2015
-- Description:	Returns a list of Portfolio Rollup Types
-- Parameters:	Brief Format (0|1)	Pass 1 to get the brief number of columns
--				JSON Flag (0|1)		Pass 1 to get output in JSON format - defalut is SQLh
-- =============================================
ALTER PROCEDURE [dbo].[CS_GetRollupTypes] 
	@BRIEF_FORM		int = 0
,	@JSON_OUTPUT	int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mySQL varchar(1000) 
	IF (@BRIEF_FORM = 0)
		IF (@JSON_OUTPUT = 0)
			SELECT RollupCode, RTRIM(LTRIM(RollupAbbr)), RTRIM(LTRIM(RollupName)), ManagerResultsFlag FROM Rollup
		ELSE
			EXEC [dbo].[ToJSON] 'SELECT RollupCode, RTRIM(LTRIM(RollupAbbr)) RollupAbbr, RTRIM(LTRIM(RollupName)) RollupName, ManagerResultsFlag  FROM Rollup'
	ELSE
		IF (@JSON_OUTPUT = 0)
			SELECT RollupCode, RollupAbbr,RollupName RollupName FROM Rollup 
		ELSE
			EXEC [dbo].[ToJSON] 'SELECT RollupCode, RTRIM(LTRIM(RollupAbbr)) RollupAbbr, RTRIM(LTRIM(RollupName)) RollupName FROM Rollup'
END
