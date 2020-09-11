from fastapi import HTTPException
from pydantic import PositiveInt
from starlette.testclient import TestClient

from dependency import app

import pytest

from http import HTTPStatus

@pytest.mark.parametrize('path',
                         [
                             ('/'),
                             ('/version.json'),
                             ('/favicon.ico'),
                             ('/bad/path')
                         ])
def test__check_expected_endpoints_failure(path: str):
    with TestClient(app) as client:
        response = client.get(path)
        assert response.status_code == HTTPStatus.FORBIDDEN


@pytest.mark.parametrize('path',
                         [
                             ('/'),
                             ('/version.json'),
                             ('/favicon.ico')
                         ])
def test__check_expected_endpoints_success(path: str):
    headers = {
        "USER_DN": "CN=twl-server-generic2, OU=DAE, OU=DIA, OU=twl-server-generic2, O=U.S. Government, C=US",
        "SSL_CLIENT_S_DN": "CN=twl-server-generic2, OU=DAE, OU=DIA, OU=twl-server-generic2, O=U.S. Government, C=US"
    }
    with TestClient(app) as client:
        response = client.get(path, headers=headers)
        assert response.status_code == HTTPStatus.OK
