

DROP SCHEMA IF EXISTS "100_test" CASCADE;

CREATE SCHEMA "100_test";


CREATE TABLE "100_test"."departments" (
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
  CONSTRAINT "departments_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "departments_parent_fkey" FOREIGN KEY ("parent_id") REFERENCES "100_test"."departments" ("id")
);

CREATE TABLE "100_test"."sectors" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "department_id" UUID NOT NULL,
  "acronym" VARCHAR(10) NOT NULL,
  "primary_color" VARCHAR(7),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "start_date" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "end_date" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "sectors_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sectors_department_fkey" FOREIGN KEY ("department_id") REFERENCES "100_test"."departments" ("id"),
  CONSTRAINT "sectors_acronym_unique" UNIQUE ("department_id", "acronym")
);


CREATE TABLE "100_test"."users" (
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
  CONSTRAINT "users_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "users_email_unique" UNIQUE ("email"),
  CONSTRAINT "users_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id")
);

CREATE TABLE "100_test"."user_roles" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "role_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_roles_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "user_roles_role_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles" ("role_id"),
  CONSTRAINT "user_roles_unique" UNIQUE ("user_id", "role_id")
);

CREATE TABLE "100_test"."user_seals" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "city_seal_id" INT NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_seals_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_seals_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "user_seals_user_unique" UNIQUE ("user_id")
);

CREATE TABLE "100_test"."user_sector_permissions" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "can_view" BOOLEAN NOT NULL DEFAULT true,
  "can_edit" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_sector_permissions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_sector_permissions_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "user_sector_permissions_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "user_sector_permissions_unique" UNIQUE ("user_id", "sector_id")
);

CREATE TABLE "100_test"."estado_users" (
  "id" SERIAL NOT NULL,
  "estado" VARCHAR(50) NOT NULL,
  CONSTRAINT "estado_users_pkey" PRIMARY KEY ("id")
);


CREATE TABLE "100_test"."ranks" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "name" VARCHAR(50) NOT NULL,
  "level" INT NOT NULL,
  "head_signature" VARCHAR(100),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "ranks_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "ranks_name_unique" UNIQUE ("name"),
  CONSTRAINT "ranks_level_unique" UNIQUE ("level")
);

COMMENT ON TABLE "100_test"."ranks" IS 'Jerarquias del municipio (per-tenant)';
COMMENT ON COLUMN "100_test"."ranks"."level" IS '1 = mas alto (Intendente), numeros mayores = menor jerarquia';

CREATE TABLE "100_test"."city_seals" (
  "id" SERIAL NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "rank_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "city_seals_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "city_seals_name_unique" UNIQUE ("name"),
  CONSTRAINT "city_seals_rank_fkey" FOREIGN KEY ("rank_id") REFERENCES "100_test"."ranks" ("id")
);

COMMENT ON TABLE "100_test"."city_seals" IS 'Sellos del municipio. rank_id NULL = generico';
COMMENT ON COLUMN "100_test"."city_seals"."rank_id" IS 'Si NOT NULL, el usuario con este sello tiene ese rango jerarquico';

ALTER TABLE "100_test"."departments"
  ADD CONSTRAINT "departments_rank_fkey" FOREIGN KEY ("rank_id") REFERENCES "100_test"."ranks" ("id");
ALTER TABLE "100_test"."user_seals"
  ADD CONSTRAINT "user_seals_seal_fkey" FOREIGN KEY ("city_seal_id") REFERENCES "100_test"."city_seals" ("id");


CREATE TABLE "100_test"."document_types" (
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
  CONSTRAINT "document_types_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_types_acronym_unique" UNIQUE ("acronym"),
  CONSTRAINT "document_types_signature_policy_chk" CHECK (signature_policy IN ('electronic','digital_all','digital_num')),
  CONSTRAINT "document_types_visibility_chk" CHECK (visibility IN ('interno','reservado','publico')),
  CONSTRAINT "document_types_global_fkey" FOREIGN KEY ("global_document_type_id") REFERENCES "public"."global_document_types" ("id")
);

CREATE TABLE "100_test"."document_types_allowed_by_rank" (
  "id" SERIAL NOT NULL,
  "document_type_id" INT NOT NULL,
  "rank_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_types_allowed_by_rank_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "dtabr_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "100_test"."document_types" ("id"),
  CONSTRAINT "dtabr_rank_fkey" FOREIGN KEY ("rank_id") REFERENCES "100_test"."ranks" ("id"),
  CONSTRAINT "dtabr_unique" UNIQUE ("document_type_id", "rank_id")
);

CREATE TABLE "100_test"."enabled_document_types_by_sector" (
  "id" SERIAL NOT NULL,
  "document_type_id" INT NOT NULL,
  "sector_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "enabled_edts_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "enabled_edts_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "100_test"."document_types" ("id"),
  CONSTRAINT "enabled_edts_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "enabled_edts_unique" UNIQUE ("document_type_id", "sector_id")
);

CREATE TABLE "100_test"."citizens" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "full_name" VARCHAR(255) NOT NULL,
  "country_id" VARCHAR(20) NOT NULL,
  "estado" VARCHAR(10) NOT NULL DEFAULT 'pendiente',
  "validated_at" TIMESTAMPTZ,
  "validated_by" VARCHAR(50),
  "created_via" VARCHAR(10),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "citizens_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "citizens_country_id_unique" UNIQUE ("country_id"),
  CONSTRAINT "citizens_estado_chk" CHECK ("estado" IN ('pendiente','validado','bloqueado')),
  CONSTRAINT "citizens_created_via_chk" CHECK ("created_via" IN ('api','backoffice'))
);

CREATE TABLE "100_test"."document_draft" (
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
  CONSTRAINT "document_draft_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_draft_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "document_draft_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "document_draft_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "100_test"."document_types" ("id"),
  CONSTRAINT "document_draft_creator_chk" CHECK (num_nonnulls("created_by", "created_by_citizen") = 1)
);

CREATE TABLE "100_test"."document_signers" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "user_id" UUID,
  "citizen_id" UUID,
  "is_numerator" BOOLEAN NOT NULL DEFAULT false,
  "signing_order" INT,
  "status" "public"."document_signer_status" NOT NULL DEFAULT 'pending',
  "signed_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_signers_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_signers_document_fkey" FOREIGN KEY ("document_id") REFERENCES "100_test"."document_draft" ("id"),
  CONSTRAINT "document_signers_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "document_signers_citizen_fkey" FOREIGN KEY ("citizen_id") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "document_signers_actor_chk" CHECK (num_nonnulls("user_id", "citizen_id") = 1)
);

CREATE TABLE "100_test"."document_rejections" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "rejected_by" UUID NOT NULL,
  "reason" TEXT,
  "rejected_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_rejections_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_rejections_document_fkey" FOREIGN KEY ("document_id") REFERENCES "100_test"."document_draft" ("id"),
  CONSTRAINT "document_rejections_user_fkey" FOREIGN KEY ("rejected_by") REFERENCES "100_test"."users" ("id")
);

CREATE TABLE "100_test"."document_draft_embedded_files" (
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
  CONSTRAINT "ddef_document_fkey" FOREIGN KEY ("document_id") REFERENCES "100_test"."document_draft" ("id") ON DELETE CASCADE,
  CONSTRAINT "ddef_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "ddef_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "ddef_creator_chk" CHECK (NOT ("created_by" IS NOT NULL AND "created_by_citizen" IS NOT NULL))
);
CREATE INDEX "idx_document_draft_embedded_files_document" ON "100_test"."document_draft_embedded_files" ("document_id");

CREATE TABLE "100_test"."official_documents" (
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
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "official_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "official_documents_document_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "100_test"."document_types" ("id"),
  CONSTRAINT "official_documents_department_fkey" FOREIGN KEY ("department_id") REFERENCES "100_test"."departments" ("id"),
  CONSTRAINT "official_documents_numerator_fkey" FOREIGN KEY ("numerator_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "official_documents_numerator_citizen_fkey" FOREIGN KEY ("numerator_citizen") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "official_documents_numerator_chk" CHECK (num_nonnulls("numerator_id", "numerator_citizen") = 1),
  CONSTRAINT "official_documents_numbering_regime_check" CHECK (numbering_regime IN ('GLOBAL', 'SPECIAL')),
  CONSTRAINT "official_documents_reservation_status_check" CHECK (reservation_status IN ('RESERVED', 'CONFIRMED', 'CANCELLED'))
);

CREATE TABLE "100_test"."official_document_embedded_files" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "official_document_id" UUID NOT NULL,
  "file_name" VARCHAR(255) NOT NULL,
  "file_size" BIGINT NOT NULL,
  "extension" VARCHAR(16) NOT NULL,
  "created_by" UUID,
  "created_by_citizen" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "official_document_embedded_files_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "odef_official_document_fkey" FOREIGN KEY ("official_document_id") REFERENCES "100_test"."official_documents" ("id") ON DELETE CASCADE,
  CONSTRAINT "odef_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "odef_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "odef_creator_chk" CHECK (NOT ("created_by" IS NOT NULL AND "created_by_citizen" IS NOT NULL))
);
CREATE INDEX "idx_official_document_embedded_files_official" ON "100_test"."official_document_embedded_files" ("official_document_id");

CREATE TABLE "100_test"."document_number_counters" (
  "document_type_id" INT NOT NULL,
  "year" SMALLINT NOT NULL,
  "department_id" UUID NOT NULL,
  "last_number" INT NOT NULL DEFAULT 0,
  "active_reservation_document_id" UUID NULL,
  "active_reservation_batch_id" UUID NULL,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_number_counters_pkey" PRIMARY KEY ("document_type_id", "year", "department_id"),
  CONSTRAINT "document_number_counters_doc_type_fkey" FOREIGN KEY ("document_type_id") REFERENCES "100_test"."document_types" ("id"),
  CONSTRAINT "document_number_counters_department_fkey" FOREIGN KEY ("department_id") REFERENCES "100_test"."departments" ("id")
);


CREATE TABLE "100_test"."case_templates" (
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
  CONSTRAINT "case_templates_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "case_templates_acronym_unique" UNIQUE ("acronym"),
  CONSTRAINT "case_templates_visibility_chk" CHECK (visibility IN ('interno','reservado')),
  CONSTRAINT "case_templates_global_fkey" FOREIGN KEY ("global_case_template_id") REFERENCES "public"."global_case_templates" ("id"),
  CONSTRAINT "case_templates_department_fkey" FOREIGN KEY ("filing_department_id") REFERENCES "100_test"."departments" ("id"),
  CONSTRAINT "case_templates_sector_fkey" FOREIGN KEY ("filing_sector_id") REFERENCES "100_test"."sectors" ("id")
);

CREATE TABLE "100_test"."case_template_allowed_departments" (
  "case_template_id" UUID NOT NULL,
  "department_id" UUID NOT NULL,
  CONSTRAINT "ctad_pkey" PRIMARY KEY ("case_template_id", "department_id"),
  CONSTRAINT "ctad_case_template_fkey" FOREIGN KEY ("case_template_id") REFERENCES "100_test"."case_templates" ("id"),
  CONSTRAINT "ctad_department_fkey" FOREIGN KEY ("department_id") REFERENCES "100_test"."departments" ("id")
);

CREATE TABLE "100_test"."cases" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "case_number" VARCHAR(50) NOT NULL,
  "reference" VARCHAR(250) NOT NULL,
  "status" "public"."status_case" NOT NULL DEFAULT 'inactive',
  "case_template_id" UUID NOT NULL,
  "created_by_user_id" UUID,
  "created_by_citizen" UUID,
  "owner_department_id" UUID NOT NULL,
  "owner_sector_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "ai_summary" TEXT,
  "short_ai_summary" TEXT,
  "ai_summary_updated_at" TIMESTAMPTZ,
  CONSTRAINT "cases_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cases_number_unique" UNIQUE ("case_number"),
  CONSTRAINT "cases_template_fkey" FOREIGN KEY ("case_template_id") REFERENCES "100_test"."case_templates" ("id"),
  CONSTRAINT "cases_created_by_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "cases_created_by_citizen_fkey" FOREIGN KEY ("created_by_citizen") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "cases_department_fkey" FOREIGN KEY ("owner_department_id") REFERENCES "100_test"."departments" ("id"),
  CONSTRAINT "cases_sector_fkey" FOREIGN KEY ("owner_sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "cases_creator_chk" CHECK (num_nonnulls("created_by_user_id", "created_by_citizen") = 1)
);

CREATE TABLE "100_test"."case_movements" (
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
  CONSTRAINT "case_movements_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "case_movements_case_fkey" FOREIGN KEY ("case_id") REFERENCES "100_test"."cases" ("id"),
  CONSTRAINT "case_movements_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "case_movements_citizen_fkey" FOREIGN KEY ("citizen_id") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "case_movements_creator_sector_fkey" FOREIGN KEY ("creator_sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "case_movements_admin_sector_fkey" FOREIGN KEY ("admin_sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "case_movements_actor_chk" CHECK (NOT ("user_id" IS NOT NULL AND "citizen_id" IS NOT NULL))
);

CREATE TABLE "100_test"."case_official_documents" (
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
  CONSTRAINT "case_official_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cod_case_fkey" FOREIGN KEY ("case_id") REFERENCES "100_test"."cases" ("id"),
  CONSTRAINT "cod_official_document_fkey" FOREIGN KEY ("official_document_id") REFERENCES "100_test"."official_documents" ("id"),
  CONSTRAINT "cod_linking_user_fkey" FOREIGN KEY ("linking_user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "cod_linking_citizen_fkey" FOREIGN KEY ("linking_citizen") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "cod_linking_actor_chk" CHECK (num_nonnulls("linking_user_id", "linking_citizen") = 1)
);

CREATE TABLE "100_test"."case_proposed_documents" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "case_id" UUID NOT NULL,
  "document_draft_id" UUID NOT NULL,
  "proposing_user_id" UUID,
  "proposing_citizen_id" UUID,
  "proposing_date" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "case_proposed_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cpd_case_fkey" FOREIGN KEY ("case_id") REFERENCES "100_test"."cases" ("id"),
  CONSTRAINT "cpd_document_draft_fkey" FOREIGN KEY ("document_draft_id") REFERENCES "100_test"."document_draft" ("id"),
  CONSTRAINT "cpd_proposing_user_fkey" FOREIGN KEY ("proposing_user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "cpd_proposing_citizen_fkey" FOREIGN KEY ("proposing_citizen_id") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "cpd_proposing_actor_chk" CHECK (num_nonnulls("proposing_user_id", "proposing_citizen_id") = 1)
);

CREATE TABLE "100_test"."case_citizen_shares" (
  "id"         UUID        NOT NULL DEFAULT gen_random_uuid(),
  "case_id"    UUID        NOT NULL,
  "citizen_id" UUID        NOT NULL,
  "shared_by"  UUID,
  "shared_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "removed_by" UUID,
  "removed_at" TIMESTAMPTZ,
  "is_active"  BOOLEAN     NOT NULL DEFAULT true,
  CONSTRAINT "ccs_pkey"           PRIMARY KEY ("id"),
  CONSTRAINT "ccs_case_fkey"      FOREIGN KEY ("case_id")    REFERENCES "100_test"."cases" ("id"),
  CONSTRAINT "ccs_citizen_fkey"   FOREIGN KEY ("citizen_id") REFERENCES "100_test"."citizens" ("id"),
  CONSTRAINT "ccs_shared_by_fkey"  FOREIGN KEY ("shared_by")  REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "ccs_removed_by_fkey" FOREIGN KEY ("removed_by") REFERENCES "100_test"."users" ("id")
);


CREATE TABLE "100_test"."case_responsibles" (
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
  CONSTRAINT "cr_pkey"          PRIMARY KEY ("id"),
  CONSTRAINT "cr_case_fkey"     FOREIGN KEY ("case_id")   REFERENCES "100_test"."cases" ("id"),
  CONSTRAINT "cr_user_fkey"     FOREIGN KEY ("user_id")   REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "cr_sector_fkey"   FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "cr_added_by_fkey" FOREIGN KEY ("added_by")  REFERENCES "100_test"."users" ("id")
);

COMMENT ON TABLE "100_test"."case_responsibles" IS 'Responsables asignados a expedientes (ADMIN único activo + ADDITIONAL ilimitados)';

CREATE TABLE "100_test"."case_favorites" (
  "id"         UUID        NOT NULL DEFAULT gen_random_uuid(),
  "user_id"    UUID        NOT NULL,
  "case_id"    UUID        NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "cf_pkey"      PRIMARY KEY ("id"),
  CONSTRAINT "cf_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id") ON DELETE CASCADE,
  CONSTRAINT "cf_case_fkey" FOREIGN KEY ("case_id") REFERENCES "100_test"."cases" ("id") ON DELETE CASCADE,
  CONSTRAINT "cf_unique"    UNIQUE ("user_id", "case_id")
);

COMMENT ON TABLE "100_test"."case_favorites" IS 'Expedientes marcados como favoritos por cada usuario';

CREATE TABLE "100_test"."case_user_views" (
  "user_id"      UUID        NOT NULL,
  "case_id"      UUID        NOT NULL,
  "last_seen_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "case_user_views_pkey"     PRIMARY KEY ("user_id", "case_id"),
  CONSTRAINT "case_user_views_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id") ON DELETE CASCADE,
  CONSTRAINT "case_user_views_case_fkey" FOREIGN KEY ("case_id") REFERENCES "100_test"."cases" ("id") ON DELETE CASCADE
);

COMMENT ON TABLE "100_test"."case_user_views" IS 'GDI-067: última vez que cada usuario abrió cada expediente (baseline de "movimientos nuevos")';

CREATE TABLE "100_test"."notification_dismissals" (
  "id"               UUID         NOT NULL DEFAULT gen_random_uuid(),
  "user_id"          UUID         NOT NULL,
  "notification_key" VARCHAR(160) NOT NULL,
  "dismissed_at"     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  CONSTRAINT "notification_dismissals_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "notification_dismissals_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id") ON DELETE CASCADE,
  CONSTRAINT "notification_dismissals_uq" UNIQUE ("user_id", "notification_key")
);

COMMENT ON TABLE "100_test"."notification_dismissals" IS 'GDI-067: dismiss manual (X) de avisos informativos (responsable/mención) por usuario';


CREATE TABLE "100_test"."settings" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "timezone" TEXT NOT NULL DEFAULT 'America/Argentina/Buenos_Aires',
  "bucket_oficial" TEXT NOT NULL,
  "bucket_tosign" TEXT NOT NULL,
  "bucket_publico" TEXT,
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


CREATE TABLE "100_test"."document_chunks" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "official_document_id" UUID NOT NULL,
  "chunk_index" INTEGER NOT NULL,
  "chunk_text" TEXT NOT NULL,
  "text_for_embedding" TEXT,
  "embedding" vector(1536),
  "embedding_model" VARCHAR(100) NOT NULL DEFAULT 'text-embedding-3-small',
  "content_tsv" tsvector GENERATED ALWAYS AS (
    to_tsvector('spanish', coalesce(text_for_embedding, chunk_text, ''))
  ) STORED,
  "indexed_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_chunks_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_chunks_official_fkey" FOREIGN KEY ("official_document_id") REFERENCES "100_test"."official_documents" ("id"),
  CONSTRAINT "document_chunks_unique" UNIQUE ("official_document_id", "chunk_index")
);

COMMENT ON TABLE "100_test"."document_chunks" IS 'Chunks de documentos oficiales con embeddings para búsqueda semántica';


CREATE TABLE "100_test"."notes_recipients" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "recipient_type" VARCHAR(3) NOT NULL,
  "sender_sector_id" UUID NOT NULL,
  "is_archived" BOOLEAN NOT NULL DEFAULT false,
  "archived_at" TIMESTAMPTZ NULL,
  CONSTRAINT "notes_recipients_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "notes_recipients_document_fkey" FOREIGN KEY ("document_id") REFERENCES "100_test"."document_draft" ("id"),
  CONSTRAINT "notes_recipients_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "notes_recipients_sender_fkey" FOREIGN KEY ("sender_sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "notes_recipients_type_check" CHECK ("recipient_type" IN ('TO', 'CC', 'BCC')),
  CONSTRAINT "notes_recipients_unique" UNIQUE ("document_id", "sector_id")
);

COMMENT ON TABLE "100_test"."notes_recipients" IS 'Destinatarios de notas oficiales (TO, CC, BCC) con soporte para archivado';

CREATE TABLE "100_test"."notes_openings" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "opened_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "notes_openings_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "notes_openings_document_fkey" FOREIGN KEY ("document_id") REFERENCES "100_test"."document_draft" ("id"),
  CONSTRAINT "notes_openings_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "notes_openings_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "notes_openings_unique" UNIQUE ("document_id", "user_id")
);

COMMENT ON TABLE "100_test"."notes_openings" IS 'Registro de apertura de notas (tracking simple sí/no)';


CREATE TABLE "100_test"."registry_families" (
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

COMMENT ON TABLE "100_test"."registry_families" IS 'Familias de registros del municipio (copiadas y personalizadas desde global)';

CREATE TABLE "100_test"."registry_family_permissions" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "registry_family_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "can_create" BOOLEAN NOT NULL DEFAULT false,
  "can_edit" BOOLEAN NOT NULL DEFAULT false,
  "can_view" BOOLEAN NOT NULL DEFAULT true,
  "can_verify" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "registry_family_permissions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "rfp_family_fkey" FOREIGN KEY ("registry_family_id") REFERENCES "100_test"."registry_families" ("id"),
  CONSTRAINT "rfp_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id"),
  CONSTRAINT "rfp_unique" UNIQUE ("registry_family_id", "sector_id")
);

COMMENT ON TABLE "100_test"."registry_family_permissions" IS 'Permisos de sectores sobre familias de registros';

CREATE TABLE "100_test"."records" (
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
  CONSTRAINT "records_family_fkey" FOREIGN KEY ("registry_family_id") REFERENCES "100_test"."registry_families" ("id"),
  CONSTRAINT "records_user_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "records_sector_fkey" FOREIGN KEY ("created_by_sector_id") REFERENCES "100_test"."sectors" ("id")
);

COMMENT ON TABLE "100_test"."records" IS 'Registros individuales con datos JSONB segun schema de la familia';

CREATE TABLE "100_test"."record_history" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "record_id" UUID NOT NULL,
  "action" VARCHAR(50) NOT NULL,
  "field_name" VARCHAR(100),
  "before_value" JSONB,
  "after_value" JSONB,
  "user_id" UUID NOT NULL,
  "sector_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_history_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_history_record_fkey" FOREIGN KEY ("record_id") REFERENCES "100_test"."records" ("id"),
  CONSTRAINT "record_history_user_fkey" FOREIGN KEY ("user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "record_history_sector_fkey" FOREIGN KEY ("sector_id") REFERENCES "100_test"."sectors" ("id")
);

COMMENT ON TABLE "100_test"."record_history" IS 'Historial de cambios en registros';

CREATE TABLE "100_test"."record_relations" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "source_record_id" UUID NOT NULL,
  "target_record_id" UUID NOT NULL,
  "relation_type" VARCHAR(50) DEFAULT 'related',
  "notes" TEXT,
  "created_by_user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_relations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_relations_source_fkey" FOREIGN KEY ("source_record_id") REFERENCES "100_test"."records" ("id"),
  CONSTRAINT "record_relations_target_fkey" FOREIGN KEY ("target_record_id") REFERENCES "100_test"."records" ("id"),
  CONSTRAINT "record_relations_user_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "record_relations_unique" UNIQUE ("source_record_id", "target_record_id")
);

COMMENT ON TABLE "100_test"."record_relations" IS 'Relaciones entre registros (ej: obra relacionada con luminaria)';

CREATE TABLE "100_test"."record_case_links" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "record_id" UUID NOT NULL,
  "case_id" UUID NOT NULL,
  "notes" TEXT,
  "linked_by_user_id" UUID NOT NULL,
  "linked_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_case_links_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_case_links_record_fkey" FOREIGN KEY ("record_id") REFERENCES "100_test"."records" ("id"),
  CONSTRAINT "record_case_links_case_fkey" FOREIGN KEY ("case_id") REFERENCES "100_test"."cases" ("id"),
  CONSTRAINT "record_case_links_user_fkey" FOREIGN KEY ("linked_by_user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "record_case_links_unique" UNIQUE ("record_id", "case_id")
);

COMMENT ON TABLE "100_test"."record_case_links" IS 'Vinculos entre registros y expedientes';

CREATE TABLE "100_test"."record_document_links" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "record_id" UUID NOT NULL,
  "document_id" UUID NOT NULL,
  "field_name" VARCHAR(100),
  "notes" TEXT,
  "linked_by_user_id" UUID NOT NULL,
  "linked_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "record_document_links_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "record_document_links_record_fkey" FOREIGN KEY ("record_id") REFERENCES "100_test"."records" ("id"),
  CONSTRAINT "record_document_links_user_fkey" FOREIGN KEY ("linked_by_user_id") REFERENCES "100_test"."users" ("id"),
  CONSTRAINT "record_document_links_unique" UNIQUE ("record_id", "document_id")
);

COMMENT ON TABLE "100_test"."record_document_links" IS 'Vinculos entre registros y documentos (draft u oficial)';


CREATE INDEX "idx_100_test_users_email" ON "100_test"."users" ("email");
CREATE INDEX "idx_100_test_users_sector" ON "100_test"."users" ("sector_id");

CREATE INDEX "idx_100_test_document_draft_status" ON "100_test"."document_draft" ("status");
CREATE INDEX "idx_100_test_document_draft_created_by" ON "100_test"."document_draft" ("created_by");
CREATE INDEX "idx_100_test_document_draft_type" ON "100_test"."document_draft" ("document_type_id");
CREATE INDEX "idx_100_test_document_draft_created_by_date" ON "100_test"."document_draft" ("created_by", "created_at" DESC);

CREATE INDEX "idx_100_test_doc_signers_document" ON "100_test"."document_signers" ("document_id");
CREATE INDEX "idx_100_test_doc_signers_user" ON "100_test"."document_signers" ("user_id");
CREATE INDEX "idx_100_test_doc_signers_status" ON "100_test"."document_signers" ("status");

CREATE INDEX "idx_100_test_official_docs_signer_sectors" ON "100_test"."official_documents" USING GIN ("signer_sector_ids");
CREATE INDEX "idx_100_test_official_docs_number" ON "100_test"."official_documents" ("official_number");
CREATE INDEX "idx_100_test_official_docs_signed_at" ON "100_test"."official_documents" ("signed_at" DESC);
CREATE INDEX "idx_100_test_official_docs_department" ON "100_test"."official_documents" ("department_id");

CREATE INDEX "idx_100_test_cases_status" ON "100_test"."cases" ("status");
CREATE INDEX "idx_100_test_cases_owner_dept" ON "100_test"."cases" ("owner_department_id");

CREATE INDEX "idx_100_test_case_mov_case" ON "100_test"."case_movements" ("case_id");
CREATE INDEX "idx_100_test_case_mov_assigned_sector" ON "100_test"."case_movements" ("assigned_sector_id");
CREATE INDEX "idx_100_test_case_mov_case_date" ON "100_test"."case_movements" ("case_id", "created_at" DESC);

CREATE INDEX "idx_100_test_case_off_docs_case" ON "100_test"."case_official_documents" ("case_id");
CREATE INDEX "idx_100_test_case_off_docs_doc" ON "100_test"."case_official_documents" ("official_document_id");

CREATE INDEX "idx_100_test_case_mov_admin_lookup" ON "100_test"."case_movements" ("case_id", "type", "is_active", "closed_at" DESC)
    WHERE "type" IN ('creation', 'transfer');

CREATE INDEX "idx_100_test_case_mov_transfers" ON "100_test"."case_movements" ("case_id")
    WHERE "type" = 'transfer';

CREATE INDEX "idx_100_test_case_mov_assigned_active" ON "100_test"."case_movements" ("case_id", "assigned_sector_id")
    WHERE "is_active" = true AND "assigned_sector_id" IS NOT NULL;

CREATE INDEX "idx_100_test_case_off_docs_active" ON "100_test"."case_official_documents" ("case_id", "linking_date" DESC)
    WHERE "is_active" = true;

CREATE INDEX "idx_100_test_cases_created_at" ON "100_test"."cases" ("created_at" DESC);
CREATE INDEX "idx_100_test_cases_active_created" ON "100_test"."cases" ("created_at" DESC)
    WHERE "status" = 'active';

CREATE INDEX "idx_100_test_doc_draft_last_modified" ON "100_test"."document_draft" ("last_modified_at" DESC);

CREATE INDEX "idx_100_test_doc_signers_doc_user" ON "100_test"."document_signers" ("document_id", "user_id");

CREATE INDEX "idx_100_test_case_prop_docs_case" ON "100_test"."case_proposed_documents" ("case_id");

CREATE UNIQUE INDEX "idx_100_test_ccs_active_unique"
  ON "100_test"."case_citizen_shares" ("case_id", "citizen_id")
  WHERE "is_active" = true;
CREATE INDEX "idx_100_test_ccs_citizen" ON "100_test"."case_citizen_shares" ("citizen_id") WHERE "is_active" = true;

CREATE UNIQUE INDEX "idx_100_test_cr_unique_admin"
  ON "100_test"."case_responsibles" ("case_id")
  WHERE "type" = 'ADMIN' AND "is_active" = true;
CREATE INDEX "idx_100_test_cr_case_active"
  ON "100_test"."case_responsibles" ("case_id", "is_active");
CREATE INDEX "idx_100_test_cr_user"
  ON "100_test"."case_responsibles" ("user_id")
  WHERE "is_active" = true;
CREATE INDEX "idx_100_test_cr_sector"
  ON "100_test"."case_responsibles" ("sector_id")
  WHERE "is_active" = true;
CREATE INDEX "idx_100_test_case_favorites_user"
  ON "100_test"."case_favorites" ("user_id", "created_at" DESC);

CREATE INDEX "idx_100_test_case_user_views_user_seen"
  ON "100_test"."case_user_views" ("user_id", "last_seen_at");

CREATE INDEX "idx_100_test_chunks_doc" ON "100_test"."document_chunks" ("official_document_id");

CREATE INDEX "idx_100_test_chunks_embedding" ON "100_test"."document_chunks"
    USING hnsw ("embedding" vector_cosine_ops);

CREATE INDEX "idx_100_test_chunks_content_tsv" ON "100_test"."document_chunks"
    USING GIN ("content_tsv");

CREATE INDEX "idx_100_test_notes_recipients_document" ON "100_test"."notes_recipients" ("document_id");
CREATE INDEX "idx_100_test_notes_recipients_sector" ON "100_test"."notes_recipients" ("sector_id");
CREATE INDEX "idx_100_test_notes_recipients_sender" ON "100_test"."notes_recipients" ("sender_sector_id");
CREATE INDEX "idx_100_test_notes_openings_document" ON "100_test"."notes_openings" ("document_id");
CREATE INDEX "idx_100_test_notes_openings_sector" ON "100_test"."notes_openings" ("sector_id");

CREATE INDEX "idx_100_test_notes_recipients_not_archived" ON "100_test"."notes_recipients" ("sector_id")
    WHERE is_archived = false;
CREATE INDEX "idx_100_test_notes_recipients_archived" ON "100_test"."notes_recipients" ("sector_id")
    WHERE is_archived = true;

CREATE INDEX "idx_100_test_counters_updated_at" ON "100_test"."document_number_counters" ("updated_at");

CREATE UNIQUE INDEX "idx_100_test_official_docs_one_reserved_special"
  ON "100_test"."official_documents" ("document_type_id", "department_id", "year")
  WHERE reservation_status = 'RESERVED' AND numbering_regime = 'SPECIAL';

CREATE INDEX "idx_100_test_official_docs_cancelled_global"
  ON "100_test"."official_documents" ("year", "reserved_at")
  WHERE reservation_status = 'CANCELLED' AND numbering_regime = 'GLOBAL';

CREATE INDEX "idx_100_test_official_docs_cancelled_special"
  ON "100_test"."official_documents" ("document_type_id", "department_id", "year", "reserved_at")
  WHERE reservation_status = 'CANCELLED' AND numbering_regime = 'SPECIAL';

CREATE INDEX "idx_100_test_official_docs_reserved_at"
  ON "100_test"."official_documents" ("reserved_at")
  WHERE reservation_status = 'RESERVED';

CREATE UNIQUE INDEX "idx_100_test_departments_acronym_active"
  ON "100_test"."departments" ("acronym")
  WHERE is_active = true AND acronym IS NOT NULL;

CREATE INDEX "idx_100_test_records_family" ON "100_test"."records" ("registry_family_id");
CREATE INDEX "idx_100_test_records_state" ON "100_test"."records" ("state");
CREATE INDEX "idx_100_test_records_created_by" ON "100_test"."records" ("created_by_user_id");
CREATE INDEX "idx_100_test_records_data" ON "100_test"."records" USING GIN ("data");
CREATE INDEX "idx_100_test_records_expiration" ON "100_test"."records" ("next_expiration")
    WHERE "next_expiration" IS NOT NULL;
CREATE INDEX "idx_100_test_record_history_record" ON "100_test"."record_history" ("record_id");
CREATE INDEX "idx_100_test_record_relations_source" ON "100_test"."record_relations" ("source_record_id");
CREATE INDEX "idx_100_test_record_relations_target" ON "100_test"."record_relations" ("target_record_id");
CREATE INDEX "idx_100_test_record_case_links_record" ON "100_test"."record_case_links" ("record_id");
CREATE INDEX "idx_100_test_record_doc_links_record" ON "100_test"."record_document_links" ("record_id");


CREATE TABLE "100_test"."document_type_fields" (
  "id"                UUID        NOT NULL DEFAULT gen_random_uuid(),
  "document_type_id"  INT         NOT NULL,
  "field_definitions" JSONB       NOT NULL DEFAULT '[]'::jsonb,
  "created_by"        UUID        NOT NULL,
  "created_at"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at"        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "dtf_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "dtf_document_type_fkey" FOREIGN KEY ("document_type_id")
      REFERENCES "100_test"."document_types" ("id"),
  CONSTRAINT "dtf_document_type_unique" UNIQUE ("document_type_id")
);

COMMENT ON TABLE "100_test"."document_type_fields" IS 'Definición de campos de formularios controlados (FFCC). Una fila por tipo de documento. field_definitions es array JSONB con los campos del formulario.';

CREATE INDEX "idx_100_test_document_type_fields_updated_at"
    ON "100_test"."document_type_fields" ("updated_at");

DROP TRIGGER IF EXISTS trg_dtf_updated_at ON "100_test"."document_type_fields";
CREATE TRIGGER trg_dtf_updated_at
    BEFORE UPDATE ON "100_test"."document_type_fields"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


CREATE OR REPLACE FUNCTION "100_test"."fn_sync_user_registry"()
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
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."users"
    FOR EACH ROW EXECUTE FUNCTION "100_test"."fn_sync_user_registry"();

DROP TRIGGER IF EXISTS trg_document_number_counters_updated_at ON "100_test"."document_number_counters";
CREATE TRIGGER "trg_document_number_counters_updated_at"
  BEFORE UPDATE ON "100_test"."document_number_counters"
  FOR EACH ROW EXECUTE FUNCTION "public"."fn_set_updated_at"();


DROP SCHEMA IF EXISTS "100_test_audit" CASCADE;

CREATE SCHEMA "100_test_audit";


CREATE TABLE "100_test_audit"."audit_log" (
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

COMMENT ON TABLE "100_test_audit"."audit_log" IS 'Registro de auditoria del municipio';

CREATE INDEX "idx_100_test_audit_audit_log_event_time" ON "100_test_audit"."audit_log" ("event_time");
CREATE INDEX "idx_100_test_audit_audit_log_table" ON "100_test_audit"."audit_log" ("table_name");
CREATE INDEX "idx_100_test_audit_audit_log_user" ON "100_test_audit"."audit_log" ("user_id");


CREATE OR REPLACE FUNCTION "100_test_audit"."fn_log_change"()
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

        INSERT INTO "100_test_audit".audit_log(
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

        INSERT INTO "100_test_audit".audit_log(
            schema_name, table_name, operation, user_name, user_id, auth_source, old_row, new_row, changed_fields
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, v_user_id, v_auth_source, v_old_row, v_new_row, v_changed_fields
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        v_old_row := to_jsonb(OLD);

        INSERT INTO "100_test_audit".audit_log(
            schema_name, table_name, operation, user_name, user_id, auth_source, old_row
        ) VALUES (
            TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, current_user, v_user_id, v_auth_source, v_old_row
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS "trg_audit_departments" ON "100_test"."departments";
CREATE TRIGGER "trg_audit_departments"
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."departments"
    FOR EACH ROW EXECUTE FUNCTION "100_test_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_sectors" ON "100_test"."sectors";
CREATE TRIGGER "trg_audit_sectors"
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."sectors"
    FOR EACH ROW EXECUTE FUNCTION "100_test_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_official_documents" ON "100_test"."official_documents";
CREATE TRIGGER "trg_audit_official_documents"
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."official_documents"
    FOR EACH ROW EXECUTE FUNCTION "100_test_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_cases" ON "100_test"."cases";
CREATE TRIGGER "trg_audit_cases"
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."cases"
    FOR EACH ROW EXECUTE FUNCTION "100_test_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_case_movements" ON "100_test"."case_movements";
CREATE TRIGGER "trg_audit_case_movements"
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."case_movements"
    FOR EACH ROW EXECUTE FUNCTION "100_test_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_case_official_documents" ON "100_test"."case_official_documents";
CREATE TRIGGER "trg_audit_case_official_documents"
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."case_official_documents"
    FOR EACH ROW EXECUTE FUNCTION "100_test_audit"."fn_log_change"();

DROP TRIGGER IF EXISTS "trg_audit_users" ON "100_test"."users";
CREATE TRIGGER "trg_audit_users"
    AFTER INSERT OR UPDATE OR DELETE ON "100_test"."users"
    FOR EACH ROW EXECUTE FUNCTION "100_test_audit"."fn_log_change"();


INSERT INTO "100_test"."estado_users" (id, estado) VALUES
  (1, 'Activo'),
  (2, 'Inactivo'),
  (3, 'Suspendido'),
  (4, 'Pendiente'),
  (5, 'Archivado')
ON CONFLICT (id) DO NOTHING;

INSERT INTO "100_test"."settings"
  (id, timezone, bucket_oficial, bucket_tosign, city, primary_color, created_at, updated_at)
VALUES
  (
    'a5500000-0000-0000-0000-000000000001',
    'America/Argentina/Buenos_Aires',
    'gdi-txst-oficial',
    'gdi-txst-tosign',
    'LATAM',
    '006400',
    NOW(),
    NOW()
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO "public"."municipalities" (id, name, acronym, country, schema_number, schema_name, primary_color, is_active, created_at)
VALUES
  (
    'b5500000-0000-0000-0000-000000000100',
    'Test Municipality',
    'TXST',
    'AR',
    100,
    '100_test',
    '006400',
    true,
    NOW()
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO "public"."api_keys" (id, api_key_hash, api_key_prefix, municipality_id, name, description, is_active, created_by)
VALUES (
  'c1000000-0000-0000-0000-000000000001',
  '<YOUR_API_KEY_HASH_SHA256>',
  'gdi-agent-10',
  'b5500000-0000-0000-0000-000000000100',
  'GDI-AgenteLANG',
  'Auto-provisioned for AI Worker transcription',
  true,
  'system'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO "public"."ai_usage_limits" (schema_name, daily_limit_usd, is_enabled)
VALUES ('100_test', 0.15, true)
ON CONFLICT (schema_name) DO NOTHING;


INSERT INTO "100_test"."departments" (id, name, acronym, parent_id, primary_color, is_active, created_at) VALUES
  ('d1000000-0000-0000-0000-000000000001', 'Intendencia', 'INTE', NULL, '#2C3E50', true, NOW()),
  ('d1000000-0000-0000-0000-000000000002', 'Legal y Tecnica', 'LEGAL', 'd1000000-0000-0000-0000-000000000001', '#1A5276', true, NOW()),
  ('d1000000-0000-0000-0000-000000000003', 'Innovacion', 'INNO', 'd1000000-0000-0000-0000-000000000001', '#6C3483', true, NOW()),
  ('d1000000-0000-0000-0000-000000000004', 'Salud', 'SAL', 'd1000000-0000-0000-0000-000000000001', '#1E8449', true, NOW()),
  ('d1000000-0000-0000-0000-000000000005', 'Hacienda', 'HAC', 'd1000000-0000-0000-0000-000000000001', '#7D6608', true, NOW()),
  ('d1000000-0000-0000-0000-000000000006', 'Tesoreria', 'TESO', 'd1000000-0000-0000-0000-000000000005', '#B7950B', true, NOW()),
  ('d1000000-0000-0000-0000-000000000007', 'Contabilidad', 'CONT', 'd1000000-0000-0000-0000-000000000005', '#5B7D3A', true, NOW()),
  ('d1000000-0000-0000-0000-000000000008', 'Seguridad', 'SEG', 'd1000000-0000-0000-0000-000000000001', '#922B21', true, NOW()),
  ('d1000000-0000-0000-0000-000000000009', 'Obra Publica', 'OOPU', 'd1000000-0000-0000-0000-000000000001', '#A04000', true, NOW()),
  ('d1000000-0000-0000-0000-00000000000a', 'Obras Particulares', 'OOPA', 'd1000000-0000-0000-0000-000000000001', '#784212', true, NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "100_test"."departments" (id, name, acronym, parent_id, primary_color, is_active, is_system, created_at) VALUES
  ('d1000000-0000-0000-0000-00000000000b', 'Tramites a Distancia', 'TAD', NULL, '#5D6D7E', true, true, NOW())
ON CONFLICT (id) DO NOTHING;


INSERT INTO "100_test"."sectors" (id, department_id, acronym, primary_color, is_active, created_at) VALUES
  ('51000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', 'PRIV', '#2C3E50', true, NOW()),
  ('51000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000002', 'PRIV', '#1A5276', true, NOW()),
  ('51000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000003', 'PRIV', '#6C3483', true, NOW()),
  ('51000000-0000-0000-0000-000000000004', 'd1000000-0000-0000-0000-000000000004', 'PRIV', '#1E8449', true, NOW()),
  ('51000000-0000-0000-0000-000000000005', 'd1000000-0000-0000-0000-000000000005', 'PRIV', '#7D6608', true, NOW()),
  ('51000000-0000-0000-0000-000000000006', 'd1000000-0000-0000-0000-000000000006', 'PRIV', '#B7950B', true, NOW()),
  ('51000000-0000-0000-0000-000000000007', 'd1000000-0000-0000-0000-000000000007', 'PRIV', '#5B7D3A', true, NOW()),
  ('51000000-0000-0000-0000-000000000008', 'd1000000-0000-0000-0000-000000000008', 'PRIV', '#922B21', true, NOW()),
  ('51000000-0000-0000-0000-000000000009', 'd1000000-0000-0000-0000-000000000009', 'PRIV', '#A04000', true, NOW()),
  ('51000000-0000-0000-0000-00000000000a', 'd1000000-0000-0000-0000-00000000000a', 'PRIV', '#784212', true, NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "100_test"."sectors" (id, department_id, acronym, primary_color, is_active, created_at) VALUES
  ('51000000-0000-0000-0000-00000000000b', 'd1000000-0000-0000-0000-000000000001', 'MESA', '#76828D', true, NOW()),
  ('51000000-0000-0000-0000-00000000000c', 'd1000000-0000-0000-0000-000000000001', 'ADMIN', '#A0A8B0', true, NOW()),
  ('51000000-0000-0000-0000-00000000000d', 'd1000000-0000-0000-0000-000000000002', 'MESA', '#6A8FA6', true, NOW()),
  ('51000000-0000-0000-0000-00000000000e', 'd1000000-0000-0000-0000-000000000005', 'MESA', '#AB9C5E', true, NOW())
ON CONFLICT (id) DO NOTHING;


INSERT INTO "100_test"."ranks" (id, name, level, head_signature) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'Intendente',  1, 'Intendente Municipal'),
  ('c0000000-0000-0000-0000-000000000002', 'Secretario',  2, 'Secretario'),
  ('c0000000-0000-0000-0000-000000000003', 'Director',    3, 'Director')
ON CONFLICT (id) DO NOTHING;


INSERT INTO "100_test"."city_seals" (id, name, description, rank_id, created_at) VALUES
  (1, 'Innovador', 'Sello para todos los funcionarios', NULL, NOW()),
  (2, 'Intendente Municipal', 'Maxima autoridad del municipio', 'c0000000-0000-0000-0000-000000000001', NOW()),
  (3, 'Secretario', 'Sello de Secretario', 'c0000000-0000-0000-0000-000000000002', NOW()),
  (4, 'Director', 'Sello de Director', 'c0000000-0000-0000-0000-000000000003', NOW())
ON CONFLICT (id) DO NOTHING;

SELECT setval('"100_test".city_seals_id_seq', 4);


UPDATE "100_test"."departments" SET rank_id = 'c0000000-0000-0000-0000-000000000001' WHERE id = 'd1000000-0000-0000-0000-000000000001';
UPDATE "100_test"."departments" SET rank_id = 'c0000000-0000-0000-0000-000000000002' WHERE id = 'd1000000-0000-0000-0000-000000000002';
UPDATE "100_test"."departments" SET rank_id = 'c0000000-0000-0000-0000-000000000002' WHERE id = 'd1000000-0000-0000-0000-000000000005';
UPDATE "100_test"."departments" SET rank_id = 'c0000000-0000-0000-0000-000000000003' WHERE id = 'd1000000-0000-0000-0000-000000000008';
UPDATE "100_test"."departments" SET rank_id = 'c0000000-0000-0000-0000-000000000003' WHERE id = 'd1000000-0000-0000-0000-000000000009';
UPDATE "100_test"."departments" SET rank_id = 'c0000000-0000-0000-0000-000000000003' WHERE id = 'd1000000-0000-0000-0000-00000000000a';
UPDATE "100_test"."departments" SET rank_id = 'c0000000-0000-0000-0000-000000000003' WHERE id = 'd1000000-0000-0000-0000-000000000003';


INSERT INTO "100_test"."users" (id, auth_id, email, full_name, sector_id, estado, created_at) VALUES
  ('a1000000-0000-0000-0000-000000000001', NULL, 'mrodriguez@munitest.com', 'Maria Rodriguez', '51000000-0000-0000-0000-000000000001', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000002', NULL, 'jperez@munitest.com', 'Juan Perez', '51000000-0000-0000-0000-000000000002', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000003', NULL, 'lgomez@munitest.com', 'Laura Gomez', '51000000-0000-0000-0000-000000000003', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000004', NULL, 'cmartinez@munitest.com', 'Carlos Martinez', '51000000-0000-0000-0000-000000000004', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000005', NULL, 'alopez@munitest.com', 'Ana Lopez', '51000000-0000-0000-0000-000000000005', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000006', NULL, 'rfernandez@munitest.com', 'Roberto Fernandez', '51000000-0000-0000-0000-000000000006', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000007', NULL, 'pgarcia@munitest.com', 'Patricia Garcia', '51000000-0000-0000-0000-000000000007', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000008', NULL, 'dsilva@munitest.com', 'Diego Silva', '51000000-0000-0000-0000-000000000008', 1, NOW()),
  ('a1000000-0000-0000-0000-000000000009', NULL, 'vcastro@munitest.com', 'Valentina Castro', '51000000-0000-0000-0000-000000000009', 1, NOW()),
  ('a1000000-0000-0000-0000-00000000000a', NULL, 'mherrera@munitest.com', 'Miguel Herrera', '51000000-0000-0000-0000-00000000000a', 1, NOW()),
  ('a1000000-0000-0000-0000-00000000000b', NULL, 'tester@munitest.com', 'Usuario Tester', '51000000-0000-0000-0000-000000000001', 1, NOW()),
  ('a1000000-0000-0000-0000-00000000000c', NULL, 'emorales@munitest.com', 'Elena Morales', '51000000-0000-0000-0000-00000000000b', 1, NOW()),
  ('a1000000-0000-0000-0000-00000000000d', NULL, 'rnavarro@munitest.com', 'Ricardo Navarro', '51000000-0000-0000-0000-00000000000c', 1, NOW()),
  ('a1000000-0000-0000-0000-00000000000e', NULL, 'amedina@munitest.com', 'Andrea Medina', '51000000-0000-0000-0000-00000000000d', 1, NOW()),
  ('a1000000-0000-0000-0000-00000000000f', NULL, 'prios@munitest.com', 'Pablo Rios', '51000000-0000-0000-0000-00000000000e', 1, NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "100_test"."users" (id, auth_id, email, full_name, sector_id, estado, created_at) VALUES
  ('a1000000-0000-0000-0000-000000000100', NULL, 'ai-worker@gdi.internal', 'AI Worker', NULL, 1, NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "100_test"."users" (id, auth_id, email, full_name, sector_id, estado, created_at) VALUES
  ('00000000-0000-0000-0000-000074657374', NULL, 'test@example.com', 'Testing User', '51000000-0000-0000-0000-000000000001', 1, NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.api_key_users (api_key_id, user_id, schema_name)
SELECT ak.id, 'a1000000-0000-0000-0000-000000000100'::uuid, '100_test'
FROM public.api_keys ak
JOIN public.municipalities m ON ak.municipality_id = m.id
WHERE m.schema_name = '100_test' AND ak.is_active = true
ON CONFLICT ON CONSTRAINT api_key_users_key_user_schema_unique DO NOTHING;

UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000001' WHERE id = 'd1000000-0000-0000-0000-000000000001';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000002' WHERE id = 'd1000000-0000-0000-0000-000000000002';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000003' WHERE id = 'd1000000-0000-0000-0000-000000000003';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000004' WHERE id = 'd1000000-0000-0000-0000-000000000004';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000005' WHERE id = 'd1000000-0000-0000-0000-000000000005';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000006' WHERE id = 'd1000000-0000-0000-0000-000000000006';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000007' WHERE id = 'd1000000-0000-0000-0000-000000000007';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000008' WHERE id = 'd1000000-0000-0000-0000-000000000008';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-000000000009' WHERE id = 'd1000000-0000-0000-0000-000000000009';
UPDATE "100_test"."departments" SET head_user_id = 'a1000000-0000-0000-0000-00000000000a' WHERE id = 'd1000000-0000-0000-0000-00000000000a';


INSERT INTO "100_test"."user_seals" (id, user_id, city_seal_id, created_at) VALUES
  ('e1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 2, NOW()),
  ('e1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 3, NOW()),
  ('e1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003', 4, NOW()),
  ('e1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000004', 4, NOW()),
  ('e1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000005', 3, NOW()),
  ('e1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000006', 4, NOW()),
  ('e1000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000007', 4, NOW()),
  ('e1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000008', 4, NOW()),
  ('e1000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000009', 4, NOW()),
  ('e1000000-0000-0000-0000-00000000000a', 'a1000000-0000-0000-0000-00000000000a', 4, NOW()),
  ('e1000000-0000-0000-0000-00000000000b', 'a1000000-0000-0000-0000-00000000000b', 1, NOW()),
  ('e1000000-0000-0000-0000-00000000000c', 'a1000000-0000-0000-0000-00000000000c', 1, NOW()),
  ('e1000000-0000-0000-0000-00000000000d', 'a1000000-0000-0000-0000-00000000000d', 1, NOW()),
  ('e1000000-0000-0000-0000-00000000000e', 'a1000000-0000-0000-0000-00000000000e', 1, NOW()),
  ('e1000000-0000-0000-0000-00000000000f', 'a1000000-0000-0000-0000-00000000000f', 1, NOW()),
  ('e1000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000074657374', 1, NOW())
ON CONFLICT (id) DO NOTHING;


INSERT INTO "100_test"."user_roles" (user_id, role_id, created_at) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', NOW()),
  ('a1000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-00000000000b', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-00000000000d', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-00000000000e', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('a1000000-0000-0000-0000-00000000000f', 'a0000000-0000-0000-0000-000000000002', NOW()),
  ('00000000-0000-0000-0000-000074657374', 'a0000000-0000-0000-0000-000000000004', NOW())
ON CONFLICT ON CONSTRAINT "user_roles_unique" DO NOTHING;


INSERT INTO "100_test"."document_types"
  (id, global_document_type_id, name, acronym, description, signature_policy, is_active, type, created_at)
VALUES
  (1, 'd0000000-0000-0000-0000-000000000001', 'Informe', 'IF', 'Informe tecnico o administrativo', 'electronic', true, 'HTML', NOW()),
  (2, 'd0000000-0000-0000-0000-000000000002', 'Nota', 'NOTA', 'Nota oficial con destinatarios TO/CC/BCC y tracking de apertura', 'electronic', true, 'NOTA', NOW()),
  (3, 'd0000000-0000-0000-0000-000000000003', 'Providencia', 'PROV', 'Providencia administrativa', 'electronic', true, 'HTML', NOW()),
  (4, 'd0000000-0000-0000-0000-000000000004', 'Acta', 'ACT', 'Acta de reunion, evento, accion, etc.', 'electronic', true, 'HTML', NOW()),
  (5, 'd0000000-0000-0000-0000-000000000005', 'Anexo', 'ANEXO', 'Anexo documental', 'electronic', true, 'HTML', NOW()),
  (6, 'd0000000-0000-0000-0000-000000000008', 'Informe Grafico Importado', 'IFGRA', 'Informe grafico importado desde archivo externo', 'electronic', true, 'Importado', NOW()),
  (7, 'd0000000-0000-0000-0000-000000000009', 'Constancia', 'CONST', 'Constancia administrativa', 'electronic', true, 'HTML', NOW()),
  (8, 'd0000000-0000-0000-0000-000000000010', 'Resolucion', 'RESOL', 'Resolucion administrativa', 'electronic', true, 'HTML', NOW()),
  (9, 'd0000000-0000-0000-0000-000000000013', 'Dictamen', 'DICTA', 'Dictamen legal o tecnico', 'electronic', true, 'HTML', NOW()),
  (10, 'd0000000-0000-0000-0000-000000000015', 'Oficio Judicial', 'OFJUD', 'Oficio judicial', 'electronic', true, 'Importado', NOW()),
  (11, 'd0000000-0000-0000-0000-00000000001f', 'Acta de Inspeccion', 'AINSP', 'Acta de inspeccion', 'electronic', true, 'HTML', NOW()),
  (12, 'd0000000-0000-0000-0000-000000000020', 'Permiso General', 'PERMI', 'Permiso general', 'electronic', true, 'HTML', NOW()),
  (13, 'd0000000-0000-0000-0000-000000000022', 'Cert. Inspeccion Final', 'CIF', 'Certificado de inspeccion final', 'electronic', true, 'HTML', NOW()),
  (14, 'd0000000-0000-0000-0000-000000000023', 'Cert. Habilit. Comercio', 'HCOM', 'Certificado de habilitacion de comercio', 'electronic', true, 'HTML', NOW()),
  (15, 'd0000000-0000-0000-0000-000000000024', 'Certificado Parcelario', 'CPARC', 'Certificado parcelario', 'electronic', true, 'Importado', NOW()),
  (16, 'd0000000-0000-0000-0000-000000000037', 'Constancia de Pago', 'PAGO', 'Constancia de pago', 'electronic', true, 'HTML', NOW()),
  (17, 'd0000000-0000-0000-0000-000000000039', 'Pre-Pliego', 'PREPL', 'Pre-pliego para compras y contrataciones', 'electronic', true, 'HTML', NOW()),
  (18, 'd0000000-0000-0000-0000-00000000003a', 'Pliego Definitivo', 'PLIEG', 'Pliego definitivo para licitaciones', 'electronic', true, 'HTML', NOW()),
  (19, 'd0000000-0000-0000-0000-00000000003e', 'Ordenanza HCD', 'PLORD', 'Ordenanza sancionada por el Honorable Concejo Deliberante', 'electronic', true, 'Importado', NOW()),
  (20, 'd0000000-0000-0000-0000-00000000003f', 'Resolucion HCD', 'PLRES', 'Resolucion emitida por el Honorable Concejo Deliberante', 'electronic', true, 'Importado', NOW()),
  (21, 'd0000000-0000-0000-0000-000000000040', 'Comunicacion HCD', 'PLCOM', 'Comunicacion oficial del Honorable Concejo Deliberante', 'electronic', true, 'Importado', NOW()),
  (22, 'd0000000-0000-0000-0000-000000000080', 'Informe RLM', 'IFRLM', 'Informe de Registro Legajo Multiproposito (generado on-demand desde un legajo RLM)', 'electronic', true, 'HTML', NOW()),
  (23, 'd0000000-0000-0000-0000-00000000003c', 'Pase', 'PV', 'Pase de expediente (Uso exclusivo modulo EE)', 'electronic', false, 'HTML', NOW()),
  (24, 'd0000000-0000-0000-0000-00000000003d', 'Caratula', 'CAEX', 'Caratula de expediente (Uso exclusivo modulo EE)', 'electronic', false, 'HTML', NOW()),
  (25, 'd0000000-0000-0000-0000-000000000042', 'Testing', 'TST', 'Documento generado automaticamente cuando una firma falla (Uso exclusivo del sistema)', 'electronic', false, 'HTML', NOW())
ON CONFLICT (id) DO NOTHING;

SELECT setval('"100_test".document_types_id_seq', 24);

UPDATE "100_test"."document_types" SET accepts_embedded_files = true WHERE id = 6;

UPDATE "100_test"."document_types" SET visibility = 'reservado' WHERE id = 9;


INSERT INTO "100_test"."case_templates"
  (id, global_case_template_id, type_name, acronym, description, creation_channel, filing_department_id, filing_sector_id, is_active, created_at)
VALUES
  ('c1000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000005', 'Testing Automatizado', 'TEST', 'Expediente para pruebas automatizadas del Equipo TESTERS', 'web', 'd1000000-0000-0000-0000-000000000003', '51000000-0000-0000-0000-000000000003', true, NOW()),
  ('c1000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000006', 'Habilitacion Comercial', 'HABI', 'Tramite de habilitacion de locales comerciales', 'web', 'd1000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000001', true, NOW()),
  ('c1000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000007', 'Permiso Industrial', 'HIND', 'Tramite de permiso para establecimientos industriales', 'web', 'd1000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000001', true, NOW()),
  ('c1000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000008', 'Compras y Contrataciones', 'COMP', 'Gestion de compras directas y contrataciones', 'web', 'd1000000-0000-0000-0000-000000000005', '51000000-0000-0000-0000-000000000005', true, NOW()),
  ('c1000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000009', 'Demanda Judicial', 'DEM', 'Seguimiento de demandas judiciales', 'web', 'd1000000-0000-0000-0000-000000000002', '51000000-0000-0000-0000-000000000002', true, NOW()),
  ('c1000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-00000000000a', 'Recursos Humanos', 'RRHH', 'Gestion administrativa del personal municipal', 'web', 'd1000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000001', true, NOW())
ON CONFLICT (id) DO NOTHING;

UPDATE "100_test"."case_templates" SET visibility = 'reservado' WHERE id = 'c1000000-0000-0000-0000-000000000005';


INSERT INTO "100_test"."registry_families"
  (id, global_registry_family_id, code, name, description, data_schema, states, is_active, created_at)
VALUES
(
  'f1000000-0000-0000-0000-000000000001',
  'f0000000-0000-0000-0000-000000000001',
  'ARQ',
  'Registro de Arquitectura y Obras Particulares',
  'Legajos de obras, habilitaciones y permisos de construccion',
  '{"direccion":{"type":"text","label":"Direccion","required":true,"has_document":false,"has_expiration":false,"has_verification":false},"tipo_obra":{"type":"select","label":"Tipo de Obra","options":["Nueva","Ampliacion","Refaccion","Demolicion"],"required":true,"has_document":false,"has_expiration":false,"has_verification":false},"superficie_m2":{"type":"number","label":"Superficie (m2)","required":false,"has_document":false,"has_expiration":false,"has_verification":false},"plano_aprobado":{"type":"text","label":"Plano Aprobado","required":false,"has_document":true,"has_expiration":false,"has_verification":true},"matricula_profesional":{"type":"text","label":"Matricula Profesional","required":false,"has_document":true,"has_expiration":true,"has_verification":true},"seguro_rc":{"type":"text","label":"Seguro de Responsabilidad Civil","required":false,"has_document":true,"has_expiration":true,"has_verification":true},"final_obra":{"type":"boolean","label":"Final de Obra","required":false,"has_document":true,"has_expiration":false,"has_verification":true}}'::jsonb,
  '["Activo","En Inspeccion","Aprobado","Rechazado","Suspendido","Archivado"]'::jsonb,
  true,
  NOW()
),
(
  'f1000000-0000-0000-0000-000000000002',
  'f0000000-0000-0000-0000-000000000002',
  'LUM',
  'Registro de Luminarias y Alumbrado Publico',
  'Legajos de instalaciones de alumbrado, reclamos y mantenimiento',
  '{"ubicacion":{"type":"text","label":"Ubicacion","required":true,"has_document":false,"has_expiration":false,"has_verification":false},"tipo_luminaria":{"type":"select","label":"Tipo de Luminaria","options":["LED","Sodio","Halogena","Otro"],"required":true,"has_document":false,"has_expiration":false,"has_verification":false},"potencia_w":{"type":"number","label":"Potencia (W)","required":false,"has_document":false,"has_expiration":false,"has_verification":false},"estado_fisico":{"type":"select","label":"Estado Fisico","options":["Bueno","Regular","Malo","Destruido"],"required":false,"has_document":false,"has_expiration":false,"has_verification":true},"proveedor":{"type":"text","label":"Proveedor","required":false,"has_document":true,"has_expiration":false,"has_verification":false},"ultima_revision":{"type":"date","label":"Ultima Revision","required":false,"has_document":false,"has_expiration":true,"has_verification":true}}'::jsonb,
  '["Activo","En Reparacion","Fuera de Servicio","Reemplazado","Archivado"]'::jsonb,
  true,
  NOW()
),
(
  'f1000000-0000-0000-0000-000000000003',
  'f0000000-0000-0000-0000-000000000003',
  'NORMA',
  'Normativa HCD',
  'Registro de normativa emitida por el Honorable Concejo Deliberante',
  '{"numero_norma":{"type":"text","label":"Numero de Norma","required":true,"has_document":false,"has_expiration":false,"has_verification":false},"tipo_norma":{"type":"select","label":"Tipo de Norma","options":["Ordenanza","Resolucion","Comunicacion","Declaracion","Ordenanza Fiscal","Ordenanza Tributaria"],"required":true,"has_expiration":false,"has_verification":false},"fecha_sancion":{"type":"date","label":"Fecha de Sancion","required":true,"has_document":false,"has_expiration":false,"has_verification":false},"materia":{"type":"select","label":"Materia","options":["Recursos Humanos","Salud Publica","Tierras","Tributario","Nomenclatura","Seguridad","Institucional","Transporte","Presupuesto","Seguridad Social","Medio Ambiente","Obras Publicas","Educacion","Cultura","Otro"],"required":false,"has_document":false,"has_expiration":false,"has_verification":false},"numero_expediente":{"type":"text","label":"Expediente HCD","required":false,"has_expiration":false,"has_verification":false},"sesion_tipo":{"type":"select","label":"Tipo de Sesion","options":["Ordinaria","Extraordinaria","Especial","Asamblea","Preparatoria","Prorroga"],"required":false,"has_expiration":false,"has_verification":false},"sesion_fecha":{"type":"date","label":"Fecha de Sesion","required":false,"has_document":false,"has_expiration":false,"has_verification":false},"sesion_numero":{"type":"text","label":"Numero de Sesion","required":false,"has_expiration":false,"has_verification":false}}'::jsonb,
  '["Vigente","Derogada","Modificada","Suspendida","En Revision","Archivada"]'::jsonb,
  true,
  NOW()
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO "100_test"."registry_family_permissions"
  (registry_family_id, sector_id, can_create, can_edit, can_view, can_verify, created_at)
VALUES
  ('f1000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-00000000000a', true, true, true, true, NOW()),
  ('f1000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000009', true, true, true, true, NOW()),
  ('f1000000-0000-0000-0000-000000000002', '51000000-0000-0000-0000-000000000009', true, true, true, true, NOW()),
  ('f1000000-0000-0000-0000-000000000003', '51000000-0000-0000-0000-000000000002', true, true, true, true, NOW())
ON CONFLICT ON CONSTRAINT "rfp_unique" DO NOTHING;


INSERT INTO "100_test"."document_draft"
  (id, created_by, document_type_id, reference, content, status, created_at)
VALUES
  (
    'dd000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000001',
    1,
    'Bienvenida a GDI',
    '{"html": "<h2>Bienvenido a GDI</h2><p>Este es su primer documento en el Sistema de Gestion Documental Inteligente.</p><p>Desde aqui puede crear, firmar y gestionar documentos oficiales de forma digital.</p><p><strong>Intendencia</strong></p>"}'::jsonb,
    'draft',
    NOW()
  ),
  (
    'dd000000-0000-0000-0000-000000000002',
    'a1000000-0000-0000-0000-000000000002',
    1,
    'Bienvenida a GDI',
    '{"html": "<h2>Bienvenido a GDI</h2><p>Este es su primer documento en el Sistema de Gestion Documental Inteligente.</p><p>Desde aqui puede crear, firmar y gestionar documentos oficiales de forma digital.</p><p><strong>Legal y Tecnica</strong></p>"}'::jsonb,
    'draft',
    NOW()
  ),
  (
    'dd000000-0000-0000-0000-000000000003',
    'a1000000-0000-0000-0000-000000000003',
    1,
    'Bienvenida a GDI',
    '{"html": "<h2>Bienvenido a GDI</h2><p>Este es su primer documento en el Sistema de Gestion Documental Inteligente.</p><p>Desde aqui puede crear, firmar y gestionar documentos oficiales de forma digital.</p><p><strong>Innovacion</strong></p>"}'::jsonb,
    'draft',
    NOW()
  ),
  (
    'dd000000-0000-0000-0000-000000000004',
    'a1000000-0000-0000-0000-000000000005',
    1,
    'Bienvenida a GDI',
    '{"html": "<h2>Bienvenido a GDI</h2><p>Este es su primer documento en el Sistema de Gestion Documental Inteligente.</p><p>Desde aqui puede crear, firmar y gestionar documentos oficiales de forma digital.</p><p><strong>Hacienda</strong></p>"}'::jsonb,
    'draft',
    NOW()
  ),
  (
    'dd000000-0000-0000-0000-000000000005',
    'a1000000-0000-0000-0000-000000000008',
    1,
    'Bienvenida a GDI',
    '{"html": "<h2>Bienvenido a GDI</h2><p>Este es su primer documento en el Sistema de Gestion Documental Inteligente.</p><p>Desde aqui puede crear, firmar y gestionar documentos oficiales de forma digital.</p><p><strong>Seguridad</strong></p>"}'::jsonb,
    'draft',
    NOW()
  )
ON CONFLICT (id) DO NOTHING;


DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'SEED DEMO 100_test COMPLETADO';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'SCHEMA 100_test:';
    RAISE NOTICE '  37 tablas creadas (Grupos A-J: +case_responsibles +case_favorites +case_user_views +notification_dismissals GDI-067)';
    RAISE NOTICE '  Todos los indices creados (incluye Grupo J: 5 indices + case_user_views GDI-067)';
    RAISE NOTICE '  Trigger de sync con user_registry activado';
    RAISE NOTICE '';
    RAISE NOTICE 'SCHEMA 100_test_audit:';
    RAISE NOTICE '  audit_log table creada';
    RAISE NOTICE '  fn_log_change function creada';
    RAISE NOTICE '  6 triggers activados (departments, sectors, official_documents, cases, case_movements, case_official_documents)';
    RAISE NOTICE '';
    RAISE NOTICE 'DATOS DEMO:';
    RAISE NOTICE '  10 Departamentos (INTE, LEGAL, INNO, SAL, HAC, TESO, CONT, SEG, OOPU, OOPA)';
    RAISE NOTICE '  14 Sectores (10 PRIV + 4 MESA/ADMIN)';
    RAISE NOTICE '  3 Ranks (Intendente, Secretario, Director)';
    RAISE NOTICE '  4 City Seals (Innovador, Intendente, Secretario, Director)';
    RAISE NOTICE '  15 Usuarios ficticios (@munitest.com)';
    RAISE NOTICE '  15 User Seals y Roles';
    RAISE NOTICE '  20 Document Types (IF, NOTA, PROV, ACT, RESOL, etc.)';
    RAISE NOTICE '  6 Case Templates (TEST, HABI, HIND, COMP, DEM, RRHH)';
    RAISE NOTICE '  3 Registry Families (ARQ, LUM, NORMA) con permisos';
    RAISE NOTICE '  5 Drafts de bienvenida (IF)';
    RAISE NOTICE '  Settings y estado_users iniciales';
    RAISE NOTICE '  Municipio registrado en public.municipalities';
    RAISE NOTICE '  API key GDI-AgenteLANG creada';
    RAISE NOTICE '  ai_usage_limits configurado ($0.15/dia)';
    RAISE NOTICE '';
    RAISE NOTICE 'LISTO PARA USAR:';
    RAISE NOTICE '  - Frontend puede hacer login con usuarios @munitest.com';
    RAISE NOTICE '  - Backend puede acceder al schema 100_test directamente';
    RAISE NOTICE '  - Auditoría activada en 100_test_audit';
    RAISE NOTICE '============================================================';
END $$;
