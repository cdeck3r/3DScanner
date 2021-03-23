import logging
import os
import pathlib
import platform
import shutil
import time
from datetime import datetime

from homie.node.node_base import Node_Base
from homie.node.property.property_enum import Property_Enum
from homie.node.property.property_integer import Property_Integer

logger = logging.getLogger(__name__)

if not platform.machine().startswith('x86'):
    import picamera

    # need to declare this outside
    # See: https://raspberrypi.stackexchange.com/a/77377
    camera = picamera.PiCamera()


class Node_Camera(Node_Base):
    """A camnode's camera and shutter-button

    scanner/camnode-hwaddr/camera/...
    scanner/camnode-hwaddr/camera/shutter-button
    scanner/camnode-hwaddr/camera/shutter-timer
    """

    # states allowed for the camera's shutter button
    BUTTON_STATES = "push,release,timer"
    # Delay time in seconds until next button press is accepted
    SUPPRESSION_TIMEOUT = 5

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

        # important functions we need for the button to work
        assert self.shutter_button
        assert self.shutter_timer
        assert Node_Camera.BUTTON_STATES
        assert Node_Camera.SUPPRESSION_TIMEOUT

        # we need the Node_Image
        self.image = device.get_node('recent-image')
        assert self.image
        assert self.image.update_recent_image
        assert self.image.new_file

        self.device = device
        # camera resolution settings
        self.x_res = self.device.device_settings['camera_x_res']
        self.y_res = self.device.device_settings['camera_y_res']

        self.button_push_time = 0
        # button's default value is 'release'
        self.button = Property_Enum(
            node=self,
            id="shutter-button",
            name="Shutter Button",
            data_format=Node_Camera.BUTTON_STATES,
            set_value=self.shutter_button,
            value='release',
        )
        self.add_property(self.button)

        # timer's default value is 0, unit is milliseconds
        self.timer = Property_Integer(
            node=self,
            id='shutter-timer',
            name='Shutter Timer',
            unit='ms',
            data_format='0:10000',
            set_value=self.shutter_timer,
            value=0,
        )
        self.add_property(self.timer)

    def __str__(self):
        return str(self.__class__.__name__)

    def take_picture(self):
        """Takes a picture using the Raspi camera module connected to camnode"""
        if platform.machine().startswith(
            'x86'
        ):  # camera node runs on desktop dev system
            image_file = self.image.new_file()
            # copy test image
            testimage_file = os.path.join(os.getcwd(), 'testimg.png')
            assert os.path.exists(testimage_file)
            shutil.copy(testimage_file, image_file)
            assert os.path.exists(image_file)
            logger.info(
                'Simulation on {} only: take picture'.format(platform.machine())
            )
            logger.info('Take picture: {}'.format(image_file))
            self.image.update_recent_image(image_file)
            return
        # we expect to run on camnode
        # Ex. https://picamera.readthedocs.io/en/release-1.13/recipes1.html#capturing-to-a-file
        camera.resolution = (self.x_res, self.y_res)
        # Camera warm-up time
        time.sleep(2)
        image_file = self.image.new_file()
        logger.info('Take picture: {}'.format(image_file))
        camera.capture(image_file)
        # tell the recent-image node to update
        self.image.update_recent_image(image_file)
        # TODO: delete image_file to clean-up

    def shutter_button(self, button_action):
        """Received new button action from some external publisher"""
        if button_action == 'push':
            self.button_push()
        if button_action == 'timer':
            self.button_timer()

    def shutter_timer(self, timeout):
        """Received new timer value from some external publisher"""
        self.timer.value = timeout

    def button_push(self):
        """Push the button to take a picture"""
        # bounce suppression:
        # accept next button push only after SUPPRESSION_TIMEOUT
        if self.button_push_time == 0:
            self.button.value = 'push'  # sends updates to clients
            self.button_push_time = time.time()
            self.take_picture()
            self.button.value = 'release'
        else:
            self.button.value = 'release'  # always enable button to be pressed
            curr_time = time.time()
            if (curr_time - self.button_push_time) > Node_Camera.SUPPRESSION_TIMEOUT:
                self.button_push_time = 0
                self.button_push()  # suppression time over, so we can hit the button
            else:
                logger.debug(
                    'Shutter button push rejected, because button still in bounce suppression.'
                )

    def button_timer(self):
        """Wait for ... milliseconds and take a picture"""
        # 1. set button state to timer
        # 2. wait self.timer.value
        # 3. take picture
        # 4. release button
        self.button.value = 'timer'
        logger.debug('Start timer: {} ms'.format(self.timer.value))
        time.sleep(self.timer.value / 1000)  # unit is ms
        self.take_picture()
        self.button.value = 'release'
