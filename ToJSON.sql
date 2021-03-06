USE [capital_system]
GO
/****** Object:  StoredProcedure [dbo].[ToJSON]    Script Date: 2/9/2015 5:05:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		VGM
-- Create date: 02/03/2015
-- Description:	Convert SQL statements into JSON
-- Credits:		http://jaminquimby.com/servers/95-sql/sql-2008/145-code-tsql-convert-query-to-json
-- =============================================
ALTER PROCEDURE [dbo].[ToJSON] 
	-- Add the parameters for the stored procedure here
	@ParameterSQL AS VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @XMLString VARCHAR(MAX)
	DECLARE @XML XML
	DECLARE @Paramlist NVARCHAR(1000)
	SET @Paramlist = N'@XML XML OUTPUT'
	SET @SQL = 'WITH PrepareTable (XMLString)'
	SET @SQL = @SQL + 'AS('
	SET @SQL = @SQL + @ParameterSQL+ ' FOR XML RAW, TYPE, ELEMENTS '
	SET @SQL = @SQL + ')'
	SET @SQL = @SQL + ' SELECT @XML=[XMLString]FROM[PrepareTable]'
	--PRINT @SQL
	EXEC sp_executesql @SQL, @Paramlist, @XML=@XML OUTPUT
	
	SET @XMLString=CAST(@XML AS VARCHAR(MAX))
  
	DECLARE @JSON VARCHAR(MAX)
	DECLARE @Row VARCHAR(MAX)
	DECLARE @RowStart INT
	DECLARE @RowEnd INT
	DECLARE @FieldStart INT
	DECLARE @FieldEnd INT
	DECLARE @KEY VARCHAR(MAX)
	DECLARE @Value VARCHAR(MAX)
  
	DECLARE @StartRoot VARCHAR(100);SET @StartRoot='<row>'
	DECLARE @EndRoot VARCHAR(100);SET @EndRoot='</row>'
	DECLARE @StartField VARCHAR(100);SET @StartField='<'
	DECLARE @EndField VARCHAR(100);SET @EndField='>'
  
	SET @RowStart=CharIndex(@StartRoot,@XMLString,0)
	PRINT '['
	WHILE @RowStart>0
	BEGIN
		SET @RowStart=@RowStart+Len(@StartRoot)
	    SET @RowEnd=CharIndex(@EndRoot,@XMLString,@RowStart)
		SET @Row=SubString(@XMLString,@RowStart,@RowEnd-@RowStart)
		SET @JSON='  {'

		-- for each row
		SET @FieldStart=CharIndex(@StartField,@Row,0)
		WHILE @FieldStart>0
		BEGIN
			-- parse node key
	        SET @FieldStart=@FieldStart+Len(@StartField)
		    SET @FieldEnd=CharIndex(@EndField,@Row,@FieldStart)
			SET @KEY=SubString(@Row,@FieldStart,@FieldEnd-@FieldStart)
	        SET @JSON=@JSON+'"'+@KEY+'":'

		    -- parse node value
			SET @FieldStart=@FieldEnd+1
	        SET @FieldEnd=CharIndex('</',@Row,@FieldStart)
		    SET @Value=SubString(@Row,@FieldStart,@FieldEnd-@FieldStart)
			SET @JSON=@JSON+'"'+@Value+'", '
  
	        SET @FieldStart=@FieldStart+Len(@StartField)
		    SET @FieldEnd=CharIndex(@EndField,@Row,@FieldStart)
			SET @FieldStart=CharIndex(@StartField,@Row,@FieldEnd)
	    END
		IF LEN(@JSON)>0SET @JSON=SubString(@JSON,0,LEN(@JSON))
		SET @JSON=@JSON+'},'
		--/ for each row
		PRINT @JSON
  
		SET @RowStart=CharIndex(@StartRoot,@XMLString,@RowEnd)
	END
	IF LEN(@JSON)>0 SET @JSON=SubString(@JSON,0,LEN(@JSON))
	SET @JSON=@JSON+CHAR(13)+']'
	PRINT @JSON
END
