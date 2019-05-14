USE [$(db)]
GO

-- set the status of all servers to stopped and clear any 'not responding' status. Any job services which are still active will automatically change the status to 2
UPDATE [dbo].[JobServices] SET status=0
WAITFOR DELAY '00:00:10.000'

-- Get list of services which remain stopped
SELECT JobServiceId INTO #EXECLIST FROM [dbo].[JobServices] WHERE status=0

-- Get list of job message ids from services
-- 
SELECT jm.JobMessageId INTO #JOBIDLIST
  FROM JobMessageDetails jmd with(nolock)
	join JobMessages jm with(nolock) on jmd.JobMessageId = jm.JobMessageId
 WHERE (jmd.ExecutorJobServiceId in (SELECT * FROM #EXECLIST)) OR (jmd.ExecutorJobServiceId IS NULL) OR (jmd.Progress <> 100 AND jmd.EndTimestamp IS NOT NULL)

-- Set the ReceiverJobServiceId in messages to NULL to avoid 
UPDATE JobMessages SET ReceiverJobServiceId=NULL WHERE JobMessageId in (SELECT * FROM #JOBIDLIST)

-- Delete records from Blueprint DB
DELETE FROM JobMessageDetails WHERE JobMessageId in (SELECT * FROM #JOBIDLIST)
DELETE FROM JobMessages WHERE JobMessageId in (SELECT * FROM #JOBIDLIST)

DELETE JobServices
  FROM JobServices js with(nolock)
 WHERE js.JobServiceId in (SELECT * FROM #EXECLIST)

DROP TABLE #JOBIDLIST
DROP TABLE #EXECLIST