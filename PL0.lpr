program pl0(output);

{pl/0 compiler with code generation}

uses
  main,
  defs;

begin {main program}
  if paramcount <> 1 then
  begin
    Writeln('Usage: PL0 filename');
    exitprog;
  end;
  mainprog(ParamStr(1));
end.
