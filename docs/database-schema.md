# Database schema

Generated from the SQLAlchemy models. The authoritative definition is the model code in `backend/app/models`; this page is a readable summary. Every table has a UUID primary key (`id`) and `created_at` / `updated_at` timestamps via shared mixins.

**20 tables.** Enumerated columns are stored as strings (see `app/models/enums.py`); the allowed values are validated at the API layer.

## Users & auth

### `users`

| Column | Type | Constraints |
|---|---|---|
| `email` | String | unique, indexed, not null |
| `full_name` | String | not null |
| `hashed_password` | String |  |
| `role` | String | not null |
| `is_active` | Boolean | not null |
| `is_verified` | Boolean | not null |
| `google_sub` | String | unique |
| `avatar_url` | String |  |
| `last_login_at` | DateTime |  |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `student_profiles`

| Column | Type | Constraints |
|---|---|---|
| `user_id` | UUID | FK → users.id, unique, not null |
| `roll_number` | String | unique |
| `semester` | Integer |  |
| `branch` | String | not null |
| `phone` | String |  |
| `bio` | String |  |
| `resume_url` | String |  |
| `linkedin_url` | String |  |
| `github_url` | String |  |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `refresh_tokens`

| Column | Type | Constraints |
|---|---|---|
| `user_id` | UUID | FK → users.id, indexed, not null |
| `jti` | String | unique, indexed, not null |
| `expires_at` | DateTime | not null |
| `revoked` | Boolean | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `device_tokens`

| Column | Type | Constraints |
|---|---|---|
| `user_id` | UUID | FK → users.id, indexed, not null |
| `fcm_token` | String | unique, not null |
| `platform` | String | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

## Directory

### `faculty`

| Column | Type | Constraints |
|---|---|---|
| `name` | String | indexed, not null |
| `designation` | String | not null |
| `email` | String |  |
| `phone` | String |  |
| `office` | String |  |
| `office_hours` | String |  |
| `photo_url` | String |  |
| `research_interests` | ARRAY | not null |
| `google_scholar_url` | String |  |
| `linkedin_url` | String |  |
| `display_order` | Integer | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `contacts`

| Column | Type | Constraints |
|---|---|---|
| `name` | String | indexed, not null |
| `category` | String | indexed, not null |
| `role` | String |  |
| `email` | String |  |
| `phone` | String |  |
| `whatsapp` | String |  |
| `linkedin_url` | String |  |
| `photo_url` | String |  |
| `display_order` | Integer | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

## Content

### `articles`

| Column | Type | Constraints |
|---|---|---|
| `title` | String | indexed, not null |
| `slug` | String | unique, indexed, not null |
| `kind` | String | indexed, not null |
| `category` | String | indexed, not null |
| `excerpt` | String |  |
| `body` | Text | not null |
| `cover_image_url` | String |  |
| `tags` | ARRAY | not null |
| `reading_minutes` | Integer | not null |
| `is_published` | Boolean | indexed, not null |
| `is_featured` | Boolean | indexed, not null |
| `view_count` | Integer | not null |
| `published_at` | DateTime |  |
| `author_id` | UUID | FK → users.id |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `article_comments`

| Column | Type | Constraints |
|---|---|---|
| `article_id` | UUID | FK → articles.id, indexed, not null |
| `user_id` | UUID | FK → users.id, not null |
| `parent_id` | UUID | FK → article_comments.id |
| `body` | String | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `article_likes`

| Column | Type | Constraints |
|---|---|---|
| `article_id` | UUID | FK → articles.id, indexed, not null |
| `user_id` | UUID | FK → users.id, not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

## Opportunities & events

### `opportunities`

| Column | Type | Constraints |
|---|---|---|
| `type` | String | indexed, not null |
| `company` | String | indexed, not null |
| `role` | String | not null |
| `location` | String |  |
| `is_remote` | Boolean | not null |
| `description` | Text | not null |
| `eligibility` | Text |  |
| `required_skills` | ARRAY | not null |
| `compensation` | String |  |
| `company_logo_url` | String |  |
| `apply_url` | String |  |
| `deadline` | DateTime | indexed |
| `is_active` | Boolean | indexed, not null |
| `applicant_count` | Integer | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `events`

| Column | Type | Constraints |
|---|---|---|
| `title` | String | indexed, not null |
| `slug` | String | unique, indexed, not null |
| `type` | String | indexed, not null |
| `description` | Text | not null |
| `banner_url` | String |  |
| `venue` | String |  |
| `starts_at` | DateTime | indexed, not null |
| `ends_at` | DateTime |  |
| `registration_open` | Boolean | not null |
| `capacity` | Integer |  |
| `registered_count` | Integer | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `event_schedule_items`

| Column | Type | Constraints |
|---|---|---|
| `event_id` | UUID | FK → events.id, indexed, not null |
| `title` | String | not null |
| `description` | String |  |
| `starts_at` | DateTime | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `event_gallery_images`

| Column | Type | Constraints |
|---|---|---|
| `event_id` | UUID | FK → events.id, indexed, not null |
| `image_url` | String | not null |
| `caption` | String |  |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `event_registrations`

| Column | Type | Constraints |
|---|---|---|
| `event_id` | UUID | FK → events.id, indexed, not null |
| `user_id` | UUID | FK → users.id, indexed, not null |
| `qr_token` | String | unique, indexed, not null |
| `status` | String | not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

## Library

### `publications`

| Column | Type | Constraints |
|---|---|---|
| `title` | String | indexed, not null |
| `type` | String | indexed, not null |
| `academic_year` | String | indexed, not null |
| `description` | Text |  |
| `cover_image_url` | String |  |
| `pdf_url` | String | not null |
| `is_published` | Boolean | indexed, not null |
| `download_count` | Integer | not null |
| `published_at` | DateTime |  |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `resources`

| Column | Type | Constraints |
|---|---|---|
| `title` | String | indexed, not null |
| `type` | String | indexed, not null |
| `description` | Text |  |
| `subject` | String | indexed |
| `semester` | Integer | indexed |
| `tags` | ARRAY | not null |
| `file_url` | String |  |
| `external_url` | String |  |
| `file_size_kb` | Integer |  |
| `download_count` | Integer | not null |
| `is_active` | Boolean | indexed, not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

## Forms & notifications

### `form_submissions`

| Column | Type | Constraints |
|---|---|---|
| `user_id` | UUID | FK → users.id, indexed, not null |
| `form_type` | String | indexed, not null |
| `payload` | JSONB | not null |
| `attachment_url` | String |  |
| `status` | String | indexed, not null |
| `admin_note` | Text |  |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `notifications`

| Column | Type | Constraints |
|---|---|---|
| `user_id` | UUID | FK → users.id, indexed |
| `type` | String | indexed, not null |
| `title` | String | not null |
| `body` | Text | not null |
| `data` | JSONB | not null |
| `is_read` | Boolean | indexed, not null |
| `sent_at` | DateTime |  |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

## Engagement & uploads

### `bookmarks`

| Column | Type | Constraints |
|---|---|---|
| `user_id` | UUID | FK → users.id, indexed, not null |
| `content_type` | String | indexed, not null |
| `content_id` | UUID | indexed, not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `favorites`

| Column | Type | Constraints |
|---|---|---|
| `user_id` | UUID | FK → users.id, indexed, not null |
| `content_type` | String | indexed, not null |
| `content_id` | UUID | indexed, not null |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

### `uploaded_files`

| Column | Type | Constraints |
|---|---|---|
| `uploader_id` | UUID | FK → users.id |
| `original_name` | String | not null |
| `stored_name` | String | unique, not null |
| `url` | String | not null |
| `content_type` | String | not null |
| `size_bytes` | Integer | not null |
| `purpose` | String |  |
| `id` | UUID | PK |
| `created_at` | DateTime | not null |
| `updated_at` | DateTime | not null |

