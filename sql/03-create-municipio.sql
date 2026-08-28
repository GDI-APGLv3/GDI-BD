


DO $$
BEGIN
    IF '{SCHEMA_NAME}' = ANY(ARRAY[
        'public', 'information_schema', 'pg_catalog', 'pg_toast',
        -- Agregar aca los schemas productivos de esta instalacion.
        '100_example', '101_example'
    ]) THEN
        RAISE EXCEPTION
            'ABORTADO: el schema "%" esta en la lista de schemas protegidos. '
            'Si realmente queres recrearlo, edita manualmente la lista PROTECTED_SCHEMAS '
            'en 03-create-municipio.sql y ejecuta bajo tu responsabilidad.',
            '{SCHEMA_NAME}';
    END IF;
END;
$$;

DROP SCHEMA IF EXISTS "{SCHEMA_NAME}" CASCADE;

CREATE SCHEMA "{SCHEMA_NAME}";


CREATE TABLE "{SCHEMA_NAME}"."departments" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "name" VARCHAR(100) NOT NULL,
  "acronym" VARCHAR(20),
  "parent_id" UUID,
  "rank_id" UUID,
  "head_user_id" UUID,
  "primary_color" VARCHAR(7),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "is_system" BOOLEAN NOT NULL DEFAULT false,
  "start_date" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "end_date" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "departments_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "departments_parent_fkey" FOREIGN KEY ("parent_id") REFERENCES "{SCHEMA_NAME}"."departments" ("id")
);

CREATE TABLE "{SCHEMA_NAME}"."sectors" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "department_id" UUID NOT NULL,
  "acronym" VARCHAR(10) NOT NULL,
  "primary_color" VARCHAR(7),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "start_date" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "end_date" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "sectors_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sectors_department_fkey" FOREIGN KEY ("department_id") REFERENCES "{SCHEMA_NAME}"."departments" ("id"),
  CONSTRAINT "sectors_acronym_unique" UNIQUE ("department_id", "acronym")
);


CREATE TABLE "{SCHEMA_NAME}"."users" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "auth_id" TEXT,
  "auth_method" VARCHAR(20) NOT NULL DEFAULT 'social',
  "email" TEXT NOT NULL,
  "full_name" VARCHAR(150) NOT NULL,
  "profile_picture_url" TEXT,
  "CountryID" VARCHAR(20),
  "sector_id" UUID,
  "estado" INT NOT NULL DEFAULT 1,
  "last_access" TIMESTAMPTZ,
  "can_global_search_documents" BOOLEAN NOT NULL DEFAULT false,
  "can_global_search_cases" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "users_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "users_email_unique" UNIQUE ("email"),
  CONSTRAINT "users_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id")
);

CREATE UNIQUE INDEX "users_auth_id_uniq" ON "{SCHEMA_NAME}"."users" ("auth_id") WHERE "auth_id" IS NOT NULL;

CREATE TABLE "{SCHEMA_NAME}"."user_roles" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "role_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_roles_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "user_roles_role_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles" ("role_id"),
  CONSTRAINT "user_roles_unique" UNIQUE ("user_id", "role_id")
);

CREATE TABLE "{SCHEMA_NAME}"."user_seals" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "city_seal_id" INT NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_seals_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_seals_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "user_seals_user_unique" UNIQUE ("user_id")
);

CREATE TABLE "{SCHEMA_NAME}"."user_sector_permissions" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "can_view" BOOLEAN NOT NULL DEFAULT true,
  "can_edit" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_sector_permissions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_sector_permissions_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "user_sector_permissions_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "user_sector_permissions_unique" UNIQUE ("user_id", "sector_id")
);

CREATE TABLE "{SCHEMA_NAME}"."estado_users" (
  "id" SERIAL NOT NULL,
  "estado" VARCHAR(50) NOT NULL,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "estado_users_pkey" PRIMARY KEY ("id")
);


CREATE TABLE "{SCHEMA_NAME}"."ranks" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "name" VARCHAR(50) NOT NULL,
  "level" INT NOT NULL,
  "head_signature" VARCHAR(100),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "ranks_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "ranks_name_unique" UNIQUE ("name"),
  CONSTRAINT "ranks_level_unique" UNIQUE ("level")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."ranks" IS 'Jerarquias del municipio (per-tenant)';
COMMENT ON COLUMN "{SCHEMA_NAME}"."ranks"."level" IS '1 = mas alto (Intendente), numeros mayores = menor jerarquia';

CREATE TABLE "{SCHEMA_NAME}"."city_seals" (
  "id" SERIAL NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "rank_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "city_seals_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "city_seals_name_unique" UNIQUE ("name"),
  CONSTRAINT "city_seals_rank_fkey" FOREIGN KEY ("rank_id") REFERENCES "{SCHEMA_NAME}"."ranks" ("id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."city_seals" IS 'Sellos del municipio. rank_id NULL = generico';
COMMENT ON COLUMN "{SCHEMA_NAME}"."city_seals"."rank_id" IS 'Si NOT NULL, el usuario con este sello tiene ese rango jerarquico';

ALTER TABLE "{SCHEMA_NAME}"."departments"
  ADD CONSTRAINT "departments_rank_fkey" FOREIGN KEY ("rank_id") REFERENCES "{SCHEMA_NAME}"."ranks" ("id");
ALTER TABLE "{SCHEMA_NAME}"."user_seals"
  ADD CONSTRAINT "user_seals_seal_fkey" FOREIGN KEY ("city_seal_id") REFERENCES "{SCHEMA_NAME}"."city_seals" ("id");


CREATE TABLE "{SCHEMA_NAME}"."document_types" (
  "id" SERIAL NOT NULL,
  "global_document_type_id" UUID,
  "name" VARCHAR(100) NOT NULL,
  "acronym" VARCHAR(6) NOT NULL,
  "description" TEXT,
  "signature_policy" TEXT NOT NULL DEFAULT 'electronic',
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "type" "public"."document_type_source" NOT NULL DEFAULT 'HTML',
  "trust" BOOLEAN NOT NULL DEFAULT true,
  "special_numbering" BOOLEAN NOT NULL DEFAULT false,
  "accepts_embedded_files" BOOLEAN NOT NULL DEFAULT false,
  "visibility" VARCHAR(10) NOT NULL DEFAULT 'interno',
  "is_reserved" BOOLEAN GENERATED ALWAYS AS (visibility = 'reservado') STORED,
  "external_signable" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_types_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_types_acronym_unique" UNIQUE ("acronym"),
  CONSTRAINT "document_types_signature_policy_chk" CHECK (signature_policy IN ('electronic','digital_all','digital_num')),
  CONSTRAINT "document_types_visibility_chk" CHECK (visibility IN ('interno','reservado','publico')),
  CONSTRAINT "document_types_global_fkey" FOREIGN KEY ("global_document_type_id") REFERENCES "public"."global_document_types" ("id")
);

CREATE TABLE "{SCHEMA_NAME}"."document_types_allowed_by_rank" (
  "id" SERIAL NOT NULL,
  "document_type_id" INT NOT NULL,
  "rank_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_types_allowed_by_rank_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "dtabr_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "{SCHEMA_NAME}"."document_types" ("id"),
  CONSTRAINT "dtabr_rank_fkey" FOREIGN KEY ("rank_id") REFERENCES "{SCHEMA_NAME}"."ranks" ("id"),
  CONSTRAINT "dtabr_unique" UNIQUE ("document_type_id", "rank_id")
);

CREATE TABLE "{SCHEMA_NAME}"."enabled_document_types_by_sector" (
  "id" SERIAL NOT NULL,
  "document_type_id" INT NOT NULL,
  "sector_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "enabled_edts_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "enabled_edts_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "{SCHEMA_NAME}"."document_types" ("id"),
  CONSTRAINT "enabled_edts_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "enabled_edts_unique" UNIQUE ("document_type_id", "sector_id")
);

CREATE TABLE "{SCHEMA_NAME}"."citizens" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "full_name" VARCHAR(255) NOT NULL,
  "country_id" VARCHAR(20) NOT NULL,
  "estado" VARCHAR(10) NOT NULL DEFAULT 'pendiente',
  "validated_at" TIMESTAMPTZ,
  "validated_by" VARCHAR(50),
  "created_via" VARCHAR(10),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "citizens_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "citizens_country_id_unique" UNIQUE ("country_id"),
  CONSTRAINT "citizens_estado_chk" CHECK ("estado" IN ('pendiente','validado','bloqueado')),
  CONSTRAINT "citizens_created_via_chk" CHECK ("created_via" IN ('api','backoffice'))
);

COMMENT ON TABLE "{SCHEMA_NAME}"."citizens" IS 'GDI-130 TAD Ciudadano: base de vecinos que firman/operan via API TAD. NO es usuario GDI (sin Auth0)';

CREATE TABLE "{SCHEMA_NAME}"."document_draft" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "created_by" UUID,
  "created_by_citizen" UUID,
  "document_type_id" INT,
  "reference" VARCHAR(100) NOT NULL,
  "content" JSONB,
  "status" "public"."document_status" NOT NULL DEFAULT 'draft',
  "sent_to_sign_at" TIMESTAMPTZ,
  "sent_by" UUID,
  "document_number" TEXT,
  "numbered_at" TIMESTAMPTZ,
  "numbered_by" UUID,
  "is_deleted" BOOLEAN NOT NULL DEFAULT false,
  "resume" TEXT,
  "short_resume" TEXT,
  "last_modified_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_draft_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_draft_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "document_draft_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "document_draft_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "{SCHEMA_NAME}"."document_types" ("id"),
  CONSTRAINT "document_draft_creator_chk" CHECK (num_nonnulls("created_by", "created_by_citizen") = 1)
);

CREATE TABLE "{SCHEMA_NAME}"."document_signers" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "user_id" UUID,
  "citizen_id" UUID,
  "is_numerator" BOOLEAN NOT NULL DEFAULT false,
  "signing_order" INT,
  "status" "public"."document_signer_status" NOT NULL DEFAULT 'pending',
  "signed_at" TIMESTAMPTZ,
  "signed_with_provider"   text DEFAULT NULL,
  "cert_serial"            text DEFAULT NULL,
  "cert_subject_cuit"      text DEFAULT NULL,
  "signature_session_id"   text DEFAULT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_signers_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_signers_document_fkey" FOREIGN KEY ("document_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id"),
  CONSTRAINT "document_signers_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "document_signers_citizen_fkey" FOREIGN KEY ("citizen_id") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "document_signers_actor_chk" CHECK (num_nonnulls("user_id", "citizen_id") = 1)
);

CREATE TABLE "{SCHEMA_NAME}"."document_rejections" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "rejected_by" UUID NOT NULL,
  "reason" TEXT,
  "rejected_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_rejections_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_rejections_document_fkey" FOREIGN KEY ("document_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id"),
  CONSTRAINT "document_rejections_user_fkey" FOREIGN KEY ("rejected_by") REFERENCES "{SCHEMA_NAME}"."users" ("id")
);

CREATE TABLE "{SCHEMA_NAME}"."document_draft_embedded_files" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "r2_key" TEXT NOT NULL,
  "file_name" VARCHAR(255) NOT NULL,
  "file_size" BIGINT NOT NULL,
  "extension" VARCHAR(16) NOT NULL,
  "created_by" UUID,
  "created_by_citizen" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_draft_embedded_files_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "ddef_document_fkey" FOREIGN KEY ("document_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id") ON DELETE CASCADE,
  CONSTRAINT "ddef_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "ddef_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "ddef_creator_chk" CHECK (NOT ("created_by" IS NOT NULL AND "created_by_citizen" IS NOT NULL))
);
CREATE INDEX "idx_document_draft_embedded_files_document" ON "{SCHEMA_NAME}"."document_draft_embedded_files" ("document_id");

CREATE TABLE "{SCHEMA_NAME}"."document_images" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "uploaded_by" UUID NOT NULL,
  "filename" VARCHAR(255) NOT NULL,
  "mime_type" VARCHAR(50) NOT NULL,
  "size_bytes" INTEGER NOT NULL,
  "r2_key" VARCHAR(512) NOT NULL,
  "alt_text" VARCHAR(255),
  "width" INTEGER,
  "height" INTEGER,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_images_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_images_mime_chk" CHECK ("mime_type" IN ('image/png','image/jpeg','image/webp')),
  CONSTRAINT "document_images_size_chk" CHECK ("size_bytes" <= 5242880),
  CONSTRAINT "document_images_document_fkey" FOREIGN KEY ("document_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id") ON DELETE CASCADE,
  CONSTRAINT "document_images_uploader_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "{SCHEMA_NAME}"."users" ("id")
);
CREATE INDEX "idx_document_images_document" ON "{SCHEMA_NAME}"."document_images" ("document_id");

CREATE TABLE "{SCHEMA_NAME}"."official_documents" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_type_id" INT NOT NULL,
  "reference" VARCHAR(100) NOT NULL,
  "content" JSONB NOT NULL,
  "official_number" VARCHAR(50) NOT NULL,
  "year" SMALLINT NOT NULL,
  "department_id" UUID NOT NULL,
  "numerator_id" UUID,
  "numerator_citizen" UUID,
  "signed_at" TIMESTAMPTZ,
  "signers" JSONB,
  "global_sequence" INT,
  "signer_sector_ids" UUID[],
  "resume" TEXT,
  "short_resume" TEXT,
  "special_number" INT NULL,
  "numbering_regime" VARCHAR(10) NULL,
  "reservation_status" VARCHAR(20) NULL,
  "reserved_at" TIMESTAMPTZ NULL,
  "reservation_id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "indexed_at" TIMESTAMPTZ NULL,
  "pdf_location" TEXT NOT NULL DEFAULT 'oficial',
  "tsa_seal_attempts" SMALLINT NOT NULL DEFAULT 0,
  "tsa_seal_outcome" TEXT NULL,
  "batch_id" UUID NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "official_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "official_documents_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "{SCHEMA_NAME}"."document_types" ("id"),
  CONSTRAINT "official_documents_department_fkey" FOREIGN KEY ("department_id") REFERENCES "{SCHEMA_NAME}"."departments" ("id"),
  CONSTRAINT "official_documents_numerator_fkey" FOREIGN KEY ("numerator_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "official_documents_numerator_citizen_fkey" FOREIGN KEY ("numerator_citizen") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "official_documents_numerator_chk" CHECK (num_nonnulls("numerator_id", "numerator_citizen") = 1),
  CONSTRAINT "official_documents_numbering_regime_check" CHECK (numbering_regime IN ('GLOBAL', 'SPECIAL')),
  CONSTRAINT "official_documents_reservation_status_check" CHECK (reservation_status IN ('RESERVED', 'CONFIRMING', 'CONFIRMED', 'CANCELLED')),
  CONSTRAINT "official_documents_pdf_location_chk" CHECK (pdf_location IN ('oficial', 'preoficial')),
  CONSTRAINT "official_documents_tsa_seal_outcome_chk" CHECK (tsa_seal_outcome IS NULL OR tsa_seal_outcome IN ('sealed', 'promoted_unsealed', 'failed_permanent', 'missing_pdf'))
);

CREATE TABLE "{SCHEMA_NAME}"."official_document_embedded_files" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "official_document_id" UUID NOT NULL,
  "file_name" VARCHAR(255) NOT NULL,
  "file_size" BIGINT NOT NULL,
  "extension" VARCHAR(16) NOT NULL,
  "created_by" UUID,
  "created_by_citizen" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "official_document_embedded_files_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "odef_official_document_fkey" FOREIGN KEY ("official_document_id") REFERENCES "{SCHEMA_NAME}"."official_documents" ("id") ON DELETE CASCADE,
  CONSTRAINT "odef_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "odef_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "odef_creator_chk" CHECK (NOT ("created_by" IS NOT NULL AND "created_by_citizen" IS NOT NULL))
);
CREATE INDEX "idx_official_document_embedded_files_official" ON "{SCHEMA_NAME}"."official_document_embedded_files" ("official_document_id");

CREATE TABLE "{SCHEMA_NAME}"."document_number_counters" (
  "document_type_id" INT NOT NULL,
  "year" SMALLINT NOT NULL,
  "department_id" UUID NOT NULL,
  "last_number" INT NOT NULL DEFAULT 0,
  "active_reservation_document_id" UUID NULL,
  "active_reservation_batch_id" UUID NULL,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_number_counters_pkey" PRIMARY KEY ("document_type_id", "year", "department_id"),
  CONSTRAINT "document_number_counters_doc_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "{SCHEMA_NAME}"."document_types" ("id"),
  CONSTRAINT "document_number_counters_department_fkey" FOREIGN KEY ("department_id") REFERENCES "{SCHEMA_NAME}"."departments" ("id")
);


CREATE TABLE "{SCHEMA_NAME}"."case_templates" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "global_case_template_id" UUID,
  "type_name" VARCHAR(100) NOT NULL,
  "acronym" VARCHAR(6) NOT NULL,
  "description" TEXT,
  "creation_channel" "public"."case_creation_channel" NOT NULL DEFAULT 'web',
  "filing_department_id" UUID NOT NULL,
  "filing_sector_id" UUID NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "visibility" VARCHAR(10) NOT NULL DEFAULT 'interno',
  "is_reserved" BOOLEAN GENERATED ALWAYS AS (visibility = 'reservado') STORED,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "case_templates_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "case_templates_acronym_unique" UNIQUE ("acronym"),
  CONSTRAINT "case_templates_visibility_chk" CHECK (visibility IN ('interno','reservado')),
  CONSTRAINT "case_templates_global_fkey" FOREIGN KEY ("global_case_template_id") REFERENCES "public"."global_case_templates" ("id"),
  CONSTRAINT "case_templates_department_fkey" FOREIGN KEY ("filing_department_id") REFERENCES "{SCHEMA_NAME}"."departments" ("id"),
  CONSTRAINT "case_templates_sector_fkey" FOREIGN KEY ("filing_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id")
);

CREATE TABLE "{SCHEMA_NAME}"."case_template_allowed_departments" (
  "case_template_id" UUID NOT NULL,
  "department_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "ctad_pkey" PRIMARY KEY ("case_template_id", "department_id"),
  CONSTRAINT "ctad_case_template_fkey" FOREIGN KEY ("case_template_id") REFERENCES "{SCHEMA_NAME}"."case_templates" ("id"),
  CONSTRAINT "ctad_department_fkey" FOREIGN KEY ("department_id") REFERENCES "{SCHEMA_NAME}"."departments" ("id")
);

CREATE TABLE "{SCHEMA_NAME}"."cases" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "case_number" VARCHAR(50) NOT NULL,
  "reference" VARCHAR(250) NOT NULL,
  "status" "public"."status_case" NOT NULL DEFAULT 'inactive',
  "case_template_id" UUID NOT NULL,
  "created_by_user_id" UUID,
  "created_by_citizen" UUID,
  "initiator_citizen_id" UUID,
  "owner_department_id" UUID NOT NULL,
  "owner_sector_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "ai_summary" TEXT,
  "short_ai_summary" TEXT,
  "ai_summary_updated_at" TIMESTAMPTZ,
  "last_modified_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "cases_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cases_number_unique" UNIQUE ("case_number"),
  CONSTRAINT "cases_template_fkey" FOREIGN KEY ("case_template_id") REFERENCES "{SCHEMA_NAME}"."case_templates" ("id"),
  CONSTRAINT "cases_created_by_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "cases_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "cases_initiator_citizen_fkey" FOREIGN KEY ("initiator_citizen_id") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "cases_department_fkey" FOREIGN KEY ("owner_department_id") REFERENCES "{SCHEMA_NAME}"."departments" ("id"),
  CONSTRAINT "cases_sector_fkey" FOREIGN KEY ("owner_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "cases_creator_chk" CHECK (num_nonnulls("created_by_user_id", "created_by_citizen") = 1)
);

CREATE TABLE "{SCHEMA_NAME}"."case_movements" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "case_id" UUID NOT NULL,
  "type" "public"."movement_type" NOT NULL,
  "user_id" UUID,
  "citizen_id" UUID,
  "creator_sector_id" UUID NOT NULL,
  "admin_sector_id" UUID NOT NULL,
  "assigned_sector_id" UUID,
  "assigned_user_id" UUID,
  "reason" VARCHAR(1000) NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "closed_at" TIMESTAMPTZ,
  "closing_reason" VARCHAR(200),
  "closed_by" UUID,
  "supporting_document_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "case_movements_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "case_movements_case_fkey" FOREIGN KEY ("case_id") REFERENCES "{SCHEMA_NAME}"."cases" ("id"),
  CONSTRAINT "case_movements_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "case_movements_citizen_fkey" FOREIGN KEY ("citizen_id") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "case_movements_creator_sector_fkey" FOREIGN KEY ("creator_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "case_movements_admin_sector_fkey" FOREIGN KEY ("admin_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "case_movements_actor_chk" CHECK (NOT ("user_id" IS NOT NULL AND "citizen_id" IS NOT NULL))
);

CREATE TABLE "{SCHEMA_NAME}"."case_assignment_tasks" (
  "id"                 UUID         NOT NULL DEFAULT gen_random_uuid(),
  "case_id"            UUID         NOT NULL,
  "assignment_id"      UUID         NOT NULL,
  "assigned_sector_id" UUID         NOT NULL,
  "assigned_user_id"   UUID,
  "reason"             VARCHAR(500) NOT NULL,
  "status"             VARCHAR(20)  NOT NULL DEFAULT 'open',
  "created_by"         UUID         NOT NULL,
  "created_at"         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  "closed_by"          UUID,
  "closed_at"          TIMESTAMPTZ,
  "closing_reason"     VARCHAR(200),
  CONSTRAINT "cat_pkey"         PRIMARY KEY ("id"),
  CONSTRAINT "cat_case_fkey"    FOREIGN KEY ("case_id")            REFERENCES "{SCHEMA_NAME}"."cases"("id"),
  CONSTRAINT "cat_assign_fkey"  FOREIGN KEY ("assignment_id")      REFERENCES "{SCHEMA_NAME}"."case_movements"("id"),
  CONSTRAINT "cat_sector_fkey"  FOREIGN KEY ("assigned_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors"("id"),
  CONSTRAINT "cat_user_fkey"    FOREIGN KEY ("assigned_user_id")   REFERENCES "{SCHEMA_NAME}"."users"("id")
);

CREATE TABLE "{SCHEMA_NAME}"."case_official_documents" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "case_id" UUID NOT NULL,
  "official_document_id" UUID NOT NULL,
  "linking_user_id" UUID,
  "linking_citizen" UUID,
  "order_number" INT NOT NULL,
  "linking_date" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "deactivated_at" TIMESTAMPTZ,
  "deactivated_by_user_id" UUID,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "case_official_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cod_case_fkey" FOREIGN KEY ("case_id") REFERENCES "{SCHEMA_NAME}"."cases" ("id"),
  CONSTRAINT "cod_official_document_fkey" FOREIGN KEY ("official_document_id") REFERENCES "{SCHEMA_NAME}"."official_documents" ("id"),
  CONSTRAINT "cod_linking_user_fkey" FOREIGN KEY ("linking_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "cod_linking_citizen_fkey" FOREIGN KEY ("linking_citizen") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "cod_linking_actor_chk" CHECK (num_nonnulls("linking_user_id", "linking_citizen") = 1)
);

CREATE TABLE "{SCHEMA_NAME}"."case_proposed_documents" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "case_id" UUID NOT NULL,
  "document_draft_id" UUID NOT NULL,
  "proposing_user_id" UUID,
  "proposing_citizen_id" UUID,
  "proposing_date" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "auto_link_on_sign" BOOLEAN NOT NULL DEFAULT false,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "case_proposed_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cpd_case_fkey" FOREIGN KEY ("case_id") REFERENCES "{SCHEMA_NAME}"."cases" ("id"),
  CONSTRAINT "cpd_document_draft_fkey" FOREIGN KEY ("document_draft_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id"),
  CONSTRAINT "cpd_proposing_user_fkey" FOREIGN KEY ("proposing_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "cpd_proposing_citizen_fkey" FOREIGN KEY ("proposing_citizen_id") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "cpd_proposing_actor_chk" CHECK (num_nonnulls("proposing_user_id", "proposing_citizen_id") = 1)
);

CREATE TABLE "{SCHEMA_NAME}"."case_citizen_shares" (
  "id"         UUID        NOT NULL DEFAULT gen_random_uuid(),
  "case_id"    UUID        NOT NULL,
  "citizen_id" UUID        NOT NULL,
  "shared_by"  UUID,
  "shared_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "removed_by" UUID,
  "removed_at" TIMESTAMPTZ,
  "is_active"  BOOLEAN     NOT NULL DEFAULT true,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "ccs_pkey"          PRIMARY KEY ("id"),
  CONSTRAINT "ccs_case_fkey"     FOREIGN KEY ("case_id")    REFERENCES "{SCHEMA_NAME}"."cases" ("id"),
  CONSTRAINT "ccs_citizen_fkey"  FOREIGN KEY ("citizen_id") REFERENCES "{SCHEMA_NAME}"."citizens" ("id"),
  CONSTRAINT "ccs_shared_by_fkey"  FOREIGN KEY ("shared_by")  REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "ccs_removed_by_fkey" FOREIGN KEY ("removed_by") REFERENCES "{SCHEMA_NAME}"."users" ("id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."case_citizen_shares" IS 'GDI-130 TAD: ciudadanos con los que un expediente esta compartido (N por expediente). shared_by NULL = automatico (creacion TAD)';


CREATE TABLE "{SCHEMA_NAME}"."settings" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "timezone" TEXT NOT NULL DEFAULT 'America/Argentina/Buenos_Aires',
  "bucket_oficial" TEXT NOT NULL,
  "bucket_tosign" TEXT NOT NULL,
  "bucket_edicion" TEXT,
  "bucket_publico" TEXT,
  "bucket_preoficial" TEXT,
  "city" VARCHAR(100) DEFAULT 'LATAM',
  "address" VARCHAR(150),
  "contact_email" VARCHAR(100),
  "website_url" VARCHAR(150),
  "annual_slogan" VARCHAR(255),
  "logo_url" TEXT,
  "isologo_url" TEXT,
  "cover_url" TEXT,
  "primary_color" VARCHAR(6) DEFAULT '16158C',
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "settings_pkey" PRIMARY KEY ("id")
);


CREATE TABLE "{SCHEMA_NAME}"."document_chunks" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "official_document_id" UUID NOT NULL,
  "chunk_index" INTEGER NOT NULL,
  "chunk_text" TEXT NOT NULL,
  "text_for_embedding" TEXT,
  "embedding" halfvec(768),
  "embedding_model" VARCHAR(100) NOT NULL DEFAULT 'text-embedding-3-small',
  "content_tsv" tsvector GENERATED ALWAYS AS (
    to_tsvector('spanish', coalesce(text_for_embedding, chunk_text, ''))
  ) STORED,
  "indexed_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_chunks_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_chunks_official_fkey" FOREIGN KEY ("official_document_id") REFERENCES "{SCHEMA_NAME}"."official_documents" ("id"),
  CONSTRAINT "document_chunks_unique" UNIQUE ("official_document_id", "chunk_index")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."document_chunks" IS 'Chunks de documentos oficiales con embeddings para búsqueda semántica';


CREATE TABLE "{SCHEMA_NAME}"."notes_recipients" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "recipient_type" VARCHAR(3) NOT NULL,
  "sender_sector_id" UUID NOT NULL,
  "is_archived" BOOLEAN NOT NULL DEFAULT false,
  "archived_at" TIMESTAMPTZ NULL,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "notes_recipients_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "notes_recipients_document_fkey" FOREIGN KEY ("document_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id"),
  CONSTRAINT "notes_recipients_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "notes_recipients_sender_fkey" FOREIGN KEY ("sender_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "notes_recipients_type_check" CHECK ("recipient_type" IN ('TO', 'CC', 'BCC')),
  CONSTRAINT "notes_recipients_unique" UNIQUE ("document_id", "sector_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."notes_recipients" IS 'Destinatarios de notas oficiales (TO, CC, BCC) con soporte para archivado';

CREATE TABLE "{SCHEMA_NAME}"."notes_openings" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "opened_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "notes_openings_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "notes_openings_document_fkey" FOREIGN KEY ("document_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id"),
  CONSTRAINT "notes_openings_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "notes_openings_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "notes_openings_unique" UNIQUE ("document_id", "user_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."notes_openings" IS 'Registro de apertura de notas (tracking simple sí/no)';

CREATE TABLE "{SCHEMA_NAME}"."memo_recipients" (
  "id"                  UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id"         UUID NOT NULL,
  "recipient_user_id"   UUID NOT NULL,
  "sender_user_id"      UUID NOT NULL,
  "recipient_type"      VARCHAR(3) NOT NULL,
  "recipient_sector_id" UUID NULL,
  "sender_sector_id"    UUID NULL,
  "is_archived"         BOOLEAN NOT NULL DEFAULT false,
  "archived_at"         TIMESTAMPTZ NULL,
  "opened_at"           TIMESTAMPTZ NULL,
  "created_at"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "memo_recipients_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "memo_recipients_document_fkey"
    FOREIGN KEY ("document_id") REFERENCES "{SCHEMA_NAME}"."document_draft" ("id"),
  CONSTRAINT "memo_recipients_recipient_fkey"
    FOREIGN KEY ("recipient_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "memo_recipients_sender_fkey"
    FOREIGN KEY ("sender_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "memo_recipients_rec_sector_fkey"
    FOREIGN KEY ("recipient_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "memo_recipients_sender_sector_fkey"
    FOREIGN KEY ("sender_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "memo_recipients_type_check"
    CHECK ("recipient_type" IN ('TO', 'CC', 'BCC')),
  CONSTRAINT "memo_recipients_unique"
    UNIQUE ("document_id", "recipient_user_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."memo_recipients" IS 'Destinatarios de memos persona-a-persona (TO, CC, BCC) con tracking de apertura inline';


CREATE TABLE "{SCHEMA_NAME}"."registry_families" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "global_registry_family_id" UUID,
  "code" VARCHAR(10) NOT NULL,
  "name" VARCHAR(200) NOT NULL,
  "description" TEXT,
  "data_schema" JSONB DEFAULT '{}',
  "states" JSONB DEFAULT '["Activo","Inactivo","Suspendido","Archivado"]',
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "is_public" BOOLEAN NOT NULL DEFAULT false,
  "public_config" JSONB,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "registry_families_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "registry_families_code_unique" UNIQUE ("code"),
  CONSTRAINT "registry_families_global_fkey" FOREIGN KEY ("global_registry_family_id") REFERENCES "public"."global_registry_families" ("id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."registry_families" IS 'Familias de registros del municipio (copiadas y personalizadas desde global)';

CREATE TABLE "{SCHEMA_NAME}"."registry_family_permissions" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "registry_family_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "can_create" BOOLEAN NOT NULL DEFAULT false,
  "can_edit" BOOLEAN NOT NULL DEFAULT false,
  "can_view" BOOLEAN NOT NULL DEFAULT true,
  "can_verify" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "registry_family_permissions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "rfp_family_fkey" FOREIGN KEY ("registry_family_id") REFERENCES "{SCHEMA_NAME}"."registry_families" ("id"),
  CONSTRAINT "rfp_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "rfp_unique" UNIQUE ("registry_family_id", "sector_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."registry_family_permissions" IS 'Permisos de sectores sobre familias de registros';

CREATE TABLE "{SCHEMA_NAME}"."records" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "record_number" VARCHAR(50) NOT NULL,
  "display_name" VARCHAR(200),
  "registry_family_id" UUID NOT NULL,
  "data" JSONB DEFAULT '{}',
  "state" VARCHAR(50) DEFAULT 'Activo',
  "next_expiration" DATE,
  "created_by_user_id" UUID NOT NULL,
  "created_by_sector_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "resume" TEXT,
  "resume_updated_at" TIMESTAMPTZ,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "records_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "records_number_unique" UNIQUE ("record_number"),
  CONSTRAINT "records_family_fkey" FOREIGN KEY ("registry_family_id") REFERENCES "{SCHEMA_NAME}"."registry_families" ("id"),
  CONSTRAINT "records_user_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "records_sector_fkey" FOREIGN KEY ("created_by_sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."records" IS 'Registros individuales con datos JSONB segun schema de la familia';

CREATE TABLE "{SCHEMA_NAME}"."record_history" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "record_id" UUID NOT NULL,
  "action" VARCHAR(50) NOT NULL,
  "field_name" VARCHAR(100),
  "before_value" JSONB,
  "after_value" JSONB,
  "user_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_history_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_history_record_fkey" FOREIGN KEY ("record_id") REFERENCES "{SCHEMA_NAME}"."records" ("id"),
  CONSTRAINT "record_history_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "record_history_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."record_history" IS 'Historial de cambios en registros';

CREATE TABLE "{SCHEMA_NAME}"."record_relations" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "source_record_id" UUID NOT NULL,
  "target_record_id" UUID NOT NULL,
  "relation_type" VARCHAR(50) DEFAULT 'related',
  "notes" TEXT,
  "created_by_user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_relations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_relations_source_fkey" FOREIGN KEY ("source_record_id") REFERENCES "{SCHEMA_NAME}"."records" ("id"),
  CONSTRAINT "record_relations_target_fkey" FOREIGN KEY ("target_record_id") REFERENCES "{SCHEMA_NAME}"."records" ("id"),
  CONSTRAINT "record_relations_user_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "record_relations_unique" UNIQUE ("source_record_id", "target_record_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."record_relations" IS 'Relaciones entre registros (ej: obra relacionada con luminaria)';

CREATE TABLE "{SCHEMA_NAME}"."record_case_links" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "record_id" UUID NOT NULL,
  "case_id" UUID NOT NULL,
  "notes" TEXT,
  "linked_by_user_id" UUID NOT NULL,
  "linked_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_case_links_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_case_links_record_fkey" FOREIGN KEY ("record_id") REFERENCES "{SCHEMA_NAME}"."records" ("id"),
  CONSTRAINT "record_case_links_case_fkey" FOREIGN KEY ("case_id") REFERENCES "{SCHEMA_NAME}"."cases" ("id"),
  CONSTRAINT "record_case_links_user_fkey" FOREIGN KEY ("linked_by_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "record_case_links_unique" UNIQUE ("record_id", "case_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."record_case_links" IS 'Vinculos entre registros y expedientes';

CREATE TABLE "{SCHEMA_NAME}"."record_document_links" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "record_id" UUID NOT NULL,
  "document_id" UUID NOT NULL,
  "field_name" VARCHAR(100),
  "notes" TEXT,
  "linked_by_user_id" UUID NOT NULL,
  "linked_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_document_links_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_document_links_record_fkey" FOREIGN KEY ("record_id") REFERENCES "{SCHEMA_NAME}"."records" ("id"),
  CONSTRAINT "record_document_links_user_fkey" FOREIGN KEY ("linked_by_user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "record_document_links_unique" UNIQUE ("record_id", "document_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."record_document_links" IS 'Vinculos entre registros y documentos (draft u oficial)';


CREATE TABLE "{SCHEMA_NAME}"."case_responsibles" (
  "id"         UUID        NOT NULL DEFAULT gen_random_uuid(),
  "case_id"    UUID        NOT NULL,
  "user_id"    UUID        NOT NULL,
  "sector_id"  UUID        NOT NULL,
  "type"       VARCHAR(20) NOT NULL CHECK ("type" IN ('ADMIN', 'ADDITIONAL')),
  "added_by"   UUID        NOT NULL,
  "added_at"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "removed_by" UUID,
  "removed_at" TIMESTAMPTZ,
  "is_active"  BOOLEAN     NOT NULL DEFAULT true,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "cr_pkey"          PRIMARY KEY ("id"),
  CONSTRAINT "cr_case_fkey"     FOREIGN KEY ("case_id")   REFERENCES "{SCHEMA_NAME}"."cases" ("id"),
  CONSTRAINT "cr_user_fkey"     FOREIGN KEY ("user_id")   REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "cr_sector_fkey"   FOREIGN KEY ("sector_id") REFERENCES "{SCHEMA_NAME}"."sectors" ("id"),
  CONSTRAINT "cr_added_by_fkey" FOREIGN KEY ("added_by")  REFERENCES "{SCHEMA_NAME}"."users" ("id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."case_responsibles" IS 'Responsables asignados a expedientes (ADMIN uno o más activos + ADDITIONAL ilimitados)';
COMMENT ON COLUMN "{SCHEMA_NAME}"."case_responsibles"."type" IS 'ADMIN = responsable principal (uno o más activos por expediente), ADDITIONAL = responsable adicional';

CREATE TABLE "{SCHEMA_NAME}"."case_favorites" (
  "id"         UUID        NOT NULL DEFAULT gen_random_uuid(),
  "user_id"    UUID        NOT NULL,
  "case_id"    UUID        NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "cf_pkey"      PRIMARY KEY ("id"),
  CONSTRAINT "cf_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id") ON DELETE CASCADE,
  CONSTRAINT "cf_case_fkey" FOREIGN KEY ("case_id") REFERENCES "{SCHEMA_NAME}"."cases" ("id") ON DELETE CASCADE,
  CONSTRAINT "cf_unique"    UNIQUE ("user_id", "case_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."case_favorites" IS 'Expedientes marcados como favoritos por cada usuario';

CREATE TABLE "{SCHEMA_NAME}"."case_user_views" (
  "user_id"      UUID        NOT NULL,
  "case_id"      UUID        NOT NULL,
  "last_seen_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "case_user_views_pkey"     PRIMARY KEY ("user_id", "case_id"),
  CONSTRAINT "case_user_views_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id") ON DELETE CASCADE,
  CONSTRAINT "case_user_views_case_fkey" FOREIGN KEY ("case_id") REFERENCES "{SCHEMA_NAME}"."cases" ("id") ON DELETE CASCADE
);

COMMENT ON TABLE "{SCHEMA_NAME}"."case_user_views" IS 'GDI-067: última vez que cada usuario abrió cada expediente (baseline de "movimientos nuevos")';

CREATE TABLE "{SCHEMA_NAME}"."notification_dismissals" (
  "id"               UUID         NOT NULL DEFAULT gen_random_uuid(),
  "user_id"          UUID         NOT NULL,
  "notification_key" VARCHAR(160) NOT NULL,
  "dismissed_at"     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  CONSTRAINT "notification_dismissals_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "notification_dismissals_user_fkey" FOREIGN KEY ("user_id") REFERENCES "{SCHEMA_NAME}"."users" ("id") ON DELETE CASCADE,
  CONSTRAINT "notification_dismissals_uq" UNIQUE ("user_id", "notification_key")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."notification_dismissals" IS 'GDI-067: dismiss manual (X) de avisos informativos (responsable/mención) por usuario';


CREATE INDEX "idx_{SCHEMA_NAME}_users_email" ON "{SCHEMA_NAME}"."users" ("email");
CREATE INDEX "idx_{SCHEMA_NAME}_users_sector" ON "{SCHEMA_NAME}"."users" ("sector_id");
CREATE INDEX "idx_{SCHEMA_NAME}_users_last_access" ON "{SCHEMA_NAME}"."users" ("last_access" DESC);

CREATE INDEX "idx_{SCHEMA_NAME}_user_sector_perms_sector" ON "{SCHEMA_NAME}"."user_sector_permissions" ("sector_id");

CREATE INDEX "idx_{SCHEMA_NAME}_document_draft_status" ON "{SCHEMA_NAME}"."document_draft" ("status");
CREATE INDEX "idx_{SCHEMA_NAME}_document_draft_created_by" ON "{SCHEMA_NAME}"."document_draft" ("created_by");
CREATE INDEX "idx_{SCHEMA_NAME}_document_draft_type" ON "{SCHEMA_NAME}"."document_draft" ("document_type_id");
CREATE INDEX "idx_{SCHEMA_NAME}_document_draft_created_by_date" ON "{SCHEMA_NAME}"."document_draft" ("created_by", "created_at" DESC);
CREATE INDEX "idx_{SCHEMA_NAME}_document_draft_resume_null" ON "{SCHEMA_NAME}"."document_draft" ("id") WHERE "resume" IS NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_document_draft_short_resume_null" ON "{SCHEMA_NAME}"."document_draft" ("id") WHERE "short_resume" IS NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_doc_signers_document" ON "{SCHEMA_NAME}"."document_signers" ("document_id");
CREATE INDEX "idx_{SCHEMA_NAME}_doc_signers_user" ON "{SCHEMA_NAME}"."document_signers" ("user_id");
CREATE INDEX "idx_{SCHEMA_NAME}_doc_signers_status" ON "{SCHEMA_NAME}"."document_signers" ("status");

CREATE INDEX "idx_{SCHEMA_NAME}_document_signers_session_id"
    ON "{SCHEMA_NAME}"."document_signers" ("signature_session_id")
    WHERE "signature_session_id" IS NOT NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_document_signers_cert_serial"
    ON "{SCHEMA_NAME}"."document_signers" ("cert_serial")
    WHERE "cert_serial" IS NOT NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_document_signers_provider"
    ON "{SCHEMA_NAME}"."document_signers" ("signed_with_provider")
    WHERE "signed_with_provider" IS NOT NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_signer_sectors" ON "{SCHEMA_NAME}"."official_documents" USING GIN ("signer_sector_ids");
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_number" ON "{SCHEMA_NAME}"."official_documents" ("official_number");
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_signed_at" ON "{SCHEMA_NAME}"."official_documents" ("signed_at" DESC);
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_department" ON "{SCHEMA_NAME}"."official_documents" ("department_id");
CREATE INDEX "idx_{SCHEMA_NAME}_official_documents_resume_null" ON "{SCHEMA_NAME}"."official_documents" ("id") WHERE "resume" IS NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_created_at" ON "{SCHEMA_NAME}"."official_documents" ("created_at" DESC);
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_doc_type" ON "{SCHEMA_NAME}"."official_documents" ("document_type_id");
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_numerator" ON "{SCHEMA_NAME}"."official_documents" ("numerator_id");
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_short_resume_null" ON "{SCHEMA_NAME}"."official_documents" ("id") WHERE "short_resume" IS NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_indexed_null" ON "{SCHEMA_NAME}"."official_documents" ("created_at" DESC) WHERE "indexed_at" IS NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_preoficial" ON "{SCHEMA_NAME}"."official_documents" ("created_at") WHERE "pdf_location" = 'preoficial';

CREATE INDEX "idx_{SCHEMA_NAME}_cases_status" ON "{SCHEMA_NAME}"."cases" ("status");
CREATE INDEX "idx_{SCHEMA_NAME}_cases_owner_dept" ON "{SCHEMA_NAME}"."cases" ("owner_department_id");
CREATE INDEX "idx_{SCHEMA_NAME}_cases_created_by" ON "{SCHEMA_NAME}"."cases" ("created_by_user_id");
CREATE INDEX "idx_{SCHEMA_NAME}_cases_owner_sector" ON "{SCHEMA_NAME}"."cases" ("owner_sector_id");
CREATE INDEX "idx_{SCHEMA_NAME}_cases_template" ON "{SCHEMA_NAME}"."cases" ("case_template_id");
CREATE INDEX "idx_{SCHEMA_NAME}_cases_last_modified" ON "{SCHEMA_NAME}"."cases" ("last_modified_at" DESC);

CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_case" ON "{SCHEMA_NAME}"."case_movements" ("case_id");
CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_assigned_sector" ON "{SCHEMA_NAME}"."case_movements" ("assigned_sector_id");
CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_case_date" ON "{SCHEMA_NAME}"."case_movements" ("case_id", "created_at" DESC);
CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_user" ON "{SCHEMA_NAME}"."case_movements" ("user_id");

CREATE INDEX "idx_{SCHEMA_NAME}_case_off_docs_case" ON "{SCHEMA_NAME}"."case_official_documents" ("case_id");
CREATE INDEX "idx_{SCHEMA_NAME}_case_off_docs_doc" ON "{SCHEMA_NAME}"."case_official_documents" ("official_document_id");

CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_admin_lookup" ON "{SCHEMA_NAME}"."case_movements" ("case_id", "type", "is_active", "closed_at" DESC)
    WHERE "type" IN ('creation', 'transfer');

CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_transfers" ON "{SCHEMA_NAME}"."case_movements" ("case_id")
    WHERE "type" = 'transfer';

CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_assigned_active" ON "{SCHEMA_NAME}"."case_movements" ("case_id", "assigned_sector_id")
    WHERE "is_active" = true AND "assigned_sector_id" IS NOT NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_cat_assignment_open" ON "{SCHEMA_NAME}"."case_assignment_tasks" ("assignment_id")
    WHERE "status" = 'open';
CREATE INDEX "idx_{SCHEMA_NAME}_cat_case_sector" ON "{SCHEMA_NAME}"."case_assignment_tasks" ("case_id", "assigned_sector_id")
    WHERE "status" = 'open';

CREATE INDEX "idx_{SCHEMA_NAME}_case_off_docs_active" ON "{SCHEMA_NAME}"."case_official_documents" ("case_id", "linking_date" DESC)
    WHERE "is_active" = true;


CREATE INDEX "idx_{SCHEMA_NAME}_cases_reference_trgm" ON "{SCHEMA_NAME}"."cases"
    USING gin (public.immutable_unaccent(LOWER("reference")) gin_trgm_ops);
CREATE INDEX "idx_{SCHEMA_NAME}_cases_number_trgm" ON "{SCHEMA_NAME}"."cases"
    USING gin (public.immutable_unaccent(LOWER("case_number")) gin_trgm_ops);

CREATE INDEX "idx_{SCHEMA_NAME}_doc_draft_reference_trgm" ON "{SCHEMA_NAME}"."document_draft"
    USING gin (public.immutable_unaccent(LOWER("reference")) gin_trgm_ops);
CREATE INDEX "idx_{SCHEMA_NAME}_official_reference_trgm" ON "{SCHEMA_NAME}"."official_documents"
    USING gin (public.immutable_unaccent(LOWER("reference")) gin_trgm_ops);
CREATE INDEX "idx_{SCHEMA_NAME}_official_number_trgm" ON "{SCHEMA_NAME}"."official_documents"
    USING gin (public.immutable_unaccent(LOWER(COALESCE("official_number", ''))) gin_trgm_ops);

CREATE INDEX "idx_{SCHEMA_NAME}_case_mov_notif_user" ON "{SCHEMA_NAME}"."case_movements"
    ("assigned_user_id", "type", "created_at" DESC)
    WHERE "is_active" = false AND "type" IN ('responsible_add', 'comment');

CREATE INDEX "idx_{SCHEMA_NAME}_cat_assigned_user_open" ON "{SCHEMA_NAME}"."case_assignment_tasks"
    ("assigned_user_id")
    WHERE "status" = 'open' AND "assigned_user_id" IS NOT NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_records_created_at" ON "{SCHEMA_NAME}"."records" ("created_at" DESC);

CREATE INDEX "idx_{SCHEMA_NAME}_cases_created_at" ON "{SCHEMA_NAME}"."cases" ("created_at" DESC);
CREATE INDEX "idx_{SCHEMA_NAME}_cases_active_created" ON "{SCHEMA_NAME}"."cases" ("created_at" DESC)
    WHERE "status" = 'active';

CREATE INDEX "idx_{SCHEMA_NAME}_doc_draft_last_modified" ON "{SCHEMA_NAME}"."document_draft" ("last_modified_at" DESC);

CREATE INDEX "idx_{SCHEMA_NAME}_doc_signers_doc_user" ON "{SCHEMA_NAME}"."document_signers" ("document_id", "user_id");

CREATE INDEX "idx_{SCHEMA_NAME}_doc_signers_user_pending" ON "{SCHEMA_NAME}"."document_signers" ("user_id")
    WHERE "status" = 'pending';
CREATE INDEX "idx_{SCHEMA_NAME}_doc_signers_doc_order_pending" ON "{SCHEMA_NAME}"."document_signers" ("document_id", "signing_order")
    WHERE "status" = 'pending';

CREATE INDEX "idx_{SCHEMA_NAME}_case_prop_docs_case" ON "{SCHEMA_NAME}"."case_proposed_documents" ("case_id");
CREATE INDEX "idx_{SCHEMA_NAME}_case_prop_docs_draft" ON "{SCHEMA_NAME}"."case_proposed_documents" ("document_draft_id");

CREATE UNIQUE INDEX "idx_{SCHEMA_NAME}_ccs_active_unique"
  ON "{SCHEMA_NAME}"."case_citizen_shares" ("case_id", "citizen_id")
  WHERE "is_active" = true;
CREATE INDEX "idx_{SCHEMA_NAME}_ccs_citizen" ON "{SCHEMA_NAME}"."case_citizen_shares" ("citizen_id") WHERE "is_active" = true;

CREATE INDEX "idx_{SCHEMA_NAME}_chunks_doc" ON "{SCHEMA_NAME}"."document_chunks" ("official_document_id");

CREATE INDEX "idx_{SCHEMA_NAME}_chunks_embedding" ON "{SCHEMA_NAME}"."document_chunks"
    USING hnsw ("embedding" halfvec_cosine_ops);

CREATE INDEX "idx_{SCHEMA_NAME}_chunks_content_tsv" ON "{SCHEMA_NAME}"."document_chunks"
    USING GIN ("content_tsv");

CREATE INDEX "idx_{SCHEMA_NAME}_notes_recipients_document" ON "{SCHEMA_NAME}"."notes_recipients" ("document_id");
CREATE INDEX "idx_{SCHEMA_NAME}_notes_recipients_sector" ON "{SCHEMA_NAME}"."notes_recipients" ("sector_id");
CREATE INDEX "idx_{SCHEMA_NAME}_notes_recipients_sender" ON "{SCHEMA_NAME}"."notes_recipients" ("sender_sector_id");
CREATE INDEX "idx_{SCHEMA_NAME}_notes_openings_document" ON "{SCHEMA_NAME}"."notes_openings" ("document_id");
CREATE INDEX "idx_{SCHEMA_NAME}_notes_openings_sector" ON "{SCHEMA_NAME}"."notes_openings" ("sector_id");
CREATE INDEX "idx_{SCHEMA_NAME}_notes_openings_doc_sector" ON "{SCHEMA_NAME}"."notes_openings" ("document_id", "sector_id");

CREATE INDEX "idx_{SCHEMA_NAME}_notes_recipients_not_archived" ON "{SCHEMA_NAME}"."notes_recipients" ("sector_id")
    WHERE is_archived = false;
CREATE INDEX "idx_{SCHEMA_NAME}_notes_recipients_archived" ON "{SCHEMA_NAME}"."notes_recipients" ("sector_id")
    WHERE is_archived = true;

CREATE INDEX "idx_{SCHEMA_NAME}_memo_recipients_document" ON "{SCHEMA_NAME}"."memo_recipients" ("document_id");
CREATE INDEX "idx_{SCHEMA_NAME}_memo_recipients_sender" ON "{SCHEMA_NAME}"."memo_recipients" ("sender_user_id");
CREATE INDEX "idx_{SCHEMA_NAME}_memo_recipients_not_archived" ON "{SCHEMA_NAME}"."memo_recipients" ("recipient_user_id")
    WHERE is_archived = false;
CREATE INDEX "idx_{SCHEMA_NAME}_memo_recipients_archived" ON "{SCHEMA_NAME}"."memo_recipients" ("recipient_user_id")
    WHERE is_archived = true;
CREATE INDEX "idx_{SCHEMA_NAME}_memo_recipients_unread" ON "{SCHEMA_NAME}"."memo_recipients" ("recipient_user_id", "document_id")
    WHERE is_archived = false AND opened_at IS NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_records_family" ON "{SCHEMA_NAME}"."records" ("registry_family_id");
CREATE INDEX "idx_{SCHEMA_NAME}_records_state" ON "{SCHEMA_NAME}"."records" ("state");
CREATE INDEX "idx_{SCHEMA_NAME}_records_created_by" ON "{SCHEMA_NAME}"."records" ("created_by_user_id");
CREATE INDEX "idx_{SCHEMA_NAME}_records_data" ON "{SCHEMA_NAME}"."records" USING GIN ("data");
CREATE INDEX "idx_{SCHEMA_NAME}_records_resume_null" ON "{SCHEMA_NAME}"."records" ("id") WHERE "resume" IS NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_records_expiration" ON "{SCHEMA_NAME}"."records" ("next_expiration")
    WHERE "next_expiration" IS NOT NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_record_history_record" ON "{SCHEMA_NAME}"."record_history" ("record_id");
CREATE INDEX "idx_{SCHEMA_NAME}_record_relations_source" ON "{SCHEMA_NAME}"."record_relations" ("source_record_id");
CREATE INDEX "idx_{SCHEMA_NAME}_record_relations_target" ON "{SCHEMA_NAME}"."record_relations" ("target_record_id");
CREATE INDEX "idx_{SCHEMA_NAME}_record_case_links_record" ON "{SCHEMA_NAME}"."record_case_links" ("record_id");
CREATE INDEX "idx_{SCHEMA_NAME}_record_doc_links_record" ON "{SCHEMA_NAME}"."record_document_links" ("record_id");
CREATE INDEX "idx_{SCHEMA_NAME}_record_doc_links_doc" ON "{SCHEMA_NAME}"."record_document_links" ("document_id");

CREATE INDEX "idx_{SCHEMA_NAME}_counters_updated_at" ON "{SCHEMA_NAME}"."document_number_counters" ("updated_at");

ALTER TABLE "{SCHEMA_NAME}"."official_documents"
  ADD CONSTRAINT "excl_{SCHEMA_NAME}_official_docs_carril_special"
  EXCLUDE USING gist (
    "document_type_id" WITH =,
    "department_id" WITH =,
    "year" WITH =,
    (COALESCE("batch_id", "id")) WITH <>
  ) WHERE (reservation_status = 'RESERVED' AND numbering_regime = 'SPECIAL');

CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_batch" ON "{SCHEMA_NAME}"."official_documents" ("batch_id") WHERE "batch_id" IS NOT NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_year_seq"
  ON "{SCHEMA_NAME}"."official_documents" ("year", "global_sequence" DESC)
  WHERE global_sequence IS NOT NULL;

CREATE UNIQUE INDEX "idx_{SCHEMA_NAME}_official_docs_unique_global_number"
  ON "{SCHEMA_NAME}"."official_documents" ("year", "global_sequence")
  WHERE reservation_status IN ('RESERVED', 'CONFIRMING', 'CONFIRMED')
    AND global_sequence IS NOT NULL;

CREATE UNIQUE INDEX "idx_{SCHEMA_NAME}_official_docs_unique_special_number"
  ON "{SCHEMA_NAME}"."official_documents" ("document_type_id", "department_id", "year", "special_number")
  WHERE reservation_status IN ('RESERVED', 'CONFIRMING', 'CONFIRMED')
    AND special_number IS NOT NULL;

CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_cancelled_global"
  ON "{SCHEMA_NAME}"."official_documents" ("year", "reserved_at")
  WHERE reservation_status = 'CANCELLED' AND numbering_regime = 'GLOBAL';

CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_cancelled_special"
  ON "{SCHEMA_NAME}"."official_documents" ("document_type_id", "department_id", "year", "reserved_at")
  WHERE reservation_status = 'CANCELLED' AND numbering_regime = 'SPECIAL';

CREATE INDEX "idx_{SCHEMA_NAME}_official_docs_reserved_at"
  ON "{SCHEMA_NAME}"."official_documents" ("reserved_at")
  WHERE reservation_status = 'RESERVED';

CREATE UNIQUE INDEX "idx_{SCHEMA_NAME}_departments_acronym_active"
  ON "{SCHEMA_NAME}"."departments" ("acronym")
  WHERE is_active = true AND acronym IS NOT NULL;
CREATE INDEX "idx_{SCHEMA_NAME}_departments_head_user_id" ON "{SCHEMA_NAME}"."departments" ("head_user_id");


CREATE INDEX "idx_{SCHEMA_NAME}_cr_admin_active"
  ON "{SCHEMA_NAME}"."case_responsibles" ("case_id")
  WHERE "type" = 'ADMIN' AND "is_active" = true;

CREATE INDEX "idx_{SCHEMA_NAME}_cr_case_active"
  ON "{SCHEMA_NAME}"."case_responsibles" ("case_id", "is_active");

CREATE INDEX "idx_{SCHEMA_NAME}_cr_user"
  ON "{SCHEMA_NAME}"."case_responsibles" ("user_id")
  WHERE "is_active" = true;

CREATE INDEX "idx_{SCHEMA_NAME}_cr_sector"
  ON "{SCHEMA_NAME}"."case_responsibles" ("sector_id")
  WHERE "is_active" = true;

CREATE INDEX "idx_{SCHEMA_NAME}_case_favorites_user"
  ON "{SCHEMA_NAME}"."case_favorites" ("user_id", "created_at" DESC);

CREATE INDEX "idx_{SCHEMA_NAME}_case_favorites_case"
  ON "{SCHEMA_NAME}"."case_favorites" ("case_id");

CREATE INDEX "idx_{SCHEMA_NAME}_case_user_views_user_seen"
  ON "{SCHEMA_NAME}"."case_user_views" ("user_id", "last_seen_at");

CREATE INDEX "idx_{SCHEMA_NAME}_departments_updated_at" ON "{SCHEMA_NAME}"."departments"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_sectors_updated_at" ON "{SCHEMA_NAME}"."sectors"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_ranks_updated_at" ON "{SCHEMA_NAME}"."ranks"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_city_seals_updated_at" ON "{SCHEMA_NAME}"."city_seals"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_users_updated_at" ON "{SCHEMA_NAME}"."users"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_user_roles_updated_at" ON "{SCHEMA_NAME}"."user_roles"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_user_seals_updated_at" ON "{SCHEMA_NAME}"."user_seals"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_user_sector_permissions_updated_at" ON "{SCHEMA_NAME}"."user_sector_permissions"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_estado_users_updated_at" ON "{SCHEMA_NAME}"."estado_users"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_document_types_updated_at" ON "{SCHEMA_NAME}"."document_types"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_document_types_allowed_by_rank_updated_at" ON "{SCHEMA_NAME}"."document_types_allowed_by_rank"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_enabled_document_types_by_sector_updated_at" ON "{SCHEMA_NAME}"."enabled_document_types_by_sector"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_cases_updated_at" ON "{SCHEMA_NAME}"."cases"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_case_movements_updated_at" ON "{SCHEMA_NAME}"."case_movements"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_case_templates_updated_at" ON "{SCHEMA_NAME}"."case_templates"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_case_template_allowed_departments_updated_at" ON "{SCHEMA_NAME}"."case_template_allowed_departments"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_case_official_documents_updated_at" ON "{SCHEMA_NAME}"."case_official_documents"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_case_proposed_documents_updated_at" ON "{SCHEMA_NAME}"."case_proposed_documents"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_official_documents_updated_at" ON "{SCHEMA_NAME}"."official_documents"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_document_signers_updated_at" ON "{SCHEMA_NAME}"."document_signers"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_document_rejections_updated_at" ON "{SCHEMA_NAME}"."document_rejections"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_notes_recipients_updated_at" ON "{SCHEMA_NAME}"."notes_recipients"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_notes_openings_updated_at" ON "{SCHEMA_NAME}"."notes_openings"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_memo_recipients_updated_at" ON "{SCHEMA_NAME}"."memo_recipients"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_registry_families_updated_at" ON "{SCHEMA_NAME}"."registry_families"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_registry_family_permissions_updated_at" ON "{SCHEMA_NAME}"."registry_family_permissions"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_records_updated_at" ON "{SCHEMA_NAME}"."records"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_record_history_updated_at" ON "{SCHEMA_NAME}"."record_history"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_record_relations_updated_at" ON "{SCHEMA_NAME}"."record_relations"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_record_case_links_updated_at" ON "{SCHEMA_NAME}"."record_case_links"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_record_document_links_updated_at" ON "{SCHEMA_NAME}"."record_document_links"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_case_responsibles_updated_at" ON "{SCHEMA_NAME}"."case_responsibles"("updated_at");
CREATE INDEX "idx_{SCHEMA_NAME}_case_favorites_updated_at" ON "{SCHEMA_NAME}"."case_favorites"("updated_at");


DROP TRIGGER IF EXISTS trg_departments_updated_at ON "{SCHEMA_NAME}"."departments";
CREATE TRIGGER trg_departments_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."departments"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_sectors_updated_at ON "{SCHEMA_NAME}"."sectors";
CREATE TRIGGER trg_sectors_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."sectors"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_users_updated_at ON "{SCHEMA_NAME}"."users";
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."users"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_user_roles_updated_at ON "{SCHEMA_NAME}"."user_roles";
CREATE TRIGGER trg_user_roles_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."user_roles"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_user_seals_updated_at ON "{SCHEMA_NAME}"."user_seals";
CREATE TRIGGER trg_user_seals_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."user_seals"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_user_sector_permissions_updated_at ON "{SCHEMA_NAME}"."user_sector_permissions";
CREATE TRIGGER trg_user_sector_permissions_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."user_sector_permissions"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_estado_users_updated_at ON "{SCHEMA_NAME}"."estado_users";
CREATE TRIGGER trg_estado_users_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."estado_users"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_ranks_updated_at ON "{SCHEMA_NAME}"."ranks";
CREATE TRIGGER trg_ranks_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."ranks"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_city_seals_updated_at ON "{SCHEMA_NAME}"."city_seals";
CREATE TRIGGER trg_city_seals_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."city_seals"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_types_updated_at ON "{SCHEMA_NAME}"."document_types";
CREATE TRIGGER trg_document_types_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."document_types"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_types_allowed_by_rank_updated_at ON "{SCHEMA_NAME}"."document_types_allowed_by_rank";
CREATE TRIGGER trg_document_types_allowed_by_rank_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."document_types_allowed_by_rank"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_enabled_document_types_by_sector_updated_at ON "{SCHEMA_NAME}"."enabled_document_types_by_sector";
CREATE TRIGGER trg_enabled_document_types_by_sector_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."enabled_document_types_by_sector"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_draft_updated_at ON "{SCHEMA_NAME}"."document_draft";
CREATE TRIGGER trg_document_draft_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."document_draft"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_signers_updated_at ON "{SCHEMA_NAME}"."document_signers";
CREATE TRIGGER trg_document_signers_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."document_signers"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_rejections_updated_at ON "{SCHEMA_NAME}"."document_rejections";
CREATE TRIGGER trg_document_rejections_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."document_rejections"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_official_documents_updated_at ON "{SCHEMA_NAME}"."official_documents";
CREATE TRIGGER trg_official_documents_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."official_documents"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_number_counters_updated_at ON "{SCHEMA_NAME}"."document_number_counters";
CREATE TRIGGER "trg_document_number_counters_updated_at"
  BEFORE UPDATE ON "{SCHEMA_NAME}"."document_number_counters"
  FOR EACH ROW EXECUTE FUNCTION "public"."fn_set_updated_at"();

DROP TRIGGER IF EXISTS trg_case_templates_updated_at ON "{SCHEMA_NAME}"."case_templates";
CREATE TRIGGER trg_case_templates_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."case_templates"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_case_template_allowed_departments_updated_at ON "{SCHEMA_NAME}"."case_template_allowed_departments";
CREATE TRIGGER trg_case_template_allowed_departments_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."case_template_allowed_departments"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_cases_updated_at ON "{SCHEMA_NAME}"."cases";
CREATE TRIGGER trg_cases_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."cases"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_case_movements_updated_at ON "{SCHEMA_NAME}"."case_movements";
CREATE TRIGGER trg_case_movements_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."case_movements"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_case_official_documents_updated_at ON "{SCHEMA_NAME}"."case_official_documents";
CREATE TRIGGER trg_case_official_documents_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."case_official_documents"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_case_proposed_documents_updated_at ON "{SCHEMA_NAME}"."case_proposed_documents";
CREATE TRIGGER trg_case_proposed_documents_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."case_proposed_documents"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

CREATE OR REPLACE FUNCTION "{SCHEMA_NAME}"."fn_update_case_last_modified"()
RETURNS TRIGGER AS $$
DECLARE
    v_schema  TEXT := TG_TABLE_SCHEMA;
    v_case_id UUID;
    v_ts      TIMESTAMPTZ;
BEGIN
    IF TG_TABLE_NAME = 'case_movements' THEN
        v_case_id := NEW.case_id;
        v_ts := NEW.created_at;
    ELSIF TG_TABLE_NAME = 'case_official_documents' THEN
        IF NOT NEW.is_active THEN
            RETURN NEW;
        END IF;
        v_case_id := NEW.case_id;
        v_ts := NEW.linking_date;
    ELSE
        RETURN NEW;
    END IF;

    EXECUTE format(
        'UPDATE %I.cases SET last_modified_at = GREATEST(last_modified_at, $1) WHERE id = $2 AND last_modified_at < $1',
        v_schema
    ) USING v_ts, v_case_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_case_movements_last_modified ON "{SCHEMA_NAME}"."case_movements";
CREATE TRIGGER trg_case_movements_last_modified
    AFTER INSERT ON "{SCHEMA_NAME}"."case_movements"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}"."fn_update_case_last_modified"();

DROP TRIGGER IF EXISTS trg_case_official_documents_last_modified ON "{SCHEMA_NAME}"."case_official_documents";
CREATE TRIGGER trg_case_official_documents_last_modified
    AFTER INSERT ON "{SCHEMA_NAME}"."case_official_documents"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}"."fn_update_case_last_modified"();

DROP TRIGGER IF EXISTS trg_settings_updated_at ON "{SCHEMA_NAME}"."settings";
CREATE TRIGGER trg_settings_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."settings"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_chunks_updated_at ON "{SCHEMA_NAME}"."document_chunks";
CREATE TRIGGER trg_document_chunks_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."document_chunks"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_notes_recipients_updated_at ON "{SCHEMA_NAME}"."notes_recipients";
CREATE TRIGGER trg_notes_recipients_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."notes_recipients"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_notes_openings_updated_at ON "{SCHEMA_NAME}"."notes_openings";
CREATE TRIGGER trg_notes_openings_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."notes_openings"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_memo_recipients_updated_at ON "{SCHEMA_NAME}"."memo_recipients";
CREATE TRIGGER trg_memo_recipients_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."memo_recipients"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_registry_families_updated_at ON "{SCHEMA_NAME}"."registry_families";
CREATE TRIGGER trg_registry_families_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."registry_families"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_registry_family_permissions_updated_at ON "{SCHEMA_NAME}"."registry_family_permissions";
CREATE TRIGGER trg_registry_family_permissions_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."registry_family_permissions"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_records_updated_at ON "{SCHEMA_NAME}"."records";
CREATE TRIGGER trg_records_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."records"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_record_history_updated_at ON "{SCHEMA_NAME}"."record_history";
CREATE TRIGGER trg_record_history_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."record_history"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_record_relations_updated_at ON "{SCHEMA_NAME}"."record_relations";
CREATE TRIGGER trg_record_relations_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."record_relations"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_record_case_links_updated_at ON "{SCHEMA_NAME}"."record_case_links";
CREATE TRIGGER trg_record_case_links_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."record_case_links"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_record_document_links_updated_at ON "{SCHEMA_NAME}"."record_document_links";
CREATE TRIGGER trg_record_document_links_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."record_document_links"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_case_responsibles_updated_at ON "{SCHEMA_NAME}"."case_responsibles";
CREATE TRIGGER trg_case_responsibles_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."case_responsibles"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_case_favorites_updated_at ON "{SCHEMA_NAME}"."case_favorites";
CREATE TRIGGER trg_case_favorites_updated_at BEFORE UPDATE ON "{SCHEMA_NAME}"."case_favorites"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


CREATE TABLE "{SCHEMA_NAME}"."document_type_fields" (
  "id"                UUID        NOT NULL DEFAULT gen_random_uuid(),
  "document_type_id"  INT         NOT NULL,
  "field_definitions" JSONB       NOT NULL DEFAULT '[]'::jsonb,
  "created_by"        UUID        NOT NULL,
  "created_at"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "dtf_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "dtf_document_type_fkey" FOREIGN KEY ("document_type_id")
      REFERENCES "{SCHEMA_NAME}"."document_types" ("id"),
  CONSTRAINT "dtf_created_by_fkey" FOREIGN KEY ("created_by")
      REFERENCES "{SCHEMA_NAME}"."users" ("id"),
  CONSTRAINT "dtf_document_type_unique" UNIQUE ("document_type_id")
);

COMMENT ON TABLE "{SCHEMA_NAME}"."document_type_fields" IS 'Definición de campos de formularios controlados (FFCC). Una fila por tipo de documento. field_definitions es array JSONB con los campos del formulario.';

CREATE INDEX "idx_{SCHEMA_NAME}_document_type_fields_updated_at"
    ON "{SCHEMA_NAME}"."document_type_fields" ("updated_at");

CREATE INDEX "idx_{SCHEMA_NAME}_dtf_created_by"
    ON "{SCHEMA_NAME}"."document_type_fields" ("created_by");

DROP TRIGGER IF EXISTS trg_dtf_updated_at ON "{SCHEMA_NAME}"."document_type_fields";
CREATE TRIGGER trg_dtf_updated_at
    BEFORE UPDATE ON "{SCHEMA_NAME}"."document_type_fields"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


CREATE OR REPLACE FUNCTION "{SCHEMA_NAME}"."fn_sync_user_registry"()
RETURNS TRIGGER AS $$
DECLARE
    v_schema_name TEXT := TG_TABLE_SCHEMA;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Insertar en user_registry (display_name y profile_picture_url se obtienen de otras tablas)
        INSERT INTO public.user_registry (email, schema_name, is_default)
        VALUES (NEW.email, v_schema_name, false)
        ON CONFLICT (email, schema_name) DO NOTHING;
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Si cambio el email, actualizar en user_registry
        IF OLD.email IS DISTINCT FROM NEW.email THEN
            UPDATE public.user_registry
            SET email = NEW.email
            WHERE email = OLD.email AND schema_name = v_schema_name;
        END IF;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- Eliminar de user_registry
        DELETE FROM public.user_registry
        WHERE email = OLD.email AND schema_name = v_schema_name;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "trg_sync_user_registry"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."users"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}"."fn_sync_user_registry"();


DO $$
BEGIN
    IF '{SCHEMA_NAME}_audit' = ANY(ARRAY[
        'public', 'information_schema', 'pg_catalog', 'pg_toast',
        -- Idem SECCION 1: los _audit de esta instalacion.
        '100_example_audit', '101_example_audit'
    ]) THEN
        RAISE EXCEPTION
            'ABORTADO: el schema "%" esta en la lista de schemas protegidos. '
            'Edita manualmente la lista en 03-create-municipio.sql si es intencional.',
            '{SCHEMA_NAME}_audit';
    END IF;
END;
$$;

DROP SCHEMA IF EXISTS "{SCHEMA_NAME}_audit" CASCADE;

CREATE SCHEMA "{SCHEMA_NAME}_audit";


CREATE TABLE "{SCHEMA_NAME}_audit"."audit_log" (
  "id" BIGSERIAL NOT NULL,
  "event_time" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "schema_name" TEXT NOT NULL,
  "table_name" TEXT NOT NULL,
  "operation" TEXT NOT NULL,
  "user_name" TEXT,
  "user_id" UUID,
  "auth_source" VARCHAR(20),
  "old_row" JSONB,
  "new_row" JSONB,
  "changed_fields" TEXT[],
  CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

COMMENT ON TABLE "{SCHEMA_NAME}_audit"."audit_log" IS 'Registro de auditoria del municipio';

CREATE INDEX "idx_{SCHEMA_NAME}_audit_audit_log_event_time" ON "{SCHEMA_NAME}_audit"."audit_log" ("event_time");
CREATE INDEX "idx_{SCHEMA_NAME}_audit_audit_log_table" ON "{SCHEMA_NAME}_audit"."audit_log" ("table_name");
CREATE INDEX "idx_{SCHEMA_NAME}_audit_audit_log_user" ON "{SCHEMA_NAME}_audit"."audit_log" ("user_id");


CREATE OR REPLACE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"()
RETURNS TRIGGER AS $$
DECLARE
    v_old_row JSONB := NULL;
    v_new_row JSONB := NULL;
    v_changed_fields TEXT[] := '{}';
    v_key TEXT;
    v_user_id UUID := NULL;
    v_auth_source VARCHAR(20) := NULL;
BEGIN
    -- Leer contexto de aplicación (inyectado via GUC por el backend)
    -- current_setting(..., true) retorna NULL si no existe en lugar de error
    BEGIN
        v_user_id := NULLIF(current_setting('app.user_id', true), '')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    BEGIN
        v_auth_source := NULLIF(current_setting('app.auth_source', true), '');
    EXCEPTION WHEN OTHERS THEN
        v_auth_source := NULL;
    END;

    IF TG_OP = 'INSERT' THEN
        v_new_row := to_jsonb(NEW);

        INSERT INTO "{SCHEMA_NAME}_audit".audit_log(
            schema_name, table_name, operation, user_name, user_id, auth_source, new_row
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, v_user_id, v_auth_source, v_new_row
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        v_old_row := to_jsonb(OLD);
        v_new_row := to_jsonb(NEW);

        -- Detectar campos cambiados
        FOR v_key IN SELECT jsonb_object_keys(v_new_row)
        LOOP
            IF v_old_row->v_key IS DISTINCT FROM v_new_row->v_key THEN
                v_changed_fields := array_append(v_changed_fields, v_key);
            END IF;
        END LOOP;

        INSERT INTO "{SCHEMA_NAME}_audit".audit_log(
            schema_name, table_name, operation, user_name, user_id, auth_source, old_row, new_row, changed_fields
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, v_user_id, v_auth_source, v_old_row, v_new_row, v_changed_fields
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        v_old_row := to_jsonb(OLD);

        INSERT INTO "{SCHEMA_NAME}_audit".audit_log(
            schema_name, table_name, operation, user_name, user_id, auth_source, old_row
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, v_user_id, v_auth_source, v_old_row
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS "trg_audit_users" ON "{SCHEMA_NAME}"."users";
CREATE TRIGGER "trg_audit_users"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."users"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_departments" ON "{SCHEMA_NAME}"."departments";
CREATE TRIGGER "trg_audit_departments"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."departments"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_sectors" ON "{SCHEMA_NAME}"."sectors";
CREATE TRIGGER "trg_audit_sectors"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."sectors"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_official_documents" ON "{SCHEMA_NAME}"."official_documents";
CREATE TRIGGER "trg_audit_official_documents"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."official_documents"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_cases" ON "{SCHEMA_NAME}"."cases";
CREATE TRIGGER "trg_audit_cases"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."cases"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_case_movements" ON "{SCHEMA_NAME}"."case_movements";
CREATE TRIGGER "trg_audit_case_movements"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."case_movements"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_case_assignment_tasks" ON "{SCHEMA_NAME}"."case_assignment_tasks";
CREATE TRIGGER "trg_audit_case_assignment_tasks"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."case_assignment_tasks"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_case_official_documents" ON "{SCHEMA_NAME}"."case_official_documents";
CREATE TRIGGER "trg_audit_case_official_documents"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."case_official_documents"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_citizens" ON "{SCHEMA_NAME}"."citizens";
CREATE TRIGGER "trg_audit_citizens"
    AFTER INSERT OR UPDATE OR DELETE ON "{SCHEMA_NAME}"."citizens"
    FOR EACH ROW EXECUTE FUNCTION "{SCHEMA_NAME}_audit"."fn_log_change"();


INSERT INTO "{SCHEMA_NAME}"."settings" (
    "timezone",
    "bucket_oficial",
    "bucket_tosign",
    "bucket_edicion",
    "bucket_publico",
    "bucket_preoficial",
    "city",
    "primary_color"
) VALUES (
    'America/Argentina/Buenos_Aires',
    '{BUCKET_OFICIAL}',
    '{BUCKET_TOSIGN}',
    '{BUCKET_TOSIGN}',
    '{BUCKET_PUBLICO}',
    '{BUCKET_PREOFICIAL}',
    '{CITY}',
    '{PRIMARY_COLOR}'
);


INSERT INTO "{SCHEMA_NAME}"."users"
    (id, auth_id, auth_method, email, full_name, sector_id, estado, created_at, updated_at)
VALUES
    ('00000000-0000-0000-0000-000074657374', NULL, 'social', 'test@example.com',
     'Testing User', NULL, 1, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "{SCHEMA_NAME}"."user_roles" (user_id, role_id, created_at, updated_at)
VALUES
    ('00000000-0000-0000-0000-000074657374',
     'a0000000-0000-0000-0000-000000000004',
     NOW(), NOW())
ON CONFLICT ON CONSTRAINT "user_roles_unique" DO NOTHING;


INSERT INTO "{SCHEMA_NAME}"."estado_users" ("id", "estado") VALUES
(1, 'Activo'),
(2, 'Inactivo'),
(3, 'Suspendido'),
(4, 'Pendiente'),
(5, 'Archivado');


INSERT INTO "{SCHEMA_NAME}"."document_types"
    ("global_document_type_id", "name", "acronym", "description", "signature_policy", "is_active", "type", "trust")
SELECT
    'd0000000-0000-0000-0000-000000000080'::uuid,
    'Informe RLM',
    'IFRLM',
    'Informe de Registro Legajo Multiproposito (generado on-demand desde un legajo RLM)',
    'electronic',
    true,
    'HTML',
    true
WHERE NOT EXISTS (
    SELECT 1 FROM "{SCHEMA_NAME}"."document_types"
    WHERE acronym = 'IFRLM'
);

INSERT INTO "{SCHEMA_NAME}"."document_types"
    ("global_document_type_id", "name", "acronym", "description",
     "signature_policy", "is_active", "type", "trust", "special_numbering")
VALUES
    ('d0000000-0000-0000-0000-000000000042'::uuid,
     'Testing',
     'TST',
     'Documento generado automaticamente cuando una firma falla (Uso exclusivo del sistema)',
     'electronic',
     true,
     'HTML',
     true,
     false)
ON CONFLICT ON CONSTRAINT "document_types_acronym_unique" DO NOTHING;


INSERT INTO "public"."municipalities"
("id", "name", "acronym", "country", "schema_number", "schema_name", "is_active")
VALUES
(
    gen_random_uuid(),
    '{MUNICIPALITY_NAME}',
    '{ACRONYM}',
    '{COUNTRY}',
    {SCHEMA_NUMBER},
    '{SCHEMA_NAME}',
    true
);


DO $$
DECLARE
    v_dept_id UUID;
    v_sector_id UUID;
BEGIN
    -- Crear departamento root
    INSERT INTO "{SCHEMA_NAME}"."departments"
    ("id", "name", "acronym", "is_active")
    VALUES
    (
        gen_random_uuid(),
        'Root Department',
        'ROOT',
        true
    );

    -- Obtener el ID del departamento creado
    SELECT id INTO v_dept_id FROM "{SCHEMA_NAME}"."departments"
    WHERE acronym = 'ROOT' LIMIT 1;

    -- Crear sector PRIV del ROOT (GDI-130: case_templates.filing_sector_id es
    -- NOT NULL desde el día 1; en tenants reales lo crea la migración 076
    -- para cada departamento, acá lo adelantamos para el ROOT porque los
    -- case_templates base se crean en este mismo script, antes del onboarding
    -- de BackOffice que crea el resto de sectores).
    INSERT INTO "{SCHEMA_NAME}"."sectors"
    ("id", "department_id", "acronym", "is_active")
    VALUES
    (
        gen_random_uuid(),
        v_dept_id,
        'PRIV',
        true
    );

    SELECT id INTO v_sector_id FROM "{SCHEMA_NAME}"."sectors"
    WHERE department_id = v_dept_id AND acronym = 'PRIV' LIMIT 1;

    -- Crear case_templates base (EEVAR + ECAPA)
    INSERT INTO "{SCHEMA_NAME}"."case_templates"
    ("id", "global_case_template_id", "type_name", "acronym", "description", "creation_channel", "filing_department_id", "filing_sector_id", "is_active")
    VALUES
    (
        gen_random_uuid(),
        'b0000000-0000-0000-0000-000000000001'::uuid,
        'Expediente Varios',
        'EEVAR',
        'Expediente para temas varios',
        'web',
        v_dept_id,
        v_sector_id,
        true
    ),
    (
        gen_random_uuid(),
        'b0000000-0000-0000-0000-000000000004'::uuid,
        'Expediente de Capacitacion',
        'ECAPA',
        'Expediente de Capacitacion',
        'web',
        v_dept_id,
        v_sector_id,
        true
    );

    RAISE NOTICE 'Departamento root (+ sector PRIV) y case_templates creados exitosamente';
END $$;

INSERT INTO "{SCHEMA_NAME}"."departments"
("id", "name", "acronym", "is_active", "is_system")
SELECT
    gen_random_uuid(),
    'Tramites a Distancia',
    'TAD',
    true,
    true
WHERE NOT EXISTS (
    SELECT 1 FROM "{SCHEMA_NAME}"."departments" WHERE "acronym" = 'TAD'
);


DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'MUNICIPIO {SCHEMA_NAME} CREADO EXITOSAMENTE';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'SCHEMA MUNICIPIO:';
    RAISE NOTICE '  Tablas: 38 (Grupos A-J: +case_responsibles +case_favorites +case_assignment_tasks +case_user_views +notification_dismissals GDI-067)';
    RAISE NOTICE '  Indices: 55 (Performance + Vectorial + Grupo J + 2 parciales cat + case_user_views)';
    RAISE NOTICE '  Triggers: 34 (33 updated_at + 1 sync user_registry)';
    RAISE NOTICE '';
    RAISE NOTICE 'SCHEMA AUDIT:';
    RAISE NOTICE '  Tabla: audit_log (con auth_source para trazabilidad)';
    RAISE NOTICE '  Funcion: fn_log_change';
    RAISE NOTICE '  Triggers: 7 (departments, sectors, official_documents, cases, case_movements, case_assignment_tasks, case_official_documents)';
    RAISE NOTICE '';
    RAISE NOTICE 'DATOS INICIALES:';
    RAISE NOTICE '  Settings: 1 (con buckets Cloudflare)';
    RAISE NOTICE '  Estado Users: 4 (Activo, Inactivo, Suspendido, Pendiente)';
    RAISE NOTICE '  Municipio: {MUNICIPALITY_NAME} registrado en public.municipalities';
    RAISE NOTICE '  Departamento: ROOT creado';
    RAISE NOTICE '  Departamento de sistema: TAD creado (GDI-130, is_system=true, oculto de UI)';
    RAISE NOTICE '  Case Templates: 2 (EEVAR, ECAPA)';
    RAISE NOTICE '';
    RAISE NOTICE 'MUNICIPIO LISTO PARA USAR';
    RAISE NOTICE '============================================================';
END $$;
