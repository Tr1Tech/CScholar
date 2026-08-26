"""Flask extensions instances.

Extensions are created here without binding them to an app, then
initialized inside create_app(). This avoids circular imports.
"""

from flask_cors import CORS

# CORS is required because the Flutter WEB client calls this API from a browser.
cors = CORS()
