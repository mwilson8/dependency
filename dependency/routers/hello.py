"""Example endpoint for fast pymera"""
from http import HTTPStatus
import logging
from fastapi import APIRouter

# Initialize an APIRouter
router = APIRouter()

LOG = logging.getLogger(__name__)


@router.get("/hello", status_code=HTTPStatus.OK)
async def hello():
    """Simple example endpoint"""
    # will return dictionaries as json (Content-Type header is inferred)
    LOG.info('Hello World!')
    LOG.warning('Hello World!')
    LOG.error('Hello World!')
    return {"hello": "world"}
