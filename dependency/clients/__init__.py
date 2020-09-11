"""Clients that must be accessible to both the app service and routers should be available here."""
import logging

from pymera.clients.aac import AacClient
from pymera.clients.zookeeper import ChimeraZookeeper

from dependency.settings import reads

LOG = logging.getLogger(__name__)

AAC_INSTANCE = AacClient(
    public_key_path=str(reads().server_public_key),
    private_key_path=str(reads().server_private_key)
)

ZK_INSTANCE = ChimeraZookeeper(
    reads().zk_connection,
    reads().zk_timeout,
    reads().zk_max_connection_attempts
)
