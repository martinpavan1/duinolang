
<div align="center">

# DuinoLang

### Domain Specific Language para Automatización Domótica Hogareña

*Un lenguaje que permite describir **cómo debe comportarse tu hogar** sin necesidad de programar ni conocer Arduino.*

---

**Programación Profesional · 2026**  
**Pavan, Martín Oscar · Ponce, Juan Manuel**


</div>

---

##  Tabla de Contenidos

- [Propuesta](#propuesta)
- [Sintaxis del Lenguaje](#sintaxis-del-lenguaje)
- [Arquitectura](#arquitectura)
- [Diseño del AST](#diseño-del-ast)
- [State Monad](#state-monad)
- [Alcance del Proyecto](#alcance-del-proyecto)
- [Decisiones de Diseño](#decisiones-de-diseño)

---

##  Propuesta

**DuinoLang** es un **DSL (Domain Specific Language) implementado en Haskell** orientado al control de sistemas domóticos. Permite definir reglas de automatización que reaccionan a sensores, al estado interno del sistema y a condiciones de tiempo, generando código ejecutable para Arduino.

El objetivo central es que el usuario final pueda **describir comportamientos** usando un lenguaje cercano al lenguaje natural, sin exponer ningún detalle de programación embebida. El DSL se encarga de la traducción.

| Problema | Solución DuinoLang |
|----------|-------------------|
| Programar Arduino requiere conocer C++ y electrónica | El usuario solo escribe reglas en lenguaje natural |
---

##  Sintaxis del Lenguaje

El usuario escribe reglas en un formato declarativo. Cada regla sigue la estructura:

```
//Declaracion de pines disponibles en placa
//Total de pines digitales disponibles = 13 (depende de placa fisica)
//Total de pines analogicos disponibles = 5 (depende de placa fisica)
[Pin0-input, Pin1-input, Pin2-input, Pin6-output]

//Declaración de sensores
//Sintaxis: Sensor 'nombre' 'tipo de señal' 'pin de conexión (input)'
define
Sensor tempCocina Digital 0
Sensor presenciaLiving Digital 1
Sensor botonGarage Digital 5
...
end-define

//Declaración de objetos (salida de la placa)
//Sintaxis: Objeto 'nombre' 'tipo de objeto' 'ubicacion' 'estado' 'pin de conexión (output)'

objetos
Objeto AAPieza TipoEncendible Pieza 0 6
Objeto LuzGarage TipoEncendible Garage 0 2
fin-objetos

si <condición> then <acción>
```

### Ejemplos de Reglas

```
si temperatura Cocina > 24 then encender AireAcon
si presencia Living == falso then apagar LuzLiving
si botonGarage activado then abrir portonGarage
si portonGarage abierto then encender luzGarage 60s
si martes then encender LuzLiving
si 8 then abrir persiana
si 18 then cerrar persiana
```

### Texto → AST

Cada regla en texto plano se transforma en su representación interna en Haskell:

| DSL (texto) | AST (Haskell) |
|-------------|---------------|
| `si temperatura Cocina > 24 then encender AireAcon` | `Si (TempMayor Cocina 24) (Encender AireCon)` |
| `si presencia Living == falso then apagar LuzLiving` | `Si (NoHayPresencia Living) (Apagar LuzLiving)` |
| `si botonGarage activado then abrir portonGarage` | `Si (EstadoEs BotonGarage Activado) (Abrir Porton)` |
| `si martes then encender LuzLiving` | `Si (EsDia Martes) (Encender LuzLiving)` |
| `si 8 then abrir persiana` | `Si (EsHora 8) (Abrir Persiana)` |

La sintaxis acepta condiciones sobre **sensores** (temperatura, presencia), **estado de dispositivos** (abierto, cerrado, activado), **día de la semana** y **hora del día**. Las acciones disponibles son: encender, apagar, abrir, cerrar — con soporte opcional para duración temporizada.

---

##  Arquitectura

El sistema se organiza en tres capas:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Lenguaje del Usuario                        │
│         si temperatura Cocina < 20 then cerrar Heladera         │
└──────────────────────────┬──────────────────────────────────────┘
                           │  Parser
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AST en Haskell                           │
│          Si (TemperaturaMenorQue Cocina 20) (Cerrar Heladera)   │
└──────────────────────────┬──────────────────────────────────────┘
                           │  Evaluador
                           ▼
                ┌──────────────────┐
                │ Código Arduino   │
                │     .ino         │
                └──────────────────┘
```

---

##  Diseño del AST

### Tipos ejemplos

```haskell
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

-- Tipo para objetos electricos que pueden encenderse-apagarse
data TipoEncendible = Luz 
                    | Heladera 
                    | AireAcond 
                    | Lavarropa 
                    | Microondas 
                    | Calefactor
  deriving (Show, Eq, Ord)

-- Tipo para objetos que se abren-cierran
data TipoAbrible = Persiana 
                  | Porton 
                  | Puerta
  deriving (Show, Eq, Ord)

-- Tipo para objetos que se activan-desactivan
data TipoActivable = Boton | SensorMovimiento
  deriving (Show, Eq, Ord)


-- Objetos encendibles, activables y abribles
data ObjetoEncendible = ObjetoEncendible {
  tipoEnc :: TipoEncendible,
  ubicacionEnc :: Ubicacion,
  nombreEnc :: String
}
  deriving (Show, Eq, Ord)

data ObjetoAbrible = ObjetoAbrible {
  tipoAbr :: TipoAbrible,
  ubicacionAbr :: Ubicacion,
  nombreAbr :: String
}
  deriving (Show, Eq, Ord)

data ObjetoActivable = ObjetoActivable {
  tipoAct :: TipoActivable,
  ubicacionAct :: Ubicacion,
  nombreAct :: String
}
  deriving (Show, Eq, Ord)

--Estados para encendibles, abribles y activables
data EstadoEncendible = Encendido | Apagado
  deriving (Show, Eq, Ord)

data EstadoAbrible = Abierto | Cerrado
  deriving (Show, Eq, Ord)

data EstadoActivable = Activado | Desactivado
  deriving (Show, Eq, Ord)

-- Tipo de sensores definidos
data Sensor = Temperatura Ubicacion String
            | Luminosidad Ubicacion String
            | Humedad Ubicacion String
  deriving (Show, Eq)

data Comparador = Mayor | Menor | Igual
  deriving (Show, Eq)


```

### Condiciones y acciones ejemplos

```haskell
data Condicion
  = CondSensor Sensor Comparador Int
  | CondEstadoEnc ObjetoEncendible EstadoEncendible
  | CondEstadoAbr ObjetoAbrible EstadoAbrible
  | CondEstadoAct ObjetoActivable EstadoActivable
  | CondDia DiaSemana
  | CondHora Comparador Int             -- 0 .. 23
  -- Condiciones compuestas (tipos recursivos) ?? reveer
  | Y  Condicion Condicion
  | O  Condicion Condicion
  | No Condicion
  deriving (Show, Eq, Ord)

data Accion
  = Encender    ObjetoEncendible
  | Apagar      ObjetoEncendible
  | Abrir       ObjetoAbrible
  | Cerrar      ObjetoAbrible
  | EncenderTemporizado ObjetoEncendible Int    -- con duración en segundos
  deriving (Show, Eq, Ord)
```
---

##  State Monad
Utilizariamos el State Monad para el manejo del Estado global, definiendo el Estado como:
```haskell
data Estado = Estado 
  { hrActual  :: Int,
    diaActual :: DiaSemana,
    temperaturas  :: [(Ubicacion, Int)],
    luminosidades :: [(Ubicacion, Int)], 
    humedades ::  [(Ubicacion, Int)],
    estadosEncendibles  :: [(ObjetoEncendible, EstadoEncendible)],
    estadosAbribles :: [(ObjetoAbrible, EstadoAbrible)],
    estadosActivable :: [(ObjetoActivable, EstadoActivable)],
    }
    deriving Show

```
Consultar si utilizamos par clave,valor o MAP
Ver funciones ACTUALIZAR, OBTENER, MODIFICAR, ELIMINAR, del estado. (CRUD)

## Gramática 

Sensor ::= TipoSensor Ubicacion

TipoSensor ::= "temperatura" | "luminosidad" | "humedad"

Ubicacion ::= Nombre

- PREGUNTAR SOBRE SENSORES!!!!!!!!!!!!!!!!!! TIPO SENSORES? ANALOGICO DIGITAL
- LISTA DE SENSORES O OBJETOS DISPONIBLES(PREDEFINIDOS)  O EL USUARIO PUEDE CREAR MAS SENSORES?
- DEFINICION DE PINES EN ARDUINO(COMO SE LIGA LA DECLARACION DEL SENSOR EN EL PROGRAMA A LA DE ARDUINO)

---


##  Alcance del Proyecto

###  Incluye

**Tipos del dominio**
- `Ubicacion`, `DiaSemana`
- `TipoEncendible`, `TipoAbrible`, `TipoActivable` - variedades de tipo de dispositivos
- `ObjetoEncendible`, `ObjetoAbrible`, `ObjetoActivable` - objetos separados por familia 
- `EstadoEncendible`, `EstadoAbrible`, `EstadoActivable` - estados separados por familia 

**AST del lenguaje**
- `Condicion` y `Accion`, con tipado por familia(no permite "cerrar" una luz)

**Estado del sistema**
- Tipo `Estado`con el estado de cada objeto/sensor, representado como listas de pares `[(clave, valor)]` ((VER SI USAR MAP))
- Monada `State` de Haskell, para manipular estado global
- Operaciones sobre el estado: **obtener** (`lookup`) y **actualizar** (inserta o reemplaza sin duplicar clave).

**Parser**
- Gramática formal que define sin ambigüedad la sintaxis de reglas, incluyendo precedencia de operadores lógicos (`no` > `y` > `o`)
- Traducción de texto plano a `Regla` (`Condicion` + `Accion`), devolviendo `Maybe`/`Either` ante reglas mal formadas o que referencian objetos no configurados

**Manejo de errores**
- `Maybe`/`Either` en las etapas donde puede fallar: parseo de reglas mal escritas, resolución de nombres de objeto contra la tabla de configuración, lectura de sensores no registrados en el `Estado`

###  No Incluye

- Comunicación serial real con hardware Arduino
- Interfaz gráfica de usuario
- Persistencia de estado entre sesiones
- Reglas con memoria de eventos pasados

---

## Decisiones de Diseño

1. El tiempo se controla mediante botones del simulador.
No se usa el reloj real del sistema. El simulador expone dos controles independientes:
- **Hora:** itera de `0` a `23` de a un paso por click, volviendo a `0` al llegar al límite.
- **Día:** itera de `0` (`Lunes`) a `6` (`Domingo`) de a un paso por click, volviendo a `0` al llegar al límite.
---
2. Los pines de Arduino son configuración fija, no parte del lenguaje
El usuario **nunca ve ni toca los pines**. La asignación `Objeto → Pin` es una tabla de configuración interna del sistema, definida una sola vez por quien instala el hardware. Este es el principio central del DSL: abstraer completamente el hardware.
---
