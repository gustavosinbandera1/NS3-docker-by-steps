# Tabla de contenido
- [Tabla de contenido](#tabla-de-contenido)
  - [Introduccion](#introduccion)
  - [Dockerfile](#dockerfile)
  - [Waf](#waf)
  - [Programacion de sockets](#programacion-de-sockets)
  - [Resumen conceptual](#resumen-conceptual)
    - [Abstracciones clave](#abstracciones-clave)
      - [Nodo](#nodo)
      - [Aplicación](#aplicaci%c3%b3n)
      - [Canal](#canal)
      - [Dispositivo de red](#dispositivo-de-red)
      - [Ayudantes de topología](#ayudantes-de-topolog%c3%ada)
      - [Un primer script ns-3](#un-primer-script-ns-3)
        - [El módulo incluye](#el-m%c3%b3dulo-incluye)
        - [Espacio de nombres Ns3](#espacio-de-nombres-ns3)
        - [Registro](#registro)
        - [Funcion main](#funcion-main)
          - [Ayudantes de topología](#ayudantes-de-topolog%c3%ada-1)
        - [PointToPointHelper](#pointtopointhelper)
        - [NetDeviceContainer](#netdevicecontainer)
        - [InternetStackHelper](#internetstackhelper)
        - [Ipv4AddressHelper](#ipv4addresshelper)
        - [Aplicaciones](#aplicaciones)
        - [UdpEchoServerHelper](#udpechoserverhelper)
        - [UdpEchoClientHelper](#udpechoclienthelper)
      - [Simulador](#simulador)
      - [Construyendo el script](#construyendo-el-script)
    - [Habilitando el registro](#habilitando-el-registro)
      - [Agregar registro a su código](#agregar-registro-a-su-c%c3%b3digo)
    - [Usando argumentos de línea de comando](#usando-argumentos-de-l%c3%adnea-de-comando)
    - [Enganchando tus propios valores](#enganchando-tus-propios-valores)


## Introduccion
En este documento se explica como ejecutar la instalacion del simulador para redes `NS3`, y como tener listo el ambiente de desarrollo para poder usar los scripts de simulacion, ademas veremos como ejecutar la aplicacion cliente servidor que trae NS3 dentro de sus ejemplos.

## Dockerfile
Primero que todo debe clonar este repositorio el cual contiene un archivo llamado __Dockerfile__, y otro archivo llamado __Mafefile__ el cual nos hace la vida mas facil a la hora de construir nuestra imagen docker y ejecutar la misma dentro de una consola.

Luego de clonar este repositorio, abrir una terminal bash y dentro del folder de este repo debe ejecutar el comando `make`, esto con el fin de crear nuestra imagen, puede tardar unos 15 o 20 minutos la instalacion, dependiendo de la velocidad de conexion  y de la maquina donde se ejecuta el proceso.

Al final despues del comando __make__, veran una salida como esta, si todo anda bien:
```
Skipping NetAnim ....
Leaving directory `netanim-3.107'
# Building examples (by user request)
# Building tests (by user request)
# Build NS-3
Entering directory `./ns-3.26'
 =>  /usr/bin/python waf configure --enable-examples --enable-tests --with-pybindgen ../pybindgen-0.17.0.post57+nga6376f2
 =>  /usr/bin/python waf build
Leaving directory `./ns-3.26'
Removing intermediate container af340e976eba
 ---> b6d5b682f25b
Step 13/14 : RUN ln -s /usr/ns-allinone-3.26/ns-3.26/ /usr/ns3/
 ---> Running in 1ac7a3f4d3cb
Removing intermediate container 1ac7a3f4d3cb
 ---> 8d5e466623c9
Step 14/14 : RUN apt-get clean &&   rm -rf /var/lib/apt &&   rm /usr/ns-allinone-3.26.tar.bz2
 ---> Running in 0f2407804f12
Removing intermediate container 0f2407804f12
 ---> cb61e81e00ab
Successfully built cb61e81e00ab
Successfully tagged mi-ns3:latest
```

Tambien pueden el comando `docker images` y veran algo como esto:
```
REPOSITORY                             TAG                 IMAGE ID            CREATED             SIZE
mi-ns3                                 latest              cb61e81e00ab        8 minutes ago       3.51GB
```

Mas adelante haremos una pequena modificacion al archivo del Docker para tener acceso a los ficheros del host.

Luego de finalizar la creacion de la imagen , el siguiente paso es:

`make run`, para lanzar nuestra consola de desarrollo

Por ejemplo al ejecutar __make__ __run__
```
gustavosinbandera1@gustavosinbandera1-HP-Laptop-17-bs0xx:~/LOCHA/DOCKERS/ns3-docker$ make run
docker run -it -e DISPLAY   --net=host mi-ns3:latest 
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr# 
```
Ya con esto tenemos el ambiente de trabajo listo para iniciar las simulaciones, vamos a hacer un test para ver si todo salio bien.

Luego de estar en la consola de NS3, podemos ir hasta la carpeta que contiene el proyecto,

```
gustavosinbandera1@gustavosinbandera1-HP-Laptop-17-bs0xx:~/LOCHA/DOCKERS/ns3-docker$ make run
docker run -it -e DISPLAY   --net=host mi-ns3:latest 
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr# ls
bin  games  include  lib  lib32  libx32  local  ns-allinone-3.26  ns3  sbin  share  src
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr# cd ns3/
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns3# ls
ns-3.26
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns3# cd ns-3.26
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns3/ns-3.26# ls
AUTHORS       LICENSE   README         VERSION   build  examples  src      testpy.supp  utils.py   waf        waf.bat  wutils.py
CHANGES.html  Makefile  RELEASE_NOTES  bindings  doc    scratch   test.py  utils        utils.pyc  waf-tools  wscript  wutils.pyc
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns3/ns-3.26# 
```
Estando dentro de la carpeta que muestra el bloque de codigo de arriba ejecutamos el test de la siguiente manera:

`./test.py -c core`




## Waf

Como se mencionó anteriormente, las secuencias de comandos en ns-3 se realizan en C ++ o Python. La mayoría de la API ns-3 está disponible en Python, pero los modelos están escritos en C ++ en cualquier caso. En este documento se supone un conocimiento práctico de C ++ y conceptos orientados a objetos. Nos tomaremos un tiempo para revisar algunos de los conceptos más avanzados o características del lenguaje, modismos y patrones de diseño posiblemente desconocidos a medida que aparecen. Sin embargo, no queremos que este tutorial se convierta en un tutorial de C ++, por lo que esperamos un comando básico del lenguaje. Hay una cantidad casi inimaginable de fuentes de información sobre C ++ disponibles en la web o en forma impresa.

Si es nuevo en C ++, es posible que desee encontrar un libro o sitio web basado en un tutorial o en un libro de cocina y trabajar al menos con las características básicas del lenguaje antes de continuar. Por ejemplo, este tutorial.

El sistema ns-3 utiliza varios componentes de la "cadena de herramientas" de GNU para el desarrollo. Una cadena de herramientas de software es el conjunto de herramientas de programación disponibles en el entorno dado. Para una revisión rápida de lo que se incluye en la cadena de herramientas GNU, consulte http://en.wikipedia.org/wiki/GNU_toolchain. ns-3 usa gcc, GNU binutils y gdb. Sin embargo, no utilizamos las herramientas del sistema de compilación GNU, ni make ni autotools. Usamos Waf para estas funciones.

## Programacion de sockets

Asumiremos una instalación básica con la API Berkeley Sockets en los ejemplos utilizados en este tutorial. Si eres nuevo en sockets, te recomendamos revisar la API y algunos casos de uso comunes. Para una buena visión general de la programación de sockets TCP / IP, recomendamos Sockets TCP / IP en C, Donahoo y Calvert.

Existe un sitio web asociado que incluye la fuente de los ejemplos en el libro, que puede encontrar en: http://cs.baylor.edu/~donahoo/practical/CSockets/.

Si comprende los primeros cuatro capítulos del libro (o para aquellos que no tienen acceso a una copia del libro, los clientes y servidores de eco que se muestran en el sitio web anterior) estará en buena forma para comprender el tutorial. Hay un libro similar sobre sockets de multidifusión, sockets multicast, Makofske y Almeroth. que cubre el material que puede necesitar comprender si mira los ejemplos de multicast en la distribución.


Estas pruebas se ejecutan en paralelo por waf. Eventualmente debería ver un informe que dice que,

```
92 of 92 tests passed (92 passed, 0 failed, 0 crashed, 0 valgrind errors)
```
Tambien veras una salida como estas:

```
Waf: Entering directory `/home/craigdo/repos/ns-3-allinone/ns-3-dev/build'
Waf: Leaving directory `/home/craigdo/repos/ns-3-allinone/ns-3-dev/build'
'build' finished successfully (1.799s)

Modules built:
aodv                      applications              bridge
click                     config-store              core
csma                      csma-layout               dsdv
emu                       energy                    flow-monitor
internet                  lte                       mesh
mobility                  mpi                       netanim
network                   nix-vector-routing        ns3tcp
ns3wifi                   olsr                      openflow
point-to-point            point-to-point-layout     propagation
spectrum                  stats                     tap-bridge
template                  test                      tools
topology-read             uan                       virtual-net-device
visualizer                wifi                      wimax

PASS: TestSuite ns3-wifi-interference
PASS: TestSuite histogram
PASS: TestSuite sample
PASS: TestSuite ipv4-address-helper
PASS: TestSuite devices-wifi
PASS: TestSuite propagation-loss-model

...

PASS: TestSuite attributes
PASS: TestSuite config
PASS: TestSuite global-value
PASS: TestSuite command-line
PASS: TestSuite basic-random-number
PASS: TestSuite object
PASS: TestSuite random-number-generators
92 of 92 tests passed (92 passed, 0 failed, 0 crashed, 0 valgrind errors)
```
SI todo se ve como el bloque de arriba, en hora buena ya estmos listos para compilar las aplicaciones en NS3.

Ahora ejecutemos la aplicacion de prueba llamada `hello-simulator`, entonces ejecutemos el comando `./waf --run hello-simulator`, la salida es como sigue:

```
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns3/ns-3.26# ./waf --run hello-simulator
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (2.348s)
Hello Simulator
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns3/ns-3.26#
```
## Resumen conceptual 
Lo primero que debemos hacer antes de comenzar a mirar o escribir código ns-3 es explicar algunos conceptos básicos y abstracciones en el sistema. Gran parte de esto puede parecer transparentemente obvio para algunos, pero recomendamos tomarse el tiempo de leer esta sección solo para asegurarse de comenzar con una base firme.

### Abstracciones clave 
En esta sección, revisaremos algunos términos que se usan comúnmente en redes, pero que tienen un significado específico en ns-3 .

#### Nodo 
En la jerga de Internet, un dispositivo informático que se conecta a una red se denomina host o, a veces, un sistema final . Debido a que ns-3 es un simulador de red , no específicamente un simulador de Internet , no utilizamos intencionalmente el término host, ya que está estrechamente asociado con Internet y sus protocolos. En su lugar, usamos un término más genérico también utilizado por otros simuladores que se origina en Graph Theory: el __nodo__.

En ns-3, la abstracción del dispositivo informático básico se denomina __nodo__. Esta abstracción está representada en C ++ por el nodo de clase . La clase Node proporciona métodos para gestionar las representaciones de dispositivos informáticos en simulaciones.

Debe pensar en un Nodo como una computadora a la que agregará funcionalidad. Uno agrega cosas como aplicaciones, pilas de protocolos y tarjetas periféricas con sus controladores asociados para permitir que la computadora realice un trabajo útil. Utilizamos el mismo modelo básico en ns-3.

#### Aplicación 
Típicamente, el software de computadora se divide en dos clases amplias. El software del sistema organiza varios recursos informáticos, como memoria, ciclos de procesador, disco, red, etc., de acuerdo con algunos modelos informáticos. El software del sistema generalmente no usa esos recursos para completar tareas que benefician directamente a un usuario. Un usuario normalmente ejecuta una aplicación que adquiere y utiliza los recursos controlados por el software del sistema para lograr algún objetivo.

A menudo, la línea de separación entre el sistema y el software de la aplicación se realiza con el cambio de nivel de privilegio que ocurre en las trampas del sistema operativo. En ns-3 no existe un concepto real del sistema operativo y, especialmente, ningún concepto de niveles de privilegio o llamadas al sistema. Sin embargo, tenemos la idea de una aplicación. Así como las aplicaciones de software se ejecutan en computadoras para realizar tareas en el "mundo real", las aplicaciones ns-3 se ejecutan en Nodos ns-3 para conducir simulaciones en el mundo simulado.

En ns-3, la abstracción básica para un programa de usuario que genera alguna actividad para simular es la aplicación. Esta abstracción está representada en C++ por la clase Aplicación. La clase de aplicación proporciona métodos para administrar las representaciones de nuestra versión de aplicaciones de nivel de usuario en simulaciones. Se espera que los desarrolladores se especialicen en la clase Aplicación en el sentido de la programación orientada a objetos para crear nuevas aplicaciones. En este tutorial, utilizaremos especializaciones de la aplicación de clase llamada __UdpEchoClientApplication__ y __UdpEchoServerApplication__. Como es de esperar, estas aplicaciones componen un conjunto de aplicaciones cliente/servidor utilizado para generar y reproducir paquetes de red simulados.

#### Canal 
En el mundo real, uno puede conectar una computadora a una red. A menudo, los medios por los que fluyen los datos en estas redes se denominan canales . Cuando conecta su cable Ethernet al enchufe en la pared, está conectando su computadora a un canal de comunicación Ethernet. En el mundo simulado de ns-3 , uno conecta un Nodo a un objeto que representa un canal de comunicación. Aquí la abstracción de subred de comunicación básica se llama canal y se representa en C++ por la clase Canal.

La clase __Channel__ proporciona métodos para administrar objetos de subred de comunicación y conectar nodos a ellos. Los canales también pueden estar especializados por desarrolladores en el sentido de programación orientada a objetos. Una especialización de canal puede modelar algo tan simple como un cable. El canal especializado también puede modelar cosas tan complicadas como un gran conmutador Ethernet o un espacio tridimensional lleno de obstáculos en el caso de las redes inalámbricas.

Utilizaremos versiones especializadas del canal llamado __CsmaChannel__ , __PointToPointChannel__ y __WifiChannel__ en este tutorial. El __CsmaChannel__ , por ejemplo, modela una versión de una subred de comunicación que implementa un medio de comunicación de acceso múltiple con detección de portadora . Esto nos da una funcionalidad similar a Ethernet.

#### Dispositivo de red
Solía ​​ocurrir que si deseaba conectar una computadora a una red, tenía que comprar un tipo específico de cable de red y un dispositivo de hardware llamado (en la terminología de la PC) una tarjeta periférica que debía instalarse en su computadora. Si la tarjeta periférica implementó alguna función de red, se denominaron Tarjetas de interfaz de red o NIC . Hoy en día, la mayoría de las computadoras vienen con el hardware de interfaz de red incorporado y los usuarios no ven estos bloques de construcción.

Una NIC no funcionará sin un controlador de software para controlar el hardware. En Unix (o Linux), una pieza de hardware periférico se clasifica como un dispositivo. Los dispositivos se controlan mediante controladores de dispositivos y los dispositivos de red (NIC) se controlan mediante controladores de dispositivos de red conocidos colectivamente como dispositivos de red . En Unix y Linux, se refiere a estos dispositivos de red por nombres como eth0 .

En ns-3, la abstracción del dispositivo de red cubre tanto el controlador de software como el hardware simulado. Un dispositivo de red se "instala" en un nodo para permitir que el nodo se comunique con otros nodos en la simulación a través de canales . Al igual que en una computadora real, un Nodo puede estar conectado a más de un Canal a través de múltiples NetDevices .

La abstracción del dispositivo neto está representada en C++ por la clase __NetDevice__. La clase NetDevice proporciona métodos para administrar conexiones a objetos __Node__ y __Channel__; y pueden estar especializados por desarrolladores en el sentido de programación orientada a objetos. Utilizaremos varias versiones especializadas de __NetDevice__ llamadas __CsmaNetDevice__, __PointToPointNetDevice__ y __WifiNetDevice__ en este tutorial. Al igual que una NIC Ethernet está diseñada para funcionar con una red Ethernet, el CsmaNetDevice está diseñado para funcionar con un CsmaChannel; el __PointToPointNetDevice__ está diseñado para funcionar con un __PointToPointChannel__ y un __WifiNetNevice__ está diseñado para funcionar con un __WifiChannel__.


#### Ayudantes de topología 
En una red real, encontrará computadoras host con NIC agregadas (o incorporadas). En ns-3, diríamos que encontrará nodos con NetDevices adjuntos . En una red simulada grande, necesitará organizar muchas conexiones entre nodos , dispositivos de red y canales.

Dado que conectar NetDevices a Nodes, NetDevices a Channels , asignar direcciones IP, etc., son tareas comunes en ns-3, proporcionamos lo que llamamos ayudantes de topología para que esto sea lo más fácil posible. Por ejemplo, puede tomar muchas operaciones básicas ns-3 distintas para crear un NetDevice, agregar una dirección MAC, instalar ese dispositivo de red en un Nod0, configurar la pila de protocolos del nodo y luego conectar el NetDevice a un Canal. Se requerirían aún más operaciones para conectar múltiples dispositivos en canales multipunto y luego para conectar redes individuales juntas en redes internas. Proporcionamos objetos auxiliares de topología que combinan esas muchas operaciones distintas en un modelo fácil de usar para su conveniencia.

#### Un primer script ns-3 
Si descargó el sistema como se sugirió anteriormente, tendrá una versión de ns-3 en un directorio `/usr/ns3/ns-3.26/`. Cambie a 
`/usr/ns3/ns-3.26/examples/tutorial. Debería ver un archivo llamado first.cc ubicado allí. Este es un script que creará un enlace simple punto a punto entre dos nodos y hará eco de un solo paquete entre los nodos. Echemos un vistazo a ese script línea por línea, así que adelante y abra first.cc con el editor vim.


##### El módulo incluye 
El código propiamente dicho comienza con una serie de sentencias de inclusión.

```cpp
#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/applications-module.h"
```
Para ayudar a nuestros usuarios de scripts de alto nivel a lidiar con la gran cantidad de archivos de inclusión presentes en el sistema, agrupamos las inclusiones de acuerdo con módulos relativamente grandes. Proporcionamos un único archivo de inclusión que cargará recursivamente todos los archivos de inclusión utilizados en cada módulo. En lugar de tener que buscar exactamente qué encabezado necesita, y posiblemente tener que obtener una serie de dependencias correctas, le brindamos la posibilidad de cargar un grupo de archivos con gran granularidad. Este no es el enfoque más eficiente, pero ciertamente hace que la escritura de guiones sea mucho más fácil.


##### Espacio de nombres Ns3

La siguiente línea en el script __first.cc__ es una declaración de espacio de nombres.

`using namespace ns3;`

##### Registro 
La siguiente línea del script es la siguiente,
`NS_LOG_COMPONENT_DEFINE  ( "FirstScriptExample" );`

##### Funcion main 

Las siguientes lineas en el script corresponde a la declaracion del main.

```cpp
int
main (int argc, char *argv[])
{
```

Las siguientes dos líneas del script se usan para habilitar dos componentes de registro integrados en las aplicaciones __Echo Client__ y __Echo Server__:

```
LogComponentEnable ( "UdpEchoClientApplication" ,  LOG_LEVEL_INFO ); 
LogComponentEnable ( "UdpEchoServerApplication" ,  LOG_LEVEL_INFO );
```

Si ha leído la documentación del componente de registro, verá que hay varios niveles de detalle / detalle de registro que puede habilitar en cada componente. Estas dos líneas de código permiten el registro de depuración en el nivel INFO para clientes y servidores echo. Esto hará que la aplicación imprima mensajes a medida que se envían y reciben paquetes durante la simulación.

Ahora llegaremos directamente al punto de crear una topología y ejecutar una simulación. Usamos los objetos auxiliares de topología para hacer este trabajo lo más fácil posible.

###### Ayudantes de topología 
`NodeContainer` 

Las siguientes dos líneas de código en nuestro script crearán realmente los objetos del nodo ns-3 que representarán las computadoras en la simulación.
```cpp
NodeContainer nodes;
nodes.Create (2);
```

Puede recordar que una de nuestras abstracciones clave es el Nodo. Esto representa una computadora a la que vamos a agregar cosas como pilas de protocolos, aplicaciones y tarjetas periféricas. El asistente de topología __NodeContainer__ proporciona una manera conveniente de crear, administrar y acceder a cualquier objeto __Node__ que creamos para ejecutar una simulación. La primera línea de arriba solo declara un __NodeContainer__ al que llamamos __nodes__ . La segunda línea llama al método Create en el objeto de __nodes__ y le pide al contenedor que cree dos nodos. Como se describe en la documentacion d ela api, el contenedor invoca el sistema ns-3 adecuado para crear dos nodos y almacena punteros a esos objetos internamente.

Los nodos tal como están en el script no hacen nada. El siguiente paso en la construcción de una topología es conectar nuestros nodos en una red. La forma más simple de red que admitimos es un enlace punto a punto único entre dos nodos. Construiremos uno de esos enlaces aquí.

##### PointToPointHelper 
Estamos construyendo un enlace punto a punto y, en un patrón que le resultará bastante familiar, usamos un objeto auxiliar de topología para hacer el trabajo de bajo nivel requerido para armar el enlace. Recuerde que dos de nuestras abstracciones clave son __NetDevice__ y __Channel__ . En el mundo real, estos términos corresponden aproximadamente a tarjetas periféricas y cables de red. Por lo general, estas dos cosas están íntimamente unidas y no se puede esperar intercambiar, por ejemplo, dispositivos Ethernet y canales inalámbricos. Nuestros ayudantes de topología siguen este acoplamiento íntimo y, por lo tanto, utilizará un único __PointToPointHelper__ para configurar y conectar objetos ns-3 __PointToPointNetDevice__ y __PointToPointChannel__  en este script.

Las siguientes tres líneas en el guión son:
```cpp
PointToPointHelper pointToPoint;
pointToPoint.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));
pointToPoint.SetChannelAttribute ("Delay", StringValue ("2ms"));
```

La primera línea,

`PointToPointHelper pointToPoint;`: Crea una instancia de un objeto PointToPointHelper en la pila. Desde una perspectiva de alto nivel.
`pointToPoint.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));`: Le dice al objeto __PointToPointHelper__ que use el valor "5Mbps" (cinco megabits por segundo) como "DataRate" cuando crea un objeto __PointToPointNetDevice__.


Desde una perspectiva más detallada, la cadena "DataRate" corresponde a lo que llamamos un Atributo del __PointToPointNetDevice__. Si observa Doxygen para la clase __ns3::PointToPointNetDevice__ y encuentra la documentación para el método GetTypeId, encontrará una lista de Atributos definidos para el dispositivo. Entre ellas se encuentra el atributo “DataRate”. La mayoría de los objetos ns-3 visibles para el usuario tienen listas similares de atributos . Utilizamos este mecanismo para configurar fácilmente las simulaciones sin volver a compilar, como verá en la siguiente sección.

Similar al "DataRate" en el __PointToPointNetDevice__ encontrará un atributo "Delay" asociado con el PointToPointChannel . La linea final, le dice a __PointToPointHelper__ que use el valor "2ms" (dos milisegundos) como el valor del retraso de transmisión de cada canal punto a punto que crea posteriormente.

##### NetDeviceContainer 
En este punto del script, tenemos un __NodeContainer__ que contiene dos nodos. Tenemos un __PointToPointHelper__ que está preparado y listo para hacer __PointToPointNetDevices__ y conectar objetos __PointToPointChannel__ entre ellos. Así como usamos el objeto auxiliar de topología __NodeContainer__ para crear los Nodos para nuestra simulación, le pediremos a __PointToPointHelper__ que haga el trabajo involucrado en la creación, configuración e instalación de nuestros dispositivos por nosotros. Tendremos que tener una lista de todos los objetos de NetDevice que se crean, por lo que usamos un __NetDeviceContainer__ para contenerlos tal como usamos un NodeContainer para contener los nodos que creamos. Las siguientes dos líneas de código,
```cpp
NetDeviceContainer devices;
devices = pointToPoint.Install (nodes);
```

finalizará la configuración de los dispositivos y el canal. La primera línea declara el contenedor del dispositivo mencionado anteriormente y la segunda realiza el trabajo pesado. el metodo Install método del __PointToPointHelper__ toma un  __NodeContainer__ como parámetro. Internamente, se crea un __NetDeviceContainer__. Para cada nodo en el NodeContainer (debe haber exactamente dos para un enlace punto a punto), se crea un PointToPointNetDevice y se guarda en el contenedor del dispositivo. Se crea un PointToPointChannel y se adjuntan los dos PointToPointNetDevices . Cuando los objetos son creados por PointToPointHelper , los atributos previamente configurados en el asistente se utilizan para inicializar los atributos correspondientes en los objetos creados.

Después de ejecutar la llamada pointToPoint.Install (nodes) tendremos dos nodos, cada uno con un dispositivo de red punto a punto instalado y un único canal punto a punto entre ellos. Ambos dispositivos estarán configurados para transmitir datos a cinco megabits por segundo a través del canal que tiene un retraso de transmisión de dos milisegundos.

##### InternetStackHelper 
Ahora tenemos nodos y dispositivos configurados, pero no tenemos ninguna pila de protocolos instalada en nuestros nodos. Las siguientes dos líneas de código se encargarán de eso.

```cpp
InternetStackHelper stack;
stack.Install (nodes);
```
El InternetStackHelper es un ayudante  de topología que consiste en pilas de Internet lo que el PointToPointHelper es a dispositivos de red punto a punto. El método Install toma un __NodeContainer__ como parámetro. Cuando se ejecuta, instalará una pila de Internet (TCP, UDP, IP, etc.) en cada uno de los nodos del contenedor de nodos.

##### Ipv4AddressHelper 
A continuación, debemos asociar los dispositivos en nuestros nodos con las direcciones IP. Proporcionamos un asistente de topología para administrar la asignación de direcciones IP. La única API visible para el usuario es establecer la dirección IP base y la máscara de red para usar cuando se realiza la asignación de dirección real (que se realiza en un nivel inferior dentro del asistente).

Las siguientes dos líneas de código en nuestro script de ejemplo, `first.cc` .
```cpp
Ipv4AddressHelper address;
address.SetBase ("10.1.1.0", "255.255.255.0");
```

declare un objeto auxiliar de dirección y dígale que debe comenzar a asignar direcciones IP de la red `10.1.1.0` usando la máscara `255.255.255.0` para definir los bits asignables. Por defecto, las direcciones asignadas comenzarán en 1 y aumentarán monotónicamente, por lo que la primera dirección asignada desde esta base será `10.1.1.1`, seguida de `10.1.1.2`, etc. El sistema ns-3 de bajo nivel en realidad recuerda todas las direcciones IP asignadas y generará un error fatal si accidentalmente hace que se genere la misma dirección dos veces (por cierto, es un error muy difícil de depurar).

La siguiente linea de codigo,
`Ipv4InterfaceContainer interfaces = address.Assign (devices);`.

realiza la asignación de dirección real. En ns-3 hacemos la asociación entre una dirección IP y un dispositivo usando un objeto Ipv4Interface. Así como a veces necesitamos una lista de dispositivos de red creados por un ayudante para referencia futura, a veces necesitamos una lista de objetos Ipv4Interface . El Ipv4InterfaceContainer proporciona esta funcionalidad.

Ahora tenemos una red punto a punto construida, con pilas instaladas y direcciones IP asignadas. Lo que necesitamos en este momento son aplicaciones para generar tráfico.

##### Aplicaciones 
Otra de las abstracciones centrales del sistema ns-3 es la Aplicación. En este script se utilizan dos especializaciones del __core ns-3 class__ de aplicaciones llamada __UdpEchoServerApplication__ y __UdpEchoClientApplication__ . Tal como lo hemos hecho en nuestras explicaciones anteriores, utilizamos objetos auxiliares para ayudar a configurar y administrar los objetos subyacentes. Aquí, usamos los objetos __UdpEchoServerHelper__ y __UdpEchoClientHelper__ para hacernos la vida más fácil.

##### UdpEchoServerHelper 
Las siguientes líneas de código en nuestro script de ejemplo, `first.cc` , se utilizan para configurar una aplicación de servidor de eco UDP en uno de los nodos que hemos creado previamente.

```cpp
UdpEchoServerHelper echoServer (9);

ApplicationContainer serverApps = echoServer.Install (nodes.Get (1));
serverApps.Start (Seconds (1.0));
serverApps.Stop (Seconds (10.0));
```

La primera línea de código en el fragmento anterior declara el UdpEchoServerHelper . Como de costumbre, esta no es la aplicación en sí misma, es un objeto utilizado para ayudarnos a crear las aplicaciones reales. Una de nuestras convenciones es colocar los Atributos requeridos en el constructor auxiliar. En este caso, el ayudante no puede hacer nada útil a menos que se le proporcione un número de puerto que el cliente también conozca. En lugar de elegir uno y esperar que todo funcione, requerimos el número de puerto como parámetro para el constructor. El constructor, a su vez, simplemente hace un SetAttribute con el valor pasado. Si lo desea, puede configurar el atributo "Puerto" a otro valor más adelante utilizando SetAttribute .

Al igual que en muchos otros objetos de ayuda, el objeto __UdpEchoServerHelper__ tiene una metodo Install. Es la ejecución de este método lo que realmente hace que la aplicación subyacente del servidor de eco se instancia y se adjunta a un nodo. Curiosamente, el metodo Install toma un __NodeContainter__ como parámetro al igual que el otro metodo Install que hemos visto. En realidad, esto es lo que se pasa al método aunque no lo parezca en este caso. Aquí hay una conversión implícita de C ++ en el trabajo que toma el resultado de nodos . Get (1) (que devuelve un puntero inteligente a un objeto de nodo - Ptr <Nodo>) y lo usa en un constructor para un NodeContainer sin nombre que luego se pasa a Install . Si alguna vez tiene dificultades para encontrar una firma de método particular en el código C ++ que se compila y se ejecuta bien, busque este tipo de conversiones implícitas.

Ahora vemos que echoServer.Install instalará una UdpEchoServerApplication en el nodo que se encuentra en el índice número uno del NodeContainer que utilizamos para administrar nuestros nodos. Instalar devolverá un contenedor que contiene punteros a todas las aplicaciones (una en este caso ya que pasamos un NodeContainer que contiene un nodo) creado por el ayudante.

Las aplicaciones requieren un tiempo para "comenzar" a generar tráfico y pueden tomar un tiempo opcional para "detenerse". Ofrecemos ambos. Estos tiempos se establecen utilizando los métodos de ApplicationContainer __Start__ y __Stop__. Estos métodos toman parámetros de tiempo. En este caso, usamos una secuencia de conversión explícita de C ++ para tomar el doble C ++ y convertirlo en un objeto de tiempo ns-3 usando una conversión de segundos. Tenga en cuenta que las reglas de conversión pueden ser controladas por el autor del modelo, y C ++ tiene sus propias reglas, por lo que no siempre puede suponer que los parámetros se convertirán felizmente para usted. Las dos lineas,
```cpp
serverApps.Start (Seconds (1.0));
serverApps.Stop (Seconds (10.0));
```

hará que la aplicación del servidor echo se inicie (se habilite) al segundo de la simulación y se detenga (se deshabilite) a los diez segundos de la simulación. Debido al hecho de que hemos declarado que un evento de simulación (el evento de detención de la aplicación) se ejecutará en diez segundos, la simulación durará al menos diez segundos.


##### UdpEchoClientHelper 
La aplicación del cliente echo se configura en un método sustancialmente similar al del servidor. Hay una __UdpEchoClientApplication__ subyacente administrada por un __UdpEchoClientHelper__.

```cpp
UdpEchoClientHelper echoClient (interfaces.GetAddress (1), 9);
echoClient.SetAttribute ("MaxPackets", UintegerValue (1));
echoClient.SetAttribute ("Interval", TimeValue (Seconds (1.)));
echoClient.SetAttribute ("PacketSize", UintegerValue (1024));

ApplicationContainer clientApps = echoClient.Install (nodes.Get (0));
clientApps.Start (Seconds (2.0));
clientApps.Stop (Seconds (10.0));
```

Para el cliente echo, sin embargo, necesitamos establecer cinco atributos diferentes. Los dos primeros atributos se establecen durante la construcción de __UdpEchoClientHelper__. Pasamos parámetros que se utilizan (internamente al ayudante) para establecer los atributos “RemoteAddress” y “RemotePort” de acuerdo con nuestra convención para hacer parametros de atributos requeridos en los constructores de ayuda.

Recuerde que utilizamos un Ipv4InterfaceContainer para realizar un seguimiento de las direcciones IP que asignamos a nuestros dispositivos. La interfaz zeroth en el contenedor de interfaces se corresponderá con la dirección IP del nodo zeroth en el contenedor de nodos . La primera interfaz en el contenedor de interfaces corresponde a la dirección IP del primer nodo en el contenedor de nodos . Entonces, en la primera línea de código (arriba), estamos creando el asistente y diciéndole que configure la dirección remota del cliente para que sea la dirección IP asignada al nodo en el que reside el servidor. También le decimos que organice el envío de paquetes al puerto nueve.

El atributo “MaxPackets” indica al cliente el número máximo de paquetes que permitirá que envíe durante la simulación. El Atributo  “Intervalo” indica al cliente el tiempo de espera entre los paquetes, y el atributo “PacketSize” le dice al cliente lo grande que sus cargas útiles de paquetes debe ser. Con esta combinación particular de Atributos , le estamos diciendo al cliente que envíe un paquete de 1024 bytes.

Al igual que en el caso de que el servidor de eco, le decimos al cliente de eco el  inicio y parada , pero aquí se inicia el cliente un segundo después de que el servidor está activado (en dos segundos en la simulación).

#### Simulador 
Lo que debemos hacer en este punto es ejecutar la simulación. Esto se hace usando la función global `Simulator::Run`.
Cuando previamente llamamos a los métodos,
```cpp
serverApps.Start (Seconds (1.0));
serverApps.Stop (Seconds (10.0));
...
clientApps.Start (Seconds (2.0));
clientApps.Stop (Seconds (10.0));
```
En realidad, programamos eventos en el simulador a 1.0 segundos, 2.0 segundos y dos eventos a 10.0 segundos. Cuando se llama a __Simulator::Run__ , el sistema comenzará a buscar en la lista de eventos programados y ejecutarlos. Primero ejecutará el evento a 1.0 segundos, lo que habilitará la aplicación del servidor de eco (este evento puede, a su vez, programar muchos otros eventos). Luego ejecutará el evento programado para t = 2.0 segundos que iniciará la aplicación del cliente echo. Nuevamente, este evento puede programar muchos más eventos. La implementación del evento de inicio en la aplicación del cliente echo comenzará la fase de transferencia de datos de la simulación enviando un paquete al servidor.

El acto de enviar el paquete al servidor desencadenará una cadena de eventos que se programarán automáticamente detrás de escena y que realizarán la mecánica del eco del paquete de acuerdo con los diversos parámetros de tiempo que hemos establecido en el script.

Eventualmente, dado que solo enviamos un paquete (recuerde que el atributo MaxPackets se configuró en uno), la cadena de eventos desencadenados por esa solicitud de eco de un solo cliente disminuirá y la simulación quedará inactiva. Una vez que esto suceda, los eventos restantes serán los eventos Stop para el servidor y el cliente. Cuando se ejecutan estos eventos, no hay más eventos para procesar y Simulator::Run regresa. La simulación se completa entonces.

Todo lo que queda es limpiar. Esto se hace llamando a la función global `Simulator::Destroy`. A medida que se ejecutaban las funciones auxiliares (o código ns-3 de bajo nivel ), lo organizaron de manera que se insertaron ganchos en el simulador para destruir todos los objetos que se crearon. No tenía que hacer un seguimiento de ninguno de estos objetos, todo lo que tenía que hacer era llamar a Simulator::Destroy y salir. El sistema ns-3 se encargó de la parte difícil para usted. Las líneas restantes de nuestro primer script ns-3 , first.cc , hacen exactamente eso:

```cpp
  Simulator::Destroy ();
  return 0;
}
```

#### Construyendo el script
Hemos hecho trivial construir sus scripts simples. Todo lo que tiene que hacer es colocar su script en el directorio `scratch` y se creará automáticamente si ejecuta Waf. Vamos a intentarlo. Copiar `ejemplos/tutorial/first.cc` en el cero directorio `scratch` después de cambiar de nuevo al directorio de nivel superior.
```
cd ../..
cp examples/tutorial/first.cc scratch/myfirst.cc
```
Ahora construya su primer script de ejemplo usando waf:

`./waf`

Debería ver mensajes que informan que su primer ejemplo se creó correctamente.

```
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
[ 900/2591] Compiling scratch/subdir/scratch-simulator-subdir.cc
[2217/2591] Compiling scratch/myfirst.cc
[2218/2591] Compiling scratch/scratch-simulator.cc
[2537/2591] Linking build/scratch/subdir/subdir
[2553/2591] Linking build/scratch/myfirst
[2573/2591] Linking build/scratch/scratch-simulator
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (10.927s)
```

Ahora puede ejecutar el ejemplo (tenga en cuenta que si crea su programa en el directorio scratch, debe ejecutarlo fuera del directorio scratch):

`./waf --run scratch/myfirst`.

Deberías ver algunos resultados:
```
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.109s)
At time 2s client sent 1024 bytes to 10.1.1.2 port 9
At time 2.00369s server received 1024 bytes from 10.1.1.1 port 49153
At time 2.00369s server sent 1024 bytes to 10.1.1.1 port 49153
At time 2.00737s client received 1024 bytes from 10.1.1.2 port 9
```

Aquí verá que el sistema de compilación comprueba para asegurarse de que el archivo se ha compilado y luego lo ejecuta. Verá que el componente de registro en el cliente echo indica que ha enviado un paquete de 1024 bytes al servidor Echo en 10.1.1.2. También verá que el componente de registro en el servidor echo dice que ha recibido los 1024 bytes de 10.1.1.1. El servidor echo repite silenciosamente el paquete y ve el registro del cliente echo que ha recibido su paquete del servidor.

### Habilitando el registro 
Usemos la variable de entorno __NS_LOG__ para activar un poco más de registro, pero primero, solo para orientarnos, avance y ejecute el último script tal como lo hizo anteriormente,

`./waf --run scratch / myfirst`

```
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run scratch/myfirst
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (2.864s)
At time 2s client sent 1024 bytes to 10.1.1.2 port 9
At time 2.00369s server received 1024 bytes from 10.1.1.1 port 49153
At time 2.00369s server sent 1024 bytes to 10.1.1.1 port 49153
At time 2.00737s client received 1024 bytes from 10.1.1.2 port 9
```

Resulta que los mensajes "Enviados" y "Recibidos" que ve arriba son en realidad mensajes de registro de __UdpEchoClientApplication__ y __UdpEchoServerApplication__ . Podemos pedirle a la aplicación cliente, por ejemplo, que imprima más información configurando su nivel de registro a través de la variable de entorno NS_LOG.

A partir de ahora voy a suponer que está utilizando un shell tipo sh que utiliza la sintaxis "VARIABLE = value". 

En este momento, la aplicación de cliente de eco UDP está respondiendo a la siguiente línea de código en scratch/myfirst.cc,

`LogComponentEnable ( "UdpEchoClientApplication" ,  LOG_LEVEL_INFO );`

Esta línea de código habilita el nivel de registro LOG_LEVEL_INFO . Cuando pasamos un indicador de nivel de registro, en realidad estamos habilitando el nivel dado y todos los niveles inferiores. En este caso, hemos habilitado NS_LOG_INFO , NS_LOG_DEBUG , NS_LOG_WARN y NS_LOG_ERROR . Podemos aumentar el nivel de registro y obtener más información sin cambiar el script y volver a compilar configurando la variable de entorno NS_LOG de esta manera:

`export NS_LOG = UdpEchoClientApplication = level_all`

El lado izquierdo de la asignación es el nombre del componente de registro que queremos establecer, y el lado derecho es la bandera que queremos usar. En este caso, vamos a activar todos los niveles de depuración para la aplicación. Si ejecuta el script con NS_LOG configurado de esta manera, el sistema de registro ns-3 recogerá el cambio y debería ver el siguiente resultado:

```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run scratch/myfirst
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.240s)
UdpEchoClientApplication:UdpEchoClient(0x1b46d90)
UdpEchoClientApplication:SetDataSize(0x1b46d90, 1024)
UdpEchoClientApplication:StartApplication(0x1b46d90)
UdpEchoClientApplication:ScheduleTransmit(0x1b46d90, +0.0ns)
UdpEchoClientApplication:Send(0x1b46d90)
At time 2s client sent 1024 bytes to 10.1.1.2 port 9
At time 2.00369s server received 1024 bytes from 10.1.1.1 port 49153
At time 2.00369s server sent 1024 bytes to 10.1.1.1 port 49153
UdpEchoClientApplication:HandleRead(0x1b46d90, 0x1b47790)
At time 2.00737s client received 1024 bytes from 10.1.1.2 port 9
UdpEchoClientApplication:StopApplication(0x1b46d90)
UdpEchoClientApplication:DoDispose(0x1b46d90)
UdpEchoClientApplication:~UdpEchoClient(0x1b46d90)
```

La información adicional de depuración proporcionada por la aplicación proviene del nivel NS_LOG_FUNCTION. Esto muestra cada vez que se llama a una función en la aplicación durante la ejecución del script. Tenga en cuenta que no hay requisitos en el sistema ns-3 de que los modelos deben admitir ninguna funcionalidad de registro particular. La decisión con respecto a la cantidad de información registrada se deja al desarrollador del modelo individual. En el caso de las aplicaciones de eco, hay una buena cantidad de salida de registro disponible.

Ahora puede ver un registro de las llamadas a funciones que se realizaron en la aplicación. Si observa detenidamente, notará dos puntos entre la cadena __UdpEchoClientApplication__ y el nombre del método donde podría haber esperado un operador de ámbito C ++ ( ::) . Esto es intencional

El nombre no es en realidad un nombre de clase, es un nombre de componente de registro. Cuando hay una correspondencia uno a uno entre un archivo fuente y una clase, generalmente será el nombre de la clase, pero debe comprender que en realidad no es un nombre de clase, y que hay un solo dos puntos en lugar de dos puntos. para recordarle de una manera relativamente sutil que separe conceptualmente el nombre del componente de registro del nombre de la clase.

Resulta que en algunos casos, puede ser difícil determinar qué método realmente genera un mensaje de registro. Si observa el texto anterior, puede preguntarse de dónde proviene la cadena " Recibió 1024 bytes de 10.1.1.2 ". Puede resolver esto. Intente hacer lo siguiente,

`export 'NS_LOG = UdpEchoClientApplication = level_all | prefix_func'`

```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run scratch/myfirst
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.100s)
UdpEchoClientApplication:UdpEchoClient(0x207d280)
UdpEchoClientApplication:SetDataSize(0x207d280, 1024)
UdpEchoClientApplication:StartApplication(0x207d280)
UdpEchoClientApplication:ScheduleTransmit(0x207d280, +0.0ns)
UdpEchoClientApplication:Send(0x207d280)
UdpEchoClientApplication:Send(): At time 2s client sent 1024 bytes to 10.1.1.2 port 9
At time 2.00369s server received 1024 bytes from 10.1.1.1 port 49153
At time 2.00369s server sent 1024 bytes to 10.1.1.1 port 49153
UdpEchoClientApplication:HandleRead(0x207d280, 0x209d3b0)
UdpEchoClientApplication:HandleRead(): At time 2.00737s client received 1024 bytes from 10.1.1.2 port 9
UdpEchoClientApplication:StopApplication(0x207d280)
UdpEchoClientApplication:DoDispose(0x207d280)
UdpEchoClientApplication:~UdpEchoClient(0x207d280)
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# 
```

Ahora puede ver que todos los mensajes que provienen de la aplicación de cliente de eco UDP se identifican como tales. El mensaje "Recibió 1024 bytes de 10.1.1.2" ahora se identifica claramente como proveniente de la aplicación de cliente echo. El mensaje restante debe provenir de la aplicación del servidor de eco UDP. Podemos habilitar ese componente ingresando una lista de componentes separados por dos puntos en la variable de entorno NS_LOG.

`export 'NS_LOG=UdpEchoClientApplication=level_all|prefix_func:UdpEchoServerApplication=level_all|prefix_func'`

La salida despues de hacer `./waf` y se ejecuta el script:

```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run scratch/myfirst
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (2.923s)
UdpEchoServerApplication:UdpEchoServer(0x1972460)
UdpEchoClientApplication:UdpEchoClient(0x19984c0)
UdpEchoClientApplication:SetDataSize(0x19984c0, 1024)
UdpEchoServerApplication:StartApplication(0x1972460)
UdpEchoClientApplication:StartApplication(0x19984c0)
UdpEchoClientApplication:ScheduleTransmit(0x19984c0, +0.0ns)
UdpEchoClientApplication:Send(0x19984c0)
UdpEchoClientApplication:Send(): At time 2s client sent 1024 bytes to 10.1.1.2 port 9
UdpEchoServerApplication:HandleRead(0x1972460, 0x192eaa0)
UdpEchoServerApplication:HandleRead(): At time 2.00369s server received 1024 bytes from 10.1.1.1 port 49153
UdpEchoServerApplication:HandleRead(): Echoing packet
UdpEchoServerApplication:HandleRead(): At time 2.00369s server sent 1024 bytes to 10.1.1.1 port 49153
UdpEchoClientApplication:HandleRead(0x19984c0, 0x192f2d0)
UdpEchoClientApplication:HandleRead(): At time 2.00737s client received 1024 bytes from 10.1.1.2 port 9
UdpEchoClientApplication:StopApplication(0x19984c0)
UdpEchoServerApplication:StopApplication(0x1972460)
UdpEchoClientApplication:DoDispose(0x19984c0)
UdpEchoServerApplication:DoDispose(0x1972460)
UdpEchoClientApplication:~UdpEchoClient(0x19984c0)
UdpEchoServerApplication:~UdpEchoServer(0x1972460)
```

A veces también es útil poder ver el tiempo de simulación en el que se genera un mensaje de registro. Puede hacer esto:


`export 'NS_LOG=UdpEchoClientApplication=level_all|prefix_func|prefix_time:UdpEchoServerApplication=level_all|prefix_func|prefix_time'`

si ejecuta el script vera algo como esto:
```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run scratch/myfirst
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.159s)
0s UdpEchoServerApplication:UdpEchoServer(0x22f9480)
0s UdpEchoClientApplication:UdpEchoClient(0x2318b30)
0s UdpEchoClientApplication:SetDataSize(0x2318b30, 1024)
1s UdpEchoServerApplication:StartApplication(0x22f9480)
2s UdpEchoClientApplication:StartApplication(0x2318b30)
2s UdpEchoClientApplication:ScheduleTransmit(0x2318b30, +0.0ns)
2s UdpEchoClientApplication:Send(0x2318b30)
2s UdpEchoClientApplication:Send(): At time 2s client sent 1024 bytes to 10.1.1.2 port 9
2.00369s UdpEchoServerApplication:HandleRead(0x22f9480, 0x2318d40)
2.00369s UdpEchoServerApplication:HandleRead(): At time 2.00369s server received 1024 bytes from 10.1.1.1 port 49153
2.00369s UdpEchoServerApplication:HandleRead(): Echoing packet
2.00369s UdpEchoServerApplication:HandleRead(): At time 2.00369s server sent 1024 bytes to 10.1.1.1 port 49153
2.00737s UdpEchoClientApplication:HandleRead(0x2318b30, 0x2319550)
2.00737s UdpEchoClientApplication:HandleRead(): At time 2.00737s client received 1024 bytes from 10.1.1.2 port 9
10s UdpEchoClientApplication:StopApplication(0x2318b30)
10s UdpEchoServerApplication:StopApplication(0x22f9480)
UdpEchoClientApplication:DoDispose(0x2318b30)
UdpEchoServerApplication:DoDispose(0x22f9480)
UdpEchoClientApplication:~UdpEchoClient(0x2318b30)
UdpEchoServerApplication:~UdpEchoServer(0x22f9480)
```

Puede ver que el constructor para el __UdpEchoServer__ fue llamado en un tiempo de simulación de 0 segundos. Esto sucede realmente antes de que comience la simulación, pero el tiempo se muestra como cero segundos. Lo mismo es cierto para el mensaje del constructor __UdpEchoClient__.

Recuerde que el script __scratch/first.cc__ inició la aplicación del servidor echo al segundo de la simulación. Ahora puede ver que el método __StartApplication__ del servidor se llama, de hecho, en un segundo. También puede ver que la aplicación del cliente echo se inicia en un tiempo de simulación de dos segundos como lo solicitamos en el script.

Ahora puede seguir el progreso de la simulación desde la llamada __ScheduleTransmit__ en el cliente que llama __Send__ a la devolución de llamada HandleRead en la aplicación del servidor echo. Tenga en cuenta que el tiempo transcurrido para que el paquete se envíe a través del enlace punto a punto es 3.69 milisegundos. Verá que el servidor echo registra un mensaje que le indica que ha hecho eco del paquete y luego, después de otro retraso de canal, ve que el cliente echo recibe el paquete echo en su método HandleRead .

Hay muchas cosas que suceden debajo de las cubiertas en esta simulación que tampoco está viendo. Puede seguir fácilmente todo el proceso activando todos los componentes de registro en el sistema. Intente configurar la variable NS_LOG en lo siguiente,

`export 'NS_LOG=*=level_all|prefix_func|prefix_time'`


El asterisco anterior es el comodín del componente de registro. Esto activará todo el registro en todos los componentes utilizados en la simulación. No reproduciré la salida aquí (al momento de escribir esto produce 1265 líneas de salida para el eco de paquete único) pero puede redirigir esta información a un archivo y consultarla con su editor favorito si lo desea,

`./waf --run scratch / myfirst> log.out 2> & 1`

#### Agregar registro a su código 
Puede agregar un nuevo registro a sus simulaciones haciendo llamadas al componente de registro a través de varias macros. Hagámoslo en el script myfirst.cc que tenemos en el directorio scratch.

Recuerde que hemos definido un componente de registro en ese script:

`NS_LOG_COMPONENT_DEFINE  ( "FirstScriptExample" );`

Ahora sabe que puede habilitar todo el registro para este componente configurando la variable de entorno NS_LOG en los distintos niveles. Avancemos y agreguemos algunos registros al script. La macro utilizada para agregar un mensaje de registro de nivel informativo es __NS_LOG_INFO__ . Continúe y agregue uno (justo antes de comenzar a crear los nodos) que le indica que el script es "Creación de topología". Esto se hace como en este fragmento de código,

Abra scratch/myfirst.cc en su editor favorito y agregue la línea,

```bash
NS_LOG_INFO  ( "Creación de topología" );
```
justo antes de las líneas,
```bash
Nodos NodeContainer;
nodos.Crear (2);
```

Ahora construya el script usando waf y borre la variable __NS_LOG__ para desactivar el torrente de registro que habilitamos anteriormente:

```bash
./waf
exportar NS_LOG =
```
Ahora, si ejecuta el script,
```bash
./waf --run scratch / myfirst
```

usted no veaa a su nuevo mensaje desde su componente de registro asociado ( FirstScriptExample ) no se ha activado. Para ver su mensaje, deberá habilitar el componente de registro __FirstScriptExample__ con un nivel mayor o igual a __NS_LOG_INFO__ . Si solo desea ver este nivel particular de registro, puede habilitarlo,

```bash
export NS_LOG = FirstScriptExample = info
```
Si ahora ejecuta el script, verá su nuevo mensaje de registro "Creación de topología",

```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run scratch/myfirst
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.416s)
Creacion de Topologia
At time 2s client sent 1024 bytes to 10.1.1.2 port 9
At time 2.00369s server received 1024 bytes from 10.1.1.1 port 49153
At time 2.00369s server sent 1024 bytes to 10.1.1.1 port 49153
At time 2.00737s client received 1024 bytes from 10.1.1.2 port 9
```

### Usando argumentos de línea de comando 
Anulación de atributos predeterminados 
Otra forma de cambiar el comportamiento de los scripts ns-3 sin editar y construir es mediante argumentos de línea de comandos. Proporcionamos un mecanismo para analizar argumentos de línea de comandos y establecer automáticamente variables locales y globales basadas en esos argumentos.

El primer paso para usar el sistema de argumento de línea de comando es declarar el analizador de línea de comando. Esto se hace simplemente (en su programa principal) como en el siguiente código,

```cpp
int
main (int argc, char *argv[])
{
  ...

  CommandLine cmd;
  cmd.Parse (argc, argv);

  ...
}
```

Este simple fragmento de dos líneas es realmente muy útil por sí mismo. Abre la puerta a los sistemas de atributos y variables globales ns-3 . Continúe y agregue esas dos líneas de código al script scratch / myfirst.cc al comienzo de main . Continúe y cree el script y ejecútelo, pero solicite ayuda al script de la siguiente manera,

Esto le pedirá a Waf que ejecute el script scratch / myfirst y pase el argumento de la línea de comando --PrintHelp al script. Las comillas son necesarias para resolver qué programa obtiene qué argumento. El analizador de línea de comando ahora verá el argumento --PrintHelp y responderá con,

```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run "scratch/myfirst --PrintHelp"
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.122s)
myfirst [Program Arguments] [General Arguments]

General Arguments:
    --PrintGlobals:              Print the list of globals.
    --PrintGroups:               Print the list of groups.
    --PrintGroup=[group]:        Print all TypeIds of group.
    --PrintTypeIds:              Print all TypeIds.
    --PrintAttributes=[typeid]:  Print all attributes of typeid.
    --PrintHelp:                 Print this help message.
```

Centrémonos en la opción __--PrintAttributes__. Ya hemos insinuado el sistema de atributos ns-3 mientras recorríamos el script first.cc . Observamos las siguientes líneas de código,

```cpp
PointToPointHelper pointToPoint;
pointToPoint.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));
pointToPoint.SetChannelAttribute ("Delay", StringValue ("2ms"));
```
se mencionó que DataRate era en realidad un atributo del __PointToPointNetDevice__. Usemos el analizador de argumentos de línea de comando para echar un vistazo a los Atributos del __PointToPointNetDevice__. La lista de ayuda dice que debemos proporcionar un TypeId . Esto corresponde al nombre de la clase a la que pertenecen los Atributos . En este caso será __ns3::PointToPointNetDevice__. Sigamos adelante y escriba,

`./waf --run "scratch/myfirst --PrintAttributes=ns3::PointToPointNetDevice"`
vera  la siguienten salida,

```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run "scratch/myfirst --PrintAttributes=ns3::PointToPointNetDevice"
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.135s)
Attributes for TypeId ns3::PointToPointNetDevice
    --ns3::PointToPointNetDevice::Address=[ff:ff:ff:ff:ff:ff]
        The MAC address of this device.
    --ns3::PointToPointNetDevice::DataRate=[32768bps]
        The default data rate for point to point links
    --ns3::PointToPointNetDevice::InterframeGap=[+0.0ns]
        The time to wait between packet (frame) transmissions
    --ns3::PointToPointNetDevice::Mtu=[1500]
        The MAC-level Maximum Transmission Unit
    --ns3::PointToPointNetDevice::ReceiveErrorModel=[0]
        The receiver error model used to simulate packet loss
    --ns3::PointToPointNetDevice::TxQueue=[0]
```

El sistema imprimirá todos los atributos de este tipo de dispositivo de red. Entre los atributos que verá en la lista se encuentra,

```bash
--ns3 :: PointToPointNetDevice :: DataRate = [32768bps]:
  La velocidad de datos predeterminada para enlaces punto a punto
```

Este es el valor predeterminado que se utilizará cuando se crea un __PointToPointNetDevice__ en el sistema. Anulamos este valor predeterminado con la configuración de Atributo en PointToPointHelper anterior. Usemos los valores predeterminados para los dispositivos y canales punto a punto eliminando la llamada SetDeviceAttribute y la llamada SetChannelAttribute del myfirst.cc que tenemos en el directorio reutilizable.

Su script ahora debería declarar __PointToPointHelper__ y no realizar ninguna operación de configuración como en el siguiente ejemplo,

```cpp
...

Nodos NodeContainer;
nodos.Crear (2);

PointToPointHelper pointToPoint;

Dispositivos NetDeviceContainer;
dispositivos = pointToPoint.Install (nodos);

...
```

Continúe y haga build al  script con Waf ( ./waf ) y regresemos y habilitemos algunos registros desde la aplicación del servidor de eco UDP y activemos el prefijo de tiempo.

`export 'NS_LOG=UdpEchoServerApplication=level_all|prefix_time'`
Si ejecuta el script, ahora debería ver el siguiente resultado,

```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run scratch/myfirst
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.085s)
0s UdpEchoServerApplication:UdpEchoServer(0x1742f50)
1s UdpEchoServerApplication:StartApplication(0x1742f50)
At time 2s client sent 1024 bytes to 10.1.1.2 port 9
2.25732s UdpEchoServerApplication:HandleRead(0x1742f50, 0x1702a30)
2.25732s At time 2.25732s server received 1024 bytes from 10.1.1.1 port 49153
2.25732s Echoing packet
2.25732s At time 2.25732s server sent 1024 bytes to 10.1.1.1 port 49153
At time 2.51465s client received 1024 bytes from 10.1.1.2 port 9
10s UdpEchoServerApplication:StopApplication(0x1742f50)
UdpEchoServerApplication:DoDispose(0x1742f50)
UdpEchoServerApplication:~UdpEchoServer(0x1742f50)
```

Recuerde que la última vez que observamos el tiempo de simulación en el que el servidor de eco recibió el paquete, fue a 2.00369 segundos.

`2.00369s UdpEchoServerApplication: HandleRead (): Recibió 1024 bytes de 10.1.1.1`
Ahora está recibiendo el paquete a 2.25732 segundos. Esto se debe a que simplemente bajamos la velocidad de datos del PointToPointNetDevice a su valor predeterminado de 32768 bits por segundo desde cinco megabits por segundo.

Si proporcionáramos un nuevo DataRate usando la línea de comando, podríamos acelerar nuestra simulación nuevamente. Hacemos esto de la siguiente manera, de acuerdo con la fórmula implícita en el ítem de ayuda:
```bash
./waf --run "scratch/myfirst --ns3::PointToPointNetDevice::DataRate=5Mbps"
```

Esto establecerá el valor predeterminado del atributo DataRate a cinco megabits por segundo. ¿Te sorprende el resultado? Resulta que para recuperar el comportamiento original del script, también tendremos que establecer el retraso de la velocidad de la luz del canal. Podemos pedirle al sistema de línea de comando que imprima los Atributos del canal tal como lo hicimos para el dispositivo de red:

```
./waf --run "scratch/myfirst --PrintAttributes=ns3::PointToPointChannel"
```

Descubrimos que el Atributo de retraso del canal se establece de la siguiente manera:
```bash
--ns3 :: PointToPointChannel :: Delay = [0ns]:
Retraso de transmisión a través del canal
```

Luego podemos establecer ambos valores predeterminados a través del sistema de línea de comandos,

```bash
./waf --run "scratch/myfirst --ns3::PointToPointNetDevice::DataRate=5Mbps --ns3::PointToPointChannel::Delay=2ms"
```

Tenga en cuenta que el servidor vuelve a recibir el paquete a los 2.00369 segundos. De hecho, podríamos establecer cualquiera de los Atributos utilizados en el script de esta manera. En particular, podríamos establecer el UdpEchoClient Attribute MaxPackets en algún otro valor que no sea uno.

¿Cómo harías eso? Darle una oportunidad. Recuerde que debe comentar el lugar donde anulamos el Atributo predeterminado y establecer explícitamente MaxPackets en el script. Luego tienes que reconstruir el script. También tendrá que encontrar la sintaxis para configurar realmente el nuevo valor de atributo predeterminado utilizando la función de ayuda de la línea de comandos. Una vez que haya resuelto esto, debería poder controlar la cantidad de paquetes que se repiten en la línea de comando. Como somos buenas personas, le diremos que su línea de comando debería terminar pareciendo algo así como,

```bash
./waf --run "scratch / myfirst --ns3::PointToPointNetDevice::DataRate=5Mbps 
--ns3::PointToPointChannel::Delay=2ms 
--ns3::UdpEchoClient::MaxPackets=2 "
```

### Enganchando tus propios valores 
También puede agregar sus propios ganchos al sistema de línea de comandos. Esto se hace simplemente usando el método AddValue para el analizador de línea de comando.

Usemos esta función para especificar el número de paquetes a hacer eco de una manera completamente diferente. Agreguemos una variable local llamada __nPackets__ a la función principal. Lo inicializaremos a uno para que coincida con nuestro comportamiento predeterminado anterior. Para permitir que el analizador de línea de comando cambie este valor, necesitamos conectar el valor al analizador. Hacemos esto agregando una llamada a AddValue . Continúe y cambie el script scratch/myfirst.cc para comenzar con el siguiente código,

```cpp
int
main (int argc, char * argv [])
{
  uint32_t nPackets = 1;

  CommandLine cmd;
  cmd.AddValue ("nPackets", "Número de paquetes a eco", nPackets);
  cmd.Parse (argc, argv);

  ...
```


Desplácese hacia abajo hasta el punto en el script donde establecemos el Atributo MaxPackets y cámbielo para que se establezca en la variable nPackets en lugar de la constante 1 como se muestra a continuación.

```cpp
echoClient. SetAttribute("MaxPackets", UintegerValue(nPackets));
```

Si desea especificar el número de paquetes a eco, ahora puede hacerlo estableciendo el argumento --nPackets en la línea de comando,

```bash
./waf --run "scratch/myfirst --nPackets = 2"
```
Si ejecuta la aplicacion ahora vera que el server recibira los dos paquetes que le hemos asignado al cliente desde la linea de comandos,

Ahora, si ejecuta el script y proporciona el argumento --PrintHelp , debería ver su nuevo argumento de usuario en la pantalla de ayuda.

Si desea especificar el número de paquetes a eco, ahora puede hacerlo estableciendo el argumento --nPackets en la línea de comando,
```bash
./waf --run "scratch/myfirst --nPackets=2"
```

Ahora deberías ver:
```bash
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# ./waf --run "scratch/myfirst --nPackets=2"
Waf: Entering directory `/usr/ns-allinone-3.26/ns-3.26/build'
Waf: Leaving directory `/usr/ns-allinone-3.26/ns-3.26/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (3.162s)
0s UdpEchoServerApplication:UdpEchoServer(0x1c96b00)
1s UdpEchoServerApplication:StartApplication(0x1c96b00)
At time 2s client sent 1024 bytes to 10.1.1.2 port 9
2.25732s UdpEchoServerApplication:HandleRead(0x1c96b00, 0x1c56a80)
2.25732s At time 2.25732s server received 1024 bytes from 10.1.1.1 port 49153
2.25732s Echoing packet
2.25732s At time 2.25732s server sent 1024 bytes to 10.1.1.1 port 49153
At time 2.51465s client received 1024 bytes from 10.1.1.2 port 9
At time 3s client sent 1024 bytes to 10.1.1.2 port 9
3.25732s UdpEchoServerApplication:HandleRead(0x1c96b00, 0x1c56a80)
3.25732s At time 3.25732s server received 1024 bytes from 10.1.1.1 port 49153
3.25732s Echoing packet
3.25732s At time 3.25732s server sent 1024 bytes to 10.1.1.1 port 49153
At time 3.51465s client received 1024 bytes from 10.1.1.2 port 9
10s UdpEchoServerApplication:StopApplication(0x1c96b00)
UdpEchoServerApplication:DoDispose(0x1c96b00)
UdpEchoServerApplication:~UdpEchoServer(0x1c96b00)
root@gustavosinbandera1-HP-Laptop-17-bs0xx:/usr/ns-allinone-3.26/ns-3.26# 
```
Ahora ha hecho eco de dos paquetes. Bastante fácil, ¿no es así?

Puede ver que si es un usuario ns-3 , puede usar el sistema de argumentos de la línea de comandos para controlar los valores y atributos globales . Si usted es un autor de modelo, puede agregar nuevos Atributos a sus Objetos y estarán automáticamente disponibles para que sus usuarios los configuren a través del sistema de línea de comandos. Si usted es un autor de scripts, puede agregar nuevas variables a sus scripts y conectarlos al sistema de línea de comandos sin problemas.