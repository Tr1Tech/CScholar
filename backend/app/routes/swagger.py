"""Swagger UI blueprint for API documentation."""

from flask import Blueprint, jsonify, send_from_directory
import os

swagger_bp = Blueprint("swagger", __name__)

SWAGGER_JSON = {
    "openapi": "3.0.0",
    "info": {
        "title": "CScholar API",
        "version": "1.0.0",
        "description": "Semantic Search and AI-Powered Recommendation System for CSU CEIT Thesis Repository",
    },
    "servers": [{"url": "http://localhost:5000"}],
    "tags": [
        {"name": "System", "description": "Health check and database status"},
        {"name": "Auth", "description": "User authentication and registration"},
        {"name": "Users", "description": "User management (admin only)"},
        {"name": "Theses", "description": "Thesis CRUD operations"},
        {"name": "Metadata", "description": "Programs, years, categories, keywords, authors, advisers"},
        {"name": "Search", "description": "Semantic search and recommendations"},
        {"name": "Upload", "description": "PDF upload and OCR"},
        {"name": "Embeddings", "description": "AI embedding generation"},
        {"name": "Dashboard", "description": "Admin and faculty dashboard data"},
    ],
    "paths": {
        # ── System ─────────────────────────────────────────────────────────────
        "/api/health": {
            "get": {
                "tags": ["System"],
                "summary": "Health check",
                "responses": {"200": {"description": "API is running"}},
            }
        },
        "/api/db-test": {
            "get": {
                "tags": ["System"],
                "summary": "Database connectivity test",
                "responses": {"200": {"description": "Connection status and table counts"}},
            }
        },
        # ── Auth ──────────────────────────────────────────────────────────────
        "/api/auth/register": {
            "post": {
                "tags": ["Auth"],
                "summary": "Register new user",
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "username": {"type": "string"},
                                    "email": {"type": "string"},
                                    "password": {"type": "string"},
                                    "role": {"type": "string", "enum": ["student", "faculty", "admin"]},
                                },
                            }
                        }
                    }
                },
                "responses": {"201": {"description": "User created"}, "400": {"description": "Invalid input"}, "409": {"description": "Username/email taken"}},
            }
        },
        "/api/auth/login": {
            "post": {
                "tags": ["Auth"],
                "summary": "Login",
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "email": {"type": "string"},
                                    "password": {"type": "string"},
                                },
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Login successful"}, "401": {"description": "Invalid credentials"}},
            }
        },
        "/api/auth/me": {
            "get": {
                "tags": ["Auth"],
                "summary": "Get current user profile",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "User profile"}, "401": {"description": "Unauthorized"}},
            }
        },
        # ── Users ─────────────────────────────────────────────────────────────
        "/api/users": {
            "get": {
                "tags": ["Users"],
                "summary": "List all users (admin only)",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "List of users"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/users/{user_id}/role": {
            "put": {
                "tags": ["Users"],
                "summary": "Update user role (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "user_id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "role": {"type": "string", "enum": ["student", "faculty", "admin"]},
                                },
                                "required": ["role"],
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Role updated"}, "404": {"description": "User not found"}},
            }
        },
        # ── Theses ────────────────────────────────────────────────────────────
        "/api/theses": {
            "get": {
                "tags": ["Theses"],
                "summary": "List theses with filters",
                "parameters": [
                    {"name": "q", "in": "query", "schema": {"type": "string"}, "description": "Search query"},
                    {"name": "program_id", "in": "query", "schema": {"type": "integer"}},
                    {"name": "year_id", "in": "query", "schema": {"type": "integer"}},
                    {"name": "category_id", "in": "query", "schema": {"type": "integer"}},
                    {"name": "keyword", "in": "query", "schema": {"type": "string"}},
                    {"name": "sort_by", "in": "query", "schema": {"type": "string"}},
                    {"name": "research_type", "in": "query", "schema": {"type": "string"}},
                    {"name": "page", "in": "query", "schema": {"type": "integer"}},
                    {"name": "per_page", "in": "query", "schema": {"type": "integer"}},
                ],
                "responses": {"200": {"description": "Paginated list of theses"}},
            },
            "post": {
                "tags": ["Theses"],
                "summary": "Create new thesis (admin only)",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "title": {"type": "string"},
                                    "abstract": {"type": "string"},
                                    "research_type": {"type": "string"},
                                    "program_id": {"type": "integer"},
                                    "academic_year_id": {"type": "integer"},
                                    "status": {"type": "string"},
                                },
                            }
                        }
                    }
                },
                "responses": {"201": {"description": "Thesis created"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/theses/{id}": {
            "get": {
                "tags": ["Theses"],
                "summary": "Get thesis by ID",
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Thesis details"}, "404": {"description": "Not found"}},
            },
            "put": {
                "tags": ["Theses"],
                "summary": "Update thesis (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Updated"}, "403": {"description": "Admin only"}},
            },
            "delete": {
                "tags": ["Theses"],
                "summary": "Delete thesis (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Deleted"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/theses/{id}/recommend": {
            "get": {
                "tags": ["Search"],
                "summary": "Get similar thesis recommendations",
                "parameters": [
                    {"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}},
                    {"name": "limit", "in": "query", "schema": {"type": "integer"}},
                ],
                "responses": {"200": {"description": "List of similar theses with similarity scores"}},
            }
        },
        # ── Metadata ──────────────────────────────────────────────────────────
        "/api/programs": {
            "get": {
                "tags": ["Metadata"],
                "summary": "List CEIT programs",
                "responses": {"200": {"description": "List of programs"}},
            },
            "post": {
                "tags": ["Metadata"],
                "summary": "Create a program (admin only)",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string"},
                                    "code": {"type": "string"},
                                    "description": {"type": "string"},
                                },
                                "required": ["name"],
                            }
                        }
                    }
                },
                "responses": {"201": {"description": "Program created"}, "400": {"description": "Invalid input"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/programs/{id}": {
            "put": {
                "tags": ["Metadata"],
                "summary": "Update a program (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string"},
                                    "code": {"type": "string"},
                                    "description": {"type": "string"},
                                },
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Program updated"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            },
            "delete": {
                "tags": ["Metadata"],
                "summary": "Delete a program (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Program deleted"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/academic-years": {
            "get": {
                "tags": ["Metadata"],
                "summary": "List academic years",
                "responses": {"200": {"description": "List of academic years"}},
            },
            "post": {
                "tags": ["Metadata"],
                "summary": "Create an academic year (admin only)",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string"},
                                    "start_year": {"type": "integer"},
                                    "end_year": {"type": "integer"},
                                    "is_active": {"type": "boolean", "default": True},
                                },
                                "required": ["name"],
                            }
                        }
                    }
                },
                "responses": {"201": {"description": "Academic year created"}, "400": {"description": "Invalid input"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/academic-years/{id}": {
            "put": {
                "tags": ["Metadata"],
                "summary": "Update an academic year (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string"},
                                    "start_year": {"type": "integer"},
                                    "end_year": {"type": "integer"},
                                    "is_active": {"type": "boolean"},
                                },
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Academic year updated"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            },
            "delete": {
                "tags": ["Metadata"],
                "summary": "Delete an academic year (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Academic year deleted"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/categories": {
            "get": {
                "tags": ["Metadata"],
                "summary": "List research categories",
                "responses": {"200": {"description": "List of categories"}},
            },
            "post": {
                "tags": ["Metadata"],
                "summary": "Create a category (admin only)",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string"},
                                    "description": {"type": "string"},
                                },
                                "required": ["name"],
                            }
                        }
                    }
                },
                "responses": {"201": {"description": "Category created"}, "400": {"description": "Invalid input"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/categories/{id}": {
            "put": {
                "tags": ["Metadata"],
                "summary": "Update a category (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string"},
                                    "description": {"type": "string"},
                                },
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Category updated"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            },
            "delete": {
                "tags": ["Metadata"],
                "summary": "Delete a category (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Category deleted"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/keywords": {
            "get": {
                "tags": ["Metadata"],
                "summary": "List research keywords (auto-generated from thesis submissions)",
                "responses": {"200": {"description": "List of keywords"}},
            }
        },
        "/api/authors": {
            "get": {
                "tags": ["Metadata"],
                "summary": "List student authors",
                "responses": {"200": {"description": "List of authors"}},
            },
            "post": {
                "tags": ["Metadata"],
                "summary": "Create an author (admin only)",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "first_name": {"type": "string"},
                                    "last_name": {"type": "string"},
                                    "email": {"type": "string"},
                                    "middle_name": {"type": "string"},
                                },
                                "required": ["first_name", "last_name"],
                            }
                        }
                    }
                },
                "responses": {"201": {"description": "Author created"}, "400": {"description": "Invalid input"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/authors/{id}": {
            "put": {
                "tags": ["Metadata"],
                "summary": "Update an author (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "first_name": {"type": "string"},
                                    "last_name": {"type": "string"},
                                    "email": {"type": "string"},
                                    "middle_name": {"type": "string"},
                                },
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Author updated"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            },
            "delete": {
                "tags": ["Metadata"],
                "summary": "Delete an author (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Author deleted"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/advisers": {
            "get": {
                "tags": ["Metadata"],
                "summary": "List faculty advisers",
                "responses": {"200": {"description": "List of advisers"}},
            },
            "post": {
                "tags": ["Metadata"],
                "summary": "Create an adviser (admin only)",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "first_name": {"type": "string"},
                                    "last_name": {"type": "string"},
                                    "email": {"type": "string"},
                                    "middle_name": {"type": "string"},
                                },
                                "required": ["first_name", "last_name"],
                            }
                        }
                    }
                },
                "responses": {"201": {"description": "Adviser created"}, "400": {"description": "Invalid input"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/advisers/{id}": {
            "put": {
                "tags": ["Metadata"],
                "summary": "Update an adviser (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "first_name": {"type": "string"},
                                    "last_name": {"type": "string"},
                                    "email": {"type": "string"},
                                    "middle_name": {"type": "string"},
                                },
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Adviser updated"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            },
            "delete": {
                "tags": ["Metadata"],
                "summary": "Delete an adviser (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Adviser deleted"}, "404": {"description": "Not found"}, "403": {"description": "Admin only"}},
            }
        },
        # ── Search ────────────────────────────────────────────────────────────
        "/api/embeddings/search": {
            "post": {
                "tags": ["Search"],
                "summary": "Semantic search",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "query": {"type": "string", "description": "Natural language search query"},
                                    "limit": {"type": "integer", "default": 10},
                                },
                                "required": ["query"],
                            }
                        }
                    }
                },
                "responses": {"200": {"description": "Search results with similarity scores"}},
            }
        },
        # ── Upload ────────────────────────────────────────────────────────────
        "/api/upload/pdf": {
            "post": {
                "tags": ["Upload"],
                "summary": "Upload PDF manuscript (admin only)",
                "security": [{"bearerAuth": []}],
                "requestBody": {
                    "content": {
                        "multipart/form-data": {
                            "schema": {"type": "object", "properties": {"file": {"type": "string", "format": "binary"}}}
                        }
                    }
                },
                "responses": {"200": {"description": "PDF parsed, extracted text returned"}},
            }
        },
        "/api/ocr/pdf": {
            "post": {
                "tags": ["Upload"],
                "summary": "OCR scanned PDF (admin only)",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "OCR completed"}},
            }
        },
        # ── Embeddings ────────────────────────────────────────────────────────
        "/api/embeddings/generate/{thesis_id}": {
            "post": {
                "tags": ["Embeddings"],
                "summary": "Generate embedding for a thesis (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "thesis_id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Embedding generated"}},
            }
        },
        "/api/embeddings/generate-bulk": {
            "post": {
                "tags": ["Embeddings"],
                "summary": "Bulk generate embeddings for all theses (admin only)",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Bulk generation complete"}},
            }
        },
        # ── Dashboard ─────────────────────────────────────────────────────────
        "/api/dashboard/stats": {
            "get": {
                "tags": ["Dashboard"],
                "summary": "Admin dashboard statistics",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Dashboard counts"}},
            }
        },
        "/api/dashboard/recent-activity": {
            "get": {
                "tags": ["Dashboard"],
                "summary": "Recent activity feed",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Recent activity items"}},
            }
        },
        "/api/faculty/dashboard": {
            "get": {
                "tags": ["Dashboard"],
                "summary": "Faculty dashboard data",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Faculty stats"}},
            }
        },
        "/api/faculty/activity": {
            "get": {
                "tags": ["Dashboard"],
                "summary": "Faculty advisee activity",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Activity items"}},
            }
        },
    },
    "components": {
        "securitySchemes": {
            "bearerAuth": {"type": "http", "scheme": "bearer", "bearerFormat": "JWT"}
        }
    },
}


@swagger_bp.route("/swagger.json")
def swagger_json():
    return jsonify(SWAGGER_JSON)
