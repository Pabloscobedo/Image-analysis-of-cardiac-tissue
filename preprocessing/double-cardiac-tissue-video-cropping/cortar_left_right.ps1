mkdir OUT -ErrorAction SilentlyContinue

Get-ChildItem -File | Where-Object { $_.Extension -match '\.mp4' } | ForEach-Object {
  $in = $_.FullName
  $base = $_.BaseName

  ffmpeg -y -i $in -vf "crop=iw/2:ih:0:0"   -c:v libx264 -preset veryfast -crf 18 -an ("OUT\" + $base + "_LEFT.mp4")
  ffmpeg -y -i $in -vf "crop=iw/2:ih:iw/2:0" -c:v libx264 -preset veryfast -crf 18 -an ("OUT\" + $base + "_RIGHT.mp4")
}