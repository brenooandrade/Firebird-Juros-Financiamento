# Firebird 3.0
Procedures criadas por mim no Firebird para realizar o cálculo de juro/financiamento via banco de dados (Funções do Excel: TIR, XTIR, PGTO).

A procedure BUSCA_TIR irá retornar a Taxa Interna de Retorno de uma operação financeira.
A procedure CALC_COMERCIAL poderá trazer as informações de financiamento de acordo com o parâmetro TIPO:
      1- Retorna Taxa de Juros (TIR)
      2- Retorna Valor de Pagamento da Série (Parcela)
      3- Retorna Valor Financiado
