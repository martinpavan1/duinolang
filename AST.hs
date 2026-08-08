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

data TipoObjeto = TipoEncendible 
                | TipoAbrible 
                | TipoActivable 
                deriving (Show, Eq, Ord)

-- Objeto general, que deriva de los Tipos de objetos
data Objeto = Objeto {
  nombreObjeto :: Nombre,
  tipo :: TipoObjeto,
  ubicacion :: Ubicacion,
  estado :: EstadoObjeto, -- por defecto en 0
  pinOutput :: Pin  -- Defino Pin de output para accionar el objeto (Ver como lo definimos para manejarlo en el pool de pines)
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
type Nombre = String
{-
## Definir pool de pines disponibles

* pines fisicos de la placa, ya sean digitales o analogicos
(10 digitales, 5 analogicos)

* Comportamiento de los pines (input/output)

* Señal admitida por cada pin 

* Implementar validaciones para detectar si el pin definido esta usado/input/output/señal permitida (digital/analogica)

(0-5 digital input)
(6-9 digital output)
(A0-A5) analogico


## Cuando el usuario defina los pines
Sensor TempCocina Digital 0
Sensor BotonGarage Digital 1

Se creara en el estado los sensores:
[Sensor TempCocina Digital 0, Sensor BotonGarage Digital 1]

Para luego acceder a los sensores definidos para utilizarlos en el resto del programa 
-}

data Sensor = Sensor {
    nombreSensor :: Nombre,
    senial :: TipoSenial,
    pinInput :: Pin
  } deriving (Show, Eq)

type ConfigSensores = [(Nombre, (Pin, TipoSenial))]
-- Al usuario le tiene que permitir definir el nombre 
-- del sensor y automaticamente adosarce al pin y tipo de señal correspondiente a ese sensor

--Y si forzamos que al principio de la ejecución del programa, el usuario defina los sensores que va a usar
{-
Parte del Parser:
define Sensores = [
  Cocina:Temperatura:2, 
  Living:Luminosidad:3, 
  Garage:Humedad:0
  ]

define
Sensor TempCocina Digital 0,
Sensor BotonGarage Digital 1,
end-define

Se construye el AST:
Sensor Temperatura


y el programa se encargue de asociarlos a los pines y tipos de señal correspondientes, para que luego el usuario pueda referirse a ellos por nombre.
-}

-- Como definimos que es un sensor digital o analogico?
-- El usuario sabe diferenciar entre sensor analogico y digital.. 

data Comparador = Mayor | Menor | Igual
  deriving (Show, Eq, Ord) -- Ver si lo sacamos??

--- Condiciones y acciones ejemplos
data Condicion = CondSensor Sensor Comparador Int
                -- Condiciones compuestas (tipos recursivos) ?? reveer
                | Y  Condicion Condicion
                | O  Condicion Condicion
                | No Condicion
                  deriving (Show, Eq)

data Accion = Encender    Objeto
            | Apagar      Objeto
            | Abrir       Objeto
            | Cerrar      Objeto
            | EncenderTemporizado Objeto Int    -- con duración en segundos
            deriving (Show, Eq, Ord)



data Estado = Estado { 
  hrActual  :: Int,
  diaActual :: DiaSemana,
  sensores :: [Sensor], -- ver
  -- temperaturas  :: [(Ubicacion, Int)],
  -- luminosidades :: [(Ubicacion, Int)], 
  -- humedades ::  [(Ubicacion, Int)],
  estados :: [(Objeto, EstadoObjeto)]
  }
    deriving Show