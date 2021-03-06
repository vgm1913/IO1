USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_PortfolioAssociations]    Script Date: 2/13/2015 7:50:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-19-2015
-- Description:	Populate Account Manager Portfolio Activities for each Portfolio at higher level
-- =============================================
ALTER PROCEDURE [dbo].[pop_PortfolioAssociations]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- begin my reseting constraint check and wipping out old data
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	DELETE FROM PortfolioAssociation
	
    -- Populate based on MARS activity member for: all Entities by Management Responsibility & CII / CFII Investment Divisions
	-- the execption list is excluded due to the new CMPS entity relationship model and done in a second wave
	-- first things first - setup all Account to Management Responsibility rows filled in from MARS Acct-Mgr-Hist
	INSERT INTO PortfolioAssociation
	SELECT
		a.acctmgraggrid
	,	a.acctaggrid
	,	b.MgmtRespPortfolioUid
	,	convert(int, a.startdt) 
	,	RTRIM(LTRIM(convert(char, a.startdt, 107))) 
	,	convert(int, a.enddt)
	,	RTRIM(LTRIM(convert(char, a.enddt, 107)))
	,	0, 0, 0, 0, 0
	FROM
		mars_par_gap..pr_acct_mgr_hist a
	,	ManagementResponsibility_MARS_xref b
	WHERE
		a.mgraggrid = b.MARS_mgraggrid

	-- Update the PortfolioAssociation table based on RP, PCX, Group, Super Group, and Investment Division links via MARS pr_acct_mgr_hist table
	-- those A-M portfolios that are related to RP
	UPDATE PortfolioAssociation
	SET RPPortfolioUid = c.rppcxaggrid
	FROM PortfolioAssociation a
	,	mars_par_gap..pr_acct_mgr_hist c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_rp_pcx e
	WHERE
		c.acctaggrid = a.AcctPortfolioUid
	AND c.acctmgraggrid = a.AcctMgmtPortfolioUid
	AND c.mgraggrid = d.MARS_mgraggrid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND c.mgraggrid = d.MARS_mgraggrid
	AND e.aggrid = c.rppcxaggrid
	AND e.rppcxind != 'P'
	AND a.StartDateIdx = c.startdt
	AND a.EndDateIdx = c.enddt

	-- those A-M portfolios that are related to PCX-MgmrResp Rollups
	UPDATE PortfolioAssociation
	SET PCXPortfolioUid = c.rppcxaggrid
	FROM PortfolioAssociation a
	,	mars_par_gap..pr_acct_mgr_hist c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_rp_pcx e
	WHERE
		c.acctaggrid = a.AcctPortfolioUid
	AND c.acctmgraggrid = a.AcctMgmtPortfolioUid
	AND c.mgraggrid = d.MARS_mgraggrid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND a.StartDateIdx = c.startdt
	AND a.EndDateIdx = c.enddt
	AND c.mgraggrid = d.MARS_mgraggrid
	AND e.aggrid = c.rppcxaggrid
	AND e.rppcxind = 'P'

	-- those A-M portfolios that are related to Group
	UPDATE PortfolioAssociation
	SET GroupPortfolioUid = c.grpaggrid
	FROM PortfolioAssociation a
	,	mars_par_gap..pr_acct_mgr_hist c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_grp e
	WHERE
		c.acctaggrid = a.AcctPortfolioUid
	AND c.acctmgraggrid = a.AcctMgmtPortfolioUid
	AND c.mgraggrid = d.MARS_mgraggrid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND a.StartDateIdx = c.startdt
	AND a.EndDateIdx = c.enddt
	AND e.aggrid = c.grpaggrid
	AND e.sprgrpind != 'Y'
	AND e.grpnum not in ('CWI', 'CRGI', 'U')

	-- those A-M portfolios that are related to Super Group
	UPDATE PortfolioAssociation
	SET SuperGroupPortfolioUid = c.sprgrpaggrid
	FROM PortfolioAssociation a
	,	mars_par_gap..pr_acct_mgr_hist c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_grp e
	WHERE
		c.acctaggrid = a.AcctPortfolioUid
	AND c.acctmgraggrid = a.AcctMgmtPortfolioUid
	AND c.mgraggrid = d.MARS_mgraggrid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND a.StartDateIdx = c.startdt
	AND a.EndDateIdx = c.enddt
	AND e.aggrid = c.sprgrpaggrid
	AND e.sprgrpind = 'Y'

	-- those A-M portfolios that are related to Investment Division (CWI, CRGI & U via MARS)
	UPDATE PortfolioAssociation
	SET InvestDivPortfolioUid = c.grpaggrid
	FROM PortfolioAssociation a
	,	mars_par_gap..pr_acct_mgr_hist c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_grp e
	WHERE
		c.acctaggrid = a.AcctPortfolioUid
	AND c.acctmgraggrid = a.AcctMgmtPortfolioUid
	AND c.mgraggrid = d.MARS_mgraggrid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND a.StartDateIdx = c.startdt
	AND a.EndDateIdx = c.enddt
	AND e.aggrid = c.grpaggrid
	AND e.sprgrpind != 'Y'
	AND e.grpnum in ('CWI', 'CRGI', 'U')

	-- those A-M portfolio that are related to CII - Mgr Resp must be EQ and not already be in CWI or CRGI or U
	UPDATE PortfolioAssociation
	SET InvestDivPortfolioUid = b.PortfolioUid
	FROM PortfolioAssociation a
	,	Portfolio b
	,	PortfolioActivity c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_mgr e
	WHERE
		a.InvestDivPortfolioUid = 0
	AND c.PortfolioUid = b.PortfolioUid
	AND	c.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND a.StartDateIdx >= c.StartDateIdx
	AND a.EndDateIdx <= c.EndDateIdx
	AND	b.PortfolioTypeUid = 7
	AND b.PortfolioName = 'CII'
	AND	e.aggrid = d.MARS_mgraggrid
	AND a.MgmrRespPortfolioUid = d.MgmtRespPortfolioUid
	AND e.mgrtypcd = 'EQ'
	AND a.SuperGroupPortfolioUid != 0

	-- those A-M portfolio that are related to GIG - Mgr Resp must be EQ and not already be in CWI or CRGI or U
	UPDATE PortfolioAssociation
	SET InvestDivPortfolioUid = b.PortfolioUid
	FROM PortfolioAssociation a
	,	Portfolio b
	,	PortfolioActivity c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_mgr e
	WHERE
		a.InvestDivPortfolioUid = 0
	AND c.PortfolioUid = b.PortfolioUid
	AND	c.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND a.StartDateIdx >= c.StartDateIdx
	AND a.EndDateIdx <= c.EndDateIdx
	AND	b.PortfolioTypeUid = 7
	AND b.PortfolioName = 'GIG'
	AND	e.aggrid = d.MARS_mgraggrid
	AND a.MgmrRespPortfolioUid = d.MgmtRespPortfolioUid
	AND e.mgrtypcd = 'EQ'
	AND a.SuperGroupPortfolioUid != 0

	-- those A-M portfolio that are related to CFII - Mgr Resp must be FI and not already be in CWI or CRGI or U
	UPDATE PortfolioAssociation
	SET InvestDivPortfolioUid = b.PortfolioUid
	FROM PortfolioAssociation a
	,	Portfolio b
	,	PortfolioActivity c
	,	ManagementResponsibility_MARS_xref d
	,	mars_par_gap..pr_mgr e
	WHERE
		a.InvestDivPortfolioUid = 0
	AND c.PortfolioUid = b.PortfolioUid
	AND	c.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND d.MgmtRespPortfolioUid = a.MgmrRespPortfolioUid
	AND a.StartDateIdx >= c.StartDateIdx
	AND a.EndDateIdx <= c.EndDateIdx
	AND	b.PortfolioTypeUid = 7
	AND b.PortfolioName = 'CFII'
	AND	e.aggrid = d.MARS_mgraggrid
	AND a.MgmrRespPortfolioUid = d.MgmtRespPortfolioUid
	AND e.mgrtypcd = 'FI'
	AND a.SuperGroupPortfolioUid != 0

	-- restore the constraints and finish up
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL

END

