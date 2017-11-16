# Backup databases to Azure storage

```sql
use master
 go
 
DECLARE @filename VARCHAR(255);

SET @filename = 'https://*****.blob.core.windows.net/backup/AdventureWork_Log'+'_'
 +CONVERT(varchar(100), GETDATE(), 100)+ '.trn';

 BACKUP log [AdventureWork]
 TO URL = @filename
 WITH CREDENTIAL = 'SQLBlobAdmin', COMPRESSION;
```

```sql
Use Master
Go

DECLARE @name VARCHAR(50);
DECLARE @filename VARCHAR(255);
DECLARE @storageAccount VARCHAR(255);
DECLARE @credential VARCHAR(100);

SET @storageAccount = 'shaktistr';
SET @credential = 'SQLBlobAdmin'

DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM master.dbo.sysdatabases
WHERE dbid NOT IN (2,3,11)
ORDER BY name ASC; -- only users databases
 
OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name;   
 
WHILE @@FETCH_STATUS = 0   
BEGIN   
 
 SET @filename = 'https://' + @storageAccount + '.blob.core.windows.net/backup/' + @name+'_FULL_'
 +CONVERT(varchar(100), GETDATE(), 100)+ '.bak';

 BACKUP database @name
 TO URL = @filename
 WITH CREDENTIAL = @credential, COMPRESSION,COPY_ONLY;

FETCH NEXT FROM db_cursor INTO @name;
END   
 
CLOSE db_cursor;
DEALLOCATE db_cursor;
```