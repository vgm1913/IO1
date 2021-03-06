USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_ConvertTemporaryPortfolioIDs]    Script Date: 2/4/2015 7:58:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-21-2015
-- Description:	Special Utility to convert negative temporary Portfolio IDs to positive ones - IO1 Sprint Challenge supplemental
-- =============================================
ALTER PROCEDURE [dbo].[pop_ConvertTemporaryPortfolioIDs] 
	-- Add the parameters for the stored procedure here
	@portfolioTypeUid int = 0 -- optional if passed will only target Portfolios with negative numbers of type @portfolioTypeUid
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL 
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	
	-- temp storage will be removed in end
	create table #temp (old_PID bigint, new_PID bigint)
	 
    -- select list of Temporary Portfolio Uids that will be converted
	if (@portfolioTypeUid = 0) -- all Portfolios
		insert	into #temp
		SELECT	PortfolioUid, 0
		FROM	Portfolio
		WHERE	PortfolioUid < 0

	ELSE -- only select and convert Temporary Portflio UIDs of type selected
		insert	into #temp
		SELECT	PortfolioUid, 0
		FROM	Portfolio
		WHERE	PortfolioUid < 0
		AND		PortfolioTypeUid = @portfolioTypeUid

	DECLARE @current_PID	bigint, @next_PID bigint, @increment int
	DECLARE @print_msg	varchar(MAX)
	SELECT @increment = 166
	SELECT @next_PID = (SELECT MIN(PortfolioUid) FROM Portfolio WHERE PortfolioUid > 1)
	IF (@next_PID > 1)
		SELECT @next_PID = 1 -- start it at one unless the min PortfolioUid that exists is 1
	WHILE (SELECT COUNT(*) from #temp WHERE old_PID < 0 and new_PID = 0) > 0
	BEGIN
		SELECT @current_PID = (SELECT MIN(old_PID) from #temp WHERE new_PID = 0)
		WHILE EXISTS(SELECT PortfolioUid FROM Portfolio WHERE PortfolioUid = @next_PID)
			-- keep going up until we get a PortfolioUid that does not exist now
			SELECT @next_PID = (SELECT @next_PID + 1)

		IF EXISTS (SELECT PortfolioUid FROM Portfolio WHERE PortfolioUid = @next_PID)
		BEGIN
			PRINT 'current PID: '+CONVERT(varchar, @current_PID) + ' next PID: '+CONVERT(varchar, @next_PID)
			PRINT '******* PID EXISTS: '++CONVERT(varchar, @next_PID)
		END
		ELSE 
		BEGIN
			-- store the old/new pair for later reference table updates
			UPDATE #temp SET new_PID = @next_PID WHERE old_PID = @current_PID AND new_PID = 0
			-- but first change the portfolio id form the @current_PID Portfolio
--			SELECT @print_msg = (SELECT ' - Portfolio UID ='+CONVERT(varchar, PortfolioUid)+' '+PortfolioName FROM Portfolio WHERE PortfolioUid = @current_PID)
--			PRINT @print_msg
			UPDATE Portfolio SET PortfolioUid = @next_PID WHERE PortfolioUid = @current_PID
--			SELECT @print_msg = (SELECT ' - Portfolio UID ='+CONVERT(varchar, PortfolioUid)+' '+PortfolioName FROM Portfolio WHERE PortfolioUid = @current_PID)
--			PRINT @print_msg
--			SELECT @print_msg = (SELECT ' * Left to do: '+CONVERT(varchar, count(*)) FROM #temp WHERE new_PID = 0)
--			PRINT @print_msg
			-- go higher ; make sure we don't reuse the same next_PID
			SELECT @next_PID = (SELECT @next_PID + 1)
		END
	END
	
	DELETE FROM PortfolioActivity
	WHERE PortfolioUid in (SELECT old_PID from #temp WHERE old_PID < 0 and new_PID > 0)

	UPDATE PortfolioActivity
	SET PortfolioUid = a.new_PID
	FROM #temp a, PortfolioActivity b
	WHERE b.PortfolioUid < 0
	AND	b.PortfolioUid = a.old_PID
	AND a.new_PID > 0

	-- cleanup
	DROP TABLE #temp
	
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL 
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL 
	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL

END