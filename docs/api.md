# API reference

The complete, always-current reference is the Swagger UI at `/docs` (and ReDoc at `/redoc`) once the app is running. This page is a static overview of every endpoint, grouped by area.

Most paths are prefixed with `/api/v1`. The **Auth** column means: 🔒 a bearer token is required (with a role if shown); ○ a token is optional and personalizes the response; — open.

## Auth

Registration is limited to allowed email domains. Login returns an access token and a refresh token; refreshing rotates the refresh token. (Logout reads the bearer token from the body/header to revoke refresh tokens.)

| Method | Path | Description | Auth |
|---|---|---|---|
| `POST` | `/api/v1/auth/google` | Google Login | — |
| `POST` | `/api/v1/auth/login` | Login | — |
| `POST` | `/api/v1/auth/login/oauth` | Login Oauth | — |
| `POST` | `/api/v1/auth/logout` | Logout | 🔒 auth |
| `GET` | `/api/v1/auth/me` | Me | 🔒 auth |
| `POST` | `/api/v1/auth/refresh` | Refresh | — |
| `POST` | `/api/v1/auth/register` | Register | — |

## Profile

The signed-in student's own profile, resume, registered events, and device tokens for push.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/profile` | Get My Profile | 🔒 auth |
| `PATCH` | `/api/v1/profile` | Update My Account | 🔒 auth |
| `POST` | `/api/v1/profile/devices` | Register Device | 🔒 auth |
| `DELETE` | `/api/v1/profile/devices/{fcm_token}` | Unregister Device | 🔒 auth |
| `GET` | `/api/v1/profile/registrations` | My Registered Events | 🔒 auth |
| `PUT` | `/api/v1/profile/resume` | Set Resume | 🔒 auth |
| `PATCH` | `/api/v1/profile/student` | Update Student Profile | 🔒 auth |

## Articles

News and blogs share one model, split by `kind`. Reads are public but personalized when a token is sent (bookmark/like flags); likes, comments and bookmarking need auth; create/update/delete need staff.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/articles` | List Articles | ○ optional |
| `POST` | `/api/v1/articles` | Create Article | 🔒 staff |
| `DELETE` | `/api/v1/articles/comments/{comment_id}` | Delete Comment | 🔒 auth |
| `DELETE` | `/api/v1/articles/{article_id}` | Delete Article | 🔒 staff |
| `PATCH` | `/api/v1/articles/{article_id}` | Update Article | 🔒 staff |
| `GET` | `/api/v1/articles/{article_id}/comments` | List Comments | — |
| `POST` | `/api/v1/articles/{article_id}/comments` | Add Comment | 🔒 auth |
| `POST` | `/api/v1/articles/{article_id}/like` | Toggle Like | 🔒 auth |
| `GET` | `/api/v1/articles/{slug}` | Get Article | ○ optional |

## Opportunities

Browse and filter the five opportunity types. Reads are public (personalized with a token); writes need admin.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/opportunities` | List Opportunities | ○ optional |
| `POST` | `/api/v1/opportunities` | Create Opportunity | 🔒 admin |
| `DELETE` | `/api/v1/opportunities/{opportunity_id}` | Delete Opportunity | 🔒 admin |
| `GET` | `/api/v1/opportunities/{opportunity_id}` | Get Opportunity | ○ optional |
| `PATCH` | `/api/v1/opportunities/{opportunity_id}` | Update Opportunity | 🔒 admin |

## Events

Browse upcoming/past events; register and check in. Registration needs auth; check-in and writes need staff/admin.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/events` | List Events | — |
| `POST` | `/api/v1/events` | Create Event | 🔒 admin |
| `DELETE` | `/api/v1/events/{event_id}` | Delete Event | 🔒 admin |
| `PATCH` | `/api/v1/events/{event_id}` | Update Event | 🔒 admin |
| `POST` | `/api/v1/events/{event_id}/check-in` | Check In | 🔒 staff |
| `DELETE` | `/api/v1/events/{event_id}/register` | Cancel Registration | 🔒 auth |
| `POST` | `/api/v1/events/{event_id}/register` | Register For Event | 🔒 auth |
| `GET` | `/api/v1/events/{slug}` | Get Event | ○ optional |

## Publications

Magazine, gazette, reports and newsletters. Reads public; writes need admin.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/publications` | List Publications | ○ optional |
| `POST` | `/api/v1/publications` | Create Publication | 🔒 admin |
| `GET` | `/api/v1/publications/years` | List Years | — |
| `DELETE` | `/api/v1/publications/{publication_id}` | Delete Publication | 🔒 admin |
| `PATCH` | `/api/v1/publications/{publication_id}` | Update Publication | 🔒 admin |
| `POST` | `/api/v1/publications/{publication_id}/download` | Register Download | — |

## Resources

Notes, papers, books, software and links. Reads public; writes need admin.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/resources` | List Resources | ○ optional |
| `POST` | `/api/v1/resources` | Create Resource | 🔒 admin |
| `DELETE` | `/api/v1/resources/{resource_id}` | Delete Resource | 🔒 admin |
| `PATCH` | `/api/v1/resources/{resource_id}` | Update Resource | 🔒 admin |
| `POST` | `/api/v1/resources/{resource_id}/download` | Register Download | — |

## Faculty

Searchable faculty directory. Reads public; writes need admin.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/faculty` | List Faculty | — |
| `POST` | `/api/v1/faculty` | Create Faculty | 🔒 admin |
| `DELETE` | `/api/v1/faculty/{faculty_id}` | Delete Faculty | 🔒 admin |
| `GET` | `/api/v1/faculty/{faculty_id}` | Get Faculty | — |
| `PATCH` | `/api/v1/faculty/{faculty_id}` | Update Faculty | 🔒 admin |

## Contacts

Contact directory grouped by role. Reads public; writes need admin.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/contacts` | List Contacts | — |
| `POST` | `/api/v1/contacts` | Create Contact | 🔒 admin |
| `DELETE` | `/api/v1/contacts/{contact_id}` | Delete Contact | 🔒 admin |
| `PATCH` | `/api/v1/contacts/{contact_id}` | Update Contact | 🔒 admin |

## Forms

Submit any of seven form types and track your own history; staff review and change status, which notifies the submitter.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/forms` | List Submissions | 🔒 staff |
| `GET` | `/api/v1/forms/mine` | My Submissions | 🔒 auth |
| `POST` | `/api/v1/forms/submit` | Submit Form | 🔒 auth |
| `PATCH` | `/api/v1/forms/{submission_id}` | Review Submission | 🔒 staff |

## Notifications

Per-user and broadcast notifications with unread counts. Sending is admin-only.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/notifications` | List Notifications | 🔒 auth |
| `POST` | `/api/v1/notifications/read-all` | Mark All Read | 🔒 auth |
| `POST` | `/api/v1/notifications/send` | Send Notification | 🔒 admin |
| `GET` | `/api/v1/notifications/unread-count` | Unread Count | 🔒 auth |
| `POST` | `/api/v1/notifications/{notification_id}/read` | Mark Read | 🔒 auth |

## Bookmarks

Toggle a bookmark on any content type and list saved items resolved to display cards.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/bookmarks` | My Bookmarks | 🔒 auth |
| `POST` | `/api/v1/bookmarks/toggle` | Toggle | 🔒 auth |

## Favorites

Same mechanism as bookmarks, used for opportunities.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/favorites` | My Favorites | 🔒 auth |
| `POST` | `/api/v1/favorites/toggle` | Toggle | 🔒 auth |

## Search

One query across articles, opportunities, events, publications, resources and faculty.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/search` | Global Search | — |

## Uploads

Upload a file, validated by extension and size.

| Method | Path | Description | Auth |
|---|---|---|---|
| `POST` | `/api/v1/uploads` | Upload File | 🔒 auth |

## Admin

Dashboard analytics, user management, and role promotion (super-admin only).

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/api/v1/admin/stats` | Dashboard Stats | 🔒 admin |
| `GET` | `/api/v1/admin/users` | List Users | 🔒 admin |
| `PATCH` | `/api/v1/admin/users/{user_id}` | Update User | 🔒 admin |
| `POST` | `/api/v1/admin/users/{user_id}/promote` | Promote User | 🔒 super-admin |

## Meta

Service metadata and health checks.

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/` | Root | — |
| `GET` | `/health` | Health | — |

