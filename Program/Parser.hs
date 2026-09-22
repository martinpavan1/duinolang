module Parser where

import Text.ParserCombinators.Parsec
import Text.Parsec.Token
import Text.Parsec.Language (emptyDef)
import AST

-- module Parser where

-- import AST

-- import Text.ParserCombinators.Parsec
-- import Text.Parsec.String (Parser)
-- import Text.Parsec.Language (emptyDef)

-- import Control.Monad (void)
-- import Data.Char (isAlpha, isAlphaNum)


-- Funcion para facilitar el testing del parser.
totParser :: Parser a -> Parser a
totParser p = do
                  whiteSpace lis
                  t <- p
                  eof
                  return t


-- Analizador de Tokens
lis :: TokenParser u
lis = makeTokenParser (emptyDef { commentLine     = "//"
                , reservedNames   =
                    [ "define"
                    , "end-define"
                    , "Pines"
                    , "Sensor"
                    , "Objeto"
                    , "Digital"
                    , "Analogica"
                    , "True"
                    , "False"
                    , "TipoEncendible"
                    , "TipoAbrible"
                    , "TipoActivable"
                    , "let"
                    , "si"
                    , "entonces"
                    , "mientras"
                    , "hacer"
                    , "ejecutar"
                    , "secuencia"
                    , "Map"
                    , "Encender"
                    , "Apagar"
                    , "Abrir"
                    , "Cerrar"
                    , "EncenderTemporizado"
                    , "o"
                    , "y"
                    , "no"
                    ]
                , reservedOpNames = 
                    [  "+"
                    , "-"
                    , "*"
                    , "/"
                    , "<"
                    , ">"
                    , ">="
                    , "<="
                    , "&"
                    , "|"
                    , "="
                    , ";"
                    , "~"
                    , ":=" -- Token asignacion
                    , ":" -- Token para def hora
                    , "," -- Token separador de campos
                    ]
                })

-- programa -> declaraciones comandos
parsePrograma :: Parser ([Comm], Estado)
parsePrograma = do
    whiteSpace lis
    estado <- parseDeclaraciones
    comandos <- parseComandos
    eof
    return (comandos, estado)


-- ============================================================
-- DEFINE
-- ============================================================

-- declaraciones -> 'define' poolPines listaDecl 'end-define'
parseDeclaraciones :: Parser Estado
parseDeclaraciones = do
    reserved "define"

    (pins, usados) <- parsePoolPines

    declaraciones <- many1 parseDecl

    reserved "end-define"

    let objetosDeclarados =
            [ (nombre, objeto)
            | DeclObjeto nombre objeto <- declaraciones
            ]

        sensoresDeclarados =
            [ (nombre, sensor)
            | DeclSensor nombre sensor <- declaraciones
            ]

    return Estado
        { constantes    = []
        , variables     = []
        , objetos       = objetosDeclarados
        , sensores      = sensoresDeclarados
        , pines         = [(p, p `elem` usados) | p <- pins]
        , temporizadores = []
        }


-- ============================================================
-- DECLARACIONES AUXILIARES
-- ============================================================

data Declaracion
    = DeclObjeto (Nombre,Objeto)
    | DeclSensor (Nombre, Sensor)
    deriving Show


-- poolPines -> 'Pines' nombre pines ';'
parsePoolPines :: Parser ([Pin])
parsePoolPines = do
    reserved "Pines"
    nombre <- identifier lis
    pines <- parsePines
    reservedOp lis ";"
    return (pines)


-- pines -> '[' listaEnteros ']'
parsePines :: Parser [Int]
parsePines = brackets parseListaEnteros


-- listaEnteros -> entero | entero ',' listaEnteros
parseListaEnteros :: Parser [Int]
parseListaEnteros = sepBy integer (reservedOp lis ",")


-- decl -> sensor | objeto
parseDecl :: Parser Declaracion
parseDecl =
            try parseSensor
            <|> parseObjeto

-- sensor -> 'Sensor' nombre tipoSenial pin activo ';'
parseSensor :: Parser Declaracion
parseSensor = do
    reserved lis "Sensor"

    nombre <- identifier lis
    tipo <- parseTipoSenial
    pin <- integer lis
    activoSensor <- parseActivo

    reservedOp lis ";"

    return (DeclSensor (nombre, Sensor {senial=tipo, pinInput=pin,      activo=activoSensor}))


-- tipoSenial -> 'Digital' | 'Analogica'
parseTipoSenial :: Parser TipoSenial 
parseTipoSenial =   try (do
                        reserved lis "Digital"
                        return Digital)
                    <|> try (do 
                        reserved lis "Analogica"
                        return Analogica)


-- activo -> 'True' | 'False'
parseActivo :: Parser Bool
parseActivo =   try (do
                    reserved lis "True"
                    return True)
                <|> try (do
                        reserved lis "False"
                        return False)

-- objeto -> 'Objeto' nombre tipoObjeto ubicacion nivel pin ';'
parseObjeto :: Parser Declaracion
parseObjeto = do
    reserved lis "Objeto"

    nombre <- identifier lis
    tipo <- parseTipoObjeto
    ubic <- identifier lis
    nivelInicial <- integer lis--ver de reemplazar por float
    pin <- integer lis

    reservedOp lis ";"

    return DeclObjeto (nombre, Objeto
                { tipo = tipo
                , ubicacion = ubic
                , estadoObjeto = nivelInicial
                , pinOutput = pin
                })


-- tipoObjeto ->
--     'TipoEncendible'
--   | 'TipoAbrible'
--   | 'TipoActivable'

parseTipoObjeto :: Parser TipoObjeto
parseTipoObjeto =   try (do
                        reserved lis "TipoEncendible"
                        return TipoEncendible)
                    <|> try (do
                            reserved lis "TipoAbrible"
                            return TipoAbrible)
                    <|> try (do
                            reserved lis "TipoActivable"
                            return TipoActivable)


-- var -> entero | nombre | listaVar
parseVar :: Parser Var
parseVar =
        do
            n <- integer lis
            return (VInt (fromInteger n))
        <|> do
            xs <- brackets lis parseListaVar
            return (VList xs)
        <|> do
            n <- identifier lis
            return (VNomb n)


-- listaVar -> '[' ']' | '[' elementos ']'
parseListaVar :: Parser [Var]
parseListaVar = brackets lis (sepBy parseVar (reservedOp lis ","))


-- ============================================================
-- COMANDOS
-- ============================================================

-- comandos -> comm | comm comandos
parseComandos :: Parser [Comm]
parseComandos =
    many1 parseComm


-- comm -> let | si | mientras | ejecutar | secuencia | map
parseComm :: Parser Comm
parseComm =
        try parseLet
    <|> try parseSi
    <|> try parseMientras
    <|> try parseEjecutar
    <|> try parseSecuencia
    <|> parseMap


-- ============================================================
-- LET
-- ============================================================

-- let -> nombre ':=' var ';'
parseLet :: Parser Comm
parseLet = do
    nombre <- identifier
    symbol ":="
    valor <- parseVar
    semi

    return (Let nombre valor)


-- ============================================================
-- SI
-- ============================================================

-- si -> 'si' condicion 'entonces' '(' comandos ')'
parseSi :: Parser Comm
parseSi = do
    reserved "si"
    condicion <- parseCondicion
    reserved "entonces"

    comandos <- parens parseComandos

    return (Si condicion comandos)


-- ============================================================
-- MIENTRAS
-- ============================================================

-- mientras -> 'mientras' condicion 'hacer' '(' comandos ')'
parseMientras :: Parser Comm
parseMientras = do
    reserved "mientras"
    condicion <- parseCondicion
    reserved "hacer"

    comandos <- parens parseComandos

    return (Mientras condicion comandos)


-- ============================================================
-- CONDICIONES
-- ============================================================

-- condicion ->
--      condicion 'o' condicion'
--    | condicion'

parseCondicion :: Parser Condicion
parseCondicion = do
    izquierda <- parseCondicionY
    parseOrResto izquierda
  where
    parseOrResto izquierda =
        (do
            reserved "o"
            derecha <- parseCondicionY
            parseOrResto (O izquierda derecha))
        <|> return izquierda


-- condicion' ->
--      condicion' 'y' condicion''
--    | condicion''

parseCondicionY :: Parser Condicion
parseCondicionY = do
    izquierda <- parseCondicionNo
    parseAndResto izquierda
  where
    parseAndResto izquierda =
        (do
            reserved "y"
            derecha <- parseCondicionNo
            parseAndResto (Y izquierda derecha))
        <|> return izquierda


-- condicion'' ->
--      '(' condicion ')'
--    | 'no' condicion''
--    | condFinal

parseCondicionNo :: Parser Condicion
parseCondicionNo =
        (do
            reserved "no"
            condicion <- parseCondicionNo
            return (No condicion))
    <|> parens parseCondicion
    <|> parseCondFinal


-- condFinal -> nombre compopp entero
parseCondFinal :: Parser Condicion
parseCondFinal = do
    nombre <- identifier
    comparador <- parseComparador
    valor <- integer

    -- En este punto no tenemos todavía el Estado.
    -- Se genera una condición provisoria basada en el nombre.
    --
    -- La resolución real nombre -> Objeto/Sensor se hace
    -- posteriormente con resolverCondicion.

    return (CondObjeto
        (Objeto
            { tipo = TipoActivable
            , ubicacion = nombre
            , estadoObjeto = 0
            , pinOutput = -1
            })
        comparador
        valor
        )


-- compopp ->
--     '<' | '>' | '==' | '<=' | '>=' | '!='

parseComparador :: Parser Comparador
parseComparador =
        try (symbol ">=" >> return MayorIgual)
    <|> try (symbol "<=" >> return MenorIgual)
    <|> try (symbol "==" >> return Igual)
    <|> try (symbol "!=" >> return Distinto)
    <|> try (symbol ">"  >> return Mayor)
    <|>     (symbol "<"  >> return Menor)


-- ============================================================
-- EJECUTAR
-- ============================================================

-- ejecutar -> accion
parseEjecutar :: Parser Comm
parseEjecutar = do
    accion <- parseAccion
    return (Ejecutar accion)


-- ============================================================
-- ACCIONES
-- ============================================================

-- accion ->
--      'Encender' nombre
--    | 'Apagar' nombre
--    | 'Abrir' nombre
--    | 'Cerrar' nombre
--    | 'EncenderTemporizado' nombre hora

parseAccion :: Parser Accion
parseAccion =
        try parseEncenderTemporizado
    <|> try parseEncender
    <|> try parseApagar
    <|> try parseAbrir
    <|> parseCerrar


parseEncender :: Parser Accion
parseEncender = do
    reserved "Encender"
    nombre <- identifier

    return $
        Encender (objetoPlaceholder nombre)


parseApagar :: Parser Accion
parseApagar = do
    reserved "Apagar"
    nombre <- identifier

    return $
        Apagar (objetoPlaceholder nombre)


parseAbrir :: Parser Accion
parseAbrir = do
    reserved "Abrir"
    nombre <- identifier

    return $
        Abrir (objetoPlaceholder nombre)


parseCerrar :: Parser Accion
parseCerrar = do
    reserved "Cerrar"
    nombre <- identifier

    return $
        Cerrar (objetoPlaceholder nombre)


parseEncenderTemporizado :: Parser Accion
parseEncenderTemporizado = do
    reserved "EncenderTemporizado"

    nombre <- identifier
    tiempo <- parseHora

    return $
        EncenderTemporizado
            (objetoPlaceholder nombre)
            tiempo


-- ============================================================
-- HORA
-- ============================================================

-- hora -> entero ':' entero ':' entero

parseHora :: Parser Hora
parseHora = do
    h <- integer
    symbol ":"
    m <- integer
    symbol ":"
    s <- integer

    if h >= 0 && m >= 0 && m < 60 && s >= 0 && s < 60
        then return (Hora h m s)
        else unexpected "hora invalida"


-- ============================================================
-- SECUENCIA
-- ============================================================

-- secuencia -> 'secuencia' '(' comandos ')'

parseSecuencia :: Parser Comm
parseSecuencia = do
    reserved "secuencia"

    comandos <- parens parseComandos

    return (listaASeceuncia comandos)


listaASeceuncia :: [Comm] -> Comm
listaASeceuncia [] =
    error "secuencia vacia"

listaASeceuncia [x] =
    x

listaASeceuncia (x:xs) =
    Secuencia x (listaASeceuncia xs)


-- ============================================================
-- MAP
-- ============================================================

-- map -> 'Map' accion listaVar

parseMap :: Parser Comm
parseMap = do
    reserved "Map"

    accion <- parseAccion
    vars <- parseListaVar

    return (Map accion vars)


-- ============================================================
-- OBJETO PLACEHOLDER
-- ============================================================

-- Durante el parsing conocemos el nombre del objeto,
-- pero todavía no conocemos su definición completa.
--
-- Luego resolverObjeto reemplaza este placeholder
-- por el objeto declarado en define.

objetoPlaceholder :: Nombre -> Objeto
objetoPlaceholder nombre =
    Objeto
        { tipo = TipoActivable
        , ubicacion = nombre
        , estadoObjeto = 0
        , pinOutput = -1
        }


-- ============================================================
-- RESOLUCION DE NOMBRES
-- ============================================================

resolverObjeto :: Estado -> Nombre -> Either String Objeto
resolverObjeto estado nombre =
    case lookup nombre (objetos estado) of
        Just obj -> Right obj
        Nothing ->
            Left ("Objeto no definido: " ++ nombre)


resolverSensor :: Estado -> Nombre -> Either String Sensor
resolverSensor estado nombre =
    case lookup nombre (sensores estado) of
        Just sensor -> Right sensor
        Nothing ->
            Left ("Sensor no definido: " ++ nombre)


-- ============================================================
-- RESOLUCION DE ACCIONES
-- ============================================================

resolverAccion :: Estado -> Accion -> Either String Accion
resolverAccion estado accion =
    case accion of

        Encender obj -> do
            obj' <- resolverObjeto estado (ubicacion obj)
            return (Encender obj')

        Apagar obj -> do
            obj' <- resolverObjeto estado (ubicacion obj)
            return (Apagar obj')

        Abrir obj -> do
            obj' <- resolverObjeto estado (ubicacion obj)
            return (Abrir obj')

        Cerrar obj -> do
            obj' <- resolverObjeto estado (ubicacion obj)
            return (Cerrar obj')

        EncenderTemporizado obj hora -> do
            obj' <- resolverObjeto estado (ubicacion obj)
            return (EncenderTemporizado obj' hora)


-- ============================================================
-- RESOLUCION DE CONDICIONES
-- ============================================================

resolverCondicion :: Estado -> Condicion -> Either String Condicion
resolverCondicion estado condicion =
    case condicion of

        CondObjeto obj comp valor -> do
            obj' <- resolverObjeto estado (ubicacion obj)
            return (CondObjeto obj' comp valor)

        CondSensor sensor comp valor ->
            Right (CondSensor sensor comp valor)

        Y c1 c2 -> do
            c1' <- resolverCondicion estado c1
            c2' <- resolverCondicion estado c2
            return (Y c1' c2')

        O c1 c2 -> do
            c1' <- resolverCondicion estado c1
            c2' <- resolverCondicion estado c2
            return (O c1' c2')

        No c -> do
            c' <- resolverCondicion estado c
            return (No c')


-- ============================================================
-- RESOLUCION DE VARIABLES
-- ============================================================

resolverVar :: Estado -> Var -> Either String Var
resolverVar estado var =
    case var of

        VInt n ->
            Right (VInt n)

        VN






















-- Funcion para facilitar el testing del parser.
totParser :: Parser a -> Parser a
totParser p = do
                  whiteSpace lis
                  t <- p
                  eof
                  return t

-- Analizador de Tokens
lis :: TokenParser u
lis = makeTokenParser (emptyDef   { commentStart  = "/*"
                                  , commentEnd    = "*/"
                                  , commentLine   = "//"
                                  , reservedNames = ["define", "end-define", "Pines", "Sensor", "Objeto", "si", "entonces", "let", "mientras", "hacer", "ejecutar"]
                                  , reservedOpNames = [  "+"
                                                       , "-"
                                                       , "*"
                                                       , "/"
                                                       , "<"
                                                       , ">"
                                                       , ">="
                                                       , "<="
                                                       , "&"
                                                       , "|"
                                                       , "="
                                                       , ";"
                                                       , "~"
                                                       , ":=" -- Token asignacion
                                                       , ":" -- Token para def hora
                                                       , "," -- Token separador de campos
                                                       ]
                                   }
                                 )
----------------------------------
-- Parser para expresiones generales
----------------------------------
generalExp :: Parser Exp
generalExp = try (do o <- objAccess
                     return (EObj o))
        <|> try (do o <- objExp
                    return (EObj o))
        <|> try (do s <- stringLiteral lis
                    return (EObj (Str s)))
        <|> try (do i <- intexp
                    return (EInt i))
        <|> try (do b <- boolexp
                    return (EBool b))
----------------------------------
--- Parser de expressiones enteras
-----------------------------------
{--
chainl p op x
parsea 0 o más ocurrencias de p separadas por op
Retorna el valor que se obtiene al aplicar todas las
funciones retornadas por op a los valores retornados
por p

t := t + t | m
term = chainl factor (do {symbol "+"; return (+)})
factor = integer <|> parens term
--}

--- +=== VER AST INT EXP ====
-- intexp :: Parser IntExp
-- intexp  = chainl1 term addopp   -- Construye expresiones asociadas a la IZQUIERDA con precedencia sobre + y -

-- term = chainl1 factor multopp   -- Construye expresiones asociadas a la IZQ con precedencia sobre * y /

-- factor = try (parens lis intexp)        -- Parsea parentesis
--          <|> try (do reservedOp lis "-" -- Parsea negacion unaria
--                      f <- factor
--                      return (UMinus f))
--          <|> (do n <- integer lis       -- Parsea Numeros
--                  return (Const n))
--          <|> do  str <- identifier lis  -- Parsea Variables
--                  return (Var str)

-- multopp = do try (reservedOp lis "*")   -- Parsea Multiplicacion
--              return Times
--           <|> do try (reservedOp lis "/")       -- Parsea Division
--                  return Div

-- addopp = do try (reservedOp lis "+")    -- Parsea Suma
--             return Plus
--          <|> do try (reservedOp lis "-")        -- Parsea Resta
--                 return Minus


-----------------------------------
--- Parser de expressiones booleanas
------------------------------------
-- boolexp :: Parser BoolExp
-- boolexp  = chainl1 boolexp2 (try (do reservedOp lis "|"         -- Parsea operador OR (Menor precedencia)
--                                      return Or))

-- boolexp2 = chainl1 boolexp3 (try (do reservedOp lis "&"         -- Parsea operador AND (Mayor precedencia)
--                                      return And))

-- boolexp3 = try (parens lis boolexp)             -- Parsea parentesis con una exp bool dentro, ej ( True | False )
--            <|> try (do reservedOp lis "~"       -- Parsea Not
--                        b <- boolexp3
--                        return (Not b))
--            <|> intcomp                          -- Parsea comparacion entre enteros
--            <|> boolvalue                        -- Parsea valores booleanos

-- intcomp = try (do i <- intexp           -- Parsea comparacion entre intexpr
--                   c <- compopp
--                   j <- intexp
--                   return (c i j))

-- compopp = try (do reservedOp lis "="    -- Parsea comparacion igual
--                   return Eq)
--           <|> try (do reservedOp lis "<"        -- Parsea comparacion menor que
--                       return Lt)
--           <|> try (do reservedOp lis ">"        -- Parsea comparacion mayor que
--                       return Gt)

-- boolvalue = try (do reserved lis "true"         -- Parsea constructor Booleano BTrue o BFalse
--                     return BTrue)
--             <|> try (do reserved lis "false"
--                         return BFalse)

-----------------------------------
--- Parser de comandos
-----------------------------------
comm :: Parser Comm
-- comm = chainl1 comm2 (try (do reservedOp lis ";"    -- Construye seq de comandos asociada a la izquierda. Seq es el de menor precedencia
--                               return Seq))
comm = chainl1 comm2 ()    -- Construye seq de comandos asociada a la izquierda. Seq es el de menor precedencia

-- En comm2 se definen los comandos de mayor precedencia
comm2 = try (do reserved lis "define"
                x <- identifier lis
                y <- identifier lis
                reserved lis "end-define"
                return (Swap x y))   -- Comando define
        <|> try (do reserved lis "skip"
                    return Skip)
        <|> try (do reserved lis "if"
                    cond <- boolexp
                    reserved lis "then"
                    case1 <- comm
                    reserved lis "else"
                    case2 <- comm
                    reserved lis "end"
                    return (Cond cond case1 case2))
        <|> try (do reserved lis "repeat"
                    c <- comm
                    reserved lis "until"
                    cond <- boolexp
                    reserved lis "end"
                    return (Repeat c cond))
        <|> try (do str <- identifier lis
                    reservedOp lis ":="
                    e <- generalExp
                    return (Let str e))


------------------------------------
-- Funcion de parseo
------------------------------------
parseComm :: SourceName -> String -> Either ParseError Comm
parseComm = parse (totParser comm)

-----------------------------------
--- Parser de Objetos
-----------------------------------
{-
reservedOp lis "{" -> Consume simbolos fijos, consume espacios y falla si no aparece el simbolo
reserved lis "palabra" -> consume palabras reservadas del lenguaje definidas en lis
identifier lis -> parsea un identificador de variables en el estado (ej nombre, apellido, edad) y retorna un String
sepBy parser separador -> parsea 0 o mas ocurrencias de *parser*, separadas por el *separador* y retorna una lista
-}

-- Parser de un campo del objeto  
-- retorna (String, IntExp) -> String == nombre del campo, IntExp == valor del campo
-- (Ej. edad : 10) obtiene los datos edad, :, 10 y los parsea name <- edad, value<-10, retorna (edad,10)
objField :: Parser (String, Exp)
objField = do
                name <- identifier lis
                reservedOp lis ":"
                value <- generalExp
                return (name, value)

-- Parser para lista de campos
-- Retorna una lista de par campo, valor; separadas por el caracter ","
-- (Ej. [nombre:"pepe",edad:15] -> [(nombre,"pepe"), (edad,15)])
objFields :: Parser [(String,Exp)]
objFields = sepBy objField (reservedOp lis ",")

-- Parser de objeto completo
-- Extraigo {, luego obtengo la lista de campos, extraigo } y al final retorno la lista de campos del objeto
objExp :: Parser ObjExp
objExp = do
        --     reservedOp lis "{"
        --     fields <- objFields
        --     reservedOp lis "}"
            fields <- braces lis objFields --De esta manera consumo los {} y espacios automaticamente
            return (Obj fields)


-----------------------------------
--- Azucar sintactica
-----------------------------------
-- fieldAccess -> acceso a un solo campo
-- Retorna el nombre del identificador del campo
-- (Ej. persona.edad -> retorna edad)
fieldAccess :: Parser String
fieldAccess = do
                reservedOp lis "."
                identifier lis


--objAccess para acceder a campos del objeto
-- Intento consumir el objeto literal (si empieza con {}) -> Si es valido, crea el objeto, lee los campos y retorna (buildAccess (EObj obj) fields)
-- Si falla, intento acceder al objeto desde la variable y lee el campo especificado
-- Uso many1 para garantizar que exista al menos un "."
{-
- objAccess es un parser que reconoce accesos a campos de objetos usando la sintaxis punto.
- Primero intenta parsear un acceso desde un objeto literal y luego desde una variable.
- Se usa many1 para asegurar que exista al menos un acceso con . y evitar ambigüedad con variables simples(No Objetos).
- La función buildAccess construye el AST anidando constructores Access para representar accesos encadenados como  persona.dir.calle.
-}

objAccess :: Parser ObjExp
objAccess = try objFromLiteral <|> try objFromVar
            where
            objFromLiteral = do
                    obj <- objExp
                    fields <- many1 fieldAccess
                    return (buildAccess (EObj obj) fields)

            objFromVar = do
                    v <- identifier lis
                    fields <- many1 fieldAccess
                    return (buildAccess (EInt (Var v)) fields)

--Ejecucion:
{-
Ejemplo: persona.dir.calle

buildAccess (EInt (Var "persona")) ["dir","calle"]
→ buildAccess (Access (EInt (Var "persona")) "dir") ["calle"]
→ buildAccess (Access (EInt (Var "persona")) "dir") "calle") []

resultado
-> Access (Access (Var "persona") "dir") "calle"

-}
buildAccess :: Exp -> [String] -> ObjExp
buildAccess exp [] = case exp of
                    EObj o -> o
                    _      -> error "Acceso invalido"
buildAccess exp (f:fs) = buildAccess' (Access exp f) fs

-- buildAccess' recibe un objeto y una lista de campos anidados al objeto
-- Si la lista de campos es vacia, retorna el objeto
-- Sino, construye el AST de acceso al campo 
-- Ej: persona.dir.calle
-- Crea el primer nodo: Access (EInt (Var "persona")) "dir" ["calle"]
-- crea el segundo nodo: Access (Access (EInt (Var "persona")) "dir") "calle"
buildAccess' :: ObjExp -> [String] -> ObjExp
buildAccess' obj [] = obj
buildAccess' obj (f:fs) = buildAccess' (Access (EObj obj) f) fs

