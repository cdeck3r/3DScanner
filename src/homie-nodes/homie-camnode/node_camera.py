from homie.node.node_base import Node_Base
from homie.node.property.property_button import Property_Button


class Node_Camera(Node_Base):
    """A camnode's camera and shutter-button

    scanner/camnode-hwaddr/camera/...
    scanner/camnode-hwaddr/camera/shutter-button
    """

    def __init__(
        self,
        device,
        id="camera",
        name="Camera",
        type_="camera",
        retain=True,
        qos=1,
    ):

        super().__init__(device, id, name, type_, retain, qos)

        assert self.shutter_button
        self.button = Property_Button(
            node=self, id="shutter-button", name="Shutter Button"
        )
        self.add_property(self.button)

    def __str__(self):
        return str(self.__class__.__name__)

    def shutter_button(self):
        """Push the button to make a picture"""
        self.button.push()
