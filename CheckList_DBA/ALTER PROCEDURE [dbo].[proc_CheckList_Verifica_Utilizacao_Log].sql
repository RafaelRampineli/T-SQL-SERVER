SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[proc_CheckList_Verifica_Utilizacao_Log]
AS
BEGIN

/*MONITORARMENTO DOS ARQUIVOS DE LOG */

DBCC SQLPERF (LOGSPACE)
END

