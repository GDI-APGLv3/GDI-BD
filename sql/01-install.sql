

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE OR REPLACE FUNCTION public.immutable_unaccent(text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
STRICT
AS $$
    SELECT public.unaccent('public.unaccent'::regdictionary, $1)
$$;

ALTER DATABASE railway SET timezone = 'America/Argentina/Buenos_Aires';


CREATE OR REPLACE FUNCTION public.fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TYPE IF EXISTS "public"."country_enum" CASCADE;
CREATE TYPE "public"."country_enum" AS ENUM (
  'AR',
  'BR',
  'UY',
  'CL',
  'PY',
  'BO',
  'PE',
  'EC',
  'CO',
  'VE',
  'MX'
);

DROP TYPE IF EXISTS "public"."document_status" CASCADE;
CREATE TYPE "public"."document_status" AS ENUM (
  'draft',
  'sent_to_sign',
  'signed',
  'rejected',
  'cancelled'
);

DROP TYPE IF EXISTS "public"."document_signer_status" CASCADE;
CREATE TYPE "public"."document_signer_status" AS ENUM (
  'pending',
  'signed',
  'rejected'
);

DROP TYPE IF EXISTS "public"."movement_type" CASCADE;
CREATE TYPE "public"."movement_type" AS ENUM (
  'creation',
  'transfer',
  'assignment',
  'assignment_close',
  'status_change',
  'document_link',
  'subsanacion',
  'document_proposal',
  'document_proposal_reject',
  'responsible_add',
  'responsible_remove',
  'comment',
  'task',
  'citizen_share',
  'citizen_unshare',
  'citizen_notify'
);

DROP TYPE IF EXISTS "public"."status_case" CASCADE;
CREATE TYPE "public"."status_case" AS ENUM (
  'inactive',
  'active',
  'archived'
);

DROP TYPE IF EXISTS "public"."case_creation_channel" CASCADE;
CREATE TYPE "public"."case_creation_channel" AS ENUM (
  'web',
  'api',
  'both'
);

DROP TYPE IF EXISTS "public"."document_type_source" CASCADE;
CREATE TYPE "public"."document_type_source" AS ENUM (
  'HTML',
  'Importado',
  'NOTA',
  'MEMO',
  'FFCC'
);


DROP TABLE IF EXISTS "public"."roles" CASCADE;
CREATE TABLE "public"."roles" (
  "role_id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "role_name" VARCHAR(50) NOT NULL,
  "description" TEXT,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "roles_pkey" PRIMARY KEY ("role_id"),
  CONSTRAINT "roles_name_unique" UNIQUE ("role_name")
);

COMMENT ON TABLE "public"."roles" IS 'Roles globales del sistema';


DROP TABLE IF EXISTS "public"."global_document_types" CASCADE;
CREATE TABLE "public"."global_document_types" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "name" VARCHAR(100) NOT NULL,
  "acronym" VARCHAR(6) NOT NULL,
  "description" TEXT,
  "signature_policy" VARCHAR(50) DEFAULT 'required',
  "is_visible" BOOLEAN NOT NULL DEFAULT true,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "type" "public"."document_type_source" NOT NULL DEFAULT 'HTML',
  "trust" BOOLEAN NOT NULL DEFAULT true,
  "special_numbering" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "global_document_types_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "global_document_types_acronym_unique" UNIQUE ("acronym"),
  CONSTRAINT "global_document_types_acronym_length" CHECK (char_length(acronym) <= 6)
);

COMMENT ON TABLE "public"."global_document_types" IS 'Tipos de documento globales';
COMMENT ON COLUMN "public"."global_document_types"."is_visible" IS 'false para tipos de uso interno (PV, CAEX)';
COMMENT ON COLUMN "public"."global_document_types"."type" IS 'HTML = creado con editor, Importado = PDF subido';
COMMENT ON COLUMN "public"."global_document_types"."trust" IS 'true = documento gobierno (confiable), false = documento externo (requiere validacion IA)';
COMMENT ON COLUMN "public"."global_document_types"."special_numbering" IS 'true = numeracion especial por tipo+departamento (DECRE, RESOL, ORD, DISPO), false = numeracion global';


DROP TABLE IF EXISTS "public"."global_case_templates" CASCADE;
CREATE TABLE "public"."global_case_templates" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "type_name" VARCHAR(100) NOT NULL,
  "acronym" VARCHAR(6) NOT NULL,
  "description" TEXT,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "global_case_templates_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "global_case_templates_acronym_unique" UNIQUE ("acronym")
);

COMMENT ON TABLE "public"."global_case_templates" IS 'Plantillas de expediente globales';


DROP TABLE IF EXISTS "public"."municipalities" CASCADE;
CREATE TABLE "public"."municipalities" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "name" TEXT NOT NULL,
  "acronym" VARCHAR(8) NOT NULL,
  "country" "public"."country_enum" NOT NULL,
  "primary_color" VARCHAR(6) NOT NULL DEFAULT '16158C',
  "schema_number" INT NOT NULL,
  "schema_name" TEXT NOT NULL,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "created_by" UUID,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "municipalities_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "municipalities_acronym_unique" UNIQUE ("acronym"),
  CONSTRAINT "municipalities_schema_number_unique" UNIQUE ("schema_number"),
  CONSTRAINT "municipalities_schema_name_unique" UNIQUE ("schema_name")
);

COMMENT ON TABLE "public"."municipalities" IS 'Lista de municipios (cada uno tiene su schema)';
COMMENT ON COLUMN "public"."municipalities"."acronym" IS 'Sigla del municipio: 2-8 caracteres [A-Z0-9] (GDI-356). Si no se provee en el alta se autogenera con 4 letras WXYZ; cambia cuando pagan. Da nombre al schema y a los buckets R2, que quedan fijos en settings.';
COMMENT ON COLUMN "public"."municipalities"."schema_number" IS 'Numero auto-incremental desde 100';


DROP TABLE IF EXISTS "public"."document_display_states" CASCADE;
CREATE TABLE "public"."document_display_states" (
  "id" SERIAL NOT NULL,
  "display_state_code" VARCHAR(50) NOT NULL,
  "display_state_name" VARCHAR(100) NOT NULL,
  "description" TEXT,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "document_display_states_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "document_display_states_code_unique" UNIQUE ("display_state_code")
);

COMMENT ON TABLE "public"."document_display_states" IS 'Estados de visualizacion de documentos';


DROP TABLE IF EXISTS "public"."user_registry" CASCADE;
CREATE TABLE "public"."user_registry" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "email" TEXT NOT NULL,
  "schema_name" TEXT NOT NULL,
  "is_default" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "user_registry_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_registry_email_schema_unique" UNIQUE ("email", "schema_name")
);

COMMENT ON TABLE "public"."user_registry" IS 'Mapeo de email a schemas permitidos (multi-tenant). Nombre municipio se obtiene de municipalities.name, foto de perfil de {schema}.users';
COMMENT ON COLUMN "public"."user_registry"."is_default" IS 'Municipio por defecto del usuario';

CREATE INDEX "idx_user_registry_email" ON "public"."user_registry" ("email");


DROP TABLE IF EXISTS "public"."api_keys" CASCADE;
CREATE TABLE "public"."api_keys" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "api_key_hash" VARCHAR(64) NOT NULL,
  "api_key_prefix" VARCHAR(16) NOT NULL,
  "municipality_id" UUID NOT NULL,
  "name" VARCHAR(100) NOT NULL,
  "description" TEXT,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "expires_at" TIMESTAMPTZ,
  "last_used_at" TIMESTAMPTZ,
  "rate_limit_per_minute" INT DEFAULT 60,
  "created_by" VARCHAR(100),
  "key_type" VARCHAR(20) NOT NULL DEFAULT 'api',
  "allowed_origins" JSONB,
  "webhook_url" TEXT,
  "webhook_secret" TEXT,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "api_keys_municipality_fkey" FOREIGN KEY ("municipality_id") REFERENCES "public"."municipalities" ("id")
);

COMMENT ON TABLE "public"."api_keys" IS 'API Keys para REST API de GDI-MCP Server';
COMMENT ON COLUMN "public"."api_keys"."api_key_hash" IS 'SHA-256 hex del API key (64 chars). La key completa solo se muestra al crearla';
COMMENT ON COLUMN "public"."api_keys"."api_key_prefix" IS 'Primeros 12 chars del API key para identificacion visual';
COMMENT ON COLUMN "public"."api_keys"."municipality_id" IS 'Municipalidad asociada - determina el schema';
COMMENT ON COLUMN "public"."api_keys"."name" IS 'Nombre descriptivo del cliente/integración';
COMMENT ON COLUMN "public"."api_keys"."expires_at" IS 'NULL = no expira';
COMMENT ON COLUMN "public"."api_keys"."last_used_at" IS 'Se actualiza en cada uso';
COMMENT ON COLUMN "public"."api_keys"."rate_limit_per_minute" IS 'Límite de requests por minuto';

CREATE UNIQUE INDEX "idx_api_keys_hash" ON "public"."api_keys" ("api_key_hash") WHERE "is_active" = true;

CREATE INDEX "idx_api_keys_municipality" ON "public"."api_keys" ("municipality_id");


DROP TABLE IF EXISTS "public"."api_key_users" CASCADE;
CREATE TABLE "public"."api_key_users" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "api_key_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "schema_name" VARCHAR(100) NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "api_key_users_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "api_key_users_key_user_schema_unique" UNIQUE ("api_key_id", "user_id", "schema_name"),
  CONSTRAINT "api_key_users_key_fkey" FOREIGN KEY ("api_key_id") REFERENCES "public"."api_keys" ("id") ON DELETE CASCADE
);

COMMENT ON TABLE "public"."api_key_users" IS 'Usuarios autorizados por API Key para REST API';
COMMENT ON COLUMN "public"."api_key_users"."user_id" IS 'UUID del usuario en el schema del tenant';
COMMENT ON COLUMN "public"."api_key_users"."schema_name" IS 'Schema donde existe el usuario (ej: 100_test)';

CREATE INDEX "idx_api_key_users_key" ON "public"."api_key_users" ("api_key_id");

CREATE INDEX "idx_api_key_users_user" ON "public"."api_key_users" ("user_id", "schema_name");


DROP TABLE IF EXISTS "public"."global_registry_families" CASCADE;
CREATE TABLE "public"."global_registry_families" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "code" VARCHAR(10) NOT NULL,
  "name" VARCHAR(200) NOT NULL,
  "description" TEXT,
  "default_data_schema" JSONB DEFAULT '{}',
  "default_states" JSONB DEFAULT '["Activo","Inactivo","Suspendido","Archivado"]',
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT "global_registry_families_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "global_registry_families_code_unique" UNIQUE ("code")
);

COMMENT ON TABLE "public"."global_registry_families" IS 'Familias de registros globales con esquema de datos por defecto';
COMMENT ON COLUMN "public"."global_registry_families"."default_data_schema" IS 'Schema JSONB que define los campos del registro';
COMMENT ON COLUMN "public"."global_registry_families"."default_states" IS 'Array JSON de estados posibles del registro';


CREATE TABLE IF NOT EXISTS "public"."tenant_certificates" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenant_id" VARCHAR(63) NOT NULL,
    "r2_bucket" VARCHAR(63) NOT NULL DEFAULT 'gdi-certificates',
    "r2_key" VARCHAR(255) NOT NULL,
    "encrypted_password" TEXT NOT NULL,
    "subject_cn" VARCHAR(255),
    "subject_org" VARCHAR(255),
    "issuer_cn" VARCHAR(255),
    "serial_number" TEXT,
    "not_valid_before" TIMESTAMPTZ,
    "not_valid_after" TIMESTAMPTZ,
    "fingerprint_sha256" VARCHAR(64),
    "file_size_bytes" INTEGER,
    "is_active" BOOLEAN DEFAULT true,
    "uploaded_by" VARCHAR(255),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "tenant_certificates_tenant_unique" UNIQUE ("tenant_id"),
    CONSTRAINT "fk_tenant_cert_municipality"
        FOREIGN KEY ("tenant_id") REFERENCES "public"."municipalities"("schema_name")
        ON DELETE RESTRICT
);

COMMENT ON TABLE "public"."tenant_certificates" IS 'Certificados digitales por tenant para firma PAdES';
COMMENT ON COLUMN "public"."tenant_certificates"."encrypted_password" IS 'Password del .p12 encriptada con Fernet';
COMMENT ON COLUMN "public"."tenant_certificates"."r2_key" IS 'Path en R2: certificates/{tenant_id}.p12';

CREATE INDEX "idx_tenant_cert_expiry"
    ON "public"."tenant_certificates" ("not_valid_after");

CREATE TABLE IF NOT EXISTS "public"."license_state" (
    "id"               INT          PRIMARY KEY DEFAULT 1,
    "license_id"       VARCHAR(64),
    "status"           VARCHAR(32)  NOT NULL,
    "max_tenants"      INT          NOT NULL DEFAULT 0,
    "features"         JSONB        DEFAULT '[]',
    "expires_at"       DATE,
    "grace_until"      DATE,
    "max_observed_at"  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "last_verified_at" TIMESTAMPTZ  DEFAULT NOW(),
    "revoked"          BOOLEAN      DEFAULT FALSE,
    "revoke_message"   TEXT,
    CONSTRAINT "license_state_singleton" CHECK ("id" = 1)
);

COMMENT ON TABLE "public"."license_state" IS
    'Cache del estado de la licencia .lic (solo se usa en on-premise). Single-row (id=1).';

CREATE TABLE IF NOT EXISTS "public"."firma_audit_log" (
    "id"                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    "created_at"               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "schema_name"              TEXT        NOT NULL,
    "session_id"               VARCHAR(50),
    "signature_method"         TEXT        NOT NULL,
    "user_id"                  UUID        NOT NULL,
    "actor_type"               VARCHAR(10) NOT NULL DEFAULT 'user',
    "user_cuit"                TEXT,
    "document_id"              UUID        NOT NULL,
    "official_number"          TEXT,
    "document_hash_pre"        BYTEA,
    "document_hash_post"       BYTEA,
    "cert_serial"              TEXT,
    "cert_issuer_dn"           TEXT,
    "cert_subject_dn"          TEXT,
    "cert_subject_cuit"        TEXT,
    "cert_not_after"           TIMESTAMPTZ,
    "cert_policy_oids"         TEXT[],
    "signature_algorithm"      TEXT,
    "signature_level"          TEXT,
    "tsa_url"                  TEXT,
    "tsa_serial"               TEXT,
    "tsa_time"                 TIMESTAMPTZ,
    "server_time"              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "time_skew_seconds"        INT,
    "ip_address"               INET,
    "user_agent"               TEXT,
    "revocation_method"        TEXT,
    "revocation_status"        TEXT,
    "revocation_check_time"    TIMESTAMPTZ,
    "result"                   TEXT        NOT NULL,
    "failure_reason"           TEXT,
    "r2_object_key"            TEXT,

    CONSTRAINT "firma_audit_log_method_chk" CHECK (
        "signature_method" IN ('electronic','digital_token','digital_cloud')
    ),
    CONSTRAINT "firma_audit_log_actor_type_chk" CHECK (
        "actor_type" IN ('user','citizen')
    ),
    CONSTRAINT "firma_audit_log_level_chk" CHECK (
        "signature_level" IS NULL OR "signature_level" IN ('B-B','B-T','B-LT','B-LTA')
    ),
    CONSTRAINT "firma_audit_log_revstatus_chk" CHECK (
        "revocation_status" IS NULL OR "revocation_status" IN ('good','revoked','unknown')
    )
);

COMMENT ON TABLE "public"."firma_audit_log" IS
    'Audit trail Ley 25.506. INSERT-only. Retención 10 años.';
COMMENT ON COLUMN "public"."firma_audit_log"."actor_type" IS
    'GDI-130 (TAD): user_id contiene el UUID de users (actor_type=user) o de citizens (actor_type=citizen). DEFAULT user mantiene válidas las filas/escrituras previas a TAD.';

CREATE INDEX IF NOT EXISTS "idx_firma_audit_log_created_schema"
    ON "public"."firma_audit_log" ("created_at", "schema_name");
CREATE INDEX IF NOT EXISTS "idx_firma_audit_log_session"
    ON "public"."firma_audit_log" ("session_id");
CREATE INDEX IF NOT EXISTS "idx_firma_audit_log_user"
    ON "public"."firma_audit_log" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_firma_audit_log_document"
    ON "public"."firma_audit_log" ("document_id");
CREATE INDEX IF NOT EXISTS "idx_firma_audit_log_result"
    ON "public"."firma_audit_log" ("result");

REVOKE ALL ON "public"."firma_audit_log" FROM PUBLIC;
REVOKE UPDATE, DELETE, TRUNCATE ON "public"."firma_audit_log" FROM PUBLIC;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE UPDATE, DELETE, TRUNCATE ON "public"."firma_audit_log" FROM authenticated;
        GRANT  INSERT, SELECT ON "public"."firma_audit_log" TO authenticated;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.signing_sessions (
    session_id      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    schema_name     TEXT        NOT NULL,
    document_id     UUID        NOT NULL,
    reservation_id  UUID,
    user_id         UUID,
    citizen_id      UUID,
    job_type        TEXT        NOT NULL DEFAULT 'sign',
    status          TEXT        NOT NULL DEFAULT 'pending',
    expires_at      TIMESTAMPTZ NOT NULL,
    available_at    TIMESTAMPTZ,
    claimed_at      TIMESTAMPTZ,
    claimed_by      TEXT,
    payload         JSONB,
    failure_reason  TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT signing_sessions_status_chk
        CHECK (status IN ('pending', 'processing', 'signed', 'failed', 'expired')),
    CONSTRAINT signing_sessions_job_type_chk
        CHECK (job_type IN ('sign', 'sign_common', 'dts', 'sign_citizen', 'digital_complete')),
    CONSTRAINT signing_sessions_firmante_chk
        CHECK (num_nonnulls(user_id, citizen_id) = 1)
);

COMMENT ON TABLE public.signing_sessions IS
    'Cola de jobs del worker escri (GDI-075/T-E9). Doble rol: cola (LISTEN/NOTIFY + SKIP LOCKED) + estado de poll. '
    'job_type sign=firma async GLOBAL numerador (con reserva de número), '
    'sign_common=firma async firmante común (sin reserva de número), dts=timestamp diferido B-B→B-T, '
    'sign_citizen=firma async del ciudadano vía TAD (GDI-205; el firmante va en citizen_id).';

COMMENT ON COLUMN public.signing_sessions.reservation_id IS
    'NULL para jobs dts y sign_common (no reservan número).';

COMMENT ON COLUMN public.signing_sessions.expires_at IS
    'El worker renueva este campo al hacer claim (O1): si el job esperó en cola, '
    'el worker igual tiene su ventana completa de procesamiento.';

COMMENT ON COLUMN public.signing_sessions.available_at IS
    'Gating temporal del claim: el worker no toma este job antes de este instante. '
    'NULL = disponible ya. Distinta de expires_at (TTL de procesamiento para el sweeper).';

COMMENT ON COLUMN public.signing_sessions.claimed_by IS
    'Identificador del worker que tomó el job (ej: hostname:pid). '
    'Permite detectar jobs huérfanos y correlacionar logs.';

CREATE INDEX IF NOT EXISTS idx_signing_sessions_pending
    ON public.signing_sessions (job_type DESC, created_at ASC, available_at)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_signing_sessions_status_expires
    ON public.signing_sessions (status, expires_at);

CREATE INDEX IF NOT EXISTS idx_signing_sessions_schema
    ON public.signing_sessions (schema_name);

CREATE INDEX IF NOT EXISTS idx_signing_sessions_reservation
    ON public.signing_sessions (reservation_id)
    WHERE reservation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_signing_sessions_schema_doc
    ON public.signing_sessions (schema_name, document_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_signing_sessions_dts_active_unique
    ON public.signing_sessions (schema_name, document_id)
    WHERE job_type = 'dts'
      AND status IN ('pending', 'processing');

CREATE UNIQUE INDEX IF NOT EXISTS idx_signing_sessions_sign_active_unique
    ON public.signing_sessions (schema_name, document_id, user_id)
    WHERE job_type = 'sign'
      AND status IN ('pending', 'processing');

CREATE INDEX IF NOT EXISTS idx_signing_sessions_fallidas_por_usuario
    ON public.signing_sessions (schema_name, user_id, updated_at DESC)
    WHERE status IN ('failed', 'expired');

CREATE UNIQUE INDEX IF NOT EXISTS idx_signing_sessions_sign_common_active_unique
    ON public.signing_sessions (schema_name, document_id, user_id)
    WHERE job_type = 'sign_common'
      AND status IN ('pending', 'processing');

CREATE UNIQUE INDEX IF NOT EXISTS idx_signing_sessions_citizen_active_unique
    ON public.signing_sessions (schema_name, document_id, citizen_id)
    WHERE job_type = 'sign_citizen'
      AND status IN ('pending', 'processing');

CREATE UNIQUE INDEX IF NOT EXISTS idx_signing_sessions_digital_complete_active_unique
    ON public.signing_sessions (schema_name, document_id, user_id)
    WHERE job_type = 'digital_complete'
      AND status IN ('pending', 'processing');

CREATE TABLE IF NOT EXISTS public.job_heartbeats (
    job_name                     TEXT        PRIMARY KEY,
    last_run_completed_at        TIMESTAMPTZ NULL,
    last_close_run_completed_at  TIMESTAMPTZ NULL,
    state                        JSONB       NOT NULL DEFAULT '{}'::jsonb,
    updated_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.job_heartbeats IS
    'GDI-304: una fila por job del lifespan. Responde "el job corrio?". El heartbeat '
    'se escribe al TERMINAR la corrida y tambien con el flag apagado: si no, "no corrio" '
    'y "esta apagado" son indistinguibles y la alerta dispara todas las noches con el '
    'sistema sano.';

CREATE TABLE IF NOT EXISTS public.tad_webhook_jobs (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    schema_name   TEXT        NOT NULL,
    api_key_id    UUID        NOT NULL,
    event_type    TEXT        NOT NULL,
    payload       JSONB       NOT NULL,
    status        TEXT        NOT NULL DEFAULT 'pending',
    attempts      INT         NOT NULL DEFAULT 0,
    available_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMPTZ,
    claimed_by    TEXT,
    last_error    TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT tad_webhook_jobs_status_chk
        CHECK (status IN ('pending', 'processing', 'sent', 'failed')),
    CONSTRAINT tad_webhook_jobs_api_key_fkey
        FOREIGN KEY (api_key_id) REFERENCES public.api_keys (id)
);

COMMENT ON TABLE public.tad_webhook_jobs IS
    'GDI-130 (TAD): cola de eventos webhook hacia el software del municipio (ej. documents.notified). '
    'El secret HMAC vive en api_keys.webhook_secret (cifrado por la app).';

COMMENT ON COLUMN public.tad_webhook_jobs.available_at IS
    'Gating temporal del claim: el worker no toma este job antes de este instante (backoff de reintentos).';

COMMENT ON COLUMN public.tad_webhook_jobs.claimed_by IS
    'Identificador del worker que tomó el job (ej: hostname:pid), para detectar jobs huérfanos.';

CREATE INDEX IF NOT EXISTS idx_tad_webhook_jobs_claim
    ON public.tad_webhook_jobs (status, available_at);

CREATE INDEX IF NOT EXISTS idx_tad_webhook_jobs_schema
    ON public.tad_webhook_jobs (schema_name);
CREATE INDEX IF NOT EXISTS idx_tad_webhook_jobs_api_key
    ON public.tad_webhook_jobs (api_key_id);

CREATE TABLE IF NOT EXISTS public.tad_idempotency_keys (
    api_key_id          UUID        NOT NULL,
    idempotency_key     TEXT        NOT NULL,
    schema_name         TEXT        NOT NULL,
    citizen_id          UUID        NOT NULL,
    request_fingerprint TEXT        NOT NULL,
    status              TEXT        NOT NULL DEFAULT 'in_flight',
    document_id         UUID,
    response_json       JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT tad_idempotency_keys_pkey
        PRIMARY KEY (api_key_id, idempotency_key),
    CONSTRAINT tad_idempotency_keys_status_chk
        CHECK (status IN ('in_flight', 'completed')),
    CONSTRAINT tad_idempotency_keys_completed_chk
        CHECK (status <> 'completed' OR (document_id IS NOT NULL AND response_json IS NOT NULL)),
    CONSTRAINT tad_idempotency_keys_api_key_fkey
        FOREIGN KEY (api_key_id) REFERENCES public.api_keys (id) ON DELETE CASCADE
);

COMMENT ON TABLE public.tad_idempotency_keys IS
    'Ventana de reintento seguro para POST /api/v1/tad/documents (24 h). Alcance = API Key (municipio).';

CREATE INDEX IF NOT EXISTS idx_tad_idempotency_keys_expiracion
    ON public.tad_idempotency_keys (api_key_id, expires_at);


DROP TRIGGER IF EXISTS trg_roles_updated_at ON "public"."roles";
CREATE TRIGGER trg_roles_updated_at BEFORE UPDATE ON "public"."roles"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_global_document_types_updated_at ON "public"."global_document_types";
CREATE TRIGGER trg_global_document_types_updated_at BEFORE UPDATE ON "public"."global_document_types"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_global_case_templates_updated_at ON "public"."global_case_templates";
CREATE TRIGGER trg_global_case_templates_updated_at BEFORE UPDATE ON "public"."global_case_templates"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_municipalities_updated_at ON "public"."municipalities";
CREATE TRIGGER trg_municipalities_updated_at BEFORE UPDATE ON "public"."municipalities"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_document_display_states_updated_at ON "public"."document_display_states";
CREATE TRIGGER trg_document_display_states_updated_at BEFORE UPDATE ON "public"."document_display_states"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_user_registry_updated_at ON "public"."user_registry";
CREATE TRIGGER trg_user_registry_updated_at BEFORE UPDATE ON "public"."user_registry"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_api_keys_updated_at ON "public"."api_keys";
CREATE TRIGGER trg_api_keys_updated_at BEFORE UPDATE ON "public"."api_keys"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_api_key_users_updated_at ON "public"."api_key_users";
CREATE TRIGGER trg_api_key_users_updated_at BEFORE UPDATE ON "public"."api_key_users"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_global_registry_families_updated_at ON "public"."global_registry_families";
CREATE TRIGGER trg_global_registry_families_updated_at BEFORE UPDATE ON "public"."global_registry_families"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_tenant_certificates_updated_at ON "public"."tenant_certificates";
CREATE TRIGGER trg_tenant_certificates_updated_at BEFORE UPDATE ON "public"."tenant_certificates"
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


CREATE TABLE IF NOT EXISTS "public"."backup_access_log" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "api_key_id" UUID NOT NULL,
    "schema_name" VARCHAR(100) NOT NULL,
    "action" VARCHAR(50) NOT NULL,
    "tables_synced" TEXT[],
    "records_count" INT DEFAULT 0,
    "ip_address" INET,
    "user_agent" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "backup_access_log_key_fkey" FOREIGN KEY ("api_key_id") REFERENCES "public"."api_keys"("id")
);

COMMENT ON TABLE "public"."backup_access_log" IS 'Log de accesos del sistema de backup';

CREATE INDEX "idx_backup_access_log_key" ON "public"."backup_access_log"("api_key_id");
CREATE INDEX "idx_backup_access_log_schema" ON "public"."backup_access_log"("schema_name");
CREATE INDEX "idx_backup_access_log_created" ON "public"."backup_access_log"("created_at" DESC);


CREATE TABLE IF NOT EXISTS public.schema_migrations (
    "version"     TEXT        NOT NULL,
    "name"        TEXT        NOT NULL,
    "applied_at"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "applied_by"  TEXT,
    "checksum"    TEXT,
    CONSTRAINT schema_migrations_pkey PRIMARY KEY (version)
);

COMMENT ON TABLE public.schema_migrations IS
    'Migraciones aplicadas. Fuente de verdad del estado de la BD por ambiente.';

INSERT INTO public.schema_migrations (version, name, applied_at, applied_by) VALUES
    ('000', 'create_schema_migrations', '2026-07-05 11:57:05-03:00', '01-install baseline'),
    ('024', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('025', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('026', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('027', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('028', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('029', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('030', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('031', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('032', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('033', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('034', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('035', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('036', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('037', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('038', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('039', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('040', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('041', 'initial_archive_batch', '2026-04-20 21:00:00-03:00', '01-install baseline'),
    ('042a', 'ai_usage_log_operation_varchar40', '2026-05-04 21:00:00-03:00', '01-install baseline'),
    ('042b', 'case_responsibles_favorites', '2026-05-18 21:00:00-03:00', '01-install baseline'),
    ('043', 'rag_query_log', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('044', 'document_chunks_hybrid_search', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('045', 'firma_audit_log', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('047', 'document_types_signature_policy_rename', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('048a', 'digital_signature_sessions', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('048b', 'global_document_types_signature_policy', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('050', 'document_signers_firma_digital', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('051', 'document_signers_indices_firma_digital', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('052', 'firma_audit_log_session_id_varchar', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('053', 'movement_type_responsible_add_remove', '2026-05-27 21:00:00-03:00', '01-install baseline'),
    ('054', 'case_responsibles_table', '2026-05-18 21:00:00-03:00', '01-install baseline'),
    ('055', 'case_favorites_table', '2026-05-18 21:00:00-03:00', '01-install baseline'),
    ('056', 'catalog_proposals', '2026-04-30 21:00:00-03:00', '01-install baseline'),
    ('057', 'updated_at_case_responsibles_favorites', '2026-06-01 16:11:59-03:00', '01-install baseline'),
    ('058', 'checkpoint_indexes', '2026-05-29 11:45:57-03:00', '01-install baseline'),
    ('059', 'agentelang_polling_index', '2026-05-29 11:46:27-03:00', '01-install baseline'),
    ('060', 'departments_head_user_index', '2026-05-29 13:47:06-03:00', '01-install baseline'),
    ('061', 'ffcc', '2026-06-03 15:09:45-03:00', '01-install baseline'),
    ('063', 'ffcc_orthogonal', '2026-06-03 17:47:17-03:00', '01-install baseline'),
    ('064', 'add_auto_link_on_sign', '2026-06-03 17:24:20-03:00', '01-install baseline'),
    ('065', 'movimientos_chat', '2026-06-03 17:11:07-03:00', '01-install baseline'),
    ('066', 'nullable_global_fk', '2026-06-04 14:43:12-03:00', '01-install baseline'),
    ('067', 'multi_admin', '2026-06-06 12:38:20-03:00', '01-install baseline'),
    ('068', 'case_assignment_tasks', '2026-06-06 12:39:11-03:00', '01-install baseline'),
    ('068b', 'rename_cat_constraints_dev', '2026-07-05 11:57:05-03:00', '01-install baseline'),
    ('069', 'dtf_created_by_fk_index', '2026-06-09 16:53:04-03:00', '01-install baseline'),
    ('070', 'superadmin_audit', '2026-06-18 11:14:04-03:00', '01-install baseline'),
    ('071', 'license_state', '2026-07-02 12:22:05-03:00', '01-install baseline'),
    ('072', 'reservation_id', '2026-07-03 17:47:45-03:00', '01-install baseline'),
    ('073', 'digital_sessions_reservation_id', '2026-07-03 17:48:07-03:00', '01-install baseline'),
    ('074', 'signing_sessions', '2026-07-03 17:48:11-03:00', '01-install baseline'),
    ('075', 'settings_async_flag', '2026-07-03 17:48:14-03:00', '01-install baseline'),
    ('076', 'sistema_test_user_and_tst_type', '2026-07-03 17:48:17-03:00', '01-install baseline'),
    ('077', 'signing_sessions_available_at_dts_unique', '2026-07-03 17:48:20-03:00', '01-install baseline'),
    ('078', 'users_auth_id_uniq', '2026-07-05 11:57:05-03:00', '01-install baseline'),
    ('079', 'estado_users_archivado', '2026-07-05 11:57:05-03:00', '01-install baseline'),
    ('080', 'document_images', '2026-07-05 11:57:05-03:00', '01-install baseline'),
    ('081', 'embedded_files', '2026-07-05 11:57:05-03:00', '01-install baseline'),
    ('082', 'reserved_by_type', '2026-07-05 11:57:05-03:00', '01-install baseline'),
    ('083', 'performance_indices', '2026-07-05 18:28:02-03:00', '01-install baseline'),
    ('084', 'cases_last_modified_at', '2026-07-05 18:28:03-03:00', '01-install baseline'),
    ('085', 'global_doc_types_digesto', '2026-07-11 17:26:25-03:00', '01-install baseline'),
    ('086', 'public_information', '2026-07-13 16:37:40-03:00', '01-install baseline'),
    ('087', 'tad_ciudadano_f1', '2026-07-23 18:03:50-03:00', '01-install baseline'),
    ('088', 'tad_ciudadano_f2', '2026-07-23 18:03:50-03:00', '01-install baseline'),
    ('089', 'tad_ciudadano_f3', '2026-07-23 18:03:50-03:00', '01-install baseline'),
    ('090', 'tad_citizen_share_movements', '2026-07-23 20:09:05-03:00', '01-install baseline'),
    ('091', 'tad_citizen_notify_movement', '2026-07-24 12:49:31-03:00', '01-install baseline'),
    ('092', 'audit_citizens', '2026-07-27 10:19:37-03:00', '01-install baseline'),
    ('093', 'home_notifications', '2026-08-05 10:39:21-03:00', '01-install baseline'),
    ('094', 'home_performance_indices', '2026-08-07 19:01:45-03:00', '01-install baseline'),
    ('095', 'reconciliation_findings', '2026-08-12 12:51:12-03:00', '01-install baseline'),
    ('096', 'case_initiator_citizen', '2026-08-12 10:42:11-03:00', '01-install baseline'),
    ('097', 'gdi188_purge_system_doc_chunks', '2026-08-12 10:47:44-03:00', '01-install baseline'),
    ('098', 'signing_sessions_job_type_schema_index', '2026-08-13 11:31:01-03:00', '01-install baseline'),
    ('099', 'gdi171_gdi172_embedding_halfvec_768', '2026-08-12 16:13:13-03:00', '01-install baseline'),
    ('100', 'signing_sessions_sign_common_job_type', '2026-08-13 17:17:20-03:00', '01-install baseline'),
    ('101', 'gdi270_preoficial_pdf_location', '2026-08-15 09:57:18-03:00', '01-install baseline'),
    ('102', 'gdi209_indice_year_global_sequence', '2026-08-15 09:57:19-03:00', '01-install baseline'),
    ('103', 'gdi271_signing_sessions_sign_unique', '2026-08-15 15:12:45-03:00', '01-install baseline'),
    ('104', 'reconcile_dup_kind_y_sign_common_unique', '2026-08-19 19:03:33-03:00', '01-install baseline'),
    ('105', 'gdi304_tsa_seal_state_y_job_heartbeats', '2026-08-20 16:27:46-03:00', '01-install baseline'),
    ('106', 'gdi205_signing_sessions_citizen', '2026-08-20 16:27:59-03:00', '01-install baseline'),
    ('107', 'gdi316_drop_electronic_signing_async', '2026-08-21 09:43:33-03:00', '01-install baseline'),
    ('108', 'gdi218_idx_firmas_fallidas_por_usuario', '2026-08-20 20:34:14-03:00', '01-install baseline'),
    ('109', 'tad_idempotency_keys', '2026-08-21 14:46:19-03:00', '01-install baseline'),
    ('110', 'gdi205_idx_citizen_unique_concurrently', '2026-08-21 14:46:20-03:00', '01-install baseline'),
    ('113', 'jit_off_a_nivel_base', '2026-08-21 20:46:46-03:00', '01-install baseline'),
    ('114', 'idx_trigram_busqueda_documentos', '2026-08-21 20:46:47-03:00', '01-install baseline'),
    ('115', 'idx_perf_listados', '2026-08-22 12:43:10-03:00', '01-install baseline'),
    ('116', 'gdi266_cierre_digital_en_el_servidor', '2026-08-24 18:08:22-03:00', '01-install baseline'),
    ('117', 'gdi167_carril_special_por_tanda', '2026-08-24 18:08:23-03:00', '01-install baseline'),
    ('118', 'gdi167_tanda_de_firma_con_token', '2026-08-24 18:08:23-03:00', '01-install baseline'),
    ('119', 'gdi341_version_del_firmador', '2026-08-24 18:08:23-03:00', '01-install baseline'),
    ('120', 'gdi167_cierre_de_tanda_lleva_su_contexto', '2026-08-24 20:54:04-03:00', '01-install baseline'),
    ('121', 'gdi356_sigla_municipio_alfanumerica', '2026-08-25 12:06:59-03:00', '01-install baseline'),
    ('122', 'gdi167_carril_special_la_guarda_que_falto', '2026-08-26 17:53:40-03:00', '01-install baseline')
ON CONFLICT (version) DO NOTHING;


CREATE TABLE IF NOT EXISTS public.superadmin_audit (
    "id"             UUID        NOT NULL DEFAULT gen_random_uuid(),
    "actor_email"    TEXT        NOT NULL,
    "action"         TEXT        NOT NULL,
    "schema_name"    TEXT,
    "payload_before" JSONB,
    "payload_after"  JSONB,
    "ip_address"     INET,
    "created_at"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT superadmin_audit_pkey PRIMARY KEY (id)
);

COMMENT ON TABLE public.superadmin_audit IS
    'Auditoría de acciones de superadmin (BackOffice). INSERT-only.';

CREATE INDEX IF NOT EXISTS idx_superadmin_audit_created
    ON public.superadmin_audit USING btree (created_at DESC);

CREATE TABLE IF NOT EXISTS public.reconciliation_findings (
    "id"              UUID        NOT NULL DEFAULT gen_random_uuid(),
    "schema_name"     TEXT        NOT NULL,
    "kind"            TEXT        NOT NULL,
    "official_number" TEXT        NOT NULL,
    "document_id"     UUID,
    "detail"          JSONB       NOT NULL DEFAULT '{}'::jsonb,
    "first_seen_at"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "last_seen_at"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "resolved_at"     TIMESTAMPTZ,
    "alerted_at"      TIMESTAMPTZ,
    CONSTRAINT reconciliation_findings_pkey PRIMARY KEY (id),
    CONSTRAINT reconciliation_findings_kind_chk CHECK (kind = ANY (ARRAY[
        'pdf_sin_documento'::text,
        'documento_sin_pdf'::text,
        'pdf_location_desincronizada'::text,
        'pdf_duplicado_en_ambos_buckets'::text
    ]))
);

COMMENT ON TABLE public.reconciliation_findings IS
    'Hallazgos del reconciliador R2 <-> BD. Un hallazgo abierto = resolved_at IS NULL.';

CREATE UNIQUE INDEX IF NOT EXISTS reconciliation_findings_uniq
    ON public.reconciliation_findings USING btree (schema_name, kind, official_number);
CREATE INDEX IF NOT EXISTS reconciliation_findings_abiertos
    ON public.reconciliation_findings USING btree (schema_name, kind, first_seen_at)
    WHERE (resolved_at IS NULL);
CREATE INDEX IF NOT EXISTS reconciliation_findings_sin_alertar
    ON public.reconciliation_findings USING btree (first_seen_at)
    WHERE ((resolved_at IS NULL) AND (alerted_at IS NULL));

CREATE TABLE IF NOT EXISTS public.catalog_proposals (
    "id"                   UUID        NOT NULL DEFAULT gen_random_uuid(),
    "catalog_table"        TEXT        NOT NULL,
    "proposed_data"        JSONB       NOT NULL,
    "proposed_by_user_id"  TEXT        NOT NULL,
    "proposed_by_schema"   TEXT        NOT NULL,
    "ai_decision"          TEXT        NOT NULL,
    "ai_reason"            TEXT,
    "status"               TEXT        NOT NULL DEFAULT 'pending'::text,
    "global_item_id"       UUID,
    "review_notes"         TEXT,
    "created_at"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "reviewed_at"          TIMESTAMPTZ,
    "reviewed_by"          TEXT,
    CONSTRAINT catalog_proposals_pkey PRIMARY KEY (id),
    CONSTRAINT catalog_proposals_catalog_table_check CHECK (catalog_table = ANY (ARRAY[
        'global_document_types'::text,
        'global_case_templates'::text,
        'global_registry_families'::text
    ])),
    CONSTRAINT catalog_proposals_ai_decision_check CHECK (ai_decision = ANY (ARRAY[
        'auto_approve'::text, 'review'::text
    ])),
    CONSTRAINT catalog_proposals_status_check CHECK (status = ANY (ARRAY[
        'pending'::text, 'approved'::text, 'rejected'::text, 'auto_approved'::text
    ]))
);

COMMENT ON TABLE public.catalog_proposals IS
    'Propuestas de alta al catálogo global, con dictamen de IA y revisión humana.';

CREATE INDEX IF NOT EXISTS idx_catalog_proposals_status_created
    ON public.catalog_proposals USING btree (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_catalog_proposals_table
    ON public.catalog_proposals USING btree (catalog_table);
CREATE INDEX IF NOT EXISTS idx_catalog_proposals_proposed_by
    ON public.catalog_proposals USING btree (proposed_by_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.digital_signature_sessions (
    "id"                 UUID        NOT NULL DEFAULT gen_random_uuid(),
    "session_id"         TEXT        NOT NULL,
    "file_id"            TEXT        NOT NULL,
    "schema_name"        TEXT        NOT NULL,
    "user_id"            UUID        NOT NULL,
    "document_id"        UUID        NOT NULL,
    "is_numerator"       BOOLEAN     NOT NULL DEFAULT false,
    "number"             TEXT,
    "status"             TEXT        NOT NULL DEFAULT 'pending'::text,
    "created_at"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "expires_at"         TIMESTAMPTZ NOT NULL,
    "consumed_at"        TIMESTAMPTZ,
    "completed_at"       TIMESTAMPTZ,
    "cancelled_at"       TIMESTAMPTZ,
    "ip_address"         INET,
    "user_agent"         TEXT,
    "document_hash_pre"  BYTEA,
    "user_cuit"          TEXT,
    "provider_name"      TEXT        NOT NULL DEFAULT 'autofirma'::text,
    "failure_reason"     TEXT,
    "reservation_id"     UUID,
    "batch_id"           UUID,
    "client_version"     TEXT,
    "cas_pre_done"       BOOLEAN     NOT NULL DEFAULT false,
    "cert_payload"       JSONB,
    CONSTRAINT digital_signature_sessions_pkey PRIMARY KEY (id),
    CONSTRAINT digital_signature_sessions_session_id_key UNIQUE (session_id),
    CONSTRAINT digital_signature_sessions_session_id_alnum CHECK (session_id ~ '^[A-Za-z0-9]+$'::text),
    CONSTRAINT digital_signature_sessions_file_id_alnum CHECK (file_id ~ '^[A-Za-z0-9]+$'::text),
    CONSTRAINT digital_signature_sessions_status_chk CHECK (status = ANY (ARRAY[
        'pending'::text, 'waiting_batch'::text, 'completing'::text, 'signed'::text,
        'cancelled'::text, 'expired'::text, 'failed'::text
    ]))
);

COMMENT ON TABLE public.digital_signature_sessions IS
    'Sesiones de firma digital con token (FirmadorGDI/AutoFirma). Cross-tenant: resuelve por schema_name.';

CREATE INDEX IF NOT EXISTS idx_dss_session
    ON public.digital_signature_sessions USING btree (session_id);
CREATE INDEX IF NOT EXISTS idx_dss_document
    ON public.digital_signature_sessions USING btree (document_id);
CREATE INDEX IF NOT EXISTS idx_dss_schema_user
    ON public.digital_signature_sessions USING btree (schema_name, user_id);
CREATE INDEX IF NOT EXISTS idx_dss_status_expires
    ON public.digital_signature_sessions USING btree (status, expires_at);
CREATE INDEX IF NOT EXISTS idx_dss_batch
    ON public.digital_signature_sessions USING btree (batch_id) WHERE (batch_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_dss_reservation_id
    ON public.digital_signature_sessions USING btree (reservation_id) WHERE (reservation_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_dss_client_version_por_usuario
    ON public.digital_signature_sessions USING btree (user_id, created_at DESC) WHERE (client_version IS NOT NULL);


DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'SCHEMA PUBLIC CREADO';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Tablas creadas: 19';
    RAISE NOTICE '  1. roles';
    RAISE NOTICE '  2. global_document_types';
    RAISE NOTICE '  3. global_case_templates';
    RAISE NOTICE '  4. municipalities';
    RAISE NOTICE '  5. document_display_states';
    RAISE NOTICE '  6. user_registry';
    RAISE NOTICE '  7. api_keys (GDI-MCP REST API)';
    RAISE NOTICE '  8. api_key_users (Usuarios autorizados por API Key)';
    RAISE NOTICE '  9. global_registry_families (Familias de registros)';
    RAISE NOTICE '  10. tenant_certificates (certificados digitales)';
    RAISE NOTICE '  11. backup_access_log (log de accesos backup)';
    RAISE NOTICE '  12. license_state (cache licencia on-premise; vacia en SaaS)';
    RAISE NOTICE '  13. signing_sessions (cola worker escri GDI-075; 6 índices)';
    RAISE NOTICE '  14. job_heartbeats (GDI-304: heartbeat de los jobs del lifespan)';
    RAISE NOTICE '  15. schema_migrations (estado de migraciones de ESTA BD)';
    RAISE NOTICE '  16. superadmin_audit (auditoria BackOffice)';
    RAISE NOTICE '  17. reconciliation_findings (reconciliador R2 <-> BD)';
    RAISE NOTICE '  18. catalog_proposals (propuestas al catalogo global)';
    RAISE NOTICE '  19. digital_signature_sessions (firma con token)';
    RAISE NOTICE 'Funcion: fn_set_updated_at (auto-update updated_at)';
    RAISE NOTICE 'Triggers: 10 (updated_at en todas las tablas)';
    RAISE NOTICE '  NOTA: ranks y seals son per-tenant (schema local)';
    RAISE NOTICE '============================================================';
END $$;
