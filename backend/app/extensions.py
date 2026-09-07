"""Extensions initialized without the app to avoid circular imports.

Import these in your views / blueprints after the app is created, or
call ``db.init_app(app)`` inside the factory.
"""

from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy

cors = CORS()
db = SQLAlchemy()
