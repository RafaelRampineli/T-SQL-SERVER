/****** Object:  Table [dbo].[TabTraceAlteracaoObjeto]    Script Date: 25/05/2015 15:30:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TabTraceAlteracaoObjeto](
	[taoID] [int] IDENTITY(1,1) NOT NULL,
	[taoTipoEvento] [varchar](30) NULL,
	[taoDataAlteracao] [datetime] NULL,
	[taoNomeServidor] [varchar](20) NULL,
	[taoNomeLogin] [varchar](50) NULL,
	[taoNomeDataBase] [varchar](20) NULL,
	[taoNomeObjeto] [varchar](50) NULL,
	[taoDescricaoEvento] [xml] NULL,
	[taoNomeHost] [varchar](80) NULL,
PRIMARY KEY CLUSTERED 
(
	[taoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO




/****** Object:  DdlTrigger [trg_TraceAlteracaoObjeto]    Script Date: 25/05/2015 15:31:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [trg_TraceAlteracaoObjeto]

ON DATABASE

FOR DDL_DATABASE_LEVEL_EVENTS

AS

BEGIN

    SET NOCOUNT ON

    DECLARE @Evento XML

    SET @Evento = EVENTDATA()

    INSERT INTO TabTraceAlteracaoObjeto(
    		taoTipoEvento, 
            taoDataAlteracao, 
            taoNomeServidor, 
            taoNomeLogin, 
            taoNomeDataBase, 
            taoNomeObjeto, 
            taoDescricaoEvento,
			taoNomeHost)

    SELECT  @Evento.value('(/EVENT_INSTANCE/EventType/text())[1]','varchar(50)') Tipo_Evento,

            @Evento.value('(/EVENT_INSTANCE/PostTime/text())[1]','datetime') PostTime,

            @Evento.value('(/EVENT_INSTANCE/ServerName/text())[1]','varchar(50)') ServerName,

            @Evento.value('(/EVENT_INSTANCE/LoginName/text())[1]','varchar(50)') LoginName,

            @Evento.value('(/EVENT_INSTANCE/DatabaseName/text())[1]','varchar(50)') DatabaseName,

            @Evento.value('(/EVENT_INSTANCE/ObjectName/text())[1]','varchar(50)') ObjectName, @Evento,

			HOST_NAME()

END


GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

ENABLE TRIGGER [trg_TraceAlteracaoObjeto] ON DATABASE
GO


