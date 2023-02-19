# See also
# https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/MPEG

all: source.mov h264-1920x816-9mbs-aac-44k-128k-2ch.mov
all: mpeg1-320x240-1536k-mp2-192k-2ch-mencoder.mpeg mpeg1-320x240-1024k-mp2-128k-2ch-mencoder.mpeg
all: mpeg1-320x240-1536k-mp3-192k-2ch-ffmpeg.mpeg   mpeg1-320x240-1024k-mp3-128k-2ch-ffmpeg.mpeg
all: mpeg1-320x240-1536k-mp2-192k-2ch-ffmpeg.mpeg   mpeg1-320x240-1024k-mp2-128k-2ch-ffmpeg.mpeg
all: mpeg1-320x240-768k-mp2-128k-2ch-ffmpeg.mpeg    mpeg1-320x240-512k-mp2-96k-2ch-ffmpeg.mpeg
all: mpeg1-240x180-512k-mp2-96k-2ch-ffmpeg.mpeg     mpeg1-160x120-384k-mp2-64k-2ch-ffmpeg.mpeg
all: mpeg1-480x204-1536k-mp2-192k-2ch-ffmpeg.mpeg   mpeg1-480x204-1024k-mp2-192k-2ch-ffmpeg.mpeg
all: mpeg1-720x306-1536k-mp2-192k-2ch-ffmpeg.mpeg   mpeg1-720x306-1024k-mp2-192k-2ch-ffmpeg.mpeg
all: mpeg1-960x408-1536k-mp2-192k-2ch-ffmpeg.mpeg   mpeg1-960x408-1024k-mp2-192k-2ch-ffmpeg.mpeg
all: mpeg2-480x204-1024k-mp2-128k-2ch-ffmpeg.mpeg   mpeg2-720x306-1536k-mp2-192k-2ch-ffmpeg.mpeg   mpeg2-960x408-2M-mp2-192k-2ch-ffmpeg.mpeg
all: mpeg2-480x204-1024k-mp3-128k-2ch-ffmpeg.mpeg   mpeg2-720x306-1536k-mp3-192k-2ch-ffmpeg.mpeg   mpeg2-960x408-2M-mp3-192k-2ch-ffmpeg.mpeg
all: mpeg2-480x204-1024k-ac3-128k-2ch-ffmpeg.mpeg   mpeg2-720x306-1536k-ac3-192k-2ch-ffmpeg.mpeg   mpeg2-960x408-2M-ac3-192k-2ch-ffmpeg.mpeg
all: mpeg2-1440x612-4M-ac3-192k-2ch-ffmpeg.mpeg     mpeg2-1440x612-8M-ac3-192k-2ch-ffmpeg.mpeg     mpeg2-1920x816-8M-ac3-192k-2ch-ffmpeg.mpeg
all: mpeg4-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4 mpeg4-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4 mpeg4-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4
all: xvid-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4  xvid-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4  xvid-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4
all: h264-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4  h264-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4  h264-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4
all: h265-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4  h265-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4  h265-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4
.PHONY: all

clean:
	mv source.mov source.mov_
	rm -f *.mp4 *.mov *.mpeg
	mv source.mov_ source.mov
.PHONY: clean

h264-1920x816-9mbs-aac-44k-128k-2ch.mov:
	ln -s source.mov h264-1920x816-9mbs-aac-44k-128k-2ch.mov

source.mov:
	wget -O source.mov http://movietrailers.apple.com/movies/wb/blade-runner-2049/blade-runner-2049-trailer-4_h1080p.mov

#
# MPEG-1 video (MPEG-1 Part 2): https://en.wikipedia.org/wiki/MPEG-1
# Old-school MPEG-1 originally seemed to target a max of 320x240 @ 1.5Mbit/s.
# However, it appears OS X can generally handle larger resolutions.
#

# Experiment: how does mencoder compare to ffmpeg in terms of playback compatibility?
# See http://www.mplayerhq.hu/DOCS/HTML/en/menc-feat-mpeg.html
mpeg1-320x240-1536k-mp2-192k-2ch-mencoder.mpeg:
	mencoder source.mov -ss 2 \
	-of mpeg -mpegopts format=mpeg1:tsaf:muxrate=4000 \
	-ovc lavc -lavcopts vcodec=mpeg1video:vbitrate=1536:keyint=15:mbd=2:aspect=4/3 \
	-vf crop=1088:816,scale=320:240 \
	-oac lavc -lavcopts acodec=mp2:abitrate=192 \
	-o mpeg1-320x240-1536k-mp2-192k-2ch-mencoder.mpeg

mpeg1-320x240-1024k-mp2-128k-2ch-mencoder.mpeg:
	mencoder source.mov -ss 2 \
	-of mpeg -mpegopts format=mpeg1:tsaf:muxrate=4000 \
	-ovc lavc -lavcopts vcodec=mpeg1video:vbitrate=1024:keyint=15:mbd=2:aspect=4/3 \
	-vf crop=1088:816,scale=320:240 \
	-oac lavc -lavcopts acodec=mp2:abitrate=128 \
	-o mpeg1-320x240-1024k-mp2-128k-2ch-mencoder.mpeg

# Experiment: is MPEG-1 layer 2 audio or MPEG-1 layer 3 audio more compatible?
# See https://trac.ffmpeg.org/wiki/Scaling
mpeg1-320x240-1536k-mp3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1536k \
	-filter:v "crop=iw-832,scale=320:240" \
	-codec:a libmp3lame -b:a 92k \
	mpeg1-320x240-1536k-mp3-192k-2ch-ffmpeg.mpeg

mpeg1-320x240-1024k-mp3-128k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1024k \
	-filter:v "crop=iw-832,scale=320:240" \
	-codec:a libmp3lame -b:a 128k \
	mpeg1-320x240-1024k-mp3-128k-2ch-ffmpeg.mpeg

mpeg1-320x240-1536k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1536k \
	-filter:v "crop=iw-832,scale=320:240" \
	-codec:a mp2 -b:a 192k \
	mpeg1-320x240-1536k-mp2-192k-2ch-ffmpeg.mpeg

mpeg1-320x240-1024k-mp2-128k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1024k \
	-filter:v "crop=iw-832,scale=320:240" \
	-codec:a mp2 -b:a 128k \
	mpeg1-320x240-1024k-mp2-128k-2ch-ffmpeg.mpeg

mpeg1-320x240-768k-mp2-128k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 768k \
	-filter:v "crop=iw-832,scale=320:240" \
	-codec:a mp2 -b:a 128k \
	mpeg1-320x240-768k-mp2-128k-2ch-ffmpeg.mpeg

mpeg1-320x240-512k-mp2-96k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 512k \
	-filter:v "crop=iw-832,scale=320:240" \
	-codec:a mp2 -b:a 96k \
	mpeg1-320x240-512k-mp2-96k-2ch-ffmpeg.mpeg

# Smaller resolutions / bitrates to try on old G3's.
mpeg1-240x180-512k-mp2-96k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 512k \
	-filter:v "crop=iw-832,scale=240:180" \
	-codec:a mp2 -b:a 96k \
	mpeg1-240x180-512k-mp2-96k-2ch-ffmpeg.mpeg

mpeg1-160x120-384k-mp2-64k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 384k \
	-filter:v "crop=iw-832,scale=160:120" \
	-codec:a mp2 -b:a 64k \
	mpeg1-160x120-384k-mp2-64k-2ch-ffmpeg.mpeg

# Experiment: resolutions outside of 320x240?
mpeg1-480x204-1536k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1536k \
	-filter:v "scale=480:204" \
	-codec:a mp2 -b:a 192k \
	mpeg1-480x204-1536k-mp2-192k-2ch-ffmpeg.mpeg

mpeg1-480x204-1024k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a mp2 -b:a 192k \
	mpeg1-480x204-1024k-mp2-192k-2ch-ffmpeg.mpeg

mpeg1-720x306-1536k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a mp2 -b:a 192k \
	mpeg1-720x306-1536k-mp2-192k-2ch-ffmpeg.mpeg

mpeg1-720x306-1024k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1024k \
	-filter:v "scale=720:306" \
	-codec:a mp2 -b:a 192k \
	mpeg1-720x306-1024k-mp2-192k-2ch-ffmpeg.mpeg

mpeg1-960x408-1536k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1536k \
	-filter:v "scale=960:408" \
	-codec:a mp2 -b:a 192k \
	mpeg1-960x408-1536k-mp2-192k-2ch-ffmpeg.mpeg

mpeg1-960x408-1024k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg1video -b:v 1024k \
	-filter:v "scale=960:408" \
	-codec:a mp2 -b:a 192k \
	mpeg1-960x408-1024k-mp2-192k-2ch-ffmpeg.mpeg

#
# MPEG-2 video (MPEG-2 Part 2, H.262): https://en.wikipedia.org/wiki/MPEG-2
#

# TODO: some additional MPEG-2 settings to try: https://www.smorgasbork.com/2009/12/03/real-time-mpeg-2-encoding-with-ffmpeg/

mpeg2-480x204-1024k-mp2-128k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a mp2 -b:a 128k \
	mpeg2-480x204-1024k-mp2-128k-2ch-ffmpeg.mpeg

mpeg2-720x306-1536k-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a mp2 -b:a 192k \
	mpeg2-720x306-1536k-mp2-192k-2ch-ffmpeg.mpeg

mpeg2-960x408-2M-mp2-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 2M \
	-filter:v "scale=960:408" \
	-codec:a mp2 -b:a 192k \
	mpeg2-960x408-2M-mp2-192k-2ch-ffmpeg.mpeg

# Experiment: how compatible is MPEG-2 + MP3?
mpeg2-480x204-1024k-mp3-128k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a libmp3lame -b:a 128k \
	mpeg2-480x204-1024k-mp3-128k-2ch-ffmpeg.mpeg

mpeg2-720x306-1536k-mp3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a libmp3lame -b:a 192k \
	mpeg2-720x306-1536k-mp3-192k-2ch-ffmpeg.mpeg

mpeg2-960x408-2M-mp3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 2M \
	-filter:v "scale=960:408" \
	-codec:a libmp3lame -b:a 192k \
	mpeg2-960x408-2M-mp3-192k-2ch-ffmpeg.mpeg

# Experiment: how compatible is MPEG-2 + AC3?
mpeg2-480x204-1024k-ac3-128k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a ac3 -b:a 128k \
	mpeg2-480x204-1024k-ac3-128k-2ch-ffmpeg.mpeg

mpeg2-720x306-1536k-ac3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a ac3 -b:a 192k \
	mpeg2-720x306-1536k-ac3-192k-2ch-ffmpeg.mpeg

mpeg2-960x408-2M-ac3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 2M \
	-filter:v "scale=960:408" \
	-codec:a ac3 -b:a 192k \
	mpeg2-960x408-2M-ac3-192k-2ch-ffmpeg.mpeg

# Let's try some higher resolutions and bitrates:
mpeg2-1440x612-4M-ac3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 4M \
	-filter:v "scale=1440:612" \
	-codec:a ac3 -b:a 192k \
	mpeg2-1440x612-4M-ac3-192k-2ch-ffmpeg.mpeg

mpeg2-1440x612-8M-ac3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 8M \
	-filter:v "scale=1440:612" \
	-codec:a ac3 -b:a 192k \
	mpeg2-1440x612-8M-ac3-192k-2ch-ffmpeg.mpeg

mpeg2-1920x816-8M-ac3-192k-2ch-ffmpeg.mpeg:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg2video -b:v 8M \
	-filter:v "scale=1440:612" \
	-codec:a ac3 -b:a 192k \
	mpeg2-1920x816-8M-ac3-192k-2ch-ffmpeg.mpeg

#
# MPEG-4 video:
#  - MPEG-4 Part 2: https://en.wikipedia.org/wiki/MPEG-4_Part_2
#  - MPEG-4 Part 10 (H.264 / AVC): https://en.wikipedia.org/wiki/Advanced_Video_Coding
#  - AAC audio: https://trac.ffmpeg.org/wiki/Encode/AAC
#

# "mpeg4" encoder:

mpeg4-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg4 -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a libfdk_aac -b:a 128k \
	mpeg4-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4

mpeg4-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg4 -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a libfdk_aac -b:a 192k \
	mpeg4-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4

mpeg4-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v mpeg4 -b:v 2M \
	-filter:v "scale=960:408" \
	-codec:a libfdk_aac -b:a 192k \
	mpeg4-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4

# "libxvid" encoder:

xvid-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libxvid -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a libfdk_aac -b:a 128k \
	xvid-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4

xvid-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libxvid -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a libfdk_aac -b:a 192k \
	xvid-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4

xvid-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libxvid -b:v 2M \
	-filter:v "scale=960:408" \
	-codec:a libfdk_aac -b:a 192k \
	xvid-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4

# "libx264" encoder:

h264-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libx264 -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a libfdk_aac -b:a 128k \
	h264-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4

h264-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libx264 -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a libfdk_aac -b:a 192k \
	h264-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4

h264-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libx264 -b:v 2M \
	-filter:v "scale=960:408" \
	-codec:a libfdk_aac -b:a 192k \
	h264-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4

# "libx265" encoder: https://trac.ffmpeg.org/wiki/Encode/H.265

h265-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libx265 -b:v 1024k \
	-filter:v "scale=480:204" \
	-codec:a libfdk_aac -b:a 128k \
	h265-480x204-1024k-aac-lc-128k-2ch-ffmpeg.mp4

h265-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libx265 -b:v 1536k \
	-filter:v "scale=720:306" \
	-codec:a libfdk_aac -b:a 192k \
	h265-720x306-1536k-aac-lc-192k-2ch-ffmpeg.mp4

h265-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4:
	ffmpeg -i source.mov -ss 3 \
	-codec:v libx265 -b:v 2M \
	-filter:v "scale=960:408" \
	-codec:a libfdk_aac -b:a 192k \
	h265-960x408-2M-aac-lc-192k-2ch-ffmpeg.mp4
