# ffmpeg Cheat Sheet for Demo Videos

## MP4 to GIF (high quality, palettegen)
```bash
ffmpeg -i input.mp4 -vf "fps=10,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 output.gif
```

## Screen recording (Windows GDI)
```bash
# Full desktop, 15fps, 10 seconds
ffmpeg -f gdigrab -framerate 15 -t 10 -i desktop output.mp4

# Specific region (x=100, y=200, 1280x720)
ffmpeg -f gdigrab -framerate 15 -t 10 -offset_x 100 -offset_y 200 -video_size 1280x720 -i desktop output.mp4

# Specific window by title
ffmpeg -f gdigrab -framerate 15 -t 10 -i title="Window Title" output.mp4
```

## Image sequence to GIF
```bash
# 0.5fps = 2 seconds per slide
ffmpeg -framerate 0.5 -pattern_type glob -i 'slides/*.png' \
  -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:color=white" \
  -loop 0 output.gif
```

## Trim
```bash
ffmpeg -i input.mp4 -ss 00:00:02 -t 00:00:08 -c copy output.mp4
```

## Resize
```bash
ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4
```

## Optimize GIF size
```bash
# Reduce framerate
ffmpeg -i input.mp4 -vf "fps=8,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 output.gif

# Use gifsicle for further optimization (if installed)
gifsicle -O3 --lossy=80 input.gif -o output.gif
```

## Add text overlay
```bash
ffmpeg -i input.mp4 -vf "drawtext=text='Demo':fontsize=24:fontcolor=white:x=10:y=10" output.mp4
```

## Concatenate clips
```bash
# Create file list
echo "file 'clip1.mp4'" > list.txt
echo "file 'clip2.mp4'" >> list.txt
ffmpeg -f concat -i list.txt -c copy output.mp4
```
