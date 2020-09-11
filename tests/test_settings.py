import pathlib

import pytest

from dependency.settings import dependencySettings


@pytest.mark.parametrize('value,result',
                         [(f'/certs/cacerts.pem', pathlib.Path(f'/usr/src/app/certs/cacerts.pem')),
                          (pathlib.Path(f'/certs/cacerts.pem'),
                           pathlib.Path(f'/usr/src/app/certs/cacerts.pem'))])
def test_cte_ca_certs_file_path_derived_validation_success(value, result):
    """Potentially confusing- in this test, paths are derived:
    /certs/cacerts.pem becomes /usr/src/app/certs/cacerts.pem because /certs/cacerts.pem is appended to the
    root_dir whose value is /usr/src/app/ and that matches /usr/src/app/certs/cacerts.pem
    """
    assert dependencySettings(cte_ca_certs_file=value).cte_ca_certs_file == result


@pytest.mark.parametrize('value,result',
                         [(f'/usr/src/app/certs/cacerts.pem', pathlib.Path(f'/usr/src/app/certs/cacerts.pem')),
                          (pathlib.Path(f'/usr/src/app/certs/cacerts.pem'),
                           pathlib.Path(f'/usr/src/app/certs/cacerts.pem'))])
def test_cte_ca_certs_file_path_explicit_validation_success(value, result):
    """Potentially confusing- in this test, paths are explicit-
    these tests pass because /usr/src/app/certs/cacerts.pem exists in the container
    and root_dir is NOT appended"""
    assert dependencySettings(cte_ca_certs_file=value).cte_ca_certs_file == result

@pytest.mark.parametrize('value,result',
                         [
                             ('http://container:9000/one/two,http://container:10000/three/four',
                              [{'host': 'container', 'port': '9000', 'context': '/one/two'},
                               {'host': 'container', 'port': '10000', 'context': '/three/four'}]),
                             ('http://container:9000/one/two',
                              [{'host': 'container', 'port': '9000', 'context': '/one/two'}])
                         ])
def test__parse_url_success(value, result):
    assert dependencySettings(aac_instances_url=value).aac_instances() == result
