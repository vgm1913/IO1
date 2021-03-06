USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_Portfolio_INVDIV_PCX]    Script Date: 2/13/2015 4:56:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-16-2015
-- Description:	Populate Investment Division to PCX based Portfolios - lowest level portfolios of Capital System
-- =============================================
ALTER PROCEDURE [dbo].[pop_Portfolio_INVDIV_PCX]
	@cutOffDate datetime
AS
BEGIN
	exec pop_Portfolio_INVDIV_RP_or_PCX @cutOffDate, 'P'
END

