CONCLUSION_OPTIONS = [
  'Satisfactorio',
  'Satisfactorio con salvedades',
  'Necesita mejorar',
  'No satisfactorio',
  'No aplica'
]

CONCLUSION_COLORS = {
  'Satisfactorio'                => '00ff00',
  'Satisfactorio con salvedades' => '808000',
  'Necesita mejorar'             => 'f4d03f',
  'No satisfactorio'             => 'ff0000',
  'No aplica'                    => '808080'
}

CONCLUSION_IMAGES = {
  'Satisfactorio'                => 'score_success.png',
  'Satisfactorio con salvedades' => 'score_success_with_exceptions.png',
  'Necesita mejorar'             => 'score_warning.png',
  'No satisfactorio'             => 'score_danger.png',
  'No aplica'                    => 'score_not_apply.png'
}

EVOLUTION_OPTIONS = [
  'Mantiene calificación desfavorable',
  'Mantiene calificación favorable',
  'Mejora calificación',
  'Empeora calficación'
]

EVOLUTION_IMAGES = {
  'Mantiene calificación desfavorable' => 'evolution_equal_danger.png',
  'Mantiene calificación favorable'    => 'evolution_equal_success.png',
  'Mejora calificación'                => 'evolution_up.png',
  'Empeora calficación'                => 'evolution_down.png'
}

PDF_IMAGE_PATH = Rails.root.join('app', 'assets', 'images', 'pdf').freeze
PDF_DEFAULT_SCORE_IMAGE = 'score_none.png'

REVIEW_SCOPES = [
  'Auditorías/Seguimiento',
  'Trabajo especial',
  'Informe de comité',
  'Auditoría continua'
]

REVIEW_RISK_EXPOSURE = [
  'Alta',
  'Alta/media',
  'Media',
  'Media/baja',
  'Baja',
  'No relevante',
  'No aplica'
]

WEAKNESS_OPERATIONAL_RISK = [
  'Debilidad de control/errores',
  'Fraude interno',
  'Fraude externo',
  'Riesgo legal'
]

WEAKNESS_IMPACT = [
  'Reputacional',
  'Regulatorio',
  'Económico',
  'En el proceso/negocio'
]

WEAKNESS_INTERNAL_CONTROL_COMPONENTS = [
  'Ambiente de control',
  'Evaluación de riesgos',
  'Actividades de control',
  'Administración y control contable',
  'Información y comunicación',
  'Monitoreo'
]
