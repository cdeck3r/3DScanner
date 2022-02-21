import logging
import os
import platform
import re
import subprocess
import sys
import time

import yaml
from device_camnode import Device_Camnode

# define console logging
logger = logging.getLogger(__name__)
FORMATTER = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(FORMATTER)
logger.addHandler(console_handler)
logging.basicConfig(level=logging.INFO, handlers=[console_handler])

# default settings
mqtt_settings = {
    'MQTT_BROKER': 'centralnode-dca632b407ff',
    'MQTT_PORT': 1883,
}

homie_settings = {
    'topic': 'scanner',
    'update_interval': 60,
    'implementation': 'unknown',
    'fw_name': 'unknown',
    'fw_version': 'unknown',
}

device_settings = {
    'camera_x_res': 1024,
    'camera_y_res': 768,
}


def get_implementation():
    """scanner/camnode-hwaddr/$implementation"""
    try:
        with open('/proc/device-tree/model', 'r') as f:
            model = f.readline()
    except:
        model = platform.machine()
    return model


def get_fw_name():
    """scanner/camnode-hwaddr/$fw/name"""
    try:
        with open('/etc/os-release', 'r') as f:
            fw_name = f.readline()
            words = fw_name.split('"')
            fw_name = words[1]
    except:
        fw_name = "unknown"
    return fw_name


def get_fw_version():
    """scanner/camnode-hwaddr/$fw/version"""
    os_info = os.uname()
    return os_info.release


def get_ip_from_ping(hostname):
    """Ping a hostname and parse the ping tool's stdout to retrieve the IPv4 address.

    The rationale for this awkward approach is to let the system do the name resolution. In particular, if the name is not part of the DNS, this method relies on the way how ping adds the search suffix. Despite extensive research, I could not figure out how the docker container retrieves the domains suffix. Note: it's not in /etc/resolv.conf.
    """

    def ping_node(hostname, prot='-4', count=3):
        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run(
            ['ping', prot, '-c ' + str(count), hostname],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        # execute process
        process
        return process.stdout

    # discover name using a single ping; we parse the result afterwards
    for prot in ['-4', '-v']:
        # -v is not a protocol. However, providing an empty string does not work properly.
        # Instead of an empty string, providing -v has no effect for parsing steps.
        stdout = ping_node(hostname, prot=prot, count=1)
        try:
            if stdout == '':
                raise ValueError('ping returned with empty result')
            lines = stdout.split('\n')
            headline = lines[0]
            if hostname not in headline:
                raise ValueError(
                    'hostname {} not contained in ping header'.format(hostname)
                )

            # source: https://stackoverflow.com/a/2890905
            ip = re.findall(r'[0-9]+(?:\.[0-9]+){3}', headline)
            return ip[0]
        except ValueError as ve:
            print(ve)


def configure_settings(cfgfile='homie_camnode.yml'):
    """Load mqtt settings from config file and set relevant homie settings.

    The default config file is homie_camnode.yml
    """
    try:
        with open(cfgfile, 'r') as ymlfile:
            cfg = yaml.full_load(ymlfile)
            logging.info('Configure node from config file: {}'.format(cfgfile))
            mqtt_settings['MQTT_BROKER'] = cfg['mqtt']['MQTT_BROKER']
            mqtt_settings['MQTT_PORT'] = cfg['mqtt']['MQTT_PORT']
            homie_settings['update_interval'] = int(cfg['homie']['UPDATE_INTERVAL'])
            # device specific settings
            device_settings['camera_x_res'] = cfg['device']['CAMERA_X_RES']
            device_settings['camera_y_res'] = cfg['device']['CAMERA_Y_RES']
    except Exception:
        logging.warn(
            'Cannot load config file: {}. Will use default settings.'.format(cfgfile)
        )

    # configure specific settings
    homie_settings["implementation"] = get_implementation()
    homie_settings["fw_name"] = get_fw_name()
    homie_settings["fw_version"] = get_fw_version()

    # if we get the broker's IP using the default method gethostbyname,
    # we will proceed with the name, otherwise, we ping the broker to receive its ip
    #
    # Reason: the Homie4 lib's get_local_ip() function
    # needs resolve the broker's IP in order to connect to the broker
    # https://github.com/mjcumming/Homie4/blob/fa035402e9a67b754b7ad08262b78d3801bf9157/homie/support/network_information.py#L45

    # we need the broker's IP address for the Homie4 lib to work properly
    broker_ip = get_ip_from_ping(mqtt_settings['MQTT_BROKER'])
    assert broker_ip, 'Could not retrieve IP for broker {}'.format(
        mqtt_settings['MQTT_BROKER']
    )
    mqtt_settings['MQTT_BROKER'] = broker_ip
    logging.info('Broker IP address is {}'.format(broker_ip))


def start_homie_camnode():
    """Starts the main loop to announce the camnode as homie device"""

    try:
        device_name = str(platform.node())
        dev = Device_Camnode(
            name=device_name,
            device_id=device_name,
            homie_settings=homie_settings,
            mqtt_settings=mqtt_settings,
            device_settings=device_settings,
        )
        dev.start()

        logging.info('Device_Camnode started')
        while True:
            time.sleep(1)

    except (KeyboardInterrupt, SystemExit):
        print("Got quit signal for homie-camnode.")


if __name__ == "__main__":
    # change working directory to this file's directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # configure mqtt and homie settings
    configure_settings()
    start_homie_camnode()
