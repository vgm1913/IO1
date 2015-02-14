SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01/30/2015
-- Description:	Utility function - return the larger of the 2 passed in datetime values
-- =============================================
CREATE FUNCTION get_LaterDate 
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
		SELECT @Result = @date2
	ELSE
		SELECT @Result = @date1
	-- Return the result of the function
	RETURN @Result
END
GO

