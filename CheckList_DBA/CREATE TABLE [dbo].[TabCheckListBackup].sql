SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TabCheckListBackup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[database_name] [nvarchar](256) NULL,
	[name] [nvarchar](256) NULL,
	[backup_start_date] [datetime] NULL,
	[tempo] [int] NULL,
	[server_name] [nvarchar](256) NULL,
	[recovery_model] [nvarchar](120) NULL,
	[tamanho] [numeric](15, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


