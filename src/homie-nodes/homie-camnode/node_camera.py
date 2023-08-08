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
from homie.node.property.property_string import Property_String

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
    scanner/camnode-hwaddr/camera/resolution-x
    scanner/camnode-hwaddr/camera/resolution-y
    scanner/camnode-hwaddr/camera/revision
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
        self.x_res_default = self.device.device_settings['camera_x_res']
        self.y_res_default = self.device.device_settings['camera_y_res']

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

        # Camera resolution 
        self.res_x_prop = Property_Integer(
            node=self,
            id='resolution-x',
            name='Resolution width',
            unit='px',
            data_format='0:3280',
            set_value=self.resolution_x,
            value=self.x_res_default, # local default value from config file
        )
        self.add_property(self.res_x_prop)

        self.res_y_prop = Property_Integer(
            node=self,
            id='resolution-y',
            name='Resolution height',
            unit='px',
            data_format='0:2464',
            set_value=self.resolution_y,
            value=self.y_res_default, # local default value from config file
        )
        self.add_property(self.res_y_prop)

        # default resolution from local config file
        # one can only reset _to_ the default resolution
        self.def_resolution_prop = Property_String(
            node=self,
            id="def-resolution",
            name="Default resolution",
            set_value=self.def_resolution,
            value='('+str(self.x_res_default)+', '+str(self.y_res_default)+')',
        )
        self.add_property(self.def_resolution_prop)
        
        #  a string representing the revision of the Pi’s camera module. 
        # ‘ov5647’ for the V1 module, and ‘imx219’ for the V2 module.
        self.revision = Property_String(
            node=self,
            id='revision',
            name='Revision',
            value=camera.revision,
        )
        self.add_property(self.revision)

        # camera subscribes to scanner/apparatus/cameras/shutter-button
        self.device.add_subscription(
            topic='scanner/apparatus/cameras/shutter-button',
            handler=self.scanner_shutter_button,
        )

        # To retrieve central resolution updates
        # camera subscribes to scanner/apparatus/cameras/resolution-x
        self.device.add_subscription(
            topic='scanner/apparatus/cameras/resolution-x',
            handler=self.scanner_resolution_x,
        )
        
        # To retrieve central resolution updates
        # camera subscribes to scanner/apparatus/cameras/resolution-y
        self.device.add_subscription(
            topic='scanner/apparatus/cameras/resolution-y',
            handler=self.scanner_resolution_y,
        )


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
        camera.resolution = (self.res_x_prop.value, self.res_y_prop.value)
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

    def resolution_x(self, x_res):
        """Received new resolution at which image is captured (x dimension or width)"""
        self.res_x_prop.value = x_res
        logger.info('New camera resolution (width): {}'.format(self.res_x_prop.value))

    def resolution_y(self, y_res):
        """Received new resolution at which image is captured (y dimension or height)"""
        self.res_y_prop.value = y_res
        logger.info('New camera resolution (height): {}'.format(self.res_y_prop.value))

    def def_resolution(self, action):
        """Resets the resolution to the default from the local config file"""
        if action == 'reset':
            logger.info('Reset to default resolution')
            self.def_resolution_prop.value = '('+str(self.x_res_default)+', '+str(self.y_res_default)+')'
            self.resolution_x(x_res_default)
            self.resolution_y(y_res_default)
        else:
            logger.info('Setting not supported: {}'.format(action))

    def scanner_shutter_button(self, topic, button_action):
        """Handler for message on scanner/apparatus/cameras/shutter-button"""
        logger.info('Scanner shutter button hit: {}'.format(button_action))
        self.shutter_button(button_action)

    def scanner_resolution_x(self, topic, x_res):
        """Handler for message on scanner/apparatus/cameras/resolution-x"""
        logger.info('Scanner cameras resolution (x width): {}'.format(x_res))
        self.resolution_x(x_res)
        
    def scanner_resolution_y(self, topic, y_res):
        """Handler for message on scanner/apparatus/cameras/resolution-y"""
        logger.info('Scanner cameras resolution (y height): {}'.format(y_res))
        self.resolution_y(y_res)
