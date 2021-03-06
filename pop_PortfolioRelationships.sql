USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[pop_PortfolioRelationships]    Script Date: 2/11/2015 10:29:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02-07-2015
-- Description:	populate PortfolioRelationship table based on PortfolioAssociation and MARS data
-- =============================================
ALTER PROCEDURE [dbo].[pop_PortfolioRelationships] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	ALTER TABLE PortfolioRelationship NOCHECK CONSTRAINT ALL
	DELETE FROM PortfolioRelationship 
	
	DECLARE @ACCT_Type int, @MGMT_Type int, @RP_Type int, @PCX_Type int, @GRP_Type int, @SGRP_Type int, @INVDIV_Type int
	SELECT @ACCT_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'ACCT')
	SELECT @MGMT_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'MGR')
	SELECT @RP_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'RP')
	SELECT @PCX_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'PCX')
	SELECT @GRP_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'GROUP')
	SELECT @SGRP_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'SUPERGROUP')
	SELECT @INVDIV_Type = (SELECT PortfolioTypeUid FROM PortfolioType WHERE PortfolioTypeAbbr = 'INVESTDIV')

	/* Valid Relationship Portfolio Types:
		ACCT-MGR    ACCT-RP     ACCT-PCX    GROUP-ACCT  INVDIV-ACCT 
		GRP-MGR     RP-MGR      SGRP-MGR    PCX-MGR     INVDIV-MGR  
		GROUP-RP    GROUP-PCX   SGRP-RP     SGRP-PCX    
		INVDIV-RP   INVDIV-PCX  INVDIV-GRP  INVDIV-SGRP 
	*/
	
	PRINT 'populate PortfolioRelationship Table for Portfolios of type: ACCT-MGR'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		a.AcctMgmtPortfolioUid
	,	a.AcctPortfolioUid
	,	@ACCT_Type
	,	a.MgmrRespPortfolioUid
	,	@MGMT_Type 
	FROM
		PortfolioAssociation a

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: ACCT-RP'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.AcctPortfolioUid
	,	@ACCT_Type
	,	a.RPPortfolioUid
	,	@RP_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'ACCT-RP'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.RPPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: ACCT-PCX'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.AcctPortfolioUid
	,	@ACCT_Type
	,	a.PCXPortfolioUid
	,	@PCX_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'ACCT-PCX'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.PCXPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: GROUP-ACCT'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.AcctPortfolioUid
	,	@ACCT_Type
	,	a.GroupPortfolioUid
	,	@GRP_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'GROUP-ACCT'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.GroupPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: INVDIV-ACCT'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.AcctPortfolioUid
	,	@ACCT_Type
	,	a.InvestDivPortfolioUid
	,	@INVDIV_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'INVDIV-ACCT'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.InvestDivPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: RP-MGR'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.MgmrRespPortfolioUid
	,	@MGMT_Type
	,	a.RPPortfolioUid
	,	@RP_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'RP-MGR'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.RPPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: PCX-MGR'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.MgmrRespPortfolioUid
	,	@MGMT_Type
	,	a.PCXPortfolioUid
	,	@RP_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'PCX-MGR'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.PCXPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: GRP-MGR'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.MgmrRespPortfolioUid
	,	@MGMT_Type
	,	a.GroupPortfolioUid
	,	@GRP_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'GRP-MGR'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.GroupPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: SGRP-MGR'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.MgmrRespPortfolioUid
	,	@MGMT_Type
	,	a.SuperGroupPortfolioUid
	,	@SGRP_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'SGRP-MGR'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.SuperGroupPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: INVDIV-MGR'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.MgmrRespPortfolioUid
	,	@MGMT_Type
	,	a.InvestDivPortfolioUid
	,	@INVDIV_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'INVDIV-MGR'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.InvestDivPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: GROUP-RP'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.RPPortfolioUid
	,	@RP_Type 
	,	a.GroupPortfolioUid
	,	@GRP_Type
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'GROUP-RP'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.GroupPortfolioUid != 0
	AND a.RPPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: GROUP-PCX'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.PCXPortfolioUid
	,	@PCX_Type 
	,	a.GroupPortfolioUid
	,	@GRP_Type
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'GROUP-PCX'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.GroupPortfolioUid != 0
	AND a.PCXPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: SGRP-RP'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.RPPortfolioUid
	,	@RP_Type 
	,	a.SuperGroupPortfolioUid
	,	@SGRP_Type
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'SGRP-RP'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.SuperGroupPortfolioUid != 0
	AND a.RPPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: SGRP-PCX'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.PCXPortfolioUid
	,	@PCX_Type 
	,	a.SuperGroupPortfolioUid
	,	@SGRP_Type
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'SGRP-PCX'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.SuperGroupPortfolioUid != 0
	AND a.PCXPortfolioUid != 0
	
	PRINT 'populate PortfolioRelationship Table for Portfolios of type: INVDIV-RP'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.RPPortfolioUid
	,	@RP_Type
	,	a.InvestDivPortfolioUid
	,	@INVDIV_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'INVDIV-RP'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.RPPortfolioUid != 0
	AND	a.InvestDivPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: INVDIV-PCX'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.PCXPortfolioUid
	,	@PCX_Type
	,	a.InvestDivPortfolioUid
	,	@INVDIV_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'INVDIV-PCX'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.PCXPortfolioUid != 0
	AND a.InvestDivPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: INVDIV-GRP'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.GroupPortfolioUid
	,	@GRP_Type
	,	a.InvestDivPortfolioUid
	,	@INVDIV_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'INVDIV-GRP'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.GroupPortfolioUid != 0
	AND a.InvestDivPortfolioUid != 0

	PRINT 'populate PortfolioRelationship Table for Portfolios of type: INVDIV-SGRP'
	INSERT INTO PortfolioRelationship
	SELECT DISTINCT
		b.PortfolioUid
	,	a.SuperGroupPortfolioUid
	,	@SGRP_Type
	,	a.InvestDivPortfolioUid
	,	@INVDIV_Type 
	FROM
		PortfolioAssociation a
	,	Portfolio b
	,	PortfolioType c
	,	PortfolioActivity d
	WHERE
		c.PortfolioTypeAbbr = 'INVDIV-SGRP'
	AND c.PortfolioTypeUid = b.PortfolioTypeUid
	AND b.PortfolioUid = d.PortfolioUid
	AND d.AcctMgrPortfolioUid = a.AcctMgmtPortfolioUid
	AND a.SuperGroupPortfolioUid != 0
	AND a.InvestDivPortfolioUid != 0

END
