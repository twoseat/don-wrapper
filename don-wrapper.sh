#!/usr/bin/env bash

set -e

CONFIG="$HOME/.don-wrapper"
CROP="detect-crop"
TRANSCODE="transcode-video"
OPTS=""
NICE=1

source=${@: -1}
filename="${source%.*}"

while getopts ":lmpsth" opt; do
  case $opt in
    l)
      LARGE=true
      ;;
    m)
      MEDIUM=true
      ;;
    p)
      NICE=10
      ;;
    s)
      SMALL=true
      ;;
    t)
      OPTS=" --filter decomb=bob"
      ;;
    h)
      echo
      echo "Opinionated wrapper for Don Melton's excellent transcoding gem"
      echo "(https://github.com/donmelton/video_transcoding)"
      echo
      echo "This script by Paul Harris (https://github.com/twoseat/don-wrapper)"
      echo
      echo "Basic Usage:"
      echo "    ./don-wrapper.sh source [options]"
      echo
      echo "The following options are available"
      echo "    -l   Create an HD version (1080p if possible, surround if available)"
      echo "    -m   Create a 'vanilla' transcode, no options set"
      echo "    -p   Lower the priority of the encoding (slower, but lets you keep using your machine!)"
      echo "    -s   Create an iDevice version (limited to 720p and stereo)"
      echo "    -t   Applies decomb bob filter (generally used for old broadcast material)"
      echo "    -h   This text"
      echo
      echo "Examples:"
      echo "./don-wrapper.sh -sl serenity.mkv    - creates a large and (relatively) small version of 'Serenity'"
      echo "./don-wrapper.sh -st out_of_gas.mkv - creates a small deinterlaced version of 'Out of Gas'"
      echo
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

crop_detect() {
  ${CROP} --values-only ${source} &> ${filename}.tmp
  echo "$(grep '[0-9]:' ${filename}.tmp)"
  rm ${filename}.tmp
}

crop_candidate="$(crop_detect)"

if [[ ${#crop_candidate} -lt 7 ]]; then
  echo "Crop candidates:"
  echo `${CROP} "${source}"`
  read -ep "Enter the crop you want to use (smaller numbers are safer): " crop_candidate
fi

crop=" --crop ${crop_candidate}" #<T:B:L:R>
echo "Cropping at ${crop}"

if [[ $SMALL ]]; then
  echo "Creating a small copy..."
  nice -n ${NICE} ${TRANSCODE} ${crop} ${OPTS} --mp4 --720p "${source}"
  mv "${filename}.mp4" "${filename} (Small).mp4"
  mv "${filename}.mp4.log" "${filename} (Small).log"
fi

if [[ $MEDIUM ]]; then
  echo "Creating a medium copy..."
  nice -n ${NICE} ${TRANSCODE} ${crop} ${OPTS} --mp4 "${source}"
  mv "${filename}.mp4" "${filename} (Medium).mp4"
  mv "${filename}.mp4.log" "${filename} (Medium).log"
fi

if [[ $LARGE ]]; then
  echo "Creating a large copy..."
  nice -n ${NICE} ${TRANSCODE} ${crop} ${OPTS} --mp4 --big "${source}"
  mv "${filename}.mp4" "${filename} (Large).mp4"
  mv "${filename}.mp4.log" "${filename} (Large).log"
fi
