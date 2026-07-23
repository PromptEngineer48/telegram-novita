#!/usr/bin/env bash
# Generates the 7 voiceover MP3s + concatenated full-voiceover.mp3 via ElevenLabs.
# Usage:
#   ELEVENLABS_API_KEY=... ./generate_voiceover.sh list            # list voices + models
#   ELEVENLABS_API_KEY=... ./generate_voiceover.sh gen VOICE_ID MODEL_ID
set -euo pipefail
cd "$(dirname "$0")"

[ -n "${ELEVENLABS_API_KEY:-}" ] || { echo "ERROR: ELEVENLABS_API_KEY not set"; exit 1; }
API="https://api.elevenlabs.io/v1"
HDR=(-H "xi-api-key: ${ELEVENLABS_API_KEY}")

if [ "${1:-list}" = "list" ]; then
  echo "== Voices =="
  curl -sS "${HDR[@]}" "$API/voices" | jq -r '.voices[] | "\(.category)\t\(.voice_id)\t\(.name)"'
  echo "== TTS models =="
  curl -sS "${HDR[@]}" "$API/models" | jq -r '.[] | select(.can_do_text_to_speech==true) | "\(.model_id)\t\(.name)"'
  echo "== Subscription tier =="
  curl -sS "${HDR[@]}" "$API/user/subscription" | jq -r '.tier'
  exit 0
fi

VOICE_ID="${2:?usage: gen VOICE_ID MODEL_ID}"
MODEL_ID="${3:?usage: gen VOICE_ID MODEL_ID}"

sections=(01-intro 02-offer 03-signup 04-seedance 05-audio 06-claude-mcp 07-wrapup)
for s in "${sections[@]}"; do
  echo "-- generating $s"
  jq -n --rawfile t "scripts/$s.txt" --arg m "$MODEL_ID" '{text:$t, model_id:$m}' \
    | curl -sS -f "${HDR[@]}" -H "Content-Type: application/json" \
        -d @- "$API/text-to-speech/$VOICE_ID?output_format=mp3_44100_128" \
        -o "$s.mp3"
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$s.mp3" \
    | awk -v f="$s" '{printf "   %s: %.1fs\n", f, $1}'
done

# concat with 0.6s gaps
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
