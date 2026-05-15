### Tests de los configs del módulo genérico mod_analisis (issue #12).
###
### Estrategia: validar el schema de los 3 configs (campos requeridos +
### funciones invocables) sin levantar el server completo. El testServer
### del módulo entero requiere mockear ~10 datasets globales y stubear
### renderers de highcharter/gt; queda diferido a Sprint test-3 (shinytest2)
### que ya cubre el flujo end-to-end.

source(testthat::test_path("..", "..", "R", "configs_analisis.R"))


### --- Schema validation ----------------------------------------------------

campos_requeridos <- c(
  "nombre", "var_panel", "etiquetas_codigo", "showcase_pob_icon",
  "choices_categoria_foto", "choices_pelicula_desde", "default_pelicula_desde",
  "choices_pelicula_hacia", "default_pelicula_hacia",
  "choices_tasas_categoria", "default_tasas_categoria",
  "incluir_selector_tipo_tasa",
  "titulo_sankey", "sankey_nodes_labels",
  "pob_label_fn", "sentido_label_fn", "pelicula_serie_label_fn",
  "tasas_caption_fn", "pelicula_df_fn", "tasas_df_fn", "pob_n_fn",
  "incluir_toggle_definicion", "incluir_comparar_funcional",
  "mostrar_pandemia_fn"
)

for (cfg_name in c("config_cond_act", "config_cat_ocup", "config_formalidad")) {
  cfg <- get(cfg_name)

  test_that(paste(cfg_name, "tiene todos los campos requeridos"), {
    expect_true(is.list(cfg))
    faltantes <- setdiff(campos_requeridos, names(cfg))
    expect_equal(faltantes, character(0),
                 info = paste("Campos faltantes en", cfg_name, ":",
                              paste(faltantes, collapse = ", ")))
  })

  test_that(paste(cfg_name, "tiene tipos correctos en campos críticos"), {
    expect_type(cfg$nombre, "character")
    expect_type(cfg$var_panel, "character")
    expect_type(cfg$etiquetas_codigo, "character")
    expect_true(length(cfg$etiquetas_codigo) >= 2)
    expect_named(cfg$choices_categoria_foto)
    expect_named(cfg$choices_pelicula_desde)
    expect_named(cfg$choices_pelicula_hacia)
    expect_type(cfg$incluir_toggle_definicion, "logical")
    expect_type(cfg$incluir_comparar_funcional, "logical")
    expect_type(cfg$incluir_selector_tipo_tasa, "logical")
  })
}


### --- Funciones puras invocables ------------------------------------------

test_that("pob_label_fn devuelve string para una categoría válida", {
  ### cond_act usa femenino: "Población: Ocupada"
  res <- config_cond_act$pob_label_fn(list(category = "Ocupado"))
  expect_type(res, "character")
  expect_true(grepl("Ocupada", res))

  ### cat_ocup usa plural directo: "Población: Patrones"
  res <- config_cat_ocup$pob_label_fn(list(category = "Patron"))
  expect_true(grepl("Patrones", res))

  ### formalidad usa universo + categoría: "Asalariados Formales"
  res <- config_formalidad$pob_label_fn(list(category = "Formal"),
                                         definicion = "clasica")
  expect_true(grepl("Asalariados", res))
  expect_true(grepl("Formales", res))

  res <- config_formalidad$pob_label_fn(list(category = "Informal"),
                                         definicion = "ampliada")
  expect_true(grepl("Ocupados", res))
  expect_true(grepl("Informales", res))
})

test_that("sentido_label_fn distingue desde/hacia y respeta cada análisis", {
  ### cond_act: "Flujo desde la Ocupación"
  desde <- config_cond_act$sentido_label_fn(list(category = "Ocupado"),
                                             sentido_t = "t_anterior")
  hacia <- config_cond_act$sentido_label_fn(list(category = "Ocupado"),
                                             sentido_t = "t_posterior")
  expect_true(grepl("desde", as.character(desde)))
  expect_true(grepl("Ocupación", as.character(desde)))
  expect_true(grepl("hacia", as.character(hacia)))

  ### formalidad agrega universo según definición.
  res_clas <- config_formalidad$sentido_label_fn(
    list(category = "Formal"), sentido_t = "t_anterior", definicion = "clasica"
  )
  res_amp <- config_formalidad$sentido_label_fn(
    list(category = "Formal"), sentido_t = "t_anterior", definicion = "ampliada"
  )
  expect_true(grepl("asalariados", as.character(res_clas)))
  expect_true(grepl("ocupados", as.character(res_amp)))
})

test_that("pelicula_serie_label_fn devuelve string para combinaciones válidas", {
  ### cond_act: "% de Desocupados que pasan a la Inactividad"
  res <- config_cond_act$pelicula_serie_label_fn("Desocupado_t0", "Inactivo_t1")
  expect_true(grepl("Desocupados", res))
  expect_true(grepl("Inactividad", res))

  ### cat_ocup: usa el helper genérico .etiqueta_serie_plural_default.
  res <- config_cat_ocup$pelicula_serie_label_fn("Asalariado_t0", "Patron_t1")
  expect_true(grepl("Asalariados", as.character(res)))
  expect_true(grepl("Patrones", as.character(res)))

  ### formalidad: same shape, distintas etiquetas
  res <- config_formalidad$pelicula_serie_label_fn("Formal_t0", "Informal_t1")
  expect_true(grepl("Formales", as.character(res)))
  expect_true(grepl("Informales", as.character(res)))
})

test_that("tasas_caption_fn devuelve string con la categoría", {
  res <- config_cond_act$tasas_caption_fn(list(tasas_category = "Ocupado"))
  expect_true(grepl("Ocupados", res))

  res <- config_cat_ocup$tasas_caption_fn(list(tasas_category = "Asalariado"))
  expect_true(grepl("Asalariados", res))

  res <- config_formalidad$tasas_caption_fn(list(tasas_category = "Formal"),
                                              definicion = "clasica")
  expect_true(grepl("Formales", res))
  expect_true(grepl("clasica", res))
})

test_that("mostrar_pandemia_fn responde al selector de duo", {
  ### En modo "todos" (default), cond_act y cat_ocup muestran pandemia.
  expect_true(config_cond_act$mostrar_pandemia_fn(
    list(tasas_duo = "todos", duo = "todos"), "tasas"))
  expect_true(config_cat_ocup$mostrar_pandemia_fn(
    list(tasas_duo = "todos", duo = "todos"), "pelicula"))

  ### Cuando se filtra por un dúo específico, no se muestra.
  expect_false(config_cond_act$mostrar_pandemia_fn(
    list(tasas_duo = "t1-t2", duo = "todos"), "tasas"))

  ### Formalidad ampliada nunca muestra pandemia (def arranca 2023-T4).
  expect_false(config_formalidad$mostrar_pandemia_fn(
    list(tasas_duo = "todos", duo = "todos"), "tasas",
    definicion = "ampliada"))
  expect_true(config_formalidad$mostrar_pandemia_fn(
    list(tasas_duo = "todos", duo = "todos"), "tasas",
    definicion = "clasica"))
})


### --- Toggle definición y validate_pre_render: solo formalidad ----------

test_that("solo formalidad activa toggle y validación", {
  expect_false(config_cond_act$incluir_toggle_definicion)
  expect_false(config_cat_ocup$incluir_toggle_definicion)
  expect_true(config_formalidad$incluir_toggle_definicion)

  expect_null(config_cond_act$validate_pre_render_fn)
  expect_null(config_cat_ocup$validate_pre_render_fn)
  expect_true(is.function(config_formalidad$validate_pre_render_fn))
})

test_that("formalidad expone helpers internos para toggle", {
  expect_true(is.function(config_formalidad$.resolver_var_panel))
  expect_equal(config_formalidad$.resolver_var_panel("clasica"), "formalidad")
  expect_equal(config_formalidad$.resolver_var_panel("ampliada"),
               "formalidad_ampliada")
  expect_equal(config_formalidad$.resolver_universo("clasica"), "asalariados")
  expect_equal(config_formalidad$.resolver_universo("ampliada"), "ocupados")
})


### --- Tab Comparar funcional: solo cond_act -----------------------------

test_that("solo cond_act tiene Tab Comparar funcional por ahora", {
  expect_true(config_cond_act$incluir_comparar_funcional)
  expect_false(config_cat_ocup$incluir_comparar_funcional)
  expect_false(config_formalidad$incluir_comparar_funcional)
})


### --- Selector tipo de tasa: solo cond_act ------------------------------

test_that("solo cond_act tiene selector multi-tasa en sub-tab Tasas", {
  expect_true(config_cond_act$incluir_selector_tipo_tasa)
  expect_false(config_cat_ocup$incluir_selector_tipo_tasa)
  expect_false(config_formalidad$incluir_selector_tipo_tasa)
})
