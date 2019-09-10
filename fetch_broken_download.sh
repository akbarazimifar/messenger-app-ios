#!/bin/bash
mkdir temprtc
cd temprtc 
git clone https://github.com/mesibo/mesibowebrtcparts
cat mesibowebrtcparts/split-webrtc/* > ../WebRTC.framework/WebRTC
cd ..
rm -fr temprtc


