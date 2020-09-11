"""
Base configuration values for dependency.
The settings attributes are intended to be overridden at run time by environment variables.
"""
import os
import pathlib
from functools import lru_cache
from typing import Optional, List

# pylint: disable=too-many-instance-attributes
# pylint: disable=too-few-public-methods
# pylint: disable=no-name-in-module
from pydantic import PositiveInt, FilePath, AnyUrl, BaseModel, BaseSettings, DirectoryPath, validator, PathNotAFileError
from fast_pymera.models.schema import FastPymeraSettings


# pylint: disable=no-member
def validate_url(url: str) -> AnyUrl:
    """for a given string version of a url, return an AnyUrl."""

    class Model(BaseModel):
        """
        This is a way to force validation and convert a str to an AnyUrl.
        Pattern taken from pydantic tests. Creating an AnyUrl instance requires 3 parameters,
        but in this context we only have one.
        """
        v: AnyUrl

    return Model(v=url).v


class dependencySettings(BaseSettings):
    """
    Configuration properties and defaults for dependency.
    """
    testing: bool = False

    # -------------------------
    # Application
    # -------------------------
    root_dir: DirectoryPath = '/usr/src/app'  #: installation root directory

    # application hostname
    app_host: str = 'dependency'

    # application HTTPS port
    app_https_port: PositiveInt = 443

    openapi_prefix: str = '/services/dependency/1.0/'

    # static assets
    static_dir: DirectoryPath = '/dependency/static'

    cte_ca_certs_file: FilePath = '/certs/cacerts.pem'
    server_public_key: FilePath = '/certs/twl-server.public.pem'
    server_private_key: FilePath = '/certs/twl-server.private.pem'

    # -------------------------
    # Access Control Whitelist (/ACL)
    # -------------------------

    impersonation_whitelist_dns_file: FilePath = '/certs/whitelist.txt'

    def impersonation_whitelist_dns(self) -> List[str]:
        """
        Read the whitelist file and convert it to a list of string.
        :return:
        """
        return [line.rstrip('\n') for line in open(str(self.impersonation_whitelist_dns_file))]

    admin_user_whitelist_dns_file: Optional[FilePath] = None

    def admin_user_whitelist_dns(self) -> List[str]:
        """
        Read the admin whitelist file and convert it to a list of string.
        :return:
        """
        if self.admin_user_whitelist_dns_file:
            return [line.rstrip('\n') for line in open(str(self.admin_user_whitelist_dns_file))]

        return list()

    # -------------------------
    # Security Service / AAC
    # -------------------------

    @staticmethod
    def __parse_urls(urls: str) -> List[AnyUrl]:
        """Given a comma-delimited string of urls, split it and make AnyUrl types out of the results."""
        return [validate_url(u) for u in urls.split(',')]

    # location AAC announces it's instance locations!
    # 1.) Use the announcement point! IE, '/cte/service/aac/1.1'
    aac_announcement_point: Optional[pathlib.Path] = None

    # 2.) Otherwise...
    aac_instances_url: str = 'http://cte-aac-service:8443'

    def aac_instances(self) -> List[dict]:
        """Returns aac_instances_url formatted for pymera"""
        return [dict(
            host=u.host,
            port=u.port,
            context=u.path or ''
        ) for u in self.__parse_urls(self.aac_instances_url)]

    # -------------------------
    # Zookeeper
    # -------------------------
    # application announcement point
    zk_announcement_path: str = '/services/dependency/1.0'

    # The HTTP(s) context. Useful for when the service is announcing the public facing nginx as it's host
    zk_announcement_context = zk_announcement_path

    # comma-separated list of hosts to connect to (e.g. 127.0.0.1:2181,127.0.0.1:2182,[::1]:2183).
    zk_connection: str = 'zk.docker:2181'

    # zookeeper client timeout (in seconds).
    zk_timeout: PositiveInt = 30

    # maximum number of attempts to connect to zookeeper.
    zk_max_connection_attempts: PositiveInt = 5

    # -------------------------
    # Logging
    # -------------------------
    log_config: FilePath = '/pkg/logging.json'

    # pylint: disable=no-self-argument
    # pylint: disable=no-self-use
    @validator('impersonation_whitelist_dns_file',
               'log_config',
               'static_dir',
               'cte_ca_certs_file',
               'server_public_key',
               'server_private_key',
               pre=True)
    def apply_root(cls, value, values):
        """This validator applies the value of root directory to dependent files and directories."""

        # if the path exists we make the assumption here that an env override
        # value has been set (because the default does not exist), and that
        # the user would prefer the env override.
        if os.path.exists(value):
            return value

        root_dir = values.get('root_dir')
        if root_dir:
            return f'{root_dir}{value}'

        raise PathNotAFileError(path=f'{root_dir}{value}')

    class Config:
        """Settings configuration here."""
        case_sensitive = False
        # a value 'project_' would prefix all settings with 'project_'
        env_prefix = ''


@lru_cache()
def reads() -> dependencySettings:
    """instantiate dependencySettings and return it. lru_cache caches the response."""
    return dependencySettings()


def read_fastpymera_settings() -> FastPymeraSettings:
    """FastPymeraSettings are settings required to run a FastPymera service. This is a utility function
    to produce a FastPymeraSettings instance from this service's settings."""

    app_config = reads()

    return FastPymeraSettings(
        static_dir=str(app_config.static_dir), # we convert to string here because static files mount requires it
        openapi_prefix=app_config.openapi_prefix,
        app_host=app_config.app_host,
        app_https_port=app_config.app_https_port,
        impersonation_whitelist_dns=app_config.impersonation_whitelist_dns(),
        testing=app_config.testing,
        title='dependency',
        description='Super great pets!',
        version='1.0',
        aac_announcement_point=app_config.aac_announcement_point,
        aac_instances=app_config.aac_instances(),
        zk_announcement_path=app_config.zk_announcement_path,
        log_config=app_config.log_config
    )
