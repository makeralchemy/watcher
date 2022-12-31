#!/bin/bash
# script to take a image with the Raspberry Pi cameran
# and upload it to cloud storage as configured by RClone

#------------------
usage()
{
cat << EOF
usage: bash basg-arg-test -f file_name
-f | --base_filename  (Required)   Base file name for photos
-r | --rclone_dest    (Required)   RClone destination (example: OneDrive:/PiPhotos)
-d | --delay          (5m)         Delay between taking photos
-m | --max_images     (5)          Maximum number of photos to store before being overwritten
-c | --config_file    ()           RClone config file name; defaults to RClone default which is ~/.config/rclone/rclone.conf
-h | --help                          Brings up this text
EOF
}

# set default values for the command arguments

# base filename for images taken. a number will be appended to filename
base_filename=

# cloud drive as configured in RClone
rclone_dest=

# time delay between image capture
time_delay="5m"

# full path to the RClone configuration file
# if not specified, RClone defaults to ~/.config/rclone/rclone.conf
# if not running this in the home directory rclone was configured, the full path must be specified.
config_file=

# maximum number of images to be captured before overwriting them
# this is done to prevent from using up all of the space on the RClone drive
max_images=5

# parse the argument values
while [ "$1" != "" ]; do
    case $1 in
        -f | --base_filename )
            shift
            base_filename=$1
        ;;
        -r | --rclone_dest )
            shift
            rclone_dest=$1
        ;;
        -d | --delay )
            shift
            delay=$1
        ;;
        -m | --max_images )
            shift
            max_images=$1
        ;;
        -c | --config_file )
            shift
            config_file=$1
        ;;
        -h | --help )    usage
            exit
        ;;
        * )
            echo "Invalid argument '$1' specified"
            echo "For help try: $0 -h"
            exit 1
    esac
    shift
done

# a base file name for captures images must always be specified
if [ -z $base_filename ]; then
    echo "Base file name is required, provide it the flag: -f base_file_name or --base_filename base_file_name"
    exit
fi

# RClone destination must always be specified
if [ -z $rclone_dest ]; then
    echo "RClone destination is required but was not specified"
    exit
fi

# set file type for the captured images
file_type=".jpg"

# state the parameters that will be used
echo "Base file name for images: '$base_filename'"
echo "RClone destination: '$rclone_dest'"

if [ -z $config_file ]; then
    echo "RClone config file to be used: ~/.config/rclone/rclone.conf"
else
    echo "RClone config file to be used: $config_file"
fi

echo "Time delay between photos: $time_delay"
echo "Maximum images to store before being overwritten: $max_images"

# loop forever capturing images using the Raspberry Pi's camera
while true
do
    # specified number of images will be taken and then overwritten
    for (( i=1; i<=$max_images; i++ ))
    do
        # contruct file name for the image file to be uploaded
        filename="${base_filename}-${i}${file_type}"

        # capture the image
        # command to be used for an arducam 16mp camera with autofocus
#       libcamera-still -o $filename --hflip --vflip --autofocus --nopreview
        # command for generic raspberry pi cameras
        libcamera-still -o $filename --nopreview
        echo "Image captured as $filename"

        # copy the image to the RClone drive
#       rclone copy $filename OneDrive:/PiPhotos -v --config="/home/pi/.config/rclone/rclone.conf"
        rclone copy $filename $rclone_dest -v --config="/home/pi/.config/rclone/rclone.conf"
        echo "Image $filename copied to $rclone_dest"

        # print the date on the console and sleep for the specified time
        date
        echo "Sleeping for $time_delay"
        echo "----------------------------------------------------------------"
        sleep $time_delay
    done
done
