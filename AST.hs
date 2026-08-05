data Ubicacion = Cocina 
                | Living 
                | Garage 
                | Pieza 
                | Exterior
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
                deriving (Show, Eq, Ord)

-- Objeto general, que deriva de los Tipos de objetos
data Objeto = Objeto {
  tipo :: TipoObjeto,
  ubicacion :: Ubicacion,
  estado :: EstadoObjeto

} deriving (Show, Eq, Ord)

--Estados para encendibles, abribles y activables
-- Preguntar si con el nivel solucionamos los estados intermedios y completos
data EstadoObjeto = EstadoObjeto {
        nivel :: Int --de 0 a 100.. 
                      --0 es apagado, 100 es encendido, 1 a 99 estados intermedios, podemos definir estados intermedios fijos(ej: 25, 50, 75)
} deriving (Show, Eq, Ord)


-- Tipo de sensores definidos
-- data Sensor = Temperatura Ubicacion String
--             | Luminosidad Ubicacion String
--             | Humedad Ubicacion String
--   deriving (Show, Eq)

data TipoSenial = Digital | Analogica
  deriving (Show, Eq)

type Pin = Int

data Sensor = Sensor {
    nombreSensor :: String
  } deriving (Show, Eq, Ord)

type ConfigSensores = [(String, (Pin, TipoSenial))]
-- Al usuario le tiene que permitir definir el nombre 
-- del sensor y automaticamente adosarce al pin y tipo de señal correspondiente a ese sensor

--Y si forzamos que al principio de la ejecución del programa, el usuario defina los sensores que va a usar
-- define Sensores = [Cocina:Temperatura, Living:Luminosidad, Garage:Humedad] 
--y el programa se encargue de asociarlos a los pines y tipos de señal correspondientes, para que luego el usuario pueda referirse a ellos por nombre.

-- Como definimos que es un sensor digital o analogico?
-- El usuario sabe diferenciar entre sensor analogico y digital.. 

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
  estados :: [(Objeto, EstadoObjeto)]
  }
    deriving Show