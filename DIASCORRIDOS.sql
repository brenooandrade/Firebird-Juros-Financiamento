create or alter procedure DIASCORRIDOS (
    INICIO date,
    FIM date)
returns (
    DIAS integer)
AS
BEGIN
  DIAS = DATEDIFF(DAY FROM :INICIO TO :FIM);
  SUSPEND;
END