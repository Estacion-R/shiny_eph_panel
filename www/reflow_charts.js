/* Handler para forzar reflow de Highcharts después de cambios de vista
 * (issue #74, patrón hub-and-spoke).
 *
 * Problema: cuando un panel con Highcharts queda dentro de un conditionalPanel
 * con display:none, el chart pierde sus dimensiones internas. Al volver a
 * mostrarse, aparece colapsado o con tamaño incorrecto.
 *
 * Solución: cada vez que cambia la vista activa (input.app_vista) o la
 * sub-sección, el server envía un customMessage "reflow_charts" y este handler
 * itera todos los charts visibles llamando a chart.reflow().
 *
 * El setTimeout(0) espera al repaint del browser antes de medir el contenedor.
 */
Shiny.addCustomMessageHandler('reflow_charts', function(_payload) {
  setTimeout(function() {
    if (window.Highcharts && Highcharts.charts) {
      Highcharts.charts.forEach(function(c) {
        if (c && typeof c.reflow === 'function') {
          try {
            c.reflow();
          } catch (e) {
            /* chart ya destruido, ignorar */
          }
        }
      });
    }
  }, 50);
});
