USE [cmps_2]
GO
/****** Object:  StoredProcedure [dbo].[pop_PortfolioType]    Script Date: 1/19/2015 7:05:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 01-15-2015
-- Description:	Populates PortfolioType table
-- =============================================
ALTER PROCEDURE [dbo].[pop_PortfolioType] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	ALTER TABLE PortfolioType NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioType_MARS NOCHECK CONSTRAINT ALL
	ALTER TABLE EntityType NOCHECK CONSTRAINT ALL
	ALTER TABLE EntityRelationshipType NOCHECK CONSTRAINT ALL
	ALTER TABLE Portfolio NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation NOCHECK CONSTRAINT ALL
	ALTER TABLE PortfolioRollupType NOCHECK CONSTRAINT ALL

	-- create PortfolioType meta data
	if (select count(*) from PortfolioType) > 0
		delete from PortfolioType
	
	insert into PortfolioType
	select 
		b.EntityTypeID PortfolioTypeID
	,	b.AggregateTypeCd
	,	PortfolioTypeAbbr
	,	PortfolioTypeDescription
	,	RelationshipTypeFlag
	,	RelationshipEntityType1 PortfolioTypeA
	,	RelationshipEntityType2 PortfolioTypeB
	,	NULL
	from	cmps..PortfolioType a, cmps..EntityType b
	where	a.EntityTypeID = b.EntityTypeID
	and		a.PortfolioTypeID < 3000
	and		b.EntityTypeID in (select distinct EntityTypeID from cmps..InvestmentEntity)

	update PortfolioType set AggrTypeCd = 'MG', PortfolioTypeAbbr = 'P-MGR' where PortfolioTypeUid = 2
	delete from PortfolioType where PortfolioTypeUid = 8
	update PortfolioType set PortfolioTypeA = 2 where PortfolioTypeA = 8
	update PortfolioType set PortfolioTypeB = 2 where PortfolioTypeB = 8
	update PortfolioType set PortfolioTypeName = 'CG Entity Portfolios: Mgmt.Resp. Rollup (PCX)', PortfolioTypeAbbr = 'P-PCX' where PortfolioTypeUid = 4
	update PortfolioType set PortfolioTypeAbbr = 'ACCT-MGR' where PortfolioTypeUid = 80
	update PortfolioType set PortfolioTypeAbbr = 'GRP-MGR' where PortfolioTypeUid = 81
	update PortfolioType set PortfolioTypeAbbr = 'RP-MGR' where PortfolioTypeUid = 82
	update PortfolioType set PortfolioTypeAbbr = 'PCX-MGR' where PortfolioTypeUid = 84
	update PortfolioType set PortfolioTypeAbbr = 'SGRP-MGR' where PortfolioTypeUid = 85
	update PortfolioType set PortfolioTypeUid = 83 where PortfolioTypeUid = 85
	update PortfolioType set ParentType = 6 where PortfolioTypeUid = 5
	delete from PortfolioType where PortfolioTypeUid in (100, 110, 111, 112)
	insert into PortfolioType VALUES (140, 'GA', 'INVDIV-ACCT', 'CG Relationship Portfolios: Inv.Div. Account Relationship', 'Y', 1, 7, NULL)
	insert into PortfolioType VALUES (141,	'GM', 'INVDIV-MGR' , 'CG Relationship Portfolios: Inv.Div. Mgr. Relationship', 'Y', 2, 7, NULL)
	insert into PortfolioType VALUES (142,	'GR', 'INVDIV-RP'  , 'CG Relationship Portfolios: Inv.Div. RP Relationship',	'Y', 3, 7, NULL)
	insert into PortfolioType VALUES (143,	'GR', 'INVDIV-PCX' , 'CG Relationship Portfolios: Inv.Div. PCX Relationship',	'Y', 4, 7, NULL)
	insert into PortfolioType VALUES (144,	'IG', 'INVDIV-GRP' , 'CG Relationship Portfolios: Inv.Div. Group Relationship', 'Y', 5, 7, NULL)
	insert into PortfolioType VALUES (145,	'IS', 'INVDIV-SGRP', 'CG Relationship Portfolios: Inv.Div. Super Group Relationship',	'Y', 6, 7, NULL)
	update PortfolioType set PortfolioTypeAbbr = substring(PortfolioTypeAbbr, 3, DATALENGTH(PortfolioTypeAbbr)) 
	from PortfolioType  where PortfolioTypeAbbr like 'P-%'

	ALTER TABLE PortfolioType CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioType_MARS CHECK CONSTRAINT ALL
	ALTER TABLE EntityType CHECK CONSTRAINT ALL
	ALTER TABLE EntityRelationshipType CHECK CONSTRAINT ALL
	ALTER TABLE Portfolio CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioActivity CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioAssociation CHECK CONSTRAINT ALL
	ALTER TABLE PortfolioRollupType CHECK CONSTRAINT ALL

END
