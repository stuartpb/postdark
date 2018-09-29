#! /usr/bin/env bash

imgroot=$(mktemp -d)

for img in {flyer{1..4},toast{0..3}}; do
  giffile=$imgroot/$img.fig
  echo "Downloading $img..."
  curl -q "https://www.masswerk.at/flyer/clr/$img.gif" > "$giffile"
  lua repalletize.lua "$giffile"
done

# all flyers share the same palette
mv $imgroot/flyer1-palette.lua ../assets/flyer-palette.lua
# all toasts share the same map
mv $imgroot/toast0.map ../assets/toast.map
mv $imgroot/flyer*.map $imgroot/toast*-palette.lua ../assets
rm -rf "$imgroot"
