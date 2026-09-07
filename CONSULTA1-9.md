1. Ver si la gramatica es correcta
2. Revisar AST.
3. Los pines (in, out, digitales, analogicos) ya estan pre-definidos en un pool de pines
4. Decidimos que se definan los sensores y objetos, con sus respectivos pines de conexion antes de todo el codigo, porque entendemos que la persona 'no sabe programar en arduino, pero si tiene conocimiento de conexion y electricidad/electronica.
5. Utilizar monada state, monada Either (error), Writer. Debe leer todo el codigo y si hay errores mostrar todos los errores que haya, o debe interrumpir la 'compilacion' en el primer error que detecte?
6. Definimos *type Nivel = Int* para representar el nivel de apertura/iluminacion que pueden tener los objetos que permitan dichas propiedades. Con esto solucionamos los estados intermedios y completos????

7. Al tener el *type Nivel* definido, el *data EstadoObjeto* es redundante???

8. La implementacion de *Hora* es correcta?