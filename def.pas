unit defs;

interface

uses
  Classes, SysUtils;

const
  NUM_RES_WORDS = 11;           { Number of reserved words }
  ID_TABLE_LEN = 100;           { Length of identifier table }
  MAX_DIGITS_IN_NUM = 10;       { Maximum number of digits in numbers }
  IDENTIFIER_LEN = 10;          { Length of identifiers }
  ADDR_MAX = 2047;              { Maximum address }
  MAX_BLOCK_NESTING = 3;        { Maximum depth of block nesting }
  CODE_ARR_SIZE = 200;          { Size of code array }

  ERR_MSGS: array[1..32] of string = (
    'Use = instead of :=',
    '= must be followed by a number',
    'Identifier must be followed by =',
    'const, var, procedure must be followed by an identifier',
    'Semicolon or comma missing',
    'Incorrect symbol after procedure declaration',
    'Statement expected',
    'Incorrect symbol after statement part in block',
    'Period expected',
    'Semicolon between statements is missing',
    'Undeclared identifier',
    'Assignment to constant or procedure is not allowed',
    'Assignment operator := expected',
    'Call must be followed by an identifier',
    'Call of a constant or a variable is meaningless',
    'then expected',
    'Semicolon or end expected',
    'do expected',
    'Incorrect symbol following statement',
    'Relational operator expected',
    'Expression must not contain a procedure identifier',
    'Right parenthesis missing',
    'The preceding factor cannot be followed by this symbol',
    'An expression cannot begin with this symbol',
    '',
    'A read must be followed by an identifier',
    'A read to constant or procedure is meaningless',
    '',
    '',
    'This number is too large',
    '',
    'Block nesting too deep'
  );

type
  symbol = (
    nul, ident, number, plus, minus, times, slash, oddsym, eql, neq,
    lss, leq, gtr, geq, lparen, rparen, comma, semicolon, period, becomes,
    beginsym, endsym, ifsym, thensym, whilesym, dosym, callsym, constsym,
    varsym, procsym, writesym, readsym
  );
  
  alfa = packed array [1..IDENTIFIER_LEN] of char;
  
  Obj = (constant, variable, proc);
  
  symset = set of symbol;
  
  fct = (lit, opr, lod, sto, cal, int, jmp, jpc);   { Functions }

  instruction = packed record
    f: fct;           { Function code }
    l: 0..MAX_BLOCK_NESTING;     { Level }
    a: 0..ADDR_MAX;        { Displacement address }
  end;

procedure exitprog;

var
  cc: integer;      { Character count }
  ll: integer;      { Line length }
  kk, err: integer;
  cx: integer;      { Code allocation index }
  a: alfa;
  code: array [0..CODE_ARR_SIZE] of instruction;
  mnemonic: array [fct] of packed array [1..5] of char;
  declbegsys, statbegsys, facbegsys: symset;
  table: array [0..ID_TABLE_LEN] of record
    Name: alfa;
    case kind: Obj of
      constant: (val: integer);
      variable, proc: (level, adr: integer)
  end;

implementation

procedure exitprog;
begin
  Writeln('Exiting the program...');
  Halt(1);
end;

end.
