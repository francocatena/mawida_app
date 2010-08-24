# Dirección del correo electrónico de soporte
SUPPORT_EMAIL = 'soporte@mawidaweb.com.ar'.freeze
# Teléfono de soporte
SUPPORT_PHONE = '(0261) 449-8885'.freeze
# Dirección principal de soporte
SUPPORT_URL = 'http://soporte.mawidaweb.com.ar/'.freeze
# Ruta hasta el directorio de configuración
CONFIG_PATH = File.join(Rails.root, 'config', File::SEPARATOR).freeze
# Ruta hasta el directorio público
PUBLIC_PATH = File.join(Rails.root, 'public', File::SEPARATOR).freeze
# Ruta hasta el directorio privado
PRIVATE_PATH = File.join(Rails.root, 'private', File::SEPARATOR).freeze
# Ruta al directorio temporal
TEMP_PATH = File.join(Rails.root, 'tmp', File::SEPARATOR).freeze
# Prefijo de la organización para administrar grupos
APP_ADMIN_PREFIX = 'admin'.freeze
# Ruta al directorio para realizar copias de seguridad
APP_BACKUP_PATH = File.join(PRIVATE_PATH, 'backup_files', File::SEPARATOR).freeze
# Ruta a los archivos subidos a la aplicación
APP_FILES_PATH = File.join(PRIVATE_PATH, 'file_models', File::SEPARATOR).freeze
# Ruta a las imágenes subidas a la aplicación
APP_IMAGES_PATH = File.join(PRIVATE_PATH, 'image_models', File::SEPARATOR).freeze
# Cantidad de líneas por página
APP_LINES_PER_PAGE = 12
# Variable con los idiomas disponibles (Debería reemplazarse con
# I18.available_locales cuando se haya completado la traducción a Inglés)
AVAILABLE_LOCALES = [:es].freeze
# Cantidad de días en los que es posible cambiar la contraseña luego de un
# blanqueo
BLANK_PASSWORD_STALE_DAYS = 3
# Expresión regular para validar direcciones de correo
EMAIL_REGEXP = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
# Cantidad de días anteriores al vencimiento de una observación en los que el
# sistema notificará su proximidad
FINDING_WARNING_EXPIRE_DAYS = 7
# Cantidad de días a los que se debe enviar una nueva solicitud de confirmación
FINDING_STALE_UNCONFIRMED_DAYS = 1
# Cantidad de días a los que se considera como sin respuesta a una observación u
# oportunidad
FINDING_STALE_CONFIRMED_DAYS = 3
# Cantidad de detractores a mostrar en el resumen por usuario
LAST_DETRACTORS_LIMIT = 20
# Cuenta de correo destino de las notificaciones (se enviarán todas las
# notificaciones a esta cuenta)
NOTIFICATIONS_EMAIL = 'notificaciones@mawidaweb.com.ar'.freeze
# Días a los que se consideran anticuadas las notificaciones
NOTIFICATIONS_STALE_DAYS = 2
# Ruta hasta donde se almacenan los archivos de errores
ERROR_FILES_PATH = File.join(PUBLIC_PATH, 'error_files', File::SEPARATOR).freeze
# Cadena para separar las enumeraciones cuando son concatenadas
APP_ENUM_SEPARATOR = ' / '.freeze
# Tipos de parámetros
APP_PARAMETER_TYPES = ['admin', 'security'].freeze
# Márgenes a dejar en los reportes generados en PDF (T, L, B, R)
PDF_MARGINS = [25, 25, 20, 20].freeze
# Tamaño de la página a usar en los reportes generados en PDF
PDF_PAPER = 'A4'.freeze
# Logo para el pié de página de los PDFs
PDF_LOGO = File.join(Rails.root, 'public', 'images', 'logo_pdf.png').freeze
# Dimensiones del logo en pixels, primero el ancho y luego el alto
PDF_LOGO_SIZE = [352, 90].map { |size| (size / 6.0).round }
# Tamaño de fuente en los PDF
PDF_FONT_SIZE = 11
# Prefijo para los archivos que no se pueden acceder sin estar autenticado
PRIVATE_FILES_PREFIX = 'private'.freeze
# Expresión regular para dividir términos en una búsqueda
SPLIT_AND_TERMS_REGEXP = /\s+y\s+|\s*[,;]\s*|\s+AND\s+/i
# Ruta a un archivo para realizar las pruebas
TEST_FILE = File.join(PUBLIC_PATH, '500.html').freeze
# Dirección base para formar los links absolutos
URL_HOST = (Rails.env == 'development' ?
    'mawidaweb.com.ar:3000' : 'mawidaweb.com.ar').freeze
# Protocolo a utilizar para formar los links absolutos
URL_PROTOCOL = (Rails.env == 'development' ? 'http' : 'https').freeze
# Expresión regular para separar términos en las cadenas de búsqueda (operador
# AND)
SEARCH_AND_REGEXP = /\s*[;]+\s*|\s+AND\s+|\s+Y\s+/i
# Expresión regular para separar términos en las cadenas de búsqueda (operador
# OR)
SEARCH_OR_REGEXP = /\s*[,\+]+\s*|\s+OR\s+|\s+O\s+/i

# Array con los nombre de los controladores
APP_CONTROLLERS = [
  :users, :error_records, :login_records, :roles, :parameters, :organizations,
  :oportunities, :weaknesses, :reviews, :control_objective_items, :periods,
  :best_practices, :procedure_controls, :resource_classes, :plans,
  :conclusion_final_reviews, :conclusion_draft_reviews, :workflows, :findings,
  :follow_up_audit, :follow_up_committee, :follow_up_management, :backups,
  :notifications, :conclusion_audit_reports, :conclusion_committee_reports,
  :conclusion_management_reports, :help_contents, :versions, :execution_reports,
  :welcome
].freeze

# Arreglo con los modelos (y sus relaciones) que deben ser tenidos en cuenta
# para realizar la copia de seguridad
APP_MODELS_FOR_BACKUP = ['image_model', 'organization', 'privilege', 'role',
  ['user', [:organizations, :roles]], 'backup', 'best_practice',
  'business_unit', 'file_model', 'work_paper', ['finding', [:work_papers]],
  ['conclusion_review', [:oportunities, :weaknesses]], 'control_objective',
  ['control_objective_item', [:pre_audit_work_papers, :post_audit_work_papers]],
  'error_record', 'finding_answer', 'login_record', 'old_password', 'parameter',
  'period', 'resource_utilization', 'plan', 'resource_class', 'resource',
  'plan_item', 'procedure_control', 'procedure_control_item',
  'procedure_control_subitem', 'process_control', 'review', 'workflow',
  'workflow_item', 'version', 'help_contents'].freeze