### Versión de la app.
###
### Esquema SemVer adaptado a app web (no librería):
###   MAJOR (X.0.0): cambio estructural / nueva línea de análisis / breaking.
###   MINOR (0.X.0): feature nueva visible al usuario.
###   PATCH (0.0.X): fix, polish UX, mejora menor.
###
### Al hacer release: bumpear acá + agregar entrada en CHANGELOG.md +
### tag git `vX.Y.Z` en el commit del merge.
###
### Se muestra en el sidebar footer (app.R) y queda disponible para
### eventuales evento GA4 con dimensión custom 'app_version'.
APP_VERSION <- "0.7.1"
