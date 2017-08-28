CREATE PROCEDURE [dbo].[create_cross_database_query] @catlogname VARCHAR (100) = '' 
AS 
  BEGIN 
      SET nocount ON; 

      DECLARE @sqlCommand VARCHAR(1000) 
      DECLARE @createsqlCommand VARCHAR(max) 
      DECLARE @recordCount INT 
	  DECLARE @dropsqlCommand VARCHAR(1000) 
	 
	  DECLARE @Counter INT 
	  DECLARE @InnerCounter INT 
	  DECLARE @IsnullValue nvarchar(10) 
      DECLARE @Length nvarchar(10) 

      --DECLARE THE VARIABLES FOR HOLDING DATA. 
      DECLARE @TABLE_CATALOG VARCHAR(100), 
              @TABLE_SCHEMA  VARCHAR(100), 
              @TABLE_NAME    VARCHAR(100), 
			  @COLUMN_NAME  VARCHAR(100),
			  @DATA_TYPE    nvarchar(128),
			  @CHARACTER_MAXIMUM_LENGTH nvarchar(100),
			  @IS_NULLABLE varchar(3)
      --DECLARE AND SET COUNTER. 
    
   IF ((SELECT CASE ServerProperty('EngineEdition') WHEN 1 THEN 'Personal' WHEN 2 THEN 'Standard' WHEN 3 THEN 'Enterprise' 
   WHEN 4 THEN 'Express'WHEN 5 THEN 'Azure' ELSE 'Unknown' END) = 'Azure')
     BEGIN
	  SET @Counter = 1 
	  SET @InnerCounter = 1
      --DECLARE THE CURSOR FOR A QUERY. 
      DECLARE tableinfo CURSOR read_only FOR 
              SELECT distinct table_catalog, 
                     table_schema, 
                     table_name 
      FROM   tableschemainfo where table_schema ='stg' 
      
    --OPEN CURSOR. 
    OPEN tableinfo 

    --FETCH THE RECORD INTO THE VARIABLES. 
    FETCH next FROM tableinfo INTO @TABLE_CATALOG, @TABLE_SCHEMA, @TABLE_NAME 

    --LOOP UNTIL RECORDS ARE AVAILABLE. 
    WHILE @@FETCH_STATUS = 0 
      BEGIN 
	  --- Clear existing external table 
	         IF EXISTS(SELECT * FROM  information_schema.TABLES WHERE  table_name = ''+@TABLE_NAME+'' )
			 BEGIN
			    IF EXISTS (SELECT * FROM   sys.synonyms WHERE  NAME = '' + @TABLE_NAME + '') 
             BEGIN 
                SET @dropsqlCommand = 'DROP SYNONYM ' + @TABLE_NAME 
                EXEC(@dropsqlCommand ) 
            END
			 SET @dropsqlCommand = 'DROP EXTERNAL TABLE stg.'+@TABLE_NAME
			 EXEC(@dropsqlCommand )  
			 END
-----------------------------------------------------------------------------------------------------------------------------------------------
          --print @TABLE_NAME +'-----------------------------'
          --CONDITION TO CHECK SYNONYMS IS EXISTS IN CURRENT DATABASE. 
          DECLARE columninfo CURSOR read_only FOR 
              SELECT table_catalog, 
                     table_schema, 
                     table_name,
					 COLUMN_NAME,
					 DATA_TYPE ,
					 CHARACTER_MAXIMUM_LENGTH,
					 IS_NULLABLE
              FROM   tableschemainfo where  table_name = ''+@TABLE_NAME+'' 			

			   --OPEN CURSOR. 
			   OPEN columninfo 

			   --FETCH THE RECORD INTO THE VARIABLES. 
         FETCH next FROM columninfo INTO @TABLE_CATALOG, @TABLE_SCHEMA, @TABLE_NAME ,@COLUMN_NAME,@DATA_TYPE,@CHARACTER_MAXIMUM_LENGTH,@IS_NULLABLE
		set  @createsqlCommand = 'CREATE EXTERNAL TABLE ['+ @TABLE_SCHEMA+'].'+@TABLE_NAME+ '('
      WHILE @@FETCH_STATUS = 0 
      BEGIN 
	       
	     set @IsnullValue = (SELECT CASE WHEN @IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END)
		 set @Length = (SELECT CASE WHEN @CHARACTER_MAXIMUM_LENGTH = '-1' THEN 'MAX' ELSE @CHARACTER_MAXIMUM_LENGTH END)
		 set @createsqlCommand = CONCAT(@createsqlCommand, @COLUMN_NAME+' '+@DATA_TYPE+'('+@Length+') '+@IsnullValue+', ');  
		  --Print @createsqlCommand
	     --INCREMENT COUNTER. 
        SET @InnerCounter = @InnerCounter + 1 
		FETCH next FROM columninfo INTO @TABLE_CATALOG, @TABLE_SCHEMA, @TABLE_NAME ,@COLUMN_NAME,@DATA_TYPE,@CHARACTER_MAXIMUM_LENGTH,@IS_NULLABLE
		

		
	  END
          --CLOSE THE CURSOR. 
		   set @createsqlCommand = substring(@createsqlCommand, 1, (len(@createsqlCommand) - 1)) 
		   set @createsqlCommand = @createsqlCommand +' ) WITH ( DATA_SOURCE = OSC_STG_DATASOURCE) '

		  EXEC(@createsqlCommand)
    CLOSE columninfo 

    DEALLOCATE columninfo 
----------------------------------------------------------------------------------------------------------------------------------------------------
 
          --INCREMENT COUNTER. 
          SET @Counter = @Counter + 1 

          --FETCH THE NEXT RECORD INTO THE VARIABLES. 
          FETCH next FROM tableinfo INTO @TABLE_CATALOG, @TABLE_SCHEMA, 
          @TABLE_NAME 
      END 

    --CLOSE THE CURSOR. 
    CLOSE tableinfo 

    DEALLOCATE tableinfo 

		EXEC [dbo].[create_synonyms]
	END
ELSE
BEGIN
EXEC [dbo].[create_synonyms]
EXEC [dbo].[create_synonyms] @catlogname
END

	
END 
