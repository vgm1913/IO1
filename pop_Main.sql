USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Main]    Script Date: 2/7/2015 8:37:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: pop_Main
-- Description:	Main control procedure - should be called to fully populate the data set for Sprint Challenge
-- =============================================
ALTER PROCEDURE [dbo].[pop_Main] 
AS
BEGIN
	ALTER TABLE Account NOCHECK CONSTRAINT ALL
	ALTER TABLE Currency NOCHECK CONSTRAINT ALL
	ALTER TABLE GroupMandate NOCHECK CONSTRAINT ALL
	ALTER TABLE InvestmentDivision NOCHECK CONSTRAINT ALL
	ALTER TABLE InvestmentProfessional NOCHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibility NOCHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibility_MARS_xref NOCHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibilityAssetClassCategory NOCHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibilityType NOCHECK CONSTRAINT ALL
	ALTER TABLE PCX_ManagementResponsibilityRollup NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioRelationship NOCHECK CONSTRAINT ALL	
	ALTER TABLE PortfolioRollupType NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Rollup NOCHECK CONSTRAINT ALL
	ALTER TABLE RP NOCHECK CONSTRAINT ALL
	ALTER TABLE SuperGroupMandate NOCHECK CONSTRAINT ALL
	ALTER TABLE SuperGroupMembers NOCHECK CONSTRAINT ALL

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @startTime datetime
	SELECT @startTime = GETDATE()
   	PRINT '------------------------------------------'
	PRINT 'Entering Proc: pop_Main Time:'+CONVERT(varchar, @startTime)
	SET NOCOUNT ON;

	-- to ensure things run faster - remove the index nox
	IF EXISTS (select name from sysindexes where name = 'PortfolioUCI') 
		DROP INDEX Portfolio.PortfolioUCI
	DELETE FROM PortfolioActivity
	DELETE FROM PortfolioAssociation
	DELETE FROM PortfolioRelationship
	DELETE FROM Portfolio

	-- next step - populate the Portfolio and PortfolioActivity tables
	-- iterate one by one based on PortfolioType(s) setup in previous step
	DECLARE @typeId int
	SELECT @typeId = (SELECT MIN(PortfolioTypeUid) from PortfolioType)
	WHILE @typeId <= (SELECT MAX(PortfolioTypeUid) from PortfolioType)
	BEGIN
		exec pop_Portfolio @typeId
		SELECT @typeId = (SELECT MIN(PortfolioTypeUid) from PortfolioType WHERE PortfolioTypeUid > @typeId)
	END
	-- now that we are done - create the clustered index
	CREATE UNIQUE CLUSTERED INDEX PortfolioUCI on Portfolio (PortfolioUid)

	PRINT '------------------------------------------'
	PRINT 'Entering Proc: pop_PortfolioAssociations Time:'+CONVERT(varchar, GETDATE())
	exec pop_PortfolioAssociations

   	PRINT '------------------------------------------'
	PRINT 'Entering Proc: pop_ConvertTemporaryPortfolioIDs Time:'+CONVERT(varchar, GETDATE())
	exec pop_ConvertTemporaryPortfolioIDs

   	PRINT '------------------------------------------'
	PRINT 'Entering Proc: pop_PorfolioRelationships Time:'+CONVERT(varchar, GETDATE())
	exec pop_PortfolioRelationships

   	PRINT '------------------------------------------'
	PRINT 'end of run Proc: pop_Main Lapse Time: '+CONVERT(varchar, DATEDIFF(second, @startTime, GETDATE()))

	ALTER TABLE Account CHECK CONSTRAINT ALL
	ALTER TABLE Currency CHECK CONSTRAINT ALL
	ALTER TABLE GroupMandate CHECK CONSTRAINT ALL
	ALTER TABLE InvestmentDivision CHECK CONSTRAINT ALL
	ALTER TABLE InvestmentProfessional CHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibility CHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibility_MARS_xref CHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibilityAssetClassCategory CHECK CONSTRAINT ALL
	ALTER TABLE ManagementResponsibilityType CHECK CONSTRAINT ALL
	ALTER TABLE PCX_ManagementResponsibilityRollup CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioRelationship CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioRollupType CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE Rollup CHECK CONSTRAINT ALL
	ALTER TABLE RP CHECK CONSTRAINT ALL
	ALTER TABLE SuperGroupMandate CHECK CONSTRAINT ALL
	ALTER TABLE SuperGroupMembers CHECK CONSTRAINT ALL

END

