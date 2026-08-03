data Ubicacion = Cocina | Living | Garage | Pieza | Exterior
  deriving (Show, Eq, Ord)

data DiaSemana = Lunes 
                | Martes 
                | Miercoles 
                | Jueves
                | Viernes 
                | Sabado 
                | Domingo
  deriving (Show, Eq, Ord, Enum)

data TipoObjeto = TipoEncendible String 
                | TipoAbrible String 
                | TipoActivable String 
                deriving (Show)

-- Objeto general, que deriva de los Tipos de objetos
data Objeto = Objeto {
  tipo :: TipoObjeto,
  ubicacion :: Ubicacion,
  estado :: EstadoObjeto
}

--Estados para encendibles, abribles y activables
-- Preguntar si con el nivel solucionamos los estados intermedios y completos
data EstadoObjeto = EstadoObjeto {
        nivel :: Int, --de 0 a 100
}


-- Tipo de sensores definidos
-- data Sensor = Temperatura Ubicacion String
--             | Luminosidad Ubicacion String
--             | Humedad Ubicacion String
--   deriving (Show, Eq)

data TipoSenial = Digital | Analogica
  deriving (Show, Eq)

data Sensor = Sensor {
    nombreSensor :: String,
    tipoSenial :: TipoSenial
  } deriving (Show, Eq)


data Comparador = Mayor | Menor | Igual
  deriving (Show, Eq) -- Ver si lo sacamos??

--- Condiciones y acciones ejemplos
data Condicion = CondSensor Sensor Comparador Int
                -- Condiciones compuestas (tipos recursivos) ?? reveer
                | Y  Condicion Condicion
                | O  Condicion Condicion
                | No Condicion
                  deriving (Show, Eq, Ord)

data Accion = Encender    Objeto
            | Apagar      Objeto
            | Abrir       Objeto
            | Cerrar      Objeto
            | EncenderTemporizado Objeto Int    -- con duración en segundos
            deriving (Show, Eq, Ord)



data Estado = Estado { 
  hrActual  :: Int,
  diaActual :: DiaSemana,
  temperaturas  :: [(Ubicacion, Int)],
  luminosidades :: [(Ubicacion, Int)], 
  humedades ::  [(Ubicacion, Int)],
  estadosEncendibles  :: [(ObjetoEncendible, EstadoEncendible)],
  estadosAbribles :: [(ObjetoAbrible, EstadoAbrible)],
  estadosActivable :: [(ObjetoActivable, EstadoActivable)],
  }
    deriving Show 