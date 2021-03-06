(*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

%{
  open Compiler.EnhancedCompiler
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> IDENT

%token DUNIT DNAT DFLOAT DBOOL DSTRING
%token DCOLL DREC
%token DLEFT DRIGHT DBRAND
%token DTIMESCALE

%token SECOND MINUTE HOUR DAY WEEK MONTH YEAR

%token PCONST PUNOP PBINOP
%token PMAP PASSERT PORELSE
%token PIT PLETIT PENV PLETENV
%token PLEFT PRIGHT PGETCONSTANT
%token TRUE FALSE

%token WHERE INSTANCEOF MATCHES EXAMPLE
%token TEMPVAR FETCH KEY
%token IS AGGREGATE DO OVER FLATTEN VARIABLES
%token PACCEPT PBDOT PBSOMEDOT PSOME PNULL PLUSSPLUS PBINOPRED
%token PVARWITH WITHVAR LOOKUP TOSTRING

%token FLOATNEG FLOATSQRT FLOATEXP
%token FLOATLOG FLOATLOG10
%token FLOATOFINT FLOATCEIL FLOATFLOOR FLOATTRUNCATE
%token FLOATABS

%token FLOATPLUS FLOATMINUS FLOATMULT FLOATDIV
%token FLOATPOW FLOATMIN FLOATMAX
%token FLOATNE FLOATLT FLOATLE FLOATGT FLOATGE

%token AFLOATSUM AFLOATARITHMEAN AFLOATLISTMIN AFLOATLISTMAX

%token TIMEAS TIMESHIFT
%token TIMENE TIMELT TIMELE TIMEGT TIMEGE
%token TIMEDURATIONFROMSCALE TIMEDURATIONBETWEEN

%token SQLDATEPLUS SQLDATEMINUS
%token SQLDATENE SQLDATELT SQLDATELE SQLDATEGT SQLDATEGE
%token SQLDATEINTERVALBETWEEN

%token TIMEFROMSTRING TIMEDURATIONFROMSTRING

%token SQLDATEFROMSTRING SQLDATEINTERVALFROMSTRING
%token SQLGETDATECOMPONENT

%token PNOW

%token AEQ AUNION ACONCAT AMERGECONCAT AAND AOR ALT ALE AMINUS AMIN AMAX ACONTAINS ASCONCAT
%token ABARITH ARITHPLUS ARITHMINUS ARITHMULT ARITHMIN ARITHMAX ARITHDIVIDE ARITHREM
%token AIDOP ANEG ACOLL ACOUNT AFLATTEN ADISTINCT ASUM ATOSTRING ASUBSTRING ALIKE ESCAPE ANUMMIN ANUMMAX AARITHMEAN ACAST ADOT AREC ARECPROJECT AUNBRAND ASINGLETON
%token AUARITH ARITHABS ARITHLOG2 ARITHSQRT
%token RULEWHEN RULEGLOBAL RULERETURN RULENOT
%token COMMA
%token SEMI
%token SEMISEMI
%token SEMISEMISEMI
%token COLONEQUAL DOT
%token DASHTICK DASHUNDER
%token BANGDASHARROW
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token EOF

%nonassoc UINSTANCE
%nonassoc PORELSE
%nonassoc PLETIT PLETENV
%nonassoc PMAP
%nonassoc PBINOP PUNOP
%right PLUSSPLUS
%left PBSOMEDOT PBDOT
%nonassoc BANGDASHARROW
%nonassoc UIS
%right TEMPVAR UFETCH
%nonassoc TOSTRING
%nonassoc UWITHVAR
%nonassoc PASSERT

%start <(string * Compiler.EnhancedCompiler.QLang.query)> rulemain
%start <Compiler.EnhancedCompiler.QLang.camp> patmain
%type <Compiler.EnhancedCompiler.QLang.rule -> Compiler.EnhancedCompiler.QLang.rule> rule_rule

%%

rulemain:
| EXAMPLE i=IDENT COLONEQUAL r = rule DOT EOF
    { (i, Compiler.Q_rule r) }
| EXAMPLE i=IDENT COLONEQUAL p = pat DOT EOF
    { (i, Compiler.Q_camp p) }

patmain:
| p = pat EOF
    { p }

rule:
| RULERETURN p = pat
    { QRule.rule_return p }
| RULEWHEN p = pat SEMISEMI r = rule
    { QRule.rule_when p r }
| RULENOT p = pat SEMISEMI r = rule
    { QRule.rule_not p r }
| RULEGLOBAL p = pat SEMISEMI r = rule
    { QRule.rule_global p r }

rule_rule:
| RULEWHEN p = pat
    { (fun r -> QRule.rule_when p r) }
| RULENOT p = pat
    { (fun r -> QRule.rule_not p r) }
| RULEGLOBAL p = pat
    { (fun r -> QRule.rule_global p r) }
| RULEWHEN p = pat SEMISEMISEMI r = rule_rule 
    { (fun r1 -> (QRule.rule_when p (r r1))) }
| RULENOT p = pat SEMISEMISEMI r = rule_rule
    { (fun r1 -> (QRule.rule_not p (r r1))) }
| RULEGLOBAL p = pat SEMISEMISEMI r = rule_rule
    { (fun r1 -> (QRule.rule_global p (r r1))) }

pat:
(* Parenthesized pattern *)
| LPAREN p = pat RPAREN
    { p }
(* CAMP pattern *)
| PCONST DUNIT
    { QPattern.pconst QData.dunit }
| PCONST LPAREN d = data RPAREN
    { QPattern.pconst d }
| PUNOP u = uop p = pat
    { QPattern.punop u p }
| PBINOP b = bop p1 = pat p2 = pat
    { QPattern.pbinop b p1 p2 }
| PMAP p = pat
    { QPattern.pmap p }
| PASSERT p = pat
    { QPattern.passert p }
| PORELSE p1 = pat p2 = pat
    { QPattern.porelse p1 p2 }
| PIT
    { QPattern.pit }
| PLETIT p1 = pat p2 = pat
    { QPattern.pletit p1 p2 }
| PENV
    { QPattern.penv }
| PLETENV p1 = pat p2 = pat
    { QPattern.pletenv  p1 p2 }
| PLEFT
    { QPattern.pleft }
| PRIGHT
    { QPattern.pright }
| PGETCONSTANT s = STRING
    { QPattern.pgetconstant (Util.char_list_of_string s) }
(* Macros pattern *)
| PNOW
    { QPattern.pnow }
| PACCEPT
    { QPattern.pconst (QData.drec []) }
| LOOKUP s = STRING
    { QPattern.lookup (Util.char_list_of_string s) }
 | v = STRING IS p = pat %prec UIS
    { QPattern.pIS (Util.char_list_of_string v) p }
| WITHVAR s = STRING p = pat %prec UWITHVAR
    { QPattern.withVar (Util.char_list_of_string s) p }
| PVARWITH s = STRING p = pat %prec UWITHVAR
    { QPattern.pvarwith (Util.char_list_of_string s) p }
| TOSTRING p = pat
    { QPattern.toString p }
| PBINOPRED b = bop LBRACKET pl = patlist RBRACKET
    { QPattern.pat_binop_reduce b pl }
| p1 = pat PLUSSPLUS p2 = pat
    { QPattern.stringConcat p1 p2 }
| DASHUNDER
    { QPattern.pit }
| DASHTICK c = const
    { (QPattern.pconst c) }
| s = STRING BANGDASHARROW p = pat
    { QPattern.pbdot (Util.char_list_of_string s) p }
| PBDOT s = STRING p = pat %prec PBDOT
    { QPattern.pbdot (Util.char_list_of_string s) p }
| PBSOMEDOT s = STRING p = pat %prec PBSOMEDOT
    { QPattern.pbsomedot (Util.char_list_of_string s) p }
| PSOME
    { QPattern.pleft }
| PNULL
    { QPattern.pnull }
(* INSTANCEOF, FETCH, and MATCHES temporarily have hacks because of signature changes in RuleSugar.v.  TODO fix this *)
| n = STRING INSTANCEOF LBRACKET t = stringlist RBRACKET WHERE p = pat %prec UINSTANCE
    { QPattern.instanceOf (Util.char_list_of_string n) t p }
| p = pat TEMPVAR t = STRING FETCH LBRACKET e = stringlist RBRACKET KEY a = STRING DO pcont = pat %prec UFETCH
    { QPattern.fetchRef e (Util.char_list_of_string a) (Util.char_list_of_string t) p pcont }
| MATCHES LBRACKET t = stringlist RBRACKET WHERE p = pat %prec UINSTANCE
    { QPattern.matches t p }
| AGGREGATE r = rule_rule DO u = uop OVER p = pat FLATTEN f = INT
    { QRule.aggregate r u p (Util.coq_Z_of_int f) }
| VARIABLES LBRACKET v = stringlist RBRACKET
    { QPattern.returnVariables v }
data:
| DUNIT
    { QData.dunit }
| DBOOL TRUE
    { QData.dbool true }
| DBOOL FALSE
    { QData.dbool false }
| DFLOAT f = FLOAT
    { Enhanced.Data.dfloat f }
| DNAT i = INT
    { QData.dnat (Util.coq_Z_of_int i) }
| DSTRING s = STRING
    { QData.dstring (Util.char_list_of_string s) }
| DCOLL LBRACKET dl = datalist RBRACKET
    { QData.dcoll dl }
| DREC LBRACKET rl = reclist RBRACKET
    { QData.drec rl }
| DLEFT d = data
    { QData.dleft d }
| DRIGHT d = data
    { QData.dright d }
| DBRAND sl = stringlist d = data
    { QData.dbrand sl d }
| DTIMESCALE ts = timescale
    { Enhanced.Data.dtime_scale ts }

timescale:
| SECOND
  {Enhanced.Data.second}
| MINUTE
  {Enhanced.Data.minute}
| HOUR
  {Enhanced.Data.hour}
| DAY
  {Enhanced.Data.day}
| WEEK
  {Enhanced.Data.week}
| MONTH
  {Enhanced.Data.month}
| YEAR
  {Enhanced.Data.year}

datalist:
| 
    { [] }
| d = data
    { [d] }
| d = data SEMI dl = datalist
    { d :: dl }

reclist:
| 
    { [] }
| r = recatt
    { [r] }
| r = recatt SEMI rl = reclist
    { r :: rl }

recatt:
| LPAREN a = STRING COMMA d = data RPAREN
    { (Util.char_list_of_string a, d) }
    
patlist:
| p = pat
    { p :: [] }
| p = pat SEMI pl = patlist
    { p :: pl }

stringlist:
| s = STRING
    { (Util.char_list_of_string s) :: [] }
| s = STRING SEMI v = stringlist
    { (Util.char_list_of_string s) :: v }

const:
| i = INT
    { QData.dnat (Util.coq_Z_of_int i) }
| f = FLOAT
    { Enhanced.Data.dfloat f }
| s = STRING
    { QData.dstring (Util.char_list_of_string s) }

bop:
| FLOATPLUS
  { Enhanced.Ops.Binary.float_plus }
| FLOATMINUS
  { Enhanced.Ops.Binary.float_minus }
| FLOATMULT
  { Enhanced.Ops.Binary.float_mult }
| FLOATDIV
  { Enhanced.Ops.Binary.float_div }
| FLOATPOW
  { Enhanced.Ops.Binary.float_pow }
| FLOATMIN
  { Enhanced.Ops.Binary.float_min }
| FLOATMAX
  { Enhanced.Ops.Binary.float_max }
| FLOATNE
  { Enhanced.Ops.Binary.float_ne }
| FLOATLT
  { Enhanced.Ops.Binary.float_lt }
| FLOATLE
  { Enhanced.Ops.Binary.float_le }
| FLOATGT
  { Enhanced.Ops.Binary.float_gt }
| FLOATGE
  { Enhanced.Ops.Binary.float_ge }

| TIMEAS
  { Enhanced.Ops.Binary.time_as }
| TIMESHIFT
  { Enhanced.Ops.Binary.time_shift }
| TIMENE
  { Enhanced.Ops.Binary.time_ne }
| TIMELT
  { Enhanced.Ops.Binary.time_lt }
| TIMELE
  { Enhanced.Ops.Binary.time_le }
| TIMEGT
  { Enhanced.Ops.Binary.time_gt }
| TIMEGE
  { Enhanced.Ops.Binary.time_ge }
| TIMEDURATIONFROMSCALE
  { Enhanced.Ops.Binary.time_duration_from_scale }
| TIMEDURATIONBETWEEN
  { Enhanced.Ops.Binary.time_duration_between }
| SQLDATEPLUS
  { Enhanced.Ops.Binary.sql_date_plus }
| SQLDATEMINUS
  { Enhanced.Ops.Binary.sql_date_minus }
| SQLDATENE
  { Enhanced.Ops.Binary.sql_date_ne }
| SQLDATELT
  { Enhanced.Ops.Binary.sql_date_lt }
| SQLDATELE
  { Enhanced.Ops.Binary.sql_date_le }
| SQLDATEGT
  { Enhanced.Ops.Binary.sql_date_gt }
| SQLDATEGE
  { Enhanced.Ops.Binary.sql_date_ge }
| SQLDATEINTERVALBETWEEN
  { Enhanced.Ops.Binary.sql_date_interval_between }
| AEQ
    { QOps.Binary.aeq }
| AUNION
    { QOps.Binary.aunion }
| ACONCAT
    { QOps.Binary.aconcat }
| AMERGECONCAT
    { QOps.Binary.amergeconcat }
| AAND
    { QOps.Binary.aand }
| AOR
    { QOps.Binary.aor }
| ALT
    { QOps.Binary.alt }
| ALE
    { QOps.Binary.ale }
| AMINUS
    { QOps.Binary.aminus }
| AMIN
    { QOps.Binary.amin }
| AMAX
    { QOps.Binary.amax }
| ACONTAINS
    { QOps.Binary.acontains }
| ASCONCAT
    { QOps.Binary.asconcat }
| LPAREN ABARITH ARITHPLUS RPAREN
    { QOps.Binary.ZArith.aplus }
| LPAREN ABARITH ARITHMINUS RPAREN
    { QOps.Binary.ZArith.aminus }
| LPAREN ABARITH ARITHMULT RPAREN
    { QOps.Binary.ZArith.amult }
| LPAREN ABARITH ARITHMIN RPAREN
    { QOps.Binary.ZArith.amin }
| LPAREN ABARITH ARITHMAX RPAREN
    { QOps.Binary.ZArith.amax }
| LPAREN ABARITH ARITHDIVIDE RPAREN
    { QOps.Binary.ZArith.adiv }
| LPAREN ABARITH ARITHREM RPAREN
    { QOps.Binary.ZArith.arem }

sql_date_component:
| DAY
  { Enhanced.Data.sql_date_day }
| MONTH
  { Enhanced.Data.sql_date_month }
| YEAR
  { Enhanced.Data.sql_date_year }

uop:
| FLOATNEG
  { Enhanced.Ops.Unary.float_neg }
| FLOATSQRT
  { Enhanced.Ops.Unary.float_sqrt }
| FLOATEXP
  { Enhanced.Ops.Unary.float_exp }
| FLOATLOG
  { Enhanced.Ops.Unary.float_log }
| FLOATLOG10
  { Enhanced.Ops.Unary.float_log10 }
| FLOATOFINT
  { Enhanced.Ops.Unary.float_of_int }
| FLOATCEIL
  { Enhanced.Ops.Unary.float_ceil }
| FLOATFLOOR
  { Enhanced.Ops.Unary.float_floor }
| FLOATTRUNCATE
  { Enhanced.Ops.Unary.float_truncate }
| FLOATABS
  { Enhanced.Ops.Unary.float_abs }
| AIDOP
    { QOps.Unary.aidop }
| ANEG
    { QOps.Unary.aneg }
| ACOLL
    { QOps.Unary.acoll }
| ACOUNT
    { QOps.Unary.acount }
| AFLATTEN
    { QOps.Unary.aflatten }
| ADISTINCT
    { QOps.Unary.adistinct }
| ASUM
    { QOps.Unary.asum }
| ATOSTRING
    { QOps.Unary.atostring }
| ASUBSTRING LPAREN s = INT RPAREN
  { QOps.Unary.asubstring s None }
| ASUBSTRING LPAREN s = INT COMMA len = INT RPAREN
  { QOps.Unary.asubstring s (Some len) }
| ALIKE LPAREN s = STRING RPAREN
  { QOps.Unary.alike (Util.char_list_of_string s) None }
(* This should really be a CHAR escape character, but I don't know how to do that *)
| ALIKE LPAREN s = STRING ESCAPE esc = STRING RPAREN
    { QOps.Unary.alike (Util.char_list_of_string s) (Some (esc.[0])) }
| ANUMMIN
    { QOps.Unary.anummin }
| ANUMMAX
    { QOps.Unary.anummax }
| AARITHMEAN
    { QOps.Unary.aarithmean }
| LPAREN AUARITH ARITHABS RPAREN
    { QOps.Unary.ZArith.aabs }
| LPAREN AUARITH ARITHLOG2 RPAREN
    { QOps.Unary.ZArith.alog2 }
| LPAREN AUARITH ARITHSQRT RPAREN
    { QOps.Unary.ZArith.asqrt }
| LPAREN ACAST LBRACKET s = stringlist RBRACKET RPAREN
    { QOps.Unary.acast s }
| LPAREN ARECPROJECT LBRACKET s = stringlist RBRACKET RPAREN
    { QOps.Unary.arecproject s }
| LPAREN AREC s = STRING RPAREN
    { QOps.Unary.arec (Util.char_list_of_string s) }
| LPAREN ADOT s = STRING RPAREN
    { QOps.Unary.adot (Util.char_list_of_string s) }
| AUNBRAND
    { QOps.Unary.aunbrand }
| ASINGLETON
    { QOps.Unary.asingleton }
| AFLOATSUM
    { Enhanced.Ops.Unary.float_sum }
| AFLOATARITHMEAN
    { Enhanced.Ops.Unary.float_arithmean }
| AFLOATLISTMIN
    { Enhanced.Ops.Unary.float_listmin }
| AFLOATLISTMAX
    { Enhanced.Ops.Unary.float_listmax }
| TIMEFROMSTRING
    { Enhanced.Ops.Unary.time_from_string }
| TIMEDURATIONFROMSTRING
    { Enhanced.Ops.Unary.time_duration_from_string }
| SQLDATEFROMSTRING
    { Enhanced.Ops.Unary.sql_date_from_string }
| SQLDATEINTERVALFROMSTRING
    { Enhanced.Ops.Unary.sql_date_interval_from_string }
| LPAREN SQLGETDATECOMPONENT c = sql_date_component RPAREN
    { Enhanced.Ops.Unary.sql_get_date_component c }


