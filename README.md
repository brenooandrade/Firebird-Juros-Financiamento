# Firebird 3.0 - Cálculo de juros/financiamento
Procedures criadas por Breno Novais Andrade no Banco Firebird para realizar o cálculo de juro/financiamento via banco de dados (Funções do Excel: TIR, XTIR, PGTO).

1 - A procedure BUSCA_TIR irá retornar a Taxa Interna de Retorno de uma operação financeira.

2 - A tabela T021UNIDADES utilizada internamente na procedure BUSCA_TIR tem o intuito de apenas percorrer 15x os cálculos que tentam encontrar o valor da taxa, para isso basta que seja criado essa tabela T021UNIDADES, com os campos T021CODUND (integer) e T021TIPO (char(1) - default 'L'), adicione 15 registros com os códigos T021CODUND de 1 a 15 nessa tabela.

3 - A procedure CALC_COMERCIAL poderá trazer as informações de financiamento de acordo com o parâmetro TIPO:
      Tipo 1- Retorna Taxa de Juros (TIR)
      Tipo 2- Retorna Valor de Pagamento da Série (Parcela)
      Tipo 3- Retorna Valor Financiado
