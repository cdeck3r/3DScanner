import logging

from homie.device_base import Device_Base
from node_camera import Node_Camera
from node_software import Node_Software

logger = logging.getLogger(__name__)


class Device_Camnode(Device_Base):
    """scanner/camnode-hwaddr/..."""

    def __init__(
        self,
        device_id=None,
        name=None,
        homie_settings=None,
        mqtt_settings=None,
    ):

        super().__init__(device_id, name, homie_settings, mqtt_settings)

        # add the camera
        camera = Node_Camera(device=self)
        self.add_node(camera)
        logger.info('Add node: {}'.format(camera))

        # add the software node_camera
        sw = Node_Software(device=self)
        self.add_node(sw)
        logger.info('Add node: {}'.format(sw))
