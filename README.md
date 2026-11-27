# cd441

Integración y entrega continua (*CI/CD*, *Continuous Integration / Continuous Delivery*) con *GitHub Actions*.

Este repositorio contiene el material del curso de *Cloudevel* sobre integración y entrega continua con *GitHub Actions*. El recorrido construye, de forma progresiva, un *pipeline* de integración continua sobre una interfaz de programación de aplicaciones (*API*) y un primer despliegue, en modo imperativo, a *Cloud Run* en *Google Cloud Platform* (*GCP*) y a un servidor *Linux* por *SSH* (*Secure Shell*).

Curso de **20 horas**, en 17 cuadernos.

## Entorno de trabajo

El curso se imparte y se practica en *GitHub Codespaces* (el entorno de desarrollo en la nube de *GitHub*). En la página del repositorio, el menú *Code* permite crear un *Codespace* a partir de la rama de trabajo.

La configuración de ```.devcontainer/devcontainer.json``` deja listos *Python* 3.12, los *kernels* de *Jupyter* para *Python* y para *Bash* (con los que se ejecutan los cuadernos), *Docker*, el *SDK* (*Software Development Kit*) de línea de comandos de *Google Cloud* (```gcloud```) y el *CLI* (*command-line interface*) de *GitHub* (```gh```). No hace falta instalar esas herramientas en un equipo propio ni usar una máquina virtual ajena al *Codespace*.

El laboratorio de *Linux* por *SSH* (*Secure Shell*) del cuaderno 17 es la **excepción**: el destino es un *Ubuntu* 24.04 completo de cada estudiante (con *systemd* y *PostgreSQL*), porque *GitHub Codespaces* no ofrece *systemd*. El *workflow* usa, por defecto, un *runner* autoalojado en esa misma máquina y solo en un repositorio privado; si el anfitrión es alcanzable desde internet, puede usarse un *runner* hospedado.

## Contenido

- Introducción a *GitHub Actions* y conceptos de *DevOps* (cultura y prácticas de colaboración entre desarrollo y operación) y de *CI/CD*
- Sintaxis *YAML* (*YAML Ain't Markup Language*) y elementos de un *workflow*
- *Runners*, artefactos, entornos y seguridad
- Integración continua de una *API* con *Flask* y pruebas automáticas
- Imágenes de contenedor y publicación en *GitHub Container Registry* (*GHCR*)
- Despliegue a *GCP* en *Cloud Run*
- Despliegue a un servidor *Linux* por *SSH*

## Tabla de contenidos

- 01 — Introducción a *GitHub Actions*
- 02 — Actividad: «Hello world»
- 03 — *Runners*
- 04 — Introducción a *YAML*
- 05 — Elementos de un *workflow*
- 06 — Expresiones y variables
- 07 — Actividad: expresiones
- 08 — *DevOps*
- 09 — *CI/CD*
- 10 — *Runner* autoalojado en el *Codespace*
- 11 — Artefactos
- 12 — Entornos
- 13 — Seguridad
- 14 — *Pipeline* de integración continua de una *API*
- 15 — Imágenes de contenedor y registro
- 16 — Despliegue en *Cloud Run*
- 17 — Despliegue en *Linux* por *SSH*

## Estructura del repositorio

```
cd441/
├── .devcontainer/             # Entorno de GitHub Codespaces
├── 01_*.ipynb … 17_*.ipynb    # Material del curso (en la raíz)
├── api/                       # Aplicación Flask de ejemplo
├── img/
├── Dockerfile                 # Imagen de la API
└── .github/workflows/         # Workflows de CI y de despliegue
```

## Conocimientos previos

### Indispensables

- **Git y GitHub** — clonar, *commit*, *push*, *pull requests* y navegación básica de la interfaz
- **Línea de comandos Linux** — navegación, permisos y *SSH*
- **Python básico** — variables, funciones y manejo de dependencias con *pip*
- **HTTP y REST** (*Hypertext Transfer Protocol* y *Representational State Transfer*) — verbos (`GET`, `POST`, `PUT`, `DELETE`), códigos de estado y *JSON* (*JavaScript Object Notation*)

### Útiles, pero no bloqueantes

- **YAML** — el curso lo cubre desde el principio, pero conocerlo de antemano ayuda
- **Conceptos de red** — puertos, *DNS* (*Domain Name System*) y *HTTPS* aparecen al configurar los despliegues

### Lo que el propio curso enseña

- *GitHub Actions* (es el tema central)
- Un primer ```Dockerfile``` y la publicación de una imagen en un registro
- Un primer despliegue imperativo a *Cloud Run* y a *Linux* por *SSH*

### No se requieren

- Experiencia previa con *GCP* u otro proveedor de nube
- Experiencia previa con *Docker* (se cubre un primer contacto en el cuaderno 15)

## Frontera con cursos posteriores

Al terminar *cd441*, un curso posterior puede asumir:

- *pipelines* básicos de *GitHub Actions* (*runners*, artefactos, entornos y secretos);
- la construcción y publicación de una primera imagen de contenedor;
- un primer despliegue **imperativo** de esa imagen a *Cloud Run*, autenticado con *Workload Identity Federation* (*WIF*) y *OpenID Connect* (*OIDC*);
- un primer despliegue a un *Ubuntu* 24.04 por *SSH*, con *systemd* y *PostgreSQL*.

Queda **fuera del alcance** de *cd441* y se introduce en cursos posteriores:

- *Cloud SQL*
- *Secret Manager*
- *Compute Engine*
- *Terraform* e infraestructura como código en la práctica

Este curso practica *Workload Identity Federation* (*WIF*, federación de identidad de cargas de trabajo) con *OpenID Connect* (*OIDC*) en el laboratorio de *Cloud Run* (cuadernos 13 y 16): el *workflow* no usa llaves de cuenta de servicio.
