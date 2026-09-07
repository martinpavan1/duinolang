data Ubicacion = Cocina 
                | Living 
                | Garage 
                | Pieza 
                | Exterior
  deriving (Show, Eq, Ord, Enum)

data DiaSemana = Lunes 
                | Martes 
                | Miercoles 
                | Jueves
                | Viernes 
                | Sabado 
                | Domingo
  deriving (Show, Eq, Ord, Enum)

-- Definir validaciones en el parser 
data Hora = Hora {
  horas :: Int,
  minutos :: Int,
  segundos :: Int
  
} deriving (Show, Eq, Ord)

data TipoObjeto = TipoEncendible 
                | TipoLuz
                | TipoAbrible 
                | TipoActivable 
                deriving (Show, Eq, Ord)
type Pin = Int
type Nombre = String
type Nivel = Int -- de 0 a 100

-- Objeto general, que deriva de los Tipos de objetos
data Objeto = Objeto {
  nombreObjeto :: Nombre,
  tipo :: TipoObjeto,
  ubicacion :: Ubicacion,
  estadoObjeto :: Nivel, -- por defecto en 0
  pinOutput :: Pin  -- Defino Pin de output para accionar el objeto (Ver como lo definimos para manejarlo en el pool de pines)
} deriving (Show, Eq, Ord)

data TipoSenial = Digital | Analogica
  deriving (Show, Eq)

data Sensor = Sensor {
    nombreSensor :: Nombre,
    senial :: TipoSenial,
    pinInput :: Pin
  } deriving (Show, Eq)

-- Constructor data para definir variables
data Variable = VO Objeto
              | VS Sensor 
  deriving (Show, Eq)


data Comparador = Mayor | Menor | Igual | MayorIgual | MenorIgual | Distinto
  deriving (Show, Eq, Ord) -- Ver si lo sacamos??

--- Condiciones y acciones ejemplos
data Condicion = CondSensor Sensor Comparador Int
                | CondObjeto Objeto Comparador Nivel 
                -- Condiciones compuestas (tipos recursivos) ?? reveer
                | Y  Condicion Condicion
                | O  Condicion Condicion
                | No Condicion
                  deriving (Show, Eq)

data Accion = Encender    Objeto
            | Apagar      Objeto
            | Abrir       Objeto
            | Cerrar      Objeto
            | EncenderTemporizado Objeto Hora    -- duracion expresada en hr, min y seg | ejemplo 3:12:54 (3 x 3.600 + 12 x 60 + 54) x 1000 --> millis totales p arduino
            deriving (Show, Eq, Ord)


-- Estado guarda todos las configuraciones de los pines, sensores y objetos, y sus estados actuales definidos por el usuario en define
data Estado = Estado { 
  --hrActual  :: Int, -- ver
  --diaActual :: DiaSemana, -- ver
  objetos :: [Objeto],
  sensores :: [Sensor],
  pines :: [(Pin, Bool)], -- Pin usado(T) o no usado(F) 
  temporizadores :: [(Objeto, Hora)] -- pool de temporizadores
  }
    deriving Show

data Regla = Regla { -- Cumple la funcion de emparejar condiciones y acciones 
  condicion :: Condicion,
  accion :: Accion
} deriving (Show, Eq)


-- Comandos 
data Comm = Let Variable
  deriving (Show, Eq)












