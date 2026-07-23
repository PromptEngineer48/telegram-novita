#!/usr/bin/env bash
# Generates -ext clips for each section, appends them to the existing section
# MP3s, and rebuilds full-voiceover.mp3 with 0.6s gaps.
set -euo pipefail
cd "$(dirname "$0")"
[ -n "${ELEVENLABS_API_KEY:-}" ] || { echo "ERROR: ELEVENLABS_API_KEY not set"; exit 1; }
API="https://api.elevenlabs.io/v1"
VOICE_ID="TX3LPaxmHKxFdv7VOQHJ"   # Liam
MODEL_ID="eleven_v3"

sections=(01-intro 02-offer 03-signup 04-seedance 05-audio 06-claude-mcp 07-wrapup)
for s in "${sections[@]}"; do
  echo "-- extending $s"
  jq -n --rawfile t "scripts/$s-ext.txt" --arg m "$MODEL_ID" '{text:$t, model_id:$m}' \
    | curl -sS -f -H "xi-api-key: ${ELEVENLABS_API_KEY}" -H "Content-Type: application/json" \
        -d @- "$API/text-to-speech/$VOICE_ID?output_format=mp3_44100_128" \
        -o "_${s}-ext.mp3"
  printf "file '%s.mp3'\nfile '_%s-ext.mp3'\n" "$s" "$s" > _m.txt
  ffmpeg -y -v error -f concat -safe 0 -i _m.txt -c:a libmp3lame -b:a 128k "_${s}-new.mp3"
  mv "_${s}-new.mp3" "$s.mp3"
  rm -f "_${s}-ext.mp3" _m.txt
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$s.mp3" \
    | awk -v f="$s" '{printf "   %s: %.1fs\n", f, $1}'
done

ffmpeg -y -v error -f lavfi -t 0.6 -i anullsrc=r=44100:cl=mono -c:a libmp3lame -q:a 4 _gap.mp3
: > _concat.txt
n=${#sections[@]}
for i in "${!sections[@]}"; do
  echo "file '${sections[$i]}.mp3'" >> _concat.txt
  [ "$i" -lt $((n-1)) ] && echo "file '_gap.mp3'" >> _concat.txt
done
ffmpeg -y -v error -f concat -safe 0 -i _concat.txt -c:a libmp3lame -b:a 128k full-voiceover.mp3
rm -f _gap.mp3 _concat.txt
total=$(ffprobe -v error -show_entries format=duration -of csv=p=0 full-voiceover.mp3)
awk -v t="$total" 'BEGIN{printf "TOTAL: %dm %02ds\n", t/60, t%60}'
