import logging

from homie.device_base import Device_Base
from node_recentimages import Node_RecentImages

logger = logging.getLogger(__name__)


class Device_Apparatus(Device_Base):
    """scanner/apparatus/..."""

    def __init__(
        self,
        device_id=None,
        name=None,
        homie_settings=None,
        mqtt_settings=None,
        device_settings=None,
    ):
        # the device names itself
        self.device_id = 'apparatus'
        self.name = self.device_id
        self.device_settings = device_settings
        self.mqtt_settings = mqtt_settings

        super().__init__(self.device_id, self.name, homie_settings, mqtt_settings)

        # add the Node_Camera node
        # cam = Node_Camera(device=self)
        # self.add_node(cam)
        # logger.info('Add node: {}'.format(cam))

        # add the Node_RecentImage node
        recimg = Node_RecentImages(device=self)
        self.add_node(recimg)
        logger.info('Add node: {}'.format(recimg))
