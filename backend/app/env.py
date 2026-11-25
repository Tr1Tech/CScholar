"""Load environment variables for the backend.

``neon deploy`` writes Neon-managed variables to the repository's
``.env.local``. The backend lives in ``backend/``, so its own ``load_dotenv()``
never saw that file. Load the root file first (it is the source of truth for a
Neon-linked checkout), then ``backend/.env`` for local-only settings.

Neither file is committed. Real process environment variables always win over
both, which is how Render injects its configuration.
"""

import os

from dotenv import load_dotenv

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_ROOT = os.path.dirname(BACKEND_DIR)


def load_env():
    """Load root ``.env.local``, then ``backend/.env`` without overriding."""
    load_dotenv(os.path.join(PROJECT_ROOT, ".env.local"), override=False)
    load_dotenv(os.path.join(BACKEND_DIR, ".env"), override=False)
