SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TabCheckListJobsFailed](
	[Instance_Id] [int] NULL,
	[Job_Id] [varchar](255) NULL,
	[Job_Name] [varchar](255) NULL,
	[Step_Id] [int] NULL,
	[Step_Name] [varchar](255) NULL,
	[Sql_Message_Id] [int] NULL,
	[Sql_Severity] [int] NULL,
	[SQl_Message] [varchar](4000) NULL,
	[Run_Status] [int] NULL,
	[Run_Date] [int] NULL,
	[Run_Time] [int] NULL,
	[Run_Duration] [int] NULL,
	[Operator_Emailed] [varchar](255) NULL,
	[Operator_NetSent] [varchar](255) NULL,
	[Operator_Paged] [varchar](255) NULL,
	[Retries_Attempted] [int] NULL,
	[Nm_Server] [varchar](100) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


