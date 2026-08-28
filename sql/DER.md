<!-- ========================================================= -->
<!-- ARCHIVO GENERADO AUTOMATICAMENTE - NO EDITAR A MANO        -->
<!-- Fuente de verdad: sql/03-create-municipio.sql             -->
<!-- Regenerar:        python tools/generate_der.py            -->
<!-- ========================================================= -->

# DER - Schema de Municipio (GDI Latam)

Diagrama Entidad-Relacion del schema que se crea al desplegar un municipio (`sql/03-create-municipio.sql`). Cada municipio es un schema PostgreSQL independiente (multi-tenant). Las entidades `public_*` son tablas globales compartidas por todos los municipios.

| Metrica | Valor |
|---------|-------|
| Tablas del tenant | 46 |
| Foreign keys | 108 |
| Tablas globales referenciadas (`public.*`) | 4 |

> Cardinalidad: `||--o{` = FK obligatoria (NOT NULL) · `|o--o{` = FK opcional (nullable). El lado `o{` es la tabla que tiene la FK.

## Diagrama completo

```mermaid
erDiagram
    departments {
        UUID id PK
        VARCHAR name
        VARCHAR acronym
        UUID parent_id FK
        UUID rank_id FK
        UUID head_user_id
        VARCHAR primary_color
        BOOLEAN is_active
        BOOLEAN is_system
        TIMESTAMPTZ start_date
        TIMESTAMPTZ end_date
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    sectors {
        UUID id PK
        UUID department_id FK
        VARCHAR acronym
        VARCHAR primary_color
        BOOLEAN is_active
        TIMESTAMPTZ start_date
        TIMESTAMPTZ end_date
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    users {
        UUID id PK
        TEXT auth_id
        VARCHAR auth_method
        TEXT email UK
        VARCHAR full_name
        TEXT profile_picture_url
        VARCHAR CountryID
        UUID sector_id FK
        INT estado
        TIMESTAMPTZ last_access
        BOOLEAN can_global_search_documents
        BOOLEAN can_global_search_cases
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    user_roles {
        UUID id PK
        UUID user_id FK
        UUID role_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    user_seals {
        UUID id PK
        UUID user_id FK,UK
        INT city_seal_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    user_sector_permissions {
        UUID id PK
        UUID user_id FK
        UUID sector_id FK
        BOOLEAN can_view
        BOOLEAN can_edit
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    estado_users {
        SERIAL id PK
        VARCHAR estado
        TIMESTAMPTZ updated_at
    }
    ranks {
        UUID id PK
        VARCHAR name UK
        INT level UK
        VARCHAR head_signature
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    city_seals {
        SERIAL id PK
        TEXT name UK
        TEXT description
        UUID rank_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    document_types {
        SERIAL id PK
        UUID global_document_type_id FK
        VARCHAR name
        VARCHAR acronym UK
        TEXT description
        TEXT signature_policy
        BOOLEAN is_active
        document_type_source type
        BOOLEAN trust
        BOOLEAN special_numbering
        BOOLEAN accepts_embedded_files
        VARCHAR visibility
        BOOLEAN is_reserved
        BOOLEAN external_signable
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    document_types_allowed_by_rank {
        SERIAL id PK
        INT document_type_id FK
        UUID rank_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    enabled_document_types_by_sector {
        SERIAL id PK
        INT document_type_id FK
        UUID sector_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    citizens {
        UUID id PK
        VARCHAR full_name
        VARCHAR country_id UK
        VARCHAR estado
        TIMESTAMPTZ validated_at
        VARCHAR validated_by
        VARCHAR created_via
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    document_draft {
        UUID id PK
        UUID created_by FK
        UUID created_by_citizen FK
        INT document_type_id FK
        VARCHAR reference
        JSONB content
        document_status status
        TIMESTAMPTZ sent_to_sign_at
        UUID sent_by
        TEXT document_number
        TIMESTAMPTZ numbered_at
        UUID numbered_by
        BOOLEAN is_deleted
        TEXT resume
        TEXT short_resume
        TIMESTAMPTZ last_modified_at
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    document_signers {
        UUID id PK
        UUID document_id FK
        UUID user_id FK
        UUID citizen_id FK
        BOOLEAN is_numerator
        INT signing_order
        document_signer_status status
        TIMESTAMPTZ signed_at
        text signed_with_provider
        text cert_serial
        text cert_subject_cuit
        text signature_session_id
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    document_rejections {
        UUID id PK
        UUID document_id FK
        UUID rejected_by FK
        TEXT reason
        TIMESTAMPTZ rejected_at
        TIMESTAMPTZ updated_at
    }
    document_draft_embedded_files {
        UUID id PK
        UUID document_id FK
        TEXT r2_key
        VARCHAR file_name
        BIGINT file_size
        VARCHAR extension
        UUID created_by FK
        UUID created_by_citizen FK
        TIMESTAMPTZ created_at
    }
    document_images {
        UUID id PK
        UUID document_id FK
        UUID uploaded_by FK
        VARCHAR filename
        VARCHAR mime_type
        INTEGER size_bytes
        VARCHAR r2_key
        VARCHAR alt_text
        INTEGER width
        INTEGER height
        TIMESTAMPTZ created_at
    }
    official_documents {
        UUID id PK
        INT document_type_id FK
        VARCHAR reference
        JSONB content
        VARCHAR official_number
        SMALLINT year
        UUID department_id FK
        UUID numerator_id FK
        UUID numerator_citizen FK
        TIMESTAMPTZ signed_at
        JSONB signers
        INT global_sequence
        UUID_arr signer_sector_ids
        TEXT resume
        TEXT short_resume
        INT special_number
        VARCHAR numbering_regime
        VARCHAR reservation_status
        TIMESTAMPTZ reserved_at
        UUID reservation_id
        TIMESTAMPTZ indexed_at
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    official_document_embedded_files {
        UUID id PK
        UUID official_document_id FK
        VARCHAR file_name
        BIGINT file_size
        VARCHAR extension
        UUID created_by FK
        UUID created_by_citizen FK
        TIMESTAMPTZ created_at
    }
    document_number_counters {
        INT document_type_id PK,FK
        SMALLINT year PK
        UUID department_id PK,FK
        INT last_number
        UUID active_reservation_document_id
        TIMESTAMPTZ updated_at
    }
    case_templates {
        UUID id PK
        UUID global_case_template_id FK
        VARCHAR type_name
        VARCHAR acronym UK
        TEXT description
        case_creation_channel creation_channel
        UUID filing_department_id FK
        UUID filing_sector_id FK
        BOOLEAN is_active
        VARCHAR visibility
        BOOLEAN is_reserved
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    case_template_allowed_departments {
        UUID case_template_id PK,FK
        UUID department_id PK,FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    cases {
        UUID id PK
        VARCHAR case_number UK
        VARCHAR reference
        status_case status
        UUID case_template_id FK
        UUID created_by_user_id FK
        UUID created_by_citizen FK
        UUID owner_department_id FK
        UUID owner_sector_id FK
        TIMESTAMPTZ created_at
        TEXT ai_summary
        TEXT short_ai_summary
        TIMESTAMPTZ ai_summary_updated_at
        TIMESTAMPTZ last_modified_at
        TIMESTAMPTZ updated_at
    }
    case_movements {
        UUID id PK
        UUID case_id FK
        movement_type type
        UUID user_id FK
        UUID citizen_id FK
        UUID creator_sector_id FK
        UUID admin_sector_id FK
        UUID assigned_sector_id
        UUID assigned_user_id
        VARCHAR reason
        BOOLEAN is_active
        TIMESTAMPTZ closed_at
        VARCHAR closing_reason
        UUID closed_by
        UUID supporting_document_id
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    case_assignment_tasks {
        UUID id PK
        UUID case_id FK
        UUID assignment_id FK
        UUID assigned_sector_id FK
        UUID assigned_user_id FK
        VARCHAR reason
        VARCHAR status
        UUID created_by
        TIMESTAMPTZ created_at
        UUID closed_by
        TIMESTAMPTZ closed_at
        VARCHAR closing_reason
    }
    case_official_documents {
        UUID id PK
        UUID case_id FK
        UUID official_document_id FK
        UUID linking_user_id FK
        UUID linking_citizen FK
        INT order_number
        TIMESTAMPTZ linking_date
        BOOLEAN is_active
        TIMESTAMPTZ deactivated_at
        UUID deactivated_by_user_id
        TIMESTAMPTZ updated_at
    }
    case_proposed_documents {
        UUID id PK
        UUID case_id FK
        UUID document_draft_id FK
        UUID proposing_user_id FK
        UUID proposing_citizen_id FK
        TIMESTAMPTZ proposing_date
        BOOLEAN is_active
        BOOLEAN auto_link_on_sign
        TIMESTAMPTZ updated_at
    }
    case_citizen_shares {
        UUID id PK
        UUID case_id FK
        UUID citizen_id FK
        UUID shared_by FK
        TIMESTAMPTZ shared_at
        UUID removed_by FK
        TIMESTAMPTZ removed_at
        BOOLEAN is_active
        TIMESTAMPTZ updated_at
    }
    settings {
        UUID id PK
        TEXT timezone
        TEXT bucket_oficial
        TEXT bucket_tosign
        TEXT bucket_edicion
        TEXT bucket_publico
        VARCHAR city
        VARCHAR address
        VARCHAR contact_email
        VARCHAR website_url
        VARCHAR annual_slogan
        TEXT logo_url
        TEXT isologo_url
        TEXT cover_url
        VARCHAR primary_color
        BOOLEAN electronic_signing_async
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    document_chunks {
        UUID id PK
        UUID official_document_id FK
        INTEGER chunk_index
        TEXT chunk_text
        TEXT text_for_embedding
        vector embedding
        VARCHAR embedding_model
        tsvector content_tsv
        TIMESTAMPTZ indexed_at
        TIMESTAMPTZ updated_at
    }
    notes_recipients {
        UUID id PK
        UUID document_id FK
        UUID sector_id FK
        VARCHAR recipient_type
        UUID sender_sector_id FK
        BOOLEAN is_archived
        TIMESTAMPTZ archived_at
        TIMESTAMPTZ updated_at
    }
    notes_openings {
        UUID id PK
        UUID document_id FK
        UUID sector_id FK
        UUID user_id FK
        TIMESTAMPTZ opened_at
        TIMESTAMPTZ updated_at
    }
    memo_recipients {
        UUID id PK
        UUID document_id FK
        UUID recipient_user_id FK
        UUID sender_user_id FK
        VARCHAR recipient_type
        UUID recipient_sector_id FK
        UUID sender_sector_id FK
        BOOLEAN is_archived
        TIMESTAMPTZ archived_at
        TIMESTAMPTZ opened_at
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    registry_families {
        UUID id PK
        UUID global_registry_family_id FK
        VARCHAR code UK
        VARCHAR name
        TEXT description
        JSONB data_schema
        JSONB states
        BOOLEAN is_active
        BOOLEAN is_public
        JSONB public_config
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    registry_family_permissions {
        UUID id PK
        UUID registry_family_id FK
        UUID sector_id FK
        BOOLEAN can_create
        BOOLEAN can_edit
        BOOLEAN can_view
        BOOLEAN can_verify
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    records {
        UUID id PK
        VARCHAR record_number UK
        VARCHAR display_name
        UUID registry_family_id FK
        JSONB data
        VARCHAR state
        DATE next_expiration
        UUID created_by_user_id FK
        UUID created_by_sector_id FK
        TIMESTAMPTZ created_at
        TEXT resume
        TIMESTAMPTZ resume_updated_at
        TIMESTAMPTZ updated_at
    }
    record_history {
        UUID id PK
        UUID record_id FK
        VARCHAR action
        VARCHAR field_name
        JSONB before_value
        JSONB after_value
        UUID user_id FK
        UUID sector_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    record_relations {
        UUID id PK
        UUID source_record_id FK
        UUID target_record_id FK
        VARCHAR relation_type
        TEXT notes
        UUID created_by_user_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    record_case_links {
        UUID id PK
        UUID record_id FK
        UUID case_id FK
        TEXT notes
        UUID linked_by_user_id FK
        TIMESTAMPTZ linked_at
        TIMESTAMPTZ updated_at
    }
    record_document_links {
        UUID id PK
        UUID record_id FK
        UUID document_id
        VARCHAR field_name
        TEXT notes
        UUID linked_by_user_id FK
        TIMESTAMPTZ linked_at
        TIMESTAMPTZ updated_at
    }
    case_responsibles {
        UUID id PK
        UUID case_id FK
        UUID user_id FK
        UUID sector_id FK
        VARCHAR type
        UUID added_by FK
        TIMESTAMPTZ added_at
        UUID removed_by
        TIMESTAMPTZ removed_at
        BOOLEAN is_active
        TIMESTAMPTZ updated_at
    }
    case_favorites {
        UUID id PK
        UUID user_id FK
        UUID case_id FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    case_user_views {
        UUID user_id PK,FK
        UUID case_id PK,FK
        TIMESTAMPTZ last_seen_at
    }
    notification_dismissals {
        UUID id PK
        UUID user_id FK
        VARCHAR notification_key
        TIMESTAMPTZ dismissed_at
    }
    document_type_fields {
        UUID id PK
        INT document_type_id FK,UK
        JSONB field_definitions
        UUID created_by
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    public_global_case_templates {
        _ id PK
    }
    public_global_document_types {
        _ id PK
    }
    public_global_registry_families {
        _ id PK
    }
    public_roles {
        _ role_id PK
    }

    departments |o--o{ departments : "parent_id"
    ranks |o--o{ departments : "rank_id"
    departments ||--o{ sectors : "department_id"
    sectors |o--o{ users : "sector_id"
    users ||--o{ user_roles : "user_id"
    public_roles ||--o{ user_roles : "role_id"
    users ||--o{ user_seals : "user_id"
    city_seals ||--o{ user_seals : "city_seal_id"
    users ||--o{ user_sector_permissions : "user_id"
    sectors ||--o{ user_sector_permissions : "sector_id"
    ranks ||--o{ city_seals : "rank_id"
    public_global_document_types |o--o{ document_types : "global_document_type_id"
    document_types ||--o{ document_types_allowed_by_rank : "document_type_id"
    ranks ||--o{ document_types_allowed_by_rank : "rank_id"
    document_types ||--o{ enabled_document_types_by_sector : "document_type_id"
    sectors ||--o{ enabled_document_types_by_sector : "sector_id"
    users |o--o{ document_draft : "created_by"
    citizens |o--o{ document_draft : "created_by_citizen"
    document_types |o--o{ document_draft : "document_type_id"
    document_draft ||--o{ document_signers : "document_id"
    users |o--o{ document_signers : "user_id"
    citizens |o--o{ document_signers : "citizen_id"
    document_draft ||--o{ document_rejections : "document_id"
    users ||--o{ document_rejections : "rejected_by"
    document_draft ||--o{ document_draft_embedded_files : "document_id"
    users |o--o{ document_draft_embedded_files : "created_by"
    citizens |o--o{ document_draft_embedded_files : "created_by_citizen"
    document_draft ||--o{ document_images : "document_id"
    users ||--o{ document_images : "uploaded_by"
    document_types ||--o{ official_documents : "document_type_id"
    departments ||--o{ official_documents : "department_id"
    users |o--o{ official_documents : "numerator_id"
    citizens |o--o{ official_documents : "numerator_citizen"
    official_documents ||--o{ official_document_embedded_files : "official_document_id"
    users |o--o{ official_document_embedded_files : "created_by"
    citizens |o--o{ official_document_embedded_files : "created_by_citizen"
    document_types ||--o{ document_number_counters : "document_type_id"
    departments ||--o{ document_number_counters : "department_id"
    public_global_case_templates |o--o{ case_templates : "global_case_template_id"
    departments ||--o{ case_templates : "filing_department_id"
    sectors ||--o{ case_templates : "filing_sector_id"
    case_templates ||--o{ case_template_allowed_departments : "case_template_id"
    departments ||--o{ case_template_allowed_departments : "department_id"
    case_templates ||--o{ cases : "case_template_id"
    users |o--o{ cases : "created_by_user_id"
    citizens |o--o{ cases : "created_by_citizen"
    departments ||--o{ cases : "owner_department_id"
    sectors |o--o{ cases : "owner_sector_id"
    cases ||--o{ case_movements : "case_id"
    users |o--o{ case_movements : "user_id"
    citizens |o--o{ case_movements : "citizen_id"
    sectors ||--o{ case_movements : "creator_sector_id"
    sectors ||--o{ case_movements : "admin_sector_id"
    cases ||--o{ case_assignment_tasks : "case_id"
    case_movements ||--o{ case_assignment_tasks : "assignment_id"
    sectors ||--o{ case_assignment_tasks : "assigned_sector_id"
    users |o--o{ case_assignment_tasks : "assigned_user_id"
    cases ||--o{ case_official_documents : "case_id"
    official_documents ||--o{ case_official_documents : "official_document_id"
    users |o--o{ case_official_documents : "linking_user_id"
    citizens |o--o{ case_official_documents : "linking_citizen"
    cases ||--o{ case_proposed_documents : "case_id"
    document_draft ||--o{ case_proposed_documents : "document_draft_id"
    users |o--o{ case_proposed_documents : "proposing_user_id"
    citizens |o--o{ case_proposed_documents : "proposing_citizen_id"
    cases ||--o{ case_citizen_shares : "case_id"
    citizens ||--o{ case_citizen_shares : "citizen_id"
    users |o--o{ case_citizen_shares : "shared_by"
    users |o--o{ case_citizen_shares : "removed_by"
    official_documents ||--o{ document_chunks : "official_document_id"
    document_draft ||--o{ notes_recipients : "document_id"
    sectors ||--o{ notes_recipients : "sector_id"
    sectors ||--o{ notes_recipients : "sender_sector_id"
    document_draft ||--o{ notes_openings : "document_id"
    sectors ||--o{ notes_openings : "sector_id"
    users ||--o{ notes_openings : "user_id"
    document_draft ||--o{ memo_recipients : "document_id"
    users ||--o{ memo_recipients : "recipient_user_id"
    users ||--o{ memo_recipients : "sender_user_id"
    sectors |o--o{ memo_recipients : "recipient_sector_id"
    sectors |o--o{ memo_recipients : "sender_sector_id"
    public_global_registry_families |o--o{ registry_families : "global_registry_family_id"
    registry_families ||--o{ registry_family_permissions : "registry_family_id"
    sectors ||--o{ registry_family_permissions : "sector_id"
    registry_families ||--o{ records : "registry_family_id"
    users ||--o{ records : "created_by_user_id"
    sectors ||--o{ records : "created_by_sector_id"
    records ||--o{ record_history : "record_id"
    users ||--o{ record_history : "user_id"
    sectors ||--o{ record_history : "sector_id"
    records ||--o{ record_relations : "source_record_id"
    records ||--o{ record_relations : "target_record_id"
    users ||--o{ record_relations : "created_by_user_id"
    records ||--o{ record_case_links : "record_id"
    cases ||--o{ record_case_links : "case_id"
    users ||--o{ record_case_links : "linked_by_user_id"
    records ||--o{ record_document_links : "record_id"
    users ||--o{ record_document_links : "linked_by_user_id"
    cases ||--o{ case_responsibles : "case_id"
    users ||--o{ case_responsibles : "user_id"
    sectors ||--o{ case_responsibles : "sector_id"
    users ||--o{ case_responsibles : "added_by"
    users ||--o{ case_favorites : "user_id"
    cases ||--o{ case_favorites : "case_id"
    users ||--o{ case_user_views : "user_id"
    cases ||--o{ case_user_views : "case_id"
    users ||--o{ notification_dismissals : "user_id"
    document_types ||--o{ document_type_fields : "document_type_id"
```

## Entidades por grupo

### Grupo A: ESTRUCTURA ORGANIZACIONAL

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `departments` | 13 | 2 |  |
| `sectors` | 9 | 1 |  |

### Grupo B: USUARIOS

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `users` | 14 | 1 |  |
| `user_roles` | 5 | 2 |  |
| `user_seals` | 5 | 2 |  |
| `user_sector_permissions` | 7 | 2 |  |
| `estado_users` | 3 | 0 |  |

### Grupo C: RANGOS Y SELLOS (per-tenant)

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `ranks` | 6 | 0 | Jerarquias del municipio (per-tenant) |
| `city_seals` | 6 | 1 | Sellos del municipio. rank_id NULL = generico |

### Grupo D: DOCUMENTOS

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `document_types` | 16 | 1 |  |
| `document_types_allowed_by_rank` | 5 | 2 |  |
| `enabled_document_types_by_sector` | 5 | 2 |  |
| `citizens` | 9 | 0 | GDI-130 TAD Ciudadano: base de vecinos que firman/operan via API TAD. NO es usuario GDI (sin Auth0) |
| `document_draft` | 18 | 3 |  |
| `document_signers` | 14 | 3 |  |
| `document_rejections` | 6 | 2 |  |
| `document_draft_embedded_files` | 9 | 3 |  |
| `document_images` | 11 | 2 |  |
| `official_documents` | 23 | 4 |  |
| `official_document_embedded_files` | 8 | 3 |  |
| `document_number_counters` | 6 | 2 |  |

### Grupo E: EXPEDIENTES

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `case_templates` | 13 | 3 |  |
| `case_template_allowed_departments` | 4 | 2 |  |
| `cases` | 15 | 5 |  |
| `case_movements` | 17 | 5 |  |
| `case_assignment_tasks` | 12 | 4 |  |
| `case_official_documents` | 11 | 4 |  |
| `case_proposed_documents` | 9 | 4 |  |
| `case_citizen_shares` | 9 | 4 | GDI-130 TAD: ciudadanos con los que un expediente esta compartido (N por expediente). shared_by NULL = automatico (creacion TAD) |

### Grupo F: CONFIGURACION

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `settings` | 18 | 0 |  |

### Grupo G: AGENTE IA (GDI-Agente)

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `document_chunks` | 10 | 1 | Chunks de documentos oficiales con embeddings para búsqueda semántica |

### Grupo H: NOTAS (Documentos con destinatarios)

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `notes_recipients` | 8 | 3 | Destinatarios de notas oficiales (TO, CC, BCC) con soporte para archivado |
| `notes_openings` | 6 | 3 | Registro de apertura de notas (tracking simple sí/no) |
| `memo_recipients` | 12 | 5 | Destinatarios de memos persona-a-persona (TO, CC, BCC) con tracking de apertura inline |

### Grupo I: REGISTROS

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `registry_families` | 12 | 1 | Familias de registros del municipio (copiadas y personalizadas desde global) |
| `registry_family_permissions` | 9 | 2 | Permisos de sectores sobre familias de registros |
| `records` | 13 | 3 | Registros individuales con datos JSONB segun schema de la familia |
| `record_history` | 10 | 3 | Historial de cambios en registros |
| `record_relations` | 8 | 3 | Relaciones entre registros (ej: obra relacionada con luminaria) |
| `record_case_links` | 7 | 3 | Vinculos entre registros y expedientes |
| `record_document_links` | 8 | 2 | Vinculos entre registros y documentos (draft u oficial) |

### Grupo J: RESPONSABLES Y FAVORITOS DE EXPEDIENTE

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `case_responsibles` | 11 | 4 | Responsables asignados a expedientes (ADMIN uno o más activos + ADDITIONAL ilimitados) |
| `case_favorites` | 5 | 2 | Expedientes marcados como favoritos por cada usuario |
| `case_user_views` | 3 | 2 | GDI-067: última vez que cada usuario abrió cada expediente (baseline de "movimientos nuevos") |
| `notification_dismissals` | 4 | 1 | GDI-067: dismiss manual (X) de avisos informativos (responsable/mención) por usuario |

### Grupo K: FORMULARIOS CONTROLADOS (FFCC)

| Tabla | Cols | FKs | Descripcion |
|-------|------|-----|-------------|
| `document_type_fields` | 6 | 1 | Definición de campos de formularios controlados (FFCC). Una fila por tipo de documento. field_definitions es array JSONB con los campos del formulario. |

