module EvalMain (eval) where

import AST

-- Defino nuevo tipo de dato Value (Enteros, Booleanos, String y Objetos)
--implementar monada para manejar errores (retornar estado anterior al error, junto con el error)
-- modificar reglas gramaticales

data Value =  VInt Integer
            | VBool Bool
            | VStr String
            | VObj [(String, Value)]
            deriving (Show, Eq)

-- Defino Estados para Objetos
type State = [(Variable, Value)]

-- Defino Estado nulo
initState :: State
initState = []

-- Busca el valor de una variable en el objeto
lookfor :: Variable -> State -> Value
lookfor var ((x,y):xs)= if var == x then y
                                    else lookfor var xs
lookfor var [] = error ("Variable: " ++ var ++ " no definida en el estado")

-- Busco un campo en el objeto
findField :: String -> [(String, Value)] -> Value
findField campo [] = error("Campo inexistente: " ++ campo)

findField campo ((nombre,val):xs) = if campo == nombre
                                        then val
                                        else findField campo xs

-- Func aux para validar tipos para swap
sameType :: Value -> Value -> Bool
sameType v1 v2 = case (v1, v2) of
                (VInt _, VInt _) -> True
                (VBool _, VBool _) -> True
                (VStr _, VStr _) -> True
                (VObj _, VObj _) -> True
                _ -> False

-- Cambiar el valor de una variable en el estado
update :: Variable -> Value -> State -> State
update var val [] = [(var, val)]
update var val ((x,y):xs) = if var == x then (var,val):xs
                                        else (x,y): update var val xs

-----------------------------------------
--Evaluador generico para cada tipo de expresion
-----------------------------------------
evalExp :: Exp -> State -> Value
evalExp (EInt i) s = evalIntExp i s
evalExp (EBool b) s = VBool (evalBoolExp b s)
evalExp (EObj o) s = evalObjExp o s

-- Evalua un programa en el estado nulo
eval :: Comm -> State
eval p = evalComm p initState

-----------------------------------------
-- Evalua un comando en un estado dado
-- Completar definicion
-----------------------------------------
evalComm :: Comm -> State -> State
evalComm Skip s = s

-- Comando Swap entre 2 variables, copiando el estado y retornando uno nuevo
-- Swap a b
-- Obtengo el valor de a
-- Obtengo el valor de b
-- Guardo en a el valor de b (creo nuevo estado)
-- Guardo en b el valor de a (usando el estado anterior)
-- retorno nuevo estado con las variables cambiadas
evalComm (Swap a b) s = let va = lookfor a s
                            vb = lookfor b s
                        in if sameType va vb
                            then let s' = update a vb s
                                     s'' = update b va s'
                                 in s''
                            else error "Swap invalido: tipos de datos distintos"

-- Declaramos un valor en el estado
evalComm (Let var exp) s = let val = evalExp exp s
                           in evalComm Skip (update var val s)
evalComm (Seq Skip c1) s = evalComm c1 s
evalComm (Seq c0 c1) s = let s' = evalComm c0 s
                                  in evalComm (Seq Skip c1) s'

evalComm (Cond b c0 c1) s = if (evalBoolExp b s )
                            then evalComm c0 s
                            else evalComm c1 s

evalComm (Repeat c b) s = evalComm (Seq c (Cond b Skip (Repeat c b))) s

-----------------------------------------
-- Evalua una expresion entera
-- Completar definicion
-----------------------------------------
evalIntExp :: IntExp -> State -> Value
evalIntExp (Const n) _ = VInt n
evalIntExp (Var x) estado = lookfor x estado
--Opuesto con mensaje de error
evalIntExp (UMinus e) estado = case evalIntExp e estado of
                                    VInt n -> VInt (-n)
                                    _ -> error "UMinus sobre valor no entero"
--Suma con mensaje de error
evalIntExp (Plus exp1 exp2) estado = case (evalIntExp exp1 estado, evalIntExp exp2 estado) of
                                    (VInt n1, VInt n2) -> VInt (n1+n2)
                                    _ -> error "Operacion suma sobre valores no entero"
--Resta con mensaje de error
evalIntExp (Minus exp1 exp2) estado = case (evalIntExp exp1 estado, evalIntExp exp2 estado) of
                                    (VInt n1, VInt n2) -> VInt (n1-n2)
                                    _ -> error "Operacion resta sobre valores no entero"
--Multiplicacion con mensaje de error
evalIntExp (Times exp1 exp2) estado = case (evalIntExp exp1 estado, evalIntExp exp2 estado) of
                                        (VInt n1, VInt n2) -> VInt (n1*n2)
                                        _ -> error "Operacion multiplicacion sobre valores no entero"
--Division con mensaje de error
evalIntExp (Div exp1 exp2) estado = case (evalIntExp exp1 estado, evalIntExp exp2 estado) of
                                    (VInt n1, VInt n2) -> VInt (div n1 n2)
                                    _ -> error "Operacion division sobre valores no entero"

-----------------------------------------
-- Evalua una expresion booleana
-- Completar definicion                                            
-----------------------------------------
evalBoolExp :: BoolExp -> State -> Bool
evalBoolExp BTrue estado = True
evalBoolExp BFalse estado = False
evalBoolExp (Eq exp1 exp2) estado = case (evalIntExp exp1 estado, evalIntExp exp2 estado) of
                                        (VInt n1, VInt n2) -> n1 == n2
                                        _ -> error "Comparacion igual que solo se permite en enteros"

evalBoolExp (Lt exp1 exp2) estado = case (evalIntExp exp1 estado, evalIntExp exp2 estado) of
                                        (VInt n1, VInt n2) -> n1 < n2
                                        _ -> error "Comparacion menor que solo se permite entre enteros"

evalBoolExp (Gt exp1 exp2) estado = case (evalIntExp exp1 estado, evalIntExp exp2 estado) of
                                        (VInt n1, VInt n2) -> n1 > n2
                                        _ -> error "Comparacion mayor que solo se permite entre enteros"

evalBoolExp (And exp1 exp2) estado = let valor1 = evalBoolExp exp1 estado
                                         valor2 = evalBoolExp exp2 estado
                                        in valor1 && valor2

evalBoolExp (Or exp1 exp2) estado = let valor1 = evalBoolExp exp1 estado
                                        valor2 = evalBoolExp exp2 estado
                                        in valor1 || valor2
                                        
evalBoolExp (Not exp1) estado = not (evalBoolExp exp1 estado)

-----------------------------------------
-- Evalua una expresion de objeto
-----------------------------------------
evalObjExp :: ObjExp -> State -> Value
evalObjExp (Str s) _ = VStr s

evalObjExp (Obj campos) estado = VObj [(clave, evalExp valor estado) | (clave, valor) <- campos]

--Acceso al valor del campo del objeto para azucar sintactica "."
evalObjExp (Access exp campo) estado = case evalExp exp estado of  --evaluo el objeto
                                        VObj campos -> findField campo campos --busco el campo
                                        _ -> error "Acceso a campo sobre un valor que no es Objeto"

