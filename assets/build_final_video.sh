#!/usr/bin/env bash
# Builds final-video.mp4: animated gradient background, per-section title
# cards synced to the voiceover, live waveform, full voiceover audio.
set -euo pipefail
cd "$(dirname "$0")"
VO=voiceover
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
FONT_R=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf

sections=(01-intro 02-offer 03-signup 04-seedance 05-audio 06-claude-mcp 07-wrapup)
titles=("Unlimited AI for 24 Hours" "The Offer" "Sign-Up + Image Models" \
        "Seedance 2.0" "Audio Models" "Claude + Higgsfield MCP" "Wrap-Up")

TOTAL=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VO/full-voiceover.mp3")

# per-section start/end offsets inside full-voiceover (0.6s gaps between)
draw=""
t=0
for i in "${!sections[@]}"; do
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VO/${sections[$i]}.mp3")
  end=$(awk -v a="$t" -v b="$d" 'BEGIN{print a+b}')
  num=$(printf "%02d" $((i+1)))
  title=$(echo "${titles[$i]}" | sed "s/[':,]//g")
  draw+=",drawtext=fontfile=$FONT:text='$num':fontsize=140:fontcolor=0x9b7bff:x=140:y=380:alpha=0.9:enable='between(t,$t,$end)'"
  draw+=",drawtext=fontfile=$FONT:text='$title':fontsize=88:fontcolor=white:x=140:y=540:enable='between(t,$t,$end)'"
  t=$(awk -v e="$end" 'BEGIN{print e+0.6}')
done

ffmpeg -y -v error \
  -f lavfi -i "gradients=s=1920x1080:c0=0x0b1020:c1=0x231343:x0=0:y0=0:x1=1920:y1=1080:speed=0.015:d=$TOTAL:r=24" \
  -i "$VO/full-voiceover.mp3" \
  -filter_complex "\
[1:a]showwaves=s=1920x260:mode=cline:colors=0x9b7bff:r=24[wv];\
[0:v][wv]overlay=0:790:shortest=1[bgw];\
[bgw]drawtext=fontfile=$FONT:text='HIGGSFIELD  —  24H UNLIMITED ACCESS':fontsize=42:fontcolor=0xcfc4ff:x=140:y=120,\
drawtext=fontfile=$FONT_R:text='voiceover preview build — overlay your screen recordings here':fontsize=28:fontcolor=0x8888aa:x=140:y=1010$draw[v]" \
  -map "[v]" -map 1:a \
  -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p -r 24 \
  -c:a aac -b:a 192k -movflags +faststart \
  final-video.mp4

ffprobe -v error -show_entries format=duration,size -of default=noprint_wrappers=1 final-video.mp4
