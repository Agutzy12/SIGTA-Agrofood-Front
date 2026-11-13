# SIGTA · Front (pantallas)

> **Sistema Integral de Gestión y Trazabilidad Alimentaria** para **Agrifood Argentina S.A.**
> Proyecto final de Analista de Sistemas · Benítez Agustín · basado en el *Informe Técnico V5*.

Este repositorio tiene las **pantallas** de SIGTA. La API y la base de datos están en
[SIGTA-Agrofood-Back](https://github.com/Agutzy12/SIGTA-Agrofood-Back).

Módulo actual: **Gestión de Producción y Trazabilidad Industrial**.

| Paso | Caso de uso | Pantalla | Lo registra |
|---|---|---|---|
| 1 | CU-P01 Registrar Orden de Producción | Planificar orden | Supervisor de producción |
| 2 | CU-P02 Registrar ejecución y consumo | Elaborar | Supervisor de producción |
| 3 | CU-P03 Registrar control de calidad de lote | Controlar calidad | Técnico de calidad |
| 4 | CU-P04 Registrar ingreso de PT y cierre de OP | Ingresar a depósito | Operario de depósito |
| — | Consulta | Panel · Trazabilidad de lote · Catálogo · Etiquetas GS1-128 | Todos (Gerencia: sólo lectura) |

Además: permisos por rol, etiquetas logísticas **GS1-128** con código de barras real, modo claro/oscuro, versión para celular
y **aplicación instalable** (PWA) en PC, celular o colectoras.

## Tecnologías

| Tecnología | Para qué |
|---|---|
| **React 19 + TypeScript** | Pantallas |
| **Vite 6** | Desarrollo y compilación |
| **Tailwind CSS 4** + `src/estilos.css` | Estilos, modo claro/oscuro |
| **React Router 7** | Navegación entre pantallas |
| **bwip-js** | Códigos de barras GS1-128 |
| **PWA** (manifest + service worker) | Se instala y abre como una aplicación |
| **Playwright** | 10 recorridos completos en el navegador |

## Cómo correrlo en tu computadora

Primero levantá la API (ver el README de SIGTA-Agrofood-Back): tiene que quedar en http://localhost:3000.

```bash
git clone https://github.com/Agutzy12/SIGTA-Agrofood-Front.git
cd SIGTA-Agrofood-Front
npm install
npm run dev                   # pantallas en http://localhost:5173
```

En desarrollo, las llamadas a `/api` se reenvían a `http://localhost:3000`. Para usar otra API: `API_URL=https://... npm run dev`.

### Ingreso

La pantalla de ingreso tiene **accesos rápidos** para entrar con cualquier usuario sin escribir la contraseña.
También se puede entrar con email y contraseña (contraseña inicial: `sigta2026`).

## Comandos

| Comando | Qué hace |
|---|---|
| `npm run dev` | Pantallas en el puerto 5173 con recarga automática |
| `npm run build` | Versión de producción en `dist/` |
| `npm run preview` | Sirve `dist/` en el puerto 4173 (también reenvía `/api`) |
| `npm run typecheck` | Control de tipos |
| `npm run lint` | Revisión de estilo del código |
| `npm run test:e2e` | Recorre el sistema en el navegador (necesita `npm run build` y la API con los datos recién cargados: `npm run db:seed` en el Back) |

## Variables de entorno

| Variable | Para qué |
|---|---|
| `VITE_API_URL` | Dirección de la API publicada, sin `/api` (por ejemplo `https://sigta-back.vercel.app`). Vacía: usa `/api` del mismo sitio |
| `API_URL` | Sólo desarrollo: a dónde reenvía Vite las llamadas a `/api` (por defecto `http://localhost:3000`) |
| `E2E_URL` | Sólo pruebas: probar un sitio ya publicado en vez del local |

## Publicarlo en internet (Vercel)

1. Publicá primero el Back y anotá su dirección.
2. En Vercel, **Add New → Project** e importá este repositorio. `vercel.json` ya tiene la configuración.
3. En **Settings → Environment Variables** agregá `VITE_API_URL` con la dirección del Back.
4. En el Back, agregá la dirección de este proyecto a `CORS_ORIGENES` y redesplegá los dos.

## Estructura

```
src/paginas/      Una pantalla por paso del circuito, más Panel, Trazabilidad, Catálogo e Ingreso
src/componentes/  Menú, guía de pasos, etiquetas GS1, protocolo de calidad...
src/contexto/     Sesión, diálogos y tema (claro/oscuro)
src/lib/          Llamadas a la API, tipos, formatos, glosario y textos del proceso
public/           Íconos, logos, tipografía, manifest y service worker (PWA)
e2e/              Pruebas en el navegador (Playwright)
```
