# API Documentation

This document lists all API endpoints, their methods, request headers, request/query/body schemas, and possible responses.

---

**Common headers**:
- `Authorization`: `Bearer <token>` — required for endpoints that require authentication/permissions. If missing, the server treats the request as anonymous for public endpoints and returns `401`/`WWW-Authenticate: Bearer` for protected ones.
- `Content-Type`: `application/json` — required for JSON request bodies.

---

## GET /v1/healthcheck
- Method: GET
- Headers: none
- Request body: none
- Query params: none
- Success response: `200 OK`
  - Body schema:
    ```json
    {
      "status": "available"
    }
    ```
- Error responses: `500 Internal Server Error` with envelope:
  ```json
  {
    "error": "..."
  }
  ```

## GET /v1/movies
- Method: GET
- Headers:
  - `Authorization`: `Bearer <token>` — required (permission `movies:read`).
- Query parameters:
  - `title` (string, optional) — full-text search on title
  - `genres` (csv string, optional) — comma-separated list of genres
  - `page` (int, optional, default: 1)
  - `page_size` (int, optional, default: 20)
  - `sort` (string, optional, default: `id`) — allowed values: `id`, `title`, `year`, `runtime`, `-id`, `-title`, `-year`, `-runtime`
- Request body: none
- Success response: `200 OK`
  - Body schema:
    ```json
    {
      "movies": [
        {
          "id": 0,
          "title": "string",
          "year": 0,
          "runtime": "<n> mins",
          "genres": ["string"],
          "version": 0
        }
      ],
      "metadata": {
        "current_page": 1,
        "page_size": 20,
        "first_page": 1,
        "last_page": 1,
        "total_records": 0
      }
    }
    ```
- Error responses: `401` (unauthenticated), `403` (not permitted), `422` (validation on query params), `500` for server errors.
  Error body:
  ```json
  {
    "error": <message_or_map>
  }
  ```

## POST /v1/movies
- Method: POST
- Headers:
  - `Authorization`: `Bearer <token>` — required (permission `movies:write`).
  - `Content-Type`: `application/json`
- Request body schema (JSON):
  ```json
  {
    "title": "string",        
    "year": 2023,
    "runtime": "120 mins",
    "genres": ["Drama","Action"]
  }
  ```
- Success response: `201 Created`
  - Headers: `Locating: /v1/movies/<id>`
  - Body schema:
    ```json
    {
      "movie": {
        "id": 0,
        "title": "string",
        "year": 0,
        "runtime": "<n> mins",
        "genres": [
          "string"
        ],
        "version": 0
      }
    }
    ```
- Error responses:
  - `400 Bad Request` — malformed JSON
  - `422 Unprocessable Entity` — validation errors: response:
    ```json
    {
      "error": {
        "field": "message"
      }
    }
    ```
  - `500 Internal Server Error`

## GET /v1/movies/:id
- Method: GET
- Headers:
  - `Authorization`: `Bearer <token>` — required (permission `movies:read`).
- Path params:
  - `id` (integer, required)
- Success response: `200 OK`
  - Body schema:
      ```json
      {
        "movie": {
          "id": 0,
          "title": "string",
          "year": 0,
          "runtime": "<n> mins",
          "genres": [
            "string"
          ],
          "version": 0
        }
      }
      ```
- Error responses:
  - `404 Not Found` — invalid `id` or record not found
  - `401`/`403`/`500` as applicable

## PATCH /v1/movies/:id
- Method: PATCH
- Headers:
  - `Authorization`: `Bearer <token>` — required (permission `movies:write`).
  - `Content-Type`: `application/json`
- Path params:
  - `id` (integer, required)
- Request body schema (fields optional; only send fields to update):
  ```json
  {
    "title": "string",
    "year": 2023,
    "runtime": "120 mins",
    "genres": [
      "Drama"
    ]
  }
  ```
- Success response: `200 OK`
  - Body schema: same as GET single movie: `{ "movie": { ... } }`
- Error responses:
  - `400 Bad Request` — malformed JSON
  - `404 Not Found` — invalid id
  - `409 Conflict` — edit conflict (concurrent update)
  - `422 Unprocessable Entity` — validation errors
  - `500 Internal Server Error`

## DELETE /v1/movies/:id
- Method: DELETE
- Headers:
  - `Authorization`: `Bearer <token>` — required (permission `movies:write`).
- Path params: `id` (integer, required)
- Success response: `200 OK`
  - Body schema:
    ```json
    {
      "message": "movie successfully deleted"
    }
    ```
- Error responses: `404` (not found), `401`/`403`/`500` as applicable.

## POST /v1/users
- Method: POST
- Headers: `Content-Type: application/json`
- Request body schema:
  ```json
  {
    "name": "string",
    "email": "user@example.com",
    "password": "strongpassword"
  }
  ```
- Success response: `201 Created`
  - Body schema:
    ```json
    {
      "user": {
        "id": 0,
        "created_at": "<timestamp>",
        "name": "string",
        "email": "string",
        "activated": false
      }
    }
    ```
- Error responses:
  - `422 Unprocessable Entity` — validation errors (field messages)
  - `422` when email duplicate with message under `email`
  - `500` server errors

## PUT /v1/users/activated
- Method: PUT
- Headers: `Content-Type: application/json`
- Request body schema:
  ```json
  {
    "token": "<activation token>"
  }
  ```
- Success response: `200 OK`
  - Body schema: `{ "user": { ... } }` (user object with `activated: true`)
- Error responses:
  - `422` — token invalid or expired (validation error: `{ "error": { "token": "..." } }`)
  - `500` server errors

## PUT /v1/users/password
- Method: PUT
- Headers: `Content-Type: application/json`
- Request body schema:
  ```json
  {
    "password": "newpassword",
    "token": "<password reset token>"
  }
  ```
- Success response: `200 OK`
  - Body schema: `{ "message": "your password is successfully reset" }`
- Error responses: `422` validation token/password, `500` server error

## POST /v1/tokens/authentication
- Method: POST
- Headers: `Content-Type: application/json`
- Request body schema:
  ```json
  {
    "email": "user@example.com",
    "password": "password"
  }
  ```
- Success response: `201 Created`
  - Body schema:
    ```json
    {
      "authentication_token": {
        "token": "<token>",
        "expiry": "<timestamp>"
      }
    }
    ```
- Error responses:
  - `401 Unauthorized` — invalid credentials (body):
    ```json
    {
      "error": "invalid authentication credentials"
    }
    ```
  - `422` validation errors
  - `500` server error

## POST /v1/tokens/activation
- Method: POST
- Headers: `Content-Type: application/json`
- Request body schema:
  ```json
  {
    "email": "user@example.com"
  }
  ```
- Success response: `202 Accepted`
  - Body schema:
    ```json
    {
      "message": "an email will be sent to you containing activation instructions"
    }
    ```
- Error responses: `422` when email not found or already activated, `500` server error

## POST /v1/tokens/password-reset
- Method: POST
- Headers: `Content-Type: application/json`
- Request body schema:
  ```json
  {
    "email": "user@example.com"
  }
  ```
- Success response: `202 Accepted`
  - Body schema:
    ```json
    {
      "message": "an email will be sent to you containing password reset instruction"
    }
    ```
- Error responses: `422` when email not found or account not activated, `500` server error

## GET /debug/vars
- Method: GET
- Headers: none
- Description: Exposes expvar metrics
- Success response: `200 OK` with JSON body from expvar

---

Error envelope format (all errors):

```json
{
  "error": <string | { "field": "message", ... }>
}
```

---

Notes:
- `runtime` is encoded/decoded as a string like `"120 mins"`.
- Validation errors use HTTP `422 Unprocessable Entity` and return a map of field -> message inside the `error` envelope.
- Authentication uses Bearer tokens (see `/v1/tokens/authentication`). Protected endpoints require the token and specific permission codes (e.g. `movies:read`, `movies:write`).
