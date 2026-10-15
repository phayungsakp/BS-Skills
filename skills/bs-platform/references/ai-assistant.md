# AI Assistant Reference

Present in BS-Platform-Template, BS-MyInventory and BS-AI-Assistance-WM3. Check `BS-AI-Assistant/` exists before applying.

## Pieces

| Part | Location |
| --- | --- |
| Service | `BS-AI-Assistant/AiAssistant` (`AiAssistant.sln`), compose service `bs_ai_assistance` |
| Frontend chat | `src/components/AiChatPopover.js` (still uses `fetch` - legacy exception, don't copy the pattern) |
| Admin console | `src/pages/AI/AIAdminConsole.js` (BSDataGrid over `ais.*` via Dynamic CRUD - needs `ais` in `AllowedSchemas`) |
| Menu config | `src/config/aiMenu.js` |
| Provider key encryption | `src/utils/aiSecretCrypto.js` (CryptoJS PBKDF2, passphrase `REACT_APP_AI_PROVIDER_SECRET_KEY`) |

## Gateway

| Upstream | Downstream |
| --- | --- |
| `/gateway/v1/api/ai/{everything}` | `bs_ai_assistance /api/ai/{everything}` |
| `/gateway/v1/api/dashboard/suggestions` | `/api/dashboard/suggestions` |
| `/gateway/v1/api/dashboard/generate-forecast` | `/api/AiDashboard/generate-forecast` |
| `/gateway/v1/api/dashboard/auto-generate` | `/api/AiDashboard/auto-generate` |

The catch-all means new `api/ai/*` actions need no Ocelot change; new `dashboard/*` actions do.

## Controllers

- `AiChatController` (`api/ai`): `chat`, `confirm`, `reject`, `suggestions`, `favorite-prompts` (GET), `favorite-prompts/toggle`, `health`, `active-configs`, `rate-limit`, `provider-config`, `config/refresh`, `overview-stats`.
- `AiKnowledgeController` (`api/ai/knowledge`): `documents` (GET/POST), `documents/{documentId}/chunks`, `rebuild-chunks`, `rebuild-embeddings`, `sync-schema`, `schema-catalog`, `retrieval-preview`.
- `AiDashboardController` (`api/AiDashboard`): `generate-forecast`, `auto-generate`.

## Tables (`ais.t_ai_*` - never `t_ais_*`)

`t_ai_provider_config`, `t_ai_model_priority`, `t_ai_embedding_provider_config`, `t_ai_system_prompt`, `t_ai_page_config`, `t_ai_chat_log`, `t_ai_crud_audit_log`, `t_ai_favorite_prompts`, `t_ai_knowledge_document`, `t_ai_knowledge_chunk`, `t_ai_knowledge_chunk_token`, `t_ai_knowledge_retrieval_log`, `t_ai_schema_catalog`, `t_ai_schema_relation`.

Provider/model/embedding settings are DB-managed (first three tables); after editing call `config/refresh`. Root `.env` `OPENROUTER_*` entries are commented examples only.

## Rules

- Chat-proposed CRUD is a proposal: execute only through `confirm`, discard through `reject`. Never run generated SQL from the frontend or bypass `t_ai_crud_audit_log`.
- Schema knowledge comes from `sync-schema` → `t_ai_schema_catalog/relation`; after DB changes, resync instead of hard-coding table hints in prompts.
- Provider API keys go through `aiSecretCrypto` before they reach the DB. The default passphrase `CHANGE_ME_AI_SECRET_PASSPHRASE` must be replaced per environment, and backend env `AI_PROVIDER_SECRET_KEY` (`Services/Implementation/AiSecretCrypto.cs`) must hold the same value - changing either side breaks every stored key.
