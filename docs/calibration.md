## Camera calibration

Some of the cameras provide a blurred image. They need calibration. 

The lens on top of a camera changes the focus when turned. In the condition as supplied to the customer, most cameras have their focus set appropriately. However, first of all, calibration is required to improve the overall image quality for the 3D reconstruction. Secondly, a few cameras are out of focus. Their lens needs to be turned to provide a sharp image. 

This is a manual activity requiring a user to adjust the lens for a sharp image.

## Approach

The CAMNODEs are controlled by the homie device controller and do not provide a live image. The approach requires an _experienced_ user to login on a CAMNODE and export the live camera image over the scanner network to a remote display. While turning the camera's lens the user reviews the image for a clear picture of a subject.

## Howto

1. Identify the blurred image. The image name is `..._camnode-<alpha num chars>.png`.
1. Identify the camnode's IP address. In the [scanner ui](user_manual.md) run the `List all online cameras`. It provides a list of `camnode-<alpha num chars> <IP address>` correspondences.
1. Login to the CAMNODE. The login requires a [ssh authentication key](sshkeys.md). Please request the key from the developer.
1. Run `src/calibrate/export_image.sh` 

The last step exports the live camera image to the remote desktop for manual calibration.

**IMPORTANT:** Please [restart the camnode service](user_manual.md#restart-camera-service) afterwards.

