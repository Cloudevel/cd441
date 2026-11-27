"""Punto de entrada WSGI para gunicorn y para ``flask --app wsgi:app``."""

from app import create_app

app = create_app()
