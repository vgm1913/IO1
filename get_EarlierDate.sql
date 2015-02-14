USE [capital_system]
GO
/****** Object:  UserDefinedFunction [dbo].[get_EarlierDate]    Script Date: 2/13/2015 1:25:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01/30/2015
-- Description:	Utility function - return the ealier date of passed pair of datetime values
-- =============================================
ALTER FUNCTION [dbo].[get_EarlierDate] 
(
	-- Add the parameters for the function here
	@date1 datetime
,	@date2 datetime
)
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result datetime

	IF (@date1 < @date2)
		SELECT @Result = @date1
	ELSE
		SELECT @Result = @date2
	-- Return the result of the function
	RETURN @Result
END
