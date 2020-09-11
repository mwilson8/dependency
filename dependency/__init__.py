"""The dependency main functions"""
import logging

from fastapi import FastAPI
from fast_pymera import create_microservice

from dependency.clients import ZK_INSTANCE, AAC_INSTANCE
from dependency.settings import read_fastpymera_settings
from dependency.routers import hello


def my_function():
    print("version 1")

# Initialize logging
LOG = logging.getLogger(__name__)

# Initialize a FastPymera instance and provide core settings.
app: FastAPI = create_microservice(read_fastpymera_settings(), ZK_INSTANCE, AAC_INSTANCE)


# pylint: disable=fixme
# TODO- replace hello with service-specific endpoints
app.include_router(hello.router)
