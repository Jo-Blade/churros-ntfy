%{
  open Json
%}

%token NULL
%token <int> INT
%token <bool> BOOL
%token <float> FLOAT
%token <string> STRING

%token COMMA
%token COLON
%token LBRACE RBRACE
%token LBRACKET RBRACKET

%token EOF

%start <t_json option> file

%%

file:
  | EOF; { None }
  | j = json; { Some j }

json:
  | NULL; { J_Null }
  | i = INT; { J_Int i }
  | b = BOOL; { J_Bool b }
  | f = FLOAT; { J_Float f }
  | s = string; { J_String s }
  | LBRACKET; l = json_list; RBRACKET; { J_Array l }
  | LBRACE; o = obj_list; RBRACE; { J_Object o }

string:
  | s = STRING; { s }

json_list:
  | { [ ] }
  | j = json; { [j] }
  | j = json; COMMA; l = json_list; { j :: l }

obj_list:
  | key = string; COLON; value = json; { [{ key = key; value = value }] }
  | key = string; COLON; value = json; COMMA; o = obj_list; { { key = key; value = value } :: o }

%%
