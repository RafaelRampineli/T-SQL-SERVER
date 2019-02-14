SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TabCheckListArquivoSQL](
	[Name] [varchar](250) NULL,
	[FileName] [varchar](250) NULL,
	[Size] [bigint] NULL,
	[MaxSize] [bigint] NULL,
	[Growth] [varchar](100) NULL,
	[Proximo_Tamanho] [bigint] NULL,
	[Situacao] [varchar](15) NULL,
	[DataExecucao] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


