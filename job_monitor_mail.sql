DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)
DECLARE @result NVARCHAR(MAX)
DECLARE @jobID NVARCHAR(MAX)

SET @jobID = '5ABB8AAD-4B6E-4BC0-9442-8772E7871917'

-- tabela z wczoraj
 CREATE TABLE #Temp_job_tabela
( 
  [step_id]  [int],
  [PRV_Duration]  [varchar](128),
)
INSERT INTO #Temp_job_tabela
 SELECT  
  [step_id],
 STUFF(STUFF(STUFF(RIGHT(REPLICATE('0', 8) + CAST(run_duration AS VARCHAR(8)), 8), 3, 0, ':'), 6, 0, ':'), 9, 0, ':') AS 'td'
 FROM [msdb].[dbo].[sysjobhistory] 
  WHERE job_id = @jobID
  AND CONVERT (DATETIME,RTRIM(run_date))+(run_time* 9 +run_time% 10000 * 6 +run_time% 100 * 10)/ 216e4 <= GETDATE()-1
  AND CONVERT (DATETIME,RTRIM(run_date))+(run_time* 9 +run_time% 10000 * 6 +run_time% 100 * 10)/ 216e4 > GETDATE()-2
 ORDER BY run_date DESC, step_id 

---------------

SET @xml = CAST((  SELECT 
 dzis.[step_id] AS 'td','',
CONVERT (DATETIME,RTRIM(dzis.run_date))+(dzis.run_time* 9 +dzis.run_time% 10000 * 6 +dzis.run_time% 100 * 10)/ 216e4 AS 'td','',
dzis.[step_name] AS 'td','', 
[td] = case when dzis.[run_status] = 0 then 'Failed'
	        when dzis.[run_status] = 1 then 'Succeeded'
	        when dzis.[run_status] = 2 then 'Retry'
	        when dzis.[run_status] = 3 then 'Canceled'
            when dzis.[run_status] = 4 then 'Running'
	        else 'Unknown'
	       end , '',
STUFF(STUFF(STUFF(RIGHT(REPLICATE('0', 8) + CAST(dzis.run_duration AS VARCHAR(8)), 8), 3, 0, ':'), 6, 0, ':'), 9, 0, ':')  'td','',
wczoraj.PRV_Duration  'td'

FROM [msdb].[dbo].[sysjobhistory] AS dzis
LEFT OUTER JOIN #Temp_job_tabela AS wczoraj
   ON dzis.step_id = wczoraj.step_id

  WHERE job_id = @jobID
  AND CONVERT (DATETIME,RTRIM(run_date))+(run_time* 9 +run_time% 10000 * 6 +run_time% 100 * 10)/ 216e4 >= DATEADD(day, -1, GETDATE())
 ORDER BY run_date DESC, dzis.step_id 


FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))


SET @result = (SELECT run_status = case when [run_status] = 0 then 'Failed'
	        when [run_status] = 1 then 'Succeeded'
	        when [run_status] = 2 then 'Retry'
	        when [run_status] = 3 then 'Canceled'
            when [run_status] = 4 then 'Running'
	        else 'Unknown'
	       end   FROM  [msdb].[dbo].[sysjobhistory] WHERE job_id = @jobID and step_id = '0'
 AND CONVERT (DATETIME,RTRIM(run_date))+(run_time* 9 +run_time% 10000 * 6 +run_time% 100 * 10)/ 216e4 >= DATEADD(day, -1, GETDATE())  )

SET @body ='<html><body><H3>'+@result+' - Job Dzienne przeliczenie - wielokrokowe</H3>
<table border = 1> 
<tr>
<th> Step ID </th> <th> Run Date Time </th> <th> Step Name </th> <th> Run Status </th>  <th> Today Duration </th> <th> Last Day Duration </th></tr>'    

SET @body = @body + @xml +'</table></body></html>'

SET @result = @result+' - Job Dzienne przeliczenie - wielokrokowe'

EXEC msdb.dbo.sp_send_dbmail
	@profile_name = N'email_raportyO365',
    @recipients = 'michal.hajduk@psw.com.pl;artur.formella@psw.com.pl;Maksymilian.Wozniak@psw.com.pl;Karol.Skupski@psw.com.pl;Krzysztof.Kozel@psw.com.pl;Barbara.Rozniecka@psw.com.pl;hanna.koprowska@psw.com.pl;agnieszka.plotka@psw.com.pl',
   	--@recipients = 'michal.hajduk@psw.com.pl',
	@subject = @result,
    @body = @body,
	@body_format = 'HTML'
DROP TABLE #Temp_job_tabela
