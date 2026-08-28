


CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    conversation_id TEXT NOT NULL,
    schema_name TEXT NOT NULL,
    user_id TEXT NOT NULL,
    case_id UUID,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    chat_type TEXT NOT NULL,
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation
    ON public.chat_messages(conversation_id);

CREATE INDEX IF NOT EXISTS idx_chat_messages_user
    ON public.chat_messages(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_messages_schema
    ON public.chat_messages(schema_name, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_messages_case
    ON public.chat_messages(case_id) WHERE case_id IS NOT NULL;


CREATE TABLE IF NOT EXISTS public.ai_usage_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    schema_name VARCHAR(100) NOT NULL,
    document_id UUID,
    case_id UUID,
    operation VARCHAR(40) NOT NULL,
    model VARCHAR(100) NOT NULL,
    openrouter_id VARCHAR(100),
    prompt_tokens INT NOT NULL DEFAULT 0,
    completion_tokens INT NOT NULL DEFAULT 0,
    total_tokens INT GENERATED ALWAYS AS (prompt_tokens + completion_tokens) STORED,
    estimated_cost_usd DECIMAL(10,6) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'success',
    error_message TEXT,
    metadata JSONB,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_log_schema
    ON public.ai_usage_log(schema_name);

CREATE INDEX IF NOT EXISTS idx_ai_usage_log_created
    ON public.ai_usage_log(created_at);

CREATE INDEX IF NOT EXISTS idx_ai_usage_log_schema_created
    ON public.ai_usage_log(schema_name, created_at);

CREATE INDEX IF NOT EXISTS idx_ai_usage_log_openrouter
    ON public.ai_usage_log(openrouter_id) WHERE openrouter_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ai_usage_log_schema_status_created
    ON public.ai_usage_log(schema_name, status, created_at);


CREATE TABLE IF NOT EXISTS public.ai_usage_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schema_name VARCHAR(100) UNIQUE NOT NULL,
    daily_limit_usd DECIMAL(10,2) NOT NULL DEFAULT 10.00,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    today_cost_usd DECIMAL(10,6) NOT NULL DEFAULT 0,
    today_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


DROP TRIGGER IF EXISTS trg_ai_usage_log_updated_at ON public.ai_usage_log;
CREATE TRIGGER trg_ai_usage_log_updated_at BEFORE UPDATE ON public.ai_usage_log
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_ai_usage_limits_updated_at ON public.ai_usage_limits;
CREATE TRIGGER trg_ai_usage_limits_updated_at BEFORE UPDATE ON public.ai_usage_limits
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


CREATE TABLE IF NOT EXISTS public.checkpoint_migrations (
    v INTEGER PRIMARY KEY
);

INSERT INTO public.checkpoint_migrations (v)
VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)
ON CONFLICT (v) DO NOTHING;


CREATE TABLE IF NOT EXISTS public.checkpoints (
    thread_id TEXT NOT NULL,
    checkpoint_ns TEXT NOT NULL DEFAULT '',
    checkpoint_id TEXT NOT NULL,
    parent_checkpoint_id TEXT,
    type TEXT,
    checkpoint JSONB NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id)
);

CREATE INDEX IF NOT EXISTS checkpoints_thread_id_idx
    ON public.checkpoints(thread_id);


CREATE TABLE IF NOT EXISTS public.checkpoint_blobs (
    thread_id TEXT NOT NULL,
    checkpoint_ns TEXT NOT NULL DEFAULT '',
    channel TEXT NOT NULL,
    version TEXT NOT NULL,
    type TEXT NOT NULL,
    blob BYTEA,
    PRIMARY KEY (thread_id, checkpoint_ns, channel, version)
);

CREATE INDEX IF NOT EXISTS checkpoint_blobs_thread_id_idx
    ON public.checkpoint_blobs(thread_id);


CREATE TABLE IF NOT EXISTS public.checkpoint_writes (
    thread_id TEXT NOT NULL,
    checkpoint_ns TEXT NOT NULL DEFAULT '',
    checkpoint_id TEXT NOT NULL,
    task_id TEXT NOT NULL,
    idx INTEGER NOT NULL,
    channel TEXT NOT NULL,
    type TEXT,
    blob BYTEA NOT NULL,
    task_path TEXT NOT NULL DEFAULT '',
    PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id, task_id, idx)
);

CREATE INDEX IF NOT EXISTS checkpoint_writes_thread_id_idx
    ON public.checkpoint_writes(thread_id);


CREATE TABLE IF NOT EXISTS public.rag_query_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  schema_name TEXT NOT NULL,
  user_id UUID,
  source TEXT NOT NULL,
  intent TEXT,

  query TEXT NOT NULL,
  rewritten_query TEXT,

  candidates_returned INT,
  final_returned INT,
  top_similarity NUMERIC(5,4),
  bottom_similarity NUMERIC(5,4),
  threshold_applied NUMERIC(3,2),
  results_doc_ids UUID[],

  latency_ms INT
);

CREATE INDEX IF NOT EXISTS idx_rag_query_log_schema_created
  ON public.rag_query_log(schema_name, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_rag_query_log_query_trgm
  ON public.rag_query_log USING gin(query gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_rag_query_log_empty
  ON public.rag_query_log(created_at DESC)
  WHERE final_returned = 0;


DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== 02b-seed-agente.sql completado ===';
    RAISE NOTICE 'Tablas creadas (IF NOT EXISTS):';
    RAISE NOTICE '  1. public.chat_messages';
    RAISE NOTICE '  2. public.ai_usage_log';
    RAISE NOTICE '  3. public.ai_usage_limits';
    RAISE NOTICE '  4. public.checkpoint_migrations (+ seed v0..v9)';
    RAISE NOTICE '  5. public.checkpoints';
    RAISE NOTICE '  6. public.checkpoint_blobs';
    RAISE NOTICE '  7. public.checkpoint_writes';
    RAISE NOTICE '  8. public.rag_query_log (mig 043)';
    RAISE NOTICE '';
END $$;
