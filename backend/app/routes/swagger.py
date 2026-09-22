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
    "paths": {
        "/api/health": {
            "get": {
                "summary": "Health check",
                "responses": {"200": {"description": "API is running"}},
            }
        },
        "/api/db-test": {
            "get": {
                "summary": "Database connectivity test",
                "responses": {"200": {"description": "Connection status and table counts"}},
            }
        },
        "/api/auth/register": {
            "post": {
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
                "summary": "Get current user profile",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "User profile"}, "401": {"description": "Unauthorized"}},
            }
        },
        "/api/programs": {
            "get": {
                "summary": "List CEIT programs",
                "responses": {"200": {"description": "List of programs"}},
            }
        },
        "/api/academic-years": {
            "get": {
                "summary": "List academic years",
                "responses": {"200": {"description": "List of academic years"}},
            }
        },
        "/api/categories": {
            "get": {
                "summary": "List research categories",
                "responses": {"200": {"description": "List of categories"}},
            }
        },
        "/api/keywords": {
            "get": {
                "summary": "List research keywords",
                "responses": {"200": {"description": "List of keywords"}},
            }
        },
        "/api/authors": {
            "get": {
                "summary": "List student authors",
                "responses": {"200": {"description": "List of authors"}},
            }
        },
        "/api/advisers": {
            "get": {
                "summary": "List faculty advisers",
                "responses": {"200": {"description": "List of advisers"}},
            }
        },
        "/api/theses": {
            "get": {
                "summary": "List theses with filters",
                "parameters": [
                    {"name": "q", "in": "query", "schema": {"type": "string"}, "description": "Search query"},
                    {"name": "program_id", "in": "query", "schema": {"type": "integer"}},
                    {"name": "year_id", "in": "query", "schema": {"type": "integer"}},
                    {"name": "research_type", "in": "query", "schema": {"type": "string"}},
                    {"name": "page", "in": "query", "schema": {"type": "integer"}},
                    {"name": "per_page", "in": "query", "schema": {"type": "integer"}},
                ],
                "responses": {"200": {"description": "Paginated list of theses"}},
            },
            "post": {
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
                "summary": "Get thesis by ID",
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Thesis details"}, "404": {"description": "Not found"}},
            },
            "put": {
                "summary": "Update thesis (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Updated"}, "403": {"description": "Admin only"}},
            },
            "delete": {
                "summary": "Delete thesis (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Deleted"}, "403": {"description": "Admin only"}},
            }
        },
        "/api/theses/{id}/recommend": {
            "get": {
                "summary": "Get similar thesis recommendations",
                "parameters": [
                    {"name": "id", "in": "path", "required": True, "schema": {"type": "integer"}},
                    {"name": "limit", "in": "query", "schema": {"type": "integer"}},
                ],
                "responses": {"200": {"description": "List of similar theses with similarity scores"}},
            }
        },
        "/api/upload/pdf": {
            "post": {
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
                "summary": "OCR scanned PDF (admin only)",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "OCR completed"}},
            }
        },
        "/api/embeddings/generate/{thesis_id}": {
            "post": {
                "summary": "Generate embedding for a thesis (admin only)",
                "security": [{"bearerAuth": []}],
                "parameters": [{"name": "thesis_id", "in": "path", "required": True, "schema": {"type": "integer"}}],
                "responses": {"200": {"description": "Embedding generated"}},
            }
        },
        "/api/embeddings/generate-bulk": {
            "post": {
                "summary": "Bulk generate embeddings for all theses (admin only)",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Bulk generation complete"}},
            }
        },
        "/api/embeddings/search": {
            "post": {
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
        "/api/dashboard/stats": {
            "get": {
                "summary": "Admin dashboard statistics",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Dashboard counts"}},
            }
        },
        "/api/dashboard/recent-activity": {
            "get": {
                "summary": "Recent activity feed",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Recent activity items"}},
            }
        },
        "/api/faculty/dashboard": {
            "get": {
                "summary": "Faculty dashboard data",
                "security": [{"bearerAuth": []}],
                "responses": {"200": {"description": "Faculty stats"}},
            }
        },
        "/api/faculty/activity": {
            "get": {
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
