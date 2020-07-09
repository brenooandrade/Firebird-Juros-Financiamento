create or alter procedure CALC_COMERCIAL (
    ENTRADA double precision,
    PV double precision,
    PARCELA double precision,
    I double precision,
    NUM_PERIODO double precision,
    FV double precision,
    TIPO integer,
    DTVENDA date,
    DTENTRADA date,
    DTPRIMEIRA date)
returns (
    VAL_ENTRADA double precision,
    VAL_PV double precision,
    VAL_PARCELA double precision,
    VAL_I double precision,
    VAL_NUM_PERIODO double precision,
    VAL_FINANCIADO double precision,
    VAL_FV double precision,
    VAL_JUROS_ENT double precision,
    VAL_JUROS double precision,
    VAL_EQUIVALENTE double precision)
AS
declare variable RES_EQUI double precision;
   declare variable IDC_EQUI double precision;
   declare variable AUX1 double precision;
   declare variable AUX2 double precision;
   declare variable DIASENT integer;
   declare variable DIASPRI integer;
   declare variable CARENCIAENTRADA integer;
   declare variable CARENCIAAPRAZO integer;
   declare variable DIASDIF integer;
BEGIN
   /* PROCESSO:
      1- Retorna Taxa de Juros
      2- Retorna Valor de Pagamento da Série (Parcela)
      3- Retorna Valor Financiado
  ----------------------------------------------------- */
   VAL_ENTRADA               = :ENTRADA;
   VAL_PV                    = :PV;
   VAL_PARCELA               = :PARCELA;
   VAL_NUM_PERIODO           = :NUM_PERIODO;
   VAL_FV                    = :FV;
   VAL_I                     = :I;
   VAL_FINANCIADO            = :PV - :ENTRADA;

   -- TAXA INTERNA DE RETORNO
   IF (:TIPO = 1) THEN BEGIN
      SELECT VAL_TIR FROM BUSCA_TIR(:NUM_PERIODO, :PARCELA * -1, :VAL_FINANCIADO, :FV, 'F') INTO :VAL_I;
   END

   -- VALOR DA PARCELA E VALOR DA ENTRADA
   IF (:TIPO = 2) THEN BEGIN
      IF (COALESCE(:I,0) > 0) THEN BEGIN
         SELECT CAST(COALESCE(C.VALOR,0) AS INTEGER) FROM CONFIGURACOES C
         WHERE C.PARAMETRO = 'Venda.Dias.CarenciaEntrada' INTO :CARENCIAENTRADA;
         IF (:CARENCIAENTRADA IS NULL) THEN CARENCIAENTRADA = 0;
         -- VALOR DA ENTRADA
         DIASDIF = DATEDIFF(DAY, :DTENTRADA, :DTVENDA) * -1;
         IF ((:ENTRADA > 0) AND (:DIASDIF > :CARENCIAENTRADA)) THEN BEGIN
            SELECT DIAS - 30 FROM DIASCORRIDOS(:DTVENDA, :DTENTRADA) INTO :DIASENT;
            SELECT
               CASE
                  WHEN CAST(:I AS DOUBLE PRECISION) = 0 THEN
                     CAST(:VAL_FINANCIADO AS DOUBLE PRECISION) / CAST(1 AS DOUBLE PRECISION)
                  WHEN CAST(COALESCE(:DIASENT, 0) AS INTEGER) <> 0 THEN
                     (CAST((1+0)*(1/(((POWER(1+(CAST(:I AS DOUBLE PRECISION)/100),
                     CAST(1 AS DOUBLE PRECISION))-1)/((CAST(:I AS DOUBLE PRECISION)/100)*
                     (POWER((1+CAST(:I AS NUMERIC(15,4))/100),(CAST(1 AS DOUBLE PRECISION)+(CAST(:DIASENT AS DOUBLE PRECISION)/30)))))))) AS DOUBLE PRECISION)) * CAST(:ENTRADA AS DOUBLE PRECISION)
                  ELSE
                     CAST(:ENTRADA AS DOUBLE PRECISION) * (((CAST(:I AS DOUBLE PRECISION) / 100) *
                     (POWER((1 + CAST(:I AS DOUBLE PRECISION) / 100), CAST(1 AS DOUBLE PRECISION)))) /
                     (POWER((1 + CAST(:I AS DOUBLE PRECISION) / 100), CAST(1 AS DOUBLE PRECISION)) - 1))
               END
            FROM RDB$DATABASE INTO :VAL_JUROS_ENT;
         END ELSE VAL_JUROS_ENT = :ENTRADA;
         VAL_JUROS_ENT     = :VAL_JUROS_ENT - :VAL_ENTRADA;
         VAL_ENTRADA       = :ENTRADA;
   

         DIASDIF = DATEDIFF(DAY, :DTPRIMEIRA, :DTVENDA) * -1;
         IF (DIASDIF > 31) THEN BEGIN
            SELECT DIAS - 30 FROM DIASCORRIDOS(:DTVENDA, :DTPRIMEIRA) INTO :DIASPRI;
         END ELSE BEGIN
            DIASPRI = 0;
         END
         SELECT CAST(COALESCE(C.VALOR,0) AS INTEGER) FROM CONFIGURACOES C
         WHERE C.PARAMETRO = 'Venda.Dias.CarenciaAPrazo' INTO :CARENCIAAPRAZO;
         IF (:CARENCIAAPRAZO IS NULL) THEN CARENCIAAPRAZO = 0;
         SELECT
            CASE
               WHEN ((CAST(:I AS DOUBLE PRECISION) = 0) OR (:NUM_PERIODO = 0))  THEN
                  CASE WHEN (:NUM_PERIODO > 0) THEN
                           CAST(:VAL_FINANCIADO AS DOUBLE PRECISION) / CAST(:NUM_PERIODO AS DOUBLE PRECISION)
                       ELSE CAST(:VAL_FINANCIADO AS DOUBLE PRECISION) END
               WHEN (CAST(COALESCE(:DIASPRI, 0) AS INTEGER) <> 0) AND (CAST(COALESCE(:DIASPRI, 0) AS INTEGER) > :CARENCIAAPRAZO) THEN
                  (CAST((1+0)*(1/(((POWER(1+(CAST(:I AS DOUBLE PRECISION)/100),
                  CAST(:NUM_PERIODO AS DOUBLE PRECISION))-1)/((CAST(:I AS DOUBLE PRECISION)/100)*
                  (POWER((1+CAST(:I AS NUMERIC(15,4))/100),(CAST(:NUM_PERIODO AS DOUBLE PRECISION)+(CAST(:DIASPRI AS DOUBLE PRECISION)/30)))))))) AS DOUBLE PRECISION)) * CAST(:VAL_FINANCIADO AS DOUBLE PRECISION)
               ELSE
                  CAST(:VAL_FINANCIADO AS DOUBLE PRECISION) * (((CAST(:I AS DOUBLE PRECISION) / 100) *
                  (POWER((1 + CAST(:I AS DOUBLE PRECISION) / 100), CAST(:NUM_PERIODO AS DOUBLE PRECISION)))) /
                  (POWER((1 + CAST(:I AS DOUBLE PRECISION) / 100), CAST(:NUM_PERIODO AS DOUBLE PRECISION)) - 1))
            END
         FROM RDB$DATABASE INTO :VAL_PARCELA;
      END ELSE BEGIN
         IF (:NUM_PERIODO > 0) THEN VAL_PARCELA = :VAL_FINANCIADO / :NUM_PERIODO;
         ELSE BEGIN
            VAL_FV      = :VAL_FINANCIADO;
            VAL_PARCELA = :VAL_FINANCIADO;
         END
      END
   END

   -- VALOR FINANCIADO
   IF (:TIPO = 3) THEN BEGIN
      IF ((COALESCE(VAL_I, 0) > 0) AND (COALESCE(VAL_PARCELA, 0) > 0)) THEN BEGIN
         AUX1           = CAST((:VAL_PARCELA * (CAST(POWER(1+(:VAL_I/100), :NUM_PERIODO)AS NUMERIC(15,4))-1)) AS NUMERIC(15,4));
         AUX2           = CAST((:VAL_I/100) * POWER(1+(:VAL_I/100), :NUM_PERIODO) AS NUMERIC(15,4));
         VAL_PV         = CAST((:AUX1 / :AUX2) + :VAL_ENTRADA AS NUMERIC(15,2));
         VAL_FINANCIADO = CAST((:AUX1 / :AUX2) AS NUMERIC(15,2));
      END
   END

   IF (COALESCE(:VAL_FV,0) <= 0) THEN BEGIN
      -- TRATANDO TAXA 0
      IF ((COALESCE(:I,0) = 0) AND (:TIPO <> 1)) THEN BEGIN
         IF (:NUM_PERIODO > 0) THEN VAL_FV = :VAL_PV;
      END ELSE BEGIN
         IF (:NUM_PERIODO > 0) THEN VAL_FV = :VAL_PARCELA * :NUM_PERIODO;
         ELSE VAL_FV = :VAL_PV;
      END
   END
   -- BUSCANDO ENTRADA EQUIVALENTE
   IF ((:NUM_PERIODO > 0) AND ((COALESCE(:I,0) > 0) OR (:TIPO = 1))) THEN BEGIN
      RES_EQUI        = ((1 + 0) *(1/((POWER((1+(:VAL_I/100)),:NUM_PERIODO)-1)/((:VAL_I/100)*POWER((1+(:VAL_I/100)),:NUM_PERIODO)))));
      IDC_EQUI        = :RES_EQUI/(:RES_EQUI + 1);
      VAL_EQUIVALENTE = :IDC_EQUI * :VAL_PV;
   END ELSE BEGIN
      IF(:NUM_PERIODO > 0) THEN VAL_EQUIVALENTE = :VAL_FV / :NUM_PERIODO;
      ELSE VAL_EQUIVALENTE = :VAL_FV;
   END
   -- TRATANDO TAXA 0
   IF ((COALESCE(:I,0) = 0) AND (:TIPO <> 1)) THEN VAL_JUROS = 0;
   ELSE VAL_JUROS = :VAL_FV - (:VAL_PV - :VAL_ENTRADA);
   SUSPEND;
END