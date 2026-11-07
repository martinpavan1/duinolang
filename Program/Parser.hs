module Parser where

import Text.ParserCombinators.Parsec
import Text.Parsec.Token
import Text.Parsec.Language (emptyDef)
import AST


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
                    , "const" --Para constantes del programa
                    , "timer" -- para los temporizadores a utilizar
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
                    , ":=" -- asignacion a variable
                    , ":" -- para def hora
                    , "," -- separador de campos
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

-- declaraciones -> 'define' poolPines listaDecl 'end-define'
parseDeclaraciones :: Parser Estado
parseDeclaraciones = do
                        reserved lis "define"

                        pines <- parsePoolPines

                        declaraciones <- many1 parseDecl

                        reserved lis "end-define"

                        let objetosDeclarados = [(nombre, objeto) | DeclObjeto nombre objeto <- declaraciones ]

                        let sensoresDeclarados = [(nombre, sensor) | DeclSensor nombre sensor <- declaraciones ]
                        
                        let usados = [ pinOutput obj | (_, obj) <- objetosDeclarados] ++ [ pinInput sen | (_, sen) <- sensoresDeclarados]

                        return Estado
                            { constantes    = []
                            , variables     = []
                            , objetos       = objetosDeclarados
                            , sensores      = sensoresDeclarados
                            , pines         = [(p, p `elem` usados) | p <- pines]
                            , temporizadores = []
                            }

data Declaracion   = DeclObjeto (Nombre, Objeto) | DeclSensor (Nombre, Sensor) deriving Show


{- Agregar bloque de codigo para parsear los timers y const -}

-- poolPines -> 'Pines' nombre pines ';'
parsePoolPines :: Parser ([Pin])
parsePoolPines = do
                    reserved lis "Pines"
                    nombre <- identifier lis
                    pines <- parsePines
                    reservedOp lis ";"
                    return (pines)

-- pines -> '[' listaEnteros ']'
parsePines :: Parser [Int]
parsePines = brackets lis parseListaEnteros

-- listaEnteros -> entero | entero ',' listaEnteros
parseListaEnteros :: Parser [Int]
parseListaEnteros = sepBy integer (reservedOp lis ",")

-- decl -> sensor | objeto
parseDecl :: Parser Declaracion
parseDecl = try parseSensor
                <|> parseObjeto

-- sensor -> 'Sensor' nombre tipoSenial pin activo ';'
parseSensor :: Parser Declaracion
parseSensor = do
                reserved lis "Sensor"

                nombre <- identifier lis
                tipo <- parseTipoSenial
                pin <- integer lis
                activoSensor <- parseActivo -- ???

                reservedOp lis ";"

                return (DeclSensor (nombre, Sensor {senial=tipo, pinInput=pin, activo=activoSensor}))

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
                nivelInicial <- integer lis -- ver de reemplazar por float si cambiamos el AST
                pin <- integer lis

                reservedOp lis ";"

                return DeclObjeto (nombre, Objeto
                            { tipo = tipo
                            , ubicacion = ubic
                            , estadoObjeto = nivelInicial
                            , pinOutput = pin
                            })

-- tipoObjeto -> 'TipoEncendible'
--                | 'TipoAbrible'
--                | 'TipoActivable'
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
parseVar = do
                entero <- integer lis
                return (VInt (fromInteger n))
            <|> do
                listaVar <- parseListaVar
                return (VList xs)
            <|> do
                varNombre <- identifier lis
                return (VNomb n)

-- listaVar -> '[' ']' | '[' elementos ']'
parseListaVar :: Parser [Var]
parseListaVar = brackets lis (sepBy parseVar (reservedOp lis ","))

-- comandos -> comm | comm comandos
parseComandos :: Parser [Comm]
parseComandos = many1 parseComm

-- comm -> let | si | mientras | ejecutar | secuencia | map
parseComm :: Parser Comm
parseComm = try parseLet
            <|> try parseSi
            <|> try parseMientras
            <|> try parseEjecutar
            <|> try parseSecuencia
            <|> parseMap

-- let -> nombre ':=' var ';'
parseLet :: Parser Comm
parseLet = do
            reserved lis "let"
            nombre <- identifier lis
            reservedOp lis ":="
            valor <- parseVar
            reservedOp lis ";"

            return (Let nombre valor)

-- si -> 'si' condicion 'entonces' '(' comandos ')' ';'
parseSi :: Parser Comm
parseSi = do
            reserved lis "si"
            condicion <- parseCondicion
            reserved lis "entonces"

            comandos <- parens lis parseComandos
            reservedOp lis ";"

            return (Si condicion comandos)

-- mientras -> 'mientras' condicion 'hacer' '(' comandos ')' ';'
parseMientras :: Parser Comm
parseMientras = do
                    reserved lis "mientras"
                    condicion <- parseCondicion
                    reserved lis "hacer"

                    comandos <- parens lis parseComandos
                    reservedOp lis ";"

                    return (Mientras condicion comandos)

-- condicion -> condicion 'o' condicion' | condicion'
parseCondicion :: Parser Condicion
parseCondicion = do
                    izq <- parseCondicionY
                    parseRestoOr izq
                where
                    parseRestoOr izq =
                        (do
                            reserved lis "o"
                            der <- parseCondicionY
                            parseRestoOr (O izq der))
                        <|> return izq

-- condicion' -> condicion' 'y' condicion'' | condicion''
parseCondicionY :: Parser Condicion
parseCondicionY = do
                    izq <- parseCondicionNo
                    parseRestoAnd izq
                where
                    parseRestoAnd izq =
                        (do
                            reserved lis "y"
                            der <- parseCondicionNo
                            parseRestoAnd (Y izq der))
                        <|> return izq

-- condicion'' -> '(' condicion ')' | 'no' condicion'' | condFinal
parseCondicionNo :: Parser Condicion
parseCondicionNo = do
                        reserved lis "no"
                        condicion <- parseCondicionNo
                        return (No condicion)
                    <|> parens lis parseCondicion
                    <|> parseCondFinal

-- condFinal -> nombre compopp entero
parseCondFinal :: Parser Condicion
parseCondFinal = do
                    nombre <- identifier lis
                    comparador <- parseComparador
                    valor <- integer lis
                    
                    -- No tenemos el estado para acceder al nombre del identificador y 
                    -- posteriormente al valor.
                    -- Resuelvo nombre -> Objeto/Sensor en resolverCondicion
                    -- ######### TODO ###########
                    -- acceder al estado y buscar el nombre que identifica al objeto, despues el valor del mismo
                    -- para poder hacer la comparacion con el valor de referencia.

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

-- compopp -> '<' | '>' | '==' | '<=' | '>=' | '!='
parseComparador :: Parser Comparador
parseComparador = try (do 
                        reservedOp lis ">="
                        return MayorIgual)
                <|> try (do
                        reservedOp lis "<="
                        return MenorIgual)
                <|> try (do
                        reservedOp lis "==" 
                        return Igual)
                <|> try (do 
                        reservedOp lis "!=" 
                        return Distinto)
                <|> try (do
                        reservedOp lis ">"
                        return Mayor)
                <|>     (do 
                        reservedOp lis "<"
                        return Menor)

-- ejecutar -> accion
parseEjecutar :: Parser Comm
parseEjecutar = do
                accion <- parseAccion
                return (Ejecutar accion)

-- accion ->
--      'Encender' nombre
--    | 'Apagar' nombre
--    | 'Abrir' nombre
--    | 'Cerrar' nombre
--    | 'EncenderTemporizado' nombre hora

parseAccion :: Parser Accion
parseAccion = try parseEncenderTemporizado
            <|> try parseEncender
            <|> try parseApagar
            <|> try parseAbrir
            <|> parseCerrar

parseEncender :: Parser Accion
parseEncender = do
                    reserved lis "Encender"
                    nombre <- identifier lis

                    return (Encender (objetoPlaceholder nombre))

parseApagar :: Parser Accion
parseApagar = do
                reserved lis "Apagar"
                nombre <- identifier lis

                return (Apagar (objetoPlaceholder nombre))

parseAbrir :: Parser Accion
parseAbrir = do
                reserved lis "Abrir"
                nombre <- identifier lis

                return (Abrir (objetoPlaceholder nombre))

parseCerrar :: Parser Accion
parseCerrar = do
                reserved lis "Cerrar"
                nombre <- identifier lis

                return (Cerrar (objetoPlaceholder nombre))

parseEncenderTemporizado :: Parser Accion
parseEncenderTemporizado = do
                                reserved lis "EncenderTemporizado"

                                nombre <- identifier lis
                                tiempo <- parseHora

                                return (EncenderTemporizado (objetoPlaceholder nombre) tiempo)

-- hora -> entero ':' entero ':' entero
parseHora :: Parser Hora
parseHora = do
                h <- integer lis
                symbol ":"
                m <- integer lis 
                symbol ":"
                s <- integer lis

                if h >= 0 && h < 24 && m >= 0 && m < 60 && s >= 0 && s < 60
                    then return (Hora h m s)
                    else error "hora invalida"

-- secuencia -> 'secuencia' '(' comandos ')' ';'
parseSecuencia :: Parser Comm
parseSecuencia = do
                    reserved lis "secuencia"

                    comandos <- parens parseComandos
                    reservedOp lis ";"


                    return (listaASeceuncia comandos)

listaASeceuncia :: [Comm] -> Comm
listaASeceuncia [] = error "secuencia vacia"
listaASeceuncia [x] = x
listaASeceuncia (x:xs) = Secuencia x (listaASeceuncia xs)

-- map -> 'Map' accion listaVar ';'
parseMap :: Parser Comm
parseMap = do
                reserved lis "Map"

                accion <- parseAccion
                vars <- parseListaVar
                reservedOp lis ";"

                return (Map accion vars)

-- ============================================================
-- OBJETO PLACEHOLDER
-- ============================================================
-- Durante el parseo sabemos el nombre del Objeto pero no sus propiedades
-- Uso un placeholder y despues buscarObjeto reemplaza este placeholder
-- por el objeto declarado en define.

objetoPlaceholder :: Nombre -> Objeto
objetoPlaceholder nombre = Objeto { tipo = TipoActivable
                                    , ubicacion = nombre
                                    , estadoObjeto = 0
                                    , pinOutput = -1
                                    }

buscarObjeto :: Estado -> Nombre -> Either String Objeto
buscarObjeto estado nombre = case lookup nombre (objetos estado) of
                                    Just obj -> Right obj
                                    Nothing -> Left ("Objeto no definido: " ++ nombre)

buscarSensor :: Estado -> Nombre -> Either String Sensor
buscarSensor estado nombre = case lookup nombre (sensores estado) of
                                    Just sensor -> Right sensor
                                    Nothing -> Left ("Sensor no definido: " ++ nombre)

-- ============================================================
-- ACCIONES
-- ============================================================
resolverAccion :: Estado -> Accion -> Either String Accion
resolverAccion estado accion =
    case accion of

        Encender obj -> do
                            obj' <- buscarObjeto estado (ubicacion obj)
                            return (Encender obj')

        Apagar obj -> do
                        obj' <- buscarObjeto estado (ubicacion obj)
                        return (Apagar obj')

        Abrir obj -> do
                        obj' <- buscarObjeto estado (ubicacion obj)
                        return (Abrir obj')

        Cerrar obj -> do
                        obj' <- buscarObjeto estado (ubicacion obj)
                        return (Cerrar obj')

        EncenderTemporizado obj hora -> do
                                            obj' <- buscarObjeto estado (ubicacion obj)
                                            return (EncenderTemporizado obj' hora)


-- ============================================================
-- CONDICIONES
-- ============================================================

resolverCondicion :: Estado -> Condicion -> Either String Condicion
resolverCondicion estado condicion =
    case condicion of

        CondObjeto obj comp valor -> do
                                        obj' <- buscarObjeto estado (ubicacion obj)
                                        return (CondObjeto obj' comp valor)

        CondSensor sensor comp valor -> do 
                                          sens' <- buscarSensor estado (nombre sensor)
                                          return (CondSensor sens' comp valor)
            
            --return -- reemplazar con logica para resolver la condSensor

        Y c1 c2 -> do
                    c1' <- resolverCondicion estado c1 --CondSensor tempCocina > 24
                    c2' <- resolverCondicion estado c2 --CondObjeto aireCocina == 0
                    return (Y c1' c2') -- Y CondSensor tempCocina > 24 CondObjeto aireCocina == 0

        O c1 c2 -> do
                    c1' <- resolverCondicion estado c1
                    c2' <- resolverCondicion estado c2
                    return (O c1' c2')

        No c -> do
                    c' <- resolverCondicion estado c
                    return (No c')
        