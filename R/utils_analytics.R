### Helpers de analytics (issue #38).
###
### Integra Google Analytics 4 client-side con Consent Mode v2 + banner
### de cookies legal-compliant (Ley 25.326 / GDPR).
###
### Cómo funciona:
###   1. GA4 se carga con consent_mode 'denied' por default → no setea
###      cookies hasta que el user acepte.
###   2. Si el user aceptó antes (localStorage), upgrade automático.
###   3. Tracking de cambios de nav_panel via 'shown.bs.tab' (bslib usa
###      Bootstrap, dispara este evento al cambiar de pestaña).
###
### Configuración: el measurement ID está hardcodeado abajo. NO es un
### secreto (está en el HTML de cualquier página que use GA, es público).
### shinyapps.io plan free no permite env vars, así que hardcodear es
### la opción más simple y honesta.
###
### Para desactivar GA4 en local (testing sin contaminar metrics):
###   GA4_DISABLE=1 Rscript -e 'shiny::runApp(".")'


### Measurement ID del stream GA4 dedicado a la app shiny_eph_panel
### (property compartida con estacion-r.com).
GA4_MEASUREMENT_ID <- if (nzchar(Sys.getenv("GA4_DISABLE", ""))) {
  ""
} else {
  "G-NQPB4BHWMM"
}


### Indica si tenemos un ID válido configurado. Cuando es FALSE, los
### helpers devuelven NULL → la app rinde sin GA4 ni banner.
ga4_configured <- function() {
  nzchar(GA4_MEASUREMENT_ID) && grepl("^G-[A-Z0-9]+$", GA4_MEASUREMENT_ID)
}


### Tag del <head> con gtag.js + Consent Mode v2.
ga4_head_tag <- function() {
  if (!ga4_configured()) return(NULL)

  tags$head(
    tags$script(async = NA, src = paste0(
      "https://www.googletagmanager.com/gtag/js?id=", GA4_MEASUREMENT_ID
    )),
    tags$script(HTML(sprintf("
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}

      // Consent Mode v2: por default todo denegado, no setea cookies.
      gtag('consent', 'default', {
        'analytics_storage': 'denied',
        'ad_storage':        'denied',
        'wait_for_update':   500
      });

      gtag('js', new Date());
      gtag('config', '%s', {
        'anonymize_ip': true,
        'cookie_flags': 'SameSite=None;Secure'
      });

      // Si el user ya consintió en una sesión anterior (localStorage),
      // hacemos upgrade del consent al cargar.
      if (localStorage.getItem('estacion_r_consent') === 'granted') {
        gtag('consent', 'update', { 'analytics_storage': 'granted' });
      }
    ", GA4_MEASUREMENT_ID)))
  )
}


### Banner de consent. Se renderiza siempre pero queda hidden (display:none)
### y solo se muestra via JS si no hay decisión previa en localStorage.
cookie_consent_banner <- function() {
  if (!ga4_configured()) return(NULL)

  div(
    id = "cookie-banner",
    class = "cookie-banner",
    role = "dialog",
    `aria-label` = "Aviso de cookies",
    div(
      class = "cookie-banner-text",
      tags$p(
        tags$strong("Usamos cookies de analítica."),
        " Para entender cómo se usa la app y mejorarla, registramos páginas",
        " visitadas y filtros usados con Google Analytics. Sin datos",
        " personales, IPs anonimizadas. ",
        tags$a("Más info",
               href = "https://estacion-r.com/privacidad",
               target = "_blank",
               class = "cookie-banner-link"),
        "."
      )
    ),
    div(
      class = "cookie-banner-actions",
      tags$button(id = "cookie-decline",
                  type = "button",
                  class = "cookie-btn cookie-btn-secondary",
                  "Rechazar"),
      tags$button(id = "cookie-accept",
                  type = "button",
                  class = "cookie-btn cookie-btn-primary",
                  "Aceptar")
    )
  )
}


### JS handler: muestra/oculta banner, persiste decisión, trackea
### cambios de nav_panel como GA4 custom events.
analytics_js <- function() {
  if (!ga4_configured()) return(NULL)

  tags$script(HTML("
    (function() {
      var banner = document.getElementById('cookie-banner');
      var consent = localStorage.getItem('estacion_r_consent');

      // Mostrar banner solo si no hay decisión previa.
      if (banner) {
        banner.style.display = consent ? 'none' : 'flex';
      }

      var btnAccept = document.getElementById('cookie-accept');
      if (btnAccept) {
        btnAccept.addEventListener('click', function() {
          localStorage.setItem('estacion_r_consent', 'granted');
          if (typeof gtag === 'function') {
            gtag('consent', 'update', { 'analytics_storage': 'granted' });
          }
          if (banner) banner.style.display = 'none';
        });
      }

      var btnDecline = document.getElementById('cookie-decline');
      if (btnDecline) {
        btnDecline.addEventListener('click', function() {
          localStorage.setItem('estacion_r_consent', 'denied');
          if (banner) banner.style.display = 'none';
        });
      }

      // Tracking de cambios de nav_panel: bslib (sobre Bootstrap) emite
      // 'shown.bs.tab' al cambiar de pestaña en navset_pill_list y
      // navset_card_tab. El consent mode bloquea el envío si denied.
      document.addEventListener('shown.bs.tab', function(e) {
        if (typeof gtag !== 'function') return;
        var label = (e.target && e.target.textContent || '').trim() ||
                    (e.target && e.target.getAttribute('data-value')) ||
                    'unknown';
        gtag('event', 'nav_panel_change', { 'panel_label': label });
      });
    })();
  "))
}
