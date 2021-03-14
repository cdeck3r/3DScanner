import logging
import os
import platform
import re
import subprocess
import sys
import time

import yaml
from device_apparatus import Device_Apparatus

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
    'total_cams': 48,
    'img_dir': '/home/pi/www-images',
    'img_tmp_dir': '/home/pi',
}


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


def configure_settings(cfgfile='homie_apparatus.yml'):
    """Load config file and set relevant settings for mqtt, homie and the device.

    The default config file is homie_apparatus.yml
    """
    try:
        with open(cfgfile, 'r') as ymlfile:
            cfg = yaml.full_load(ymlfile)
            logging.info('Configure node from config file: {}'.format(cfgfile))
            mqtt_settings['MQTT_BROKER'] = cfg['mqtt']['MQTT_BROKER']
            mqtt_settings['MQTT_PORT'] = cfg['mqtt']['MQTT_PORT']
            homie_settings['update_interval'] = cfg['homie']['UPDATE_INTERVAL']
            # configure specific settings
            homie_settings["implementation"] = cfg['homie']['IMPLEMENTATION']
            homie_settings["fw_name"] = cfg['homie']['FW_NAME']
            homie_settings["fw_version"] = cfg['homie']['FW_VERSION']
            # device specific settings
            device_settings['total_cams'] = cfg['device']['TOTAL_CAMS']
            device_settings['img_dir'] = cfg['device']['IMG_DIR']
            device_settings['img_tmp_dir'] = cfg['device']['IMG_TMP_DIR']
    except Exception:
        logging.warn(
            'Cannot load config file: {}. Will use default settings.'.format(cfgfile)
        )

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


def start_homie_apparatus():
    """Starts the main loop to announce the scanner apparatus as homie device"""

    try:
        dev = Device_Apparatus(
            homie_settings=homie_settings,
            mqtt_settings=mqtt_settings,
            device_settings=device_settings,
        )
        dev.start()

        logging.info('Device_Apparatus started')
        while True:
            time.sleep(1)

    except (KeyboardInterrupt, SystemExit):
        print("Got quit signal for homie-camnode.")


if __name__ == "__main__":
    # change working directory to this file's directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # configure settings and start device
    configure_settings()
    start_homie_apparatus()
