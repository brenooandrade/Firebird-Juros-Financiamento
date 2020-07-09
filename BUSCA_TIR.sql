create or alter procedure BUSCA_TIR (
    NPERIODS double precision,
    PAYMENT double precision,
    PRESENTVALUE double precision,
    FUTUREVALUE double precision,
    PAYMENTTIME char(1))
returns (
    VAL_TIR double precision)
AS
    declare variable X DOUBLE PRECISION;
    declare variable Y DOUBLE PRECISION;
    declare variable Z DOUBLE PRECISION;
    declare variable ValFirst DOUBLE PRECISION;
    declare variable Pmt DOUBLE PRECISION;
    declare variable ValLast DOUBLE PRECISION;
    declare variable T DOUBLE PRECISION;
    declare variable ET DOUBLE PRECISION;
    declare variable EnT DOUBLE PRECISION;
    declare variable ET1 DOUBLE PRECISION;
    declare variable Reverso Integer;
    declare variable n_interacao Integer;
    declare variable aux3 numeric(18,15);
    declare variable C1 double precision;
    declare variable C2 double precision;
begin
    if (NPeriods <= 0) then exception Erro_Padrao 'Nº de períodos inválido';
    Payment = :Payment * -1;
    Pmt = Payment;
    if (PaymentTime = 'F') then begin
        X = PresentValue;
        Y = FutureValue + Payment;
    end else begin
        X = PresentValue + Payment;
        Y = FutureValue;
    end
    ValFirst = X;
    ValLast  = Y;
    Reverso  = 0;
    if ((ValFirst * Payment) > 0) then begin
       Reverso   = 1;
       T         = ValFirst;
       ValFirst  = ValLast;
       ValLast   = T;
    end
    if (ValFirst > 0) then begin
       ValFirst = -ValFirst;
       Pmt      = -Pmt;
       ValLast  = -ValLast;
    end
    if ((ValFirst = 0) or (ValLast < 0)) then exception Erro_Padrao 'Não foi possível encontrar a TIR';
    T = 0.0;
    FOR SELECT FIRST 15 U.T021CODUND FROM T021UNIDADES U
    WHERE U.T021TIPO IN ('L') ORDER BY U.T021CODUND INTO :N_INTERACAO DO BEGIN
        EnT = Exp(NPeriods * T);
        if (:EnT = (:EnT+1)) then begin
            VAL_TIR = -Pmt / ValFirst;
            if (Reverso = 1) then
                VAL_TIR = (Exp(-ln(VAL_TIR + 1)) - 1.0) * 100;
            suspend;
            exit;
        end
        ET  = Exp(T);
        ET1 = ET - 1.0;
        if (ET1 = 0) then begin
            X = NPeriods;
            Y = X * (X - 1.0) / 2.0;
        end else begin
            X = ET * (Exp((NPeriods - 1) * T)-1.0) / ET1;
            Y = (NPeriods * EnT - ET - X * ET) / ET1;
        end
        Z = Pmt * X + ValLast * EnT;
        aux3 = Ln(Z / - ValFirst) / ((Pmt * Y + ValLast * NPeriods * EnT) / Z);
        Y = aux3;
        T = T - Y;
        C1 = 1E-15;
        C2 = 1E-12;
        if (Abs(Y) < (C1 + C2 * Abs(T))) then begin
            if (Reverso = 0) then T = -T;
            VAL_TIR = (Exp(T)-1.0) * 100;
            suspend;
            exit;
        end
    END
    IF (VAL_TIR IS NULL) THEN BEGIN
      VAL_TIR = NULL;
      SUSPEND;
    END
end