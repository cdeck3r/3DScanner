import logging
import os
import time
from datetime import datetime

from homie.node.node_base import Node_Base
from homie.node.property.property_enum import Property_Enum
from homie.node.property.property_integer import Property_Integer
from homie.node.property.property_datetime import Property_DateTime

logger = logging.getLogger(__name__)


class Node_Cameras(Node_Base):
    """The scanner's cameras

    scanner/apparatus/cameras/...
    scanner/apparatus/cameras/shutter-button
    scanner/apparatus/cameras/last-button-push
    scanner/apparatus/cameras/online
    scanner/apparatus/cameras/online-percent
    """

    # states allowed for the camera's shutter button
    BUTTON_STATES = "push,release,timer"
    # Delay time in seconds until next button press is accepted
    SUPPRESSION_TIMEOUT = 5

    def __init__(
        self,
        device,
        id="cameras",
        name="All cameras",
        type_="camera",
        retain=True,
        qos=1,
    ):

        super().__init__(device, id, name, type_, retain, qos)

        # important functions we need for the button to work
        assert self.shutter_button
        assert self.shutter_timer
        assert Node_Cameras.BUTTON_STATES
        assert Node_Cameras.SUPPRESSION_TIMEOUT

        self.device = device
        self.total_cams = int(self.device.device_settings['total_cams'])

        self.button_push_time = 0
        # button's default value is 'release'
        self.button = Property_Enum(
            node=self,
            id="shutter-button",
            name="Shutter Button",
            data_format=Node_Cameras.BUTTON_STATES,
            set_value=self.shutter_button,
            value='release',
        )
        self.add_property(self.button)
        
        # datetime when shutter button was pushed last
        self.last_button_push = Property_DateTime(
            node=self, id='last-button-push', name='Last shutter button pushed', data_format='%Y-%m-%dT%H:%M:%S.%f',
            value=datetime.fromisoformat('1970-01-01').strftime('%Y-%m-%dT%H:%M:%S.%f'),
        )
        self.add_property(self.last_button_push)

        self.online = Property_Integer(
            node=self,
            id='online',
            name='Cameras online',
            settable=False,
            value=0,
        )
        self.add_property(self.online)

        self.online_percent = Property_Integer(
            node=self,
            id='online-percent',
            name='Cameras online in percent',
            settable=False,
            value=0,
        )
        self.add_property(self.online_percent)

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
        """Just updates the last-button-push property"""
        self.last_button_push.value = datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%f')


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
            if (curr_time - self.button_push_time) > Node_Cameras.SUPPRESSION_TIMEOUT:
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
