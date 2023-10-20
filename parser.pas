unit parser;

interface

uses
  Classes, SysUtils, defs;

procedure GetSymbol;
procedure Block(lev, tx: integer; fsys: symset);
procedure Error(n: integer);
procedure InitParser(PL0FileName: string);
procedure ExitParser;

var
  Sym: symbol;      {last symbol read}

implementation

uses codegen;

const
  POS_NOT_FOUND = 0;

var
  Ch: char;         {last character read}
  Id: alfa;         {last identifier read}
  Num: integer;     {last number read}
  Word: array [1..NUM_RES_WORDS] of alfa;
  Wsym: array [1..NUM_RES_WORDS] of symbol;
  Line: array [1..81] of char;
  Ssym: array [char] of symbol;
  SrcFile: TextFile;

procedure Error(n: integer);
begin
  Writeln(' ****', ' ': cc - 1, '^', n: 2, ': ', ERR_MSGS[n]);
  Err := Err + 1;
end {Error};

procedure GetSymbol;
var
  I, J, K: integer;

  procedure GetChar;
  begin
    if Cc = Ll then
    begin
      if EOF(SrcFile) then
      begin
        Write(' program incomplete');
        ExitProg;
      end;
      Ll := 0;
      Cc := 0;
      Write(Cx: 5, ' ');
      while not Eoln(SrcFile) do
      begin
        Ll := Ll + 1;
        Read(SrcFile, Ch);
        Write(Ch);
        Line[Ll] := Ch;
      end;
      Writeln;
      Readln(SrcFile);
      Ll := Ll + 1;
      Line[Ll] := ' ';
    end;
    Cc := Cc + 1;
    Ch := Line[Cc];
  end {GetChar};

begin {GetSymbol}
  while Ch = ' ' do
    GetChar;
  if Ch in ['a'..'z'] then
  begin {identifier or reserved word}
    K := 0;
    repeat
      if K < IDENTIFIER_LEN then
      begin
        K := K + 1;
        A[K] := Ch;
      end;
      GetChar;
    until not (Ch in ['a'..'z', '0'..'9']);
    if K >= Kk then
      Kk := K
    else
      repeat
        A[Kk] := ' ';
        Kk := Kk - 1
      until Kk = K;
    Id := A;
    I := 1;
    J := NUM_RES_WORDS;
    repeat
      K := (I + J) div 2;
      if Id <= Word[K] then
        J := K - 1;
      if Id >= Word[K] then
        I := K + 1;
    until I > J;
    if I - 1 > J then
      Sym := Wsym[K]
    else
      Sym := ident;
  end
  else
  if Ch in ['0'..'9'] then
  begin {number}
    K := 0;
    Num := 0;
    Sym := number;
    repeat
      Num := 10 * Num + (Ord(Ch) - Ord('0'));
      K := K + 1;
      GetChar;
    until not (Ch in ['0'..'9']);
    if K > MAX_DIGITS_IN_NUM then
      Error(30);
  end
  else
  if Ch = ':' then
  begin
    GetChar;
    if Ch = '=' then
    begin
      Sym := becomes;
      GetChar;
    end
    else
      Sym := nul;
  end
  else
  begin
    Sym := Ssym[Ch];
    GetChar;
  end;
end {GetSymbol};

procedure Test(s1, s2: symset; n: integer);
begin
  if not (Sym in s1) then
  begin
    Error(n);
    s1 := s1 + s2;
    while not (Sym in s1) do
      GetSymbol;
  end;
end {Test};

procedure Block(lev, tx: integer; fsys: symset);
var
  Dx: integer;     {data allocation index}
  Tx0: integer;     {initial table index}
  Cx0: integer;     {initial code index}

  procedure Enter(k: Obj);
  begin {enter object into table}
    Tx := Tx + 1;
    with Table[Tx] do
    begin
      Name := Id;
      Kind := k;
      case k of
        constant:
        begin
          if Num > ADDR_MAX then
          begin
            Error(30);
            Num := 0;
          end;
          Val := Num;
        end;
        variable:
        begin
          Level := Lev;
          Adr := Dx;
          Dx := Dx + 1;
        end;
        proc: Level := Lev
      end;
    end;
  end {Enter};

  function Position(Id: alfa): integer;
  var
    I: integer;
  begin {find identifier id in table}
    Table[POS_NOT_FOUND].Name := Id;
    I := Tx;
    while Table[I].Name <> Id do
      I := I - 1;
    Result := I;
  end {Position};

  procedure ConstDeclaration;
  begin
    if Sym = ident then
    begin
      GetSymbol;
      if Sym in [eql, becomes] then
      begin
        if Sym = becomes then
          Error(1);
        GetSymbol;
        if Sym = number then
        begin
          Enter(constant);
          GetSymbol;
        end
        else
          Error(2);
      end
      else
        Error(3);
    end
    else
      Error(4);
  end {ConstDeclaration};

  procedure VarDeclaration;
  begin
    if Sym = ident then
    begin
      Enter(variable);
      GetSymbol;
    end
    else
      Error(4);
  end {VarDeclaration};

  procedure ListCode;
  var
    I: integer;
  begin {list code generated for this block}
    for I := Cx0 to Cx - 1 do
      with Code[I] do
        Writeln(I: 5, Mnemonic[F]: 5, L: 3, A: 5);
  end {ListCode};

  procedure Statement(fsys: symset);
  var
    I, Cx1, Cx2: integer;

    procedure Expression(fsys: symset);
    var
      Addop: symbol;

      procedure Term(fsys: symset);
      var
        Mulop: symbol;

        procedure Factor(fsys: symset);
        var
          I: integer;
        begin
          Test(facbegsys, fsys, 24);
          while Sym in facbegsys do
          begin
            if Sym = ident then
            begin
              I := Position(Id);
              if I = POS_NOT_FOUND then
                Error(11)
              else
                with Table[I] do
                  case Kind of
                    constant: Gen(lit, 0, Val);
                    variable: Gen(lod, Lev - Level, Adr);
                    proc: Error(21)
                  end;
              GetSymbol;
            end
            else
            if Sym = number then
            begin
              if Num > ADDR_MAX then
              begin
                Error(30);
                Num := 0;
              end;
              Gen(lit, 0, Num);
              GetSymbol;
            end
            else
            if Sym = lparen then
            begin
              GetSymbol;
              Expression([rparen] + fsys);
              if Sym = rparen then
                GetSymbol
              else
                Error(22);
            end;
            Test(fsys, [lparen], 23);
          end;
        end {Factor};

      begin {Term}
        Factor(fsys + [times, slash]);
        while Sym in [times, slash] do
        begin
          Mulop := Sym;
          GetSymbol;
          Factor(fsys + [times, slash]);
          if Mulop = times then
            Gen(opr, 0, 4)
          else
            Gen(opr, 0, 5);
        end;
      end {Term};
    begin {Expression}
      if Sym in [plus, minus] then
      begin
        Addop := Sym;
        GetSymbol;
        Term(fsys + [plus, minus]);
        if Addop = minus then
          Gen(opr, 0, 1);
      end
      else
        Term(fsys + [plus, minus]);
      while Sym in [plus, minus] do
      begin
        Addop := Sym;
        GetSymbol;
        Term(fsys + [plus, minus]);
        if Addop = plus then
          Gen(opr, 0, 2)
        else
          Gen(opr, 0, 3);
      end;
    end {Expression};

    procedure Condition(fsys: symset);
    var
      Relop: symbol;
    begin
      if Sym = oddsym then
      begin
        GetSymbol;
        Expression(fsys);
        Gen(opr, 0, 6);
      end
      else
      begin
        Expression([eql, neq, lss, gtr, leq, geq] + fsys);
        if not (Sym in [eql, neq, lss, leq, gtr, geq]) then
          Error(20)
        else
        begin
          Relop := Sym;
          GetSymbol;
          Expression(fsys);
          case Relop of
            eql: Gen(opr, 0, 8);
            neq: Gen(opr, 0, 9);
            lss: Gen(opr, 0, 10);
            geq: Gen(opr, 0, 11);
            gtr: Gen(opr, 0, 12);
            leq: Gen(opr, 0, 13);
          end;
        end;
      end;
    end {Condition};

  begin {Statement}
    if Sym = ident then
    begin
      I := Position(Id);
      if I = POS_NOT_FOUND then
        Error(11)
      else
      if Table[I].Kind <> variable then
      begin {assignment to non-variable}
        Error(12);
        I := 0;
      end;
      GetSymbol;
      if Sym = becomes then
        GetSymbol
      else
        Error(13);
      Expression(fsys);
      if I <> 0 then
        with Table[I] do
          Gen(sto, Lev - Level, Adr);
    end
    else
    if Sym = callsym then
    begin
      GetSymbol;
      if Sym <> ident then
        Error(14)
      else
      begin
        I := Position(Id);
        if I = POS_NOT_FOUND then
          Error(11)
        else
          with Table[I] do
            if Kind = proc then
              Gen(cal, Lev - Level, Adr)
            else
              Error(15);
        GetSymbol;
      end;
    end
    else
    if Sym = ifsym then
    begin
      GetSymbol;
      Condition([thensym, dosym] + fsys);
      if Sym = thensym then
        GetSymbol
      else
        Error(16);
      Cx1 := Cx;
      Gen(jpc, 0, 0);
      Statement(fsys);
      Code[Cx1].A := Cx;
    end
    else
    if Sym = beginsym then
    begin
      GetSymbol;
      Statement([semicolon, endsym] + fsys);
      while Sym in [semicolon] + statbegsys do
      begin
        if Sym = semicolon then
          GetSymbol
        else
          Error(10);
        Statement([semicolon, endsym] + fsys);
      end;
      if Sym = endsym then
        GetSymbol
      else
        Error(17);
    end
    else
    if Sym = whilesym then
    begin
      Cx1 := Cx;
      GetSymbol;
      Condition([dosym] + fsys);
      Cx2 := Cx;
      Gen(jpc, 0, 0);
      if Sym = dosym then
        GetSymbol
      else
        Error(18);
      Statement(fsys);
      Gen(jmp, 0, Cx1);
      Code[Cx2].A := Cx;
    end
    else if Sym = writesym then
    begin
      GetSymbol;
      Expression(fsys);
      Gen(opr, 0, 15);
    end
    else if Sym = readsym then
    begin
      GetSymbol;
      if Sym <> ident then
        Error(26)
      else
      begin
        I := Position(Id);
        if I = POS_NOT_FOUND then
          Error(11)
        else
        begin
          Gen(opr, 0, 14);
          with Table[I] do
            if Kind = variable then
              Gen(sto, Lev - Level, Adr)
            else
              Error(27);
        end;
        GetSymbol;
      end;
    end;
    Test(fsys, [], 19);
  end {Statement};

begin {Block}
  Dx := 3;
  Tx0 := Tx;
  Table[Tx].Adr := Cx;
  Gen(jmp, 0, 0);
  if Lev > MAX_BLOCK_NESTING then
    Error(32);
  repeat
    if Sym = constsym then
    begin
      GetSymbol;
      repeat
        ConstDeclaration;
        while Sym = comma do
        begin
          GetSymbol;
          ConstDeclaration;
        end;
        if Sym = semicolon then
          GetSymbol
        else
          Error(5)
      until Sym <> ident;
    end;
    if Sym = varsym then
    begin
      GetSymbol;
      repeat
        VarDeclaration;
        while Sym = comma do
        begin
          GetSymbol;
          VarDeclaration;
        end;
        if Sym = semicolon then
          GetSymbol
        else
          Error(5)
      until Sym <> ident;
    end;
    while Sym = procsym do
    begin
      GetSymbol;
      if Sym = ident then
      begin
        Enter(proc);
        GetSymbol;
      end
      else
        Error(4);
      if Sym = semicolon then
        GetSymbol
      else
        Error(5);
      Block(Lev + 1, Tx, [semicolon] + fsys);
      if Sym = semicolon then
      begin
        GetSymbol;
        Test(statbegsys + [ident, procsym], fsys, 6);
      end
      else
        Error(5);
    end;
    Test(statbegsys + [ident], declbegsys, 7)
  until not (Sym in declbegsys);
  Code[Table[Tx0].Adr].A := Cx;
  with Table[Tx0] do
  begin
    Adr := Cx; {start adr of code}
  end;
  Cx0 := 0{cx};
  Gen(int, 0, Dx);
  Statement([semicolon, endsym] + fsys);
  Gen(opr, 0, 0); {return}
  Test(fsys, [], 8);
  ListCode;
end {Block};

procedure InitParser(PL0FileName: string);
begin
  AssignFile(SrcFile, PL0FileName);
  Reset(SrcFile);
  for Ch := chr(0) to chr(255) do
    Ssym[Ch] := nul;
  Word[1] := 'begin     ';
  Word[2] := 'call      ';
  Word[3] := 'const     ';
  Word[4] := 'do        ';
  Word[5] := 'end       ';
  Word[6] := 'if        ';
  Word[7] := 'odd       ';
  Word[8] := 'procedure ';
  Word[9] := 'then      ';
  Word[10] := 'var       ';
  Word[11] := 'while     ';
  Wsym[1] := beginsym;
  Wsym[2] := callsym;
  Wsym[3] := constsym;
  Wsym[4] := dosym;
  Wsym[5] := endsym;
  Wsym[6] := ifsym;
  Wsym[7] := oddsym;
  Wsym[8] := procsym;
  Wsym[9] := thensym;
  Wsym[10] := varsym;
  Wsym[11] := whilesym;
  Ssym['+'] := plus;
  Ssym['-'] := minus;
  Ssym['*'] := times;
  Ssym['/'] := slash;
  Ssym['('] := lparen;
  Ssym[')'] := rparen;
  Ssym['='] := eql;
  Ssym[','] := comma;
  Ssym['.'] := period;
  Ssym['#'] := neq;
  Ssym['<'] := lss;
  Ssym['>'] := gtr;
  Ssym['['] := leq;
  Ssym[']'] := geq;
  Ssym[';'] := semicolon;
  Ssym['!'] := writesym;
  Ssym['?'] := readsym;
  Mnemonic[lit] := '  lit';
  Mnemonic[opr] := '  opr';
  Mnemonic[lod] := '  lod';
  Mnemonic[sto] := '  sto';
  Mnemonic[cal] := '  cal';
  Mnemonic[int] := '  int';
  Mnemonic[jmp] := '  jmp';
  Mnemonic[jpc] := '  jpc';
  DeclBegSys := [constsym, varsym, procsym];
  StatBegSys := [beginsym, callsym, ifsym, whilesym];
  FacBegSys := [ident, number, lparen];
  Err := 0;
  Cc := 0;
  Cx := 0;
  Ll := 0;
  Ch := ' ';
  Kk := IDENTIFIER_LEN;
end;

procedure ExitParser;
begin
  CloseFile(SrcFile);
end;

end.
