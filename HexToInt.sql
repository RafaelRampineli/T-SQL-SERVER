SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  FUNCTION [dbo].[HexToInt](@Caracter char)  
RETURNS int AS  
BEGIN 
	DECLARE @Retorno int

	IF ISNUMERIC(@Caracter) = 1
		SET @Retorno = ASCII(@Caracter) - ASCII('0')
	ELSE
		SET @Retorno = ASCII(@Caracter) - ASCII('A') + 10

	RETURN @Retorno

END


