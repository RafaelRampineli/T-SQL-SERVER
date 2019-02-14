SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TabCheckListEspacodisco](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Drive] [varchar](10) NULL,
	[Tamanho (MB)] [int] NULL,
	[Usado (MB)] [int] NULL,
	[Livre (MB)] [int] NULL,
	[Livre (%)] [int] NULL,
	[Usado (%)] [int] NULL,
	[Ocupado SQL (MB)] [int] NULL,
	[Data] [smalldatetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


