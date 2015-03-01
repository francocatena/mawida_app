# Menú del auditado
APP_AUDITED_MENU_ITEMS = [
  MenuItem.new(
    :follow_up,
    order: 1,
    children: [
      MenuItem.new(
        :pending_findings,
        order: 1,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'incomplete'",
        url: { controller: '/findings', completed: :incomplete }
      ),
      MenuItem.new(
        :complete_findings,
        order: 2,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'complete'",
        url: { controller: '/findings', completed: :complete }
      ),
      MenuItem.new(
        :notifications,
        order: 3,
        controllers: :notifications,
        url: { controller: '/notifications' }
      )
    ]
  )
].freeze

# Menú del auditor
APP_AUDITOR_MENU_ITEMS = [
  # ADMINISTRACIÓN
  MenuItem.new(
    :administration,
    order: 1,
    children: [
      MenuItem.new(
        :organization,
        order: 1,
        url: { controller: '/organizations' },
        children: [
          MenuItem.new(
            :management,
            order: 1,
            controllers: :organizations,
            url: { controller: '/organizations' }
          ),
          MenuItem.new(
            :business_units,
            order: 2,
            controllers: :business_unit_types,
            url: { controller: '/business_unit_types' }
          )
        ]
      ),
      MenuItem.new(
        :security,
        order: 2,
        url: { controller: '/users' },
        children: [
          MenuItem.new(
            :users,
            order: 1,
            controllers: :users,
            url: { controller: '/users' }
          ),
          MenuItem.new(
            :reports,
            order: 2,
            controllers: [:error_records, :login_records, :versions],
            url: { controller: '/login_records', action: :choose }
          ),
          MenuItem.new(
            :roles,
            order: 3,
            controllers: :roles,
            url: { controller: '/roles' }
          )
        ]
      ),
      MenuItem.new(
        :best_practices,
        order: 3,
        controllers: :best_practices,
        url: { controller: '/best_practices' }
      ),
      MenuItem.new(
        :settings,
        order: 4,
        controllers: :settings,
        url: { controller: '/settings' }
      ),
      MenuItem.new(
        :benefits,
        order: 5,
        controllers: :benefits,
        url: { controller: '/benefits' }
      ),
      MenuItem.new(
        :e_mails,
        order: 6,
        controllers: :e_mails,
        url: { controller: '/e_mails' }
      ),
      MenuItem.new(
        :questionnaires,
        order: 7,
        url: { controller: '/questionnaires' },
        children: [
          MenuItem.new(
            :definition,
            order: 1,
            controllers: :questionnaires,
            url: { controller: '/questionnaires' }
          ),
          MenuItem.new(
            :polls,
            order: 2,
            controllers: :polls,
            url: { controller: '/polls' }
          ),
          MenuItem.new(
            :reports,
            order: 3,
            controllers: :polls,
            url: { controller: '/polls', action: :reports }
          )
        ]
      )
    ]
  ),
  # PLANIFICACIÓN
  MenuItem.new(
    :planning,
    order: 2,
    children: [
      MenuItem.new(
        :resources,
        order: 1,
        controllers: :resource_classes,
        url: { controller: '/resource_classes' }
      ),
      MenuItem.new(
        :periods,
        order: 2,
        controllers: :periods,
        url: { controller: '/periods' }
      ),
      MenuItem.new(
        :plans,
        order: 3,
        controllers: :plans,
        url: { controller: '/plans' }
      )
    ]
  ),
  # EJECUCIÓN
  MenuItem.new(
    :execution,
    order: 3,
    children: [
      MenuItem.new(
        :reviews,
        order: 1,
        controllers: :reviews,
        url: { controller: '/reviews' }
      ),
      MenuItem.new(
        :workflows,
        order: 2,
        controllers: :workflows,
        url: { controller: '/workflows' }
      ),
      MenuItem.new(
        :control_objectives,
        order: 3,
        controllers: :control_objective_items,
        url: { controller: '/control_objective_items' }
      ),
      MenuItem.new(
        :weaknesses,
        order: 4,
        controllers: :weaknesses,
        url: { controller: '/weaknesses' }
      ),
      MenuItem.new(
        :oportunities,
        order: 5,
        controllers: :oportunities,
        url: { controller: '/oportunities' }
      ),
      MenuItem.new(
        :reports,
        order: 6,
        controllers: :execution_reports,
        url: { controller: '/execution_reports' }
      )
    ]
  ),
  # CONCLUSIÓN
  MenuItem.new(
    :conclusion,
    order: 4,
    children: [
      MenuItem.new(
        :draft_reviews,
        order: 1,
        controllers: :conclusion_draft_reviews,
        url: { controller: '/conclusion_draft_reviews' }
      ),
      MenuItem.new(
        :final_reviews,
        order: 2,
        controllers: :conclusion_final_reviews,
        url: { controller: '/conclusion_final_reviews' }
      ),
      MenuItem.new(
        :reports,
        order: 3,
        controllers: :conclusion_reports,
        url: { controller: '/conclusion_reports' }
      )
    ]
  ),
  # SEGUIMIENTO
  MenuItem.new(
    :follow_up,
    order: 5,
    children: [
      MenuItem.new(
        :pending_findings,
        order: 1,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'incomplete'",
        url: { controller: '/findings', completed: :incomplete }
      ),
      MenuItem.new(
        :complete_findings,
        order: 2,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'complete'",
        url: { controller: '/findings', completed: :complete }
      ),
      MenuItem.new(
        :notifications,
        order: 3,
        controllers: :notifications,
        url: { controller: '/notifications' }
      ),
      MenuItem.new(
        :reports,
        order: 4,
        controllers: :follow_up_audit,
        url: { controller: '/follow_up_audit' }
      )
    ]
  )
].freeze

# Menú del auditado para organizaciones de Gestión de la Calidad
APP_AUDITED_QM_MENU_ITEMS = [
  MenuItem.new(
    :follow_up,
    order: 1,
    children: [
      MenuItem.new(
        :pending_findings,
        order: 1,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'incomplete'",
        url: { controller: '/findings', completed: :incomplete }
      ),
      MenuItem.new(
        :complete_findings,
        order: 2,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'complete'",
        url: { controller: '/findings', completed: :complete }
      ),
      MenuItem.new(
        :notifications,
        order: 3,
        controllers: :notifications,
        url: { controller: '/notifications' }
      )
    ]
  )
].freeze

# Menú del auditor para organizaciones de Gestión de la Calidad
APP_AUDITOR_QM_MENU_ITEMS = [
  # ADMINISTRACIÓN
  MenuItem.new(
    :administration,
    order: 1,
    children: [
      MenuItem.new(
        :organization,
        order: 1,
        url: { controller: '/organizations' },
        children: [
          MenuItem.new(
            :management,
            order: 1,
            controllers: :organizations,
            url: { controller: '/organizations' }
          ),
          MenuItem.new(
            :business_units,
            order: 2,
            controllers: :business_unit_types,
            url: { controller: '/business_unit_types' }
          )
        ]
      ),
      MenuItem.new(
        :security,
        order: 2,
        url: { controller: '/users' },
        children: [
          MenuItem.new(
            :users,
            order: 1,
            controllers: :users,
            url: { controller: '/users' }
          ),
          MenuItem.new(
            :reports,
            order: 2,
            controllers: [:error_records, :login_records, :versions],
            url: { controller: '/login_records', action: :choose }
          ),
          MenuItem.new(
            :roles,
            order: 3,
            controllers: :roles,
            url: { controller: '/roles' }
          )
        ]
      ),
      MenuItem.new(
        :best_practices,
        order: 3,
        controllers: :best_practices,
        url: { controller: '/best_practices' }
      ),
      MenuItem.new(
        :settings,
        order: 4,
        controllers: :settings,
        url: { controller: '/settings' }
      ),
      MenuItem.new(
        :benefits,
        order: 5,
        controllers: :benefits,
        url: { controller: '/benefits' }
      ),
      MenuItem.new(
        :e_mails,
        order: 6,
        controllers: :e_mails,
        url: { controller: '/e_mails' }
      ),
      MenuItem.new(
        :questionnaires,
        order: 7,
        url: { controller: '/questionnaires' },
        children: [
          MenuItem.new(
            :definition,
            order: 1,
            controllers: :questionnaires,
            url: { controller: '/questionnaires' }
          ),
          MenuItem.new(
            :polls,
            order: 2,
            controllers: :polls,
            url: { controller: '/polls' }
          ),
          MenuItem.new(
            :reports,
            order: 3,
            controllers: :polls,
            url: { controller: '/polls', action: :reports }
          )
        ]
      )
    ]
  ),
  # PLANIFICACIÓN
  MenuItem.new(
    :planning,
    order: 2,
    children: [
      MenuItem.new(
        :resources,
        order: 1,
        controllers: :resource_classes,
        url: { controller: '/resource_classes' }
      ),
      MenuItem.new(
        :periods,
        order: 2,
        controllers: :periods,
        url: { controller: '/periods' }
      ),
      MenuItem.new(
        :plans,
        order: 3,
        controllers: :plans,
        url: { controller: '/plans' }
      )
    ]
  ),
  # EJECUCIÓN
  MenuItem.new(
    :execution,
    order: 3,
    children: [
      MenuItem.new(
        :reviews,
        order: 1,
        controllers: :reviews,
        url: { controller: '/reviews' }
      ),
      MenuItem.new(
        :workflows,
        order: 2,
        controllers: :workflows,
        url: { controller: '/workflows' }
      ),
      MenuItem.new(
        :control_objectives,
        order: 3,
        controllers: :control_objective_items,
        url: { controller: '/control_objective_items' }
      ),
      MenuItem.new(
        :findings,
        order: 4,
        url: { controller: '/nonconformities' },
        children: [
          MenuItem.new(
            :nonconformities,
            order: 5,
            controllers: :nonconformities,
            url: { controller: '/nonconformities' }
          ),
          MenuItem.new(
            :weaknesses,
            order: 4,
            controllers: :weaknesses,
            url: { controller: '/weaknesses' }
          ),
          MenuItem.new(
            :oportunities,
            order: 5,
            controllers: :oportunities,
            url: { controller: '/oportunities' }
          ),
          MenuItem.new(
            :potential_nonconformities,
            order: 5,
            controllers: :potential_nonconformities,
            url: { controller: '/potential_nonconformities' }
          ),
          MenuItem.new(
            :fortresses,
            order: 5,
            controllers: :fortresses,
            url: { controller: '/fortresses' }
            ),
        ]
      ),
      MenuItem.new(
        :reports,
        order: 5,
        controllers: :execution_reports,
        url: { controller: '/execution_reports' }
      )
    ]
  ),
  # CONCLUSIÓN
  MenuItem.new(
    :conclusion,
    order: 4,
    children: [
      MenuItem.new(
        :draft_reviews,
        order: 1,
        controllers: :conclusion_draft_reviews,
        url: { controller: '/conclusion_draft_reviews' }
      ),
      MenuItem.new(
        :final_reviews,
        order: 2,
        controllers: :conclusion_final_reviews,
        url: { controller: '/conclusion_final_reviews' }
      ),
      MenuItem.new(
        :reports,
        order: 3,
        controllers: :conclusion_reports,
        url: { controller: '/conclusion_reports' }
      )
    ]
  ),
  # SEGUIMIENTO
  MenuItem.new(
    :follow_up,
    order: 5,
    children: [
      MenuItem.new(
        :pending_findings,
        order: 1,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'incomplete'",
        url: { controller: '/findings', completed: :incomplete }
      ),
      MenuItem.new(
        :complete_findings,
        order: 2,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'complete'",
        url: { controller: '/findings', completed: :complete }
      ),
      MenuItem.new(
        :notifications,
        order: 3,
        controllers: :notifications,
        url: { controller: '/notifications' }
      ),
      MenuItem.new(
        :reports,
        order: 4,
        controllers: :follow_up_audit,
        url: { controller: '/follow_up_audit' }
      )
    ]
  )
].freeze

APP_AUDITOR_MODULES = APP_AUDITOR_MENU_ITEMS.map do |menu_item|
  menu_item.submenu_names
end.flatten.freeze

APP_AUDITED_MODULES = APP_AUDITED_MENU_ITEMS.map do |menu_item|
  menu_item.submenu_names
end.flatten.freeze

APP_AUDITOR_QM_MODULES = APP_AUDITOR_QM_MENU_ITEMS.map do |menu_item|
  menu_item.submenu_names
end.flatten.freeze

APP_AUDITED_QM_MODULES = APP_AUDITED_QM_MENU_ITEMS.map do |menu_item|
  menu_item.submenu_names
end.flatten.freeze

APP_MODULES = (
  APP_AUDITOR_MODULES | APP_AUDITED_MODULES | APP_AUDITOR_QM_MODULES | APP_AUDITED_QM_MODULES
).freeze

ALLOWED_MODULES_BY_TYPE = {
  admin: (APP_AUDITOR_MODULES | APP_AUDITOR_QM_MODULES),
  manager: (APP_AUDITOR_MODULES | APP_AUDITOR_QM_MODULES),
  supervisor: (APP_AUDITOR_MODULES | APP_AUDITOR_QM_MODULES),
  auditor_senior: (APP_AUDITOR_MODULES | APP_AUDITOR_QM_MODULES),
  auditor_junior: (APP_AUDITOR_MODULES | APP_AUDITOR_QM_MODULES),
  committee: (APP_AUDITOR_MODULES | APP_AUDITOR_QM_MODULES),
  audited: (APP_AUDITED_MODULES | APP_AUDITED_QM_MODULES),
  executive_manager: (APP_AUDITOR_MODULES | APP_AUDITOR_QM_MODULES)
}
