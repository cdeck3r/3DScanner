# Calibrate Cameras

Some of the cameras provide a blurred image. They need calibration. 

## Usage

Check the [user documentation](../docs/calibration.md) for usage instructions.

**Note:** The script `export_image.sh` stops the camnode's homie service to enable the live camera image export over the network. After the end of the calibration the homie service needs to restarted on all camnodes. See [UI manual - Restart camera service](../docs/user_manual.md#restart-camera-service).

## Scripts

* `export_image.sh`: wrapper; call this script to export the live camera image to a remote display
* `install_calibrate.sh`: install all scripts 
* `... .py`: worker; actually exports the image
