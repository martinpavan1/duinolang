
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

data DiaSemana = Lunes | Martes | Miercoles | Jueves
               | Viernes | Sabado | Domingo
  deriving (Show, Eq, Ord, Enum)

data Objeto = LuzLiving | LuzPieza | LuzGarage
            | Heladera  | Persiana  | PortonGarage
  deriving (Show, Eq, Ord)

data EstadoDispositivo = Encendido | Apagado | Abierto | Cerrado | Activado
  deriving (Show, Eq)
```

### Condiciones y acciones ejemplos

```haskell
data Condicion
  = TemperaturaMenorQue Ubicacion Int
  | TemperaturaMayorQue Ubicacion Int
  | PresenciaEn         Ubicacion
  | NoHayPresenciaEn    Ubicacion
  | EstadoEs            Objeto EstadoDispositivo
  | EsDia               DiaSemana
  | EsHora              Int              -- 0 .. 23

  -- Condiciones compuestas (tipos recursivos) ?? reveer
  | Y  Condicion Condicion
  | O  Condicion Condicion
  | No Condicion

data Accion
  = Encender    Objeto
  | Apagar      Objeto
  | Abrir       Objeto
  | Cerrar      Objeto
  | EncenderPor Objeto Int              -- con duración en segundos

```
---

##  State Monad
Evaluar usar State Monad para representar los estados del ambiente, tales como temperaturas, luces, presencias, etce etc



---




##  Alcance del Proyecto

###  Incluye

- Tipos (`Objeto`, `Sensor`, `Ubicacion`, `DiaSemana`)
- AST de `Condicion` y `Accion` con tipos recursivos (REVEER RECURSIVOS)
- Evaluador: dadas reglas y estado, retorna acciones 
- Simulador interactivo: botón que avanza hora/día y reevalua el programa
- `Maybe` para manejo de errrores
- Parser

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
