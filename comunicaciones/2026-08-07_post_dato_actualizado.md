# Post redes · App actualizada con el último trimestre publicado por INDEC (2026-T1)

> Post "activador": la excusa es la actualización de datos (2026-T1), el
> objetivo es traer de vuelta a quien ya conoce la app y activar a quien
> todavía no la probó. No es un post de feature nueva.
> Fecha de implementación: 2026-08-07.
> Canal: LinkedIn (pedido explícito de Pablo). Twitter/Telegram no incluidos
> en este draft; se pueden adaptar si se decide sumarlos.
> Estado: programado por Pablo para el martes 2026-08-11.
>
> **BLOQUEANTE hasta el 2026-08-11:** el deploy de 2026-T1 (2026-08-07)
> introdujo una regresión real — la vista Foto de todo análisis abre en
> blanco por default (dúo inválido armado con un t1 inexistente). Fix
> listo y validado en PR #95, pendiente de deploy a producción con
> confirmación de Pablo. Si el martes el fix no está deployado y
> verificado, este post NO debe salir: estaría invitando tráfico a la
> pantalla principal rota. Detalle completo en `cambios_a_comunicar.md`.

---

## Contexto para la edición

- El panel longitudinal de la EPH pasa a cubrir 2003 → 2026-T1 (antes
  llegaba a 2025-T4). El dúo nuevo es 2025-T4 → 2026-T1.
- INDEC publica los microdatos con varios meses de rezago respecto al
  cierre del trimestre: **no** es "el dato de julio 2026", es la última
  base de microdatos que INDEC puso a disposición. El copy evita insinuar
  que es información en tiempo real.
- La app se actualiza sola cada vez que INDEC publica: es un dato de
  confianza real (aunque esta vez requirió arreglar el pipeline a mano),
  vale usarlo como refuerzo de marca sin entrar en detalle técnico.
- Sin número de versión, sin nombres de archivos, sin mención al problema
  de CI que hubo que resolver.

---

## LinkedIn

[EPH ACTUALIZADA 📊] - Ya está el primer trimestre de 2026

Hoy queríamos compartirles que shiny_eph_panel, nuestra app pública para
analizar el mercado laboral argentino con la técnica de panel de la EPH,
ya incorpora la última base de microdatos que publicó el INDEC.

Con esta actualización, el panel longitudinal queda armado desde 2003
hasta el primer trimestre de 2026. Ya se puede ver, por ejemplo, cuántas
personas que estaban desocupadas a fines de 2025 consiguieron trabajo en
los primeros meses de 2026, o cómo se movió la informalidad laboral entre
esos dos trimestres.

Por si todavía no la conocés, así se recorre:

▸ Foto: la situación de cada trimestre, con matriz de transición y tasas.
▸ Película: cómo se mueven las mismas personas entre trimestres, o entre
  el mismo trimestre de dos años distintos.
▸ Armá tu panel: filtrás por sexo, edad, condición de actividad, categoría
  ocupacional y aglomerado, y descargás el subconjunto que necesitás con
  el pareo entre trimestres ya resuelto.

La app se actualiza sola cada vez que el INDEC publica una nueva base, así
que siempre vas a encontrar ahí el dato más reciente disponible.

👉 Probá la aplicación acá: https://estacionr.shinyapps.io/shiny_eph_panel/

¿Qué te gustaría analizar con estos datos? ¡Contanos en comentarios! 💬

#EPH #MercadoLaboral #RStats #DatosPúblicos #estacionR

---

## Asset visual sugerido

- Screenshot de la Foto (matriz de transición o Sankey) mostrando el dúo
  nuevo 2025-T4 → 2026-T1 seleccionado. Reutilizable de posts anteriores
  si no hay tiempo de capturar uno nuevo: lo importante es que se lea el
  período en el selector.
- Alternativa más simple: captura del hub con las tarjetas, sin edición.

---

## Pendientes a resolver

- ~~[CHEQUEAR ESTO: confirmar la fecha de publicación real antes de postear]~~
  Resuelto: Pablo programó el envío para el martes 2026-08-11. "Hoy" en el
  copy sigue siendo válido como relativo al día de publicación.
- [CHEQUEAR ESTO: decidir si sumar Twitter/Telegram con este mismo ángulo
  o dejarlo solo en LinkedIn como se pidió]
- **NUEVO, bloqueante:** verificar que el fix de PR #95 esté deployado y
  confirmado en producción antes del 2026-08-11. Ver nota al inicio del
  documento.
