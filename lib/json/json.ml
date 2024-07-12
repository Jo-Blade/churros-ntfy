type t_assoc = { key : string; value : t_json }

and t_json =
  | J_Null
  | J_Int of int
  | J_Bool of bool
  | J_Float of float
  | J_String of string
  | J_Array of t_json list
  | J_Object of t_assoc list
[@@deriving show { with_path = false }]
