# cd441
CI/CD con GitHub Actions

Curso de 16 horas sobre integración y despliegue continuo usando GitHub Actions, con
ejemplos reales apuntando a GCP, un servidor Linux convencional y GitHub Pages.

## Contenido

- Introducción a GitHub Actions y conceptos de DevOps/CI/CD
- Sintaxis YAML y elementos de un workflow
- Runners, artefactos, entornos y seguridad
- API REST con Flask: pipeline de CI con pruebas automáticas
- Despliegue a GCP (Cloud Run) y a servidor Linux vía SSH
- Sitio estático con Quarto desplegado en GitHub Pages

## Estructura del repositorio

```
cd441/
├── notebooks/          # Notebooks del curso (en la raíz)
├── api/                # Proyecto Flask autónomo
├── web/                # Sitio estático con Quarto
└── .github/workflows/  # Workflows de CI/CD
```

## Conocimientos previos

### Indispensables

- **Git y GitHub** — clonar, commit, push, pull requests y navegación básica de la interfaz
- **Línea de comandos Linux** — navegación, permisos y SSH
- **Python básico** — variables, funciones y manejo de dependencias con pip
- **HTTP y REST** — verbos (GET, POST, PUT, DELETE), status codes y JSON

### Útiles pero no bloqueantes

- **YAML** — el curso lo cubre desde cero, pero conocerlo de antemano ayuda
- **Docker básico** — haber visto un `docker build` facilita la parte de GCP
- **Conceptos de red** — puertos, DNS y HTTPS aparecen al configurar los despliegues

### No se requieren

- Experiencia previa con GCP u otro proveedor de nube
- Conocimiento de GitHub Actions (es el tema central del curso)
- Quarto u otro generador de sitios estáticos
