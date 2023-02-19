# See also:
# https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
# https://timothygu.me/lame/detailed.html

# OS X / Power compatibility summary:
#   Safari 5.0.6 (Leopard)
#     Supported: WAV, MP3, AAC-LC, AAC-HE, AAC-HEv2
#     Unsupported: FLAC
#   Safari 4.1.3 (Tiger)
#     Supported: WAV, MP3, AAC-LC
#     Unsupported: AAC-HE, AAC-HEv2, FLAC
#   QuickTime Player 7.5 (Leopard)
#     Supported: WAV, MP3, AAC-LC, AAC-HE, AAC-HEv2
#     Unsupported: FLAC
#   VLC 2.0.10 (Leopard)
#     Supported: WAV, FLAC, MP3, AAC-LC, AAC-HE, AAC-HEv2
#   VLC 0.9.10 (Tiger)
#     Supported: WAV, FLAC, MP3, AAC-LC, AAC-HE
#     Unsupported: AAC-HEv2

# Note: homebrew stopped shipping ffmpeg with non-free codecs enabled.
# This means 'brew install ffmpeg' doesn't understand '-c:a libfdk_aac'.
# The homebrew-ffmpeg tap was created to address this.
# See https://github.com/homebrew-ffmpeg/homebrew-ffmpeg
#   brew uninstall ffmpeg
#   brew tap homebrew-ffmpeg/ffmpeg
#   brew install homebrew-ffmpeg/ffmpeg/ffmpeg --with-fdk-aac
# Or, to enable everything:
#   brew install homebrew-ffmpeg/ffmpeg/ffmpeg $(brew options homebrew-ffmpeg/ffmpeg/ffmpeg --compact | sed -e 's/--with-chromaprint//' | sed -e 's/--with-libzvbi//' | sed -e 's/--with-decklink//')

# WAV, lossless, https://en.wikipedia.org/wiki/WAV
all: 44k-16b-2ch.wav 44k-16b-1ch.wav 44k-8b-2ch.wav 44k-8b-2ch.wav
all: 22k-16b-2ch.wav 22k-16b-1ch.wav 22k-8b-2ch.wav 22k-8b-1ch.wav
all: 11k-16b-2ch.wav 11k-16b-1ch.wav 11k-8b-2ch.wav 11k-8b-1ch.wav
# FLAC, lossless, https://en.wikipedia.org/wiki/FLAC
all: 44k-16b-2ch.flac
# MPEG-1 audio layer 3, https://en.wikipedia.org/wiki/MP3
all: 44k-320k-2ch.mp3 44k-192k-2ch.mp3 44k-128k-2chjs.mp3 44k-96k-2chjs.mp3
all: 44k-vbr0-2ch.mp3 44k-vbr2-2ch.mp3 44k-vbr4-2ch.mp3 44k-vbr6-2chjs.mp3
# AAC, https://en.wikipedia.org/wiki/Advanced_Audio_Coding
# AAC LC is playable by Safari on both Leopard and Tiger.
# AAC HE and HE v2 are playable by Safari on Leopard, but not Tiger.
all: 44k-aac-lc-192k-2ch.m4a 44k-aac-lc-128k-2ch.m4a
all: 44k-aac-he-64k-2ch.m4a
all: 44k-aac-he2-48k-2ch.m4a
.PHONY: all

clean:
	mv source.wav source.wav_
	rm -f *.wav *.flac *.mp3 *.m4a
	mv source.wav_ source.wav
.PHONY: clean

44k-16b-2ch.wav:
	ln -s source.wav 44k-16b-2ch.wav

# -c:a pcm_s16le: PCM signed 16-bit little endian (standard 16-bit WAV)
# -ac 1: mono
44k-16b-1ch.wav:
	nice ffmpeg -i source.wav -c:a pcm_s16le -ac 1 44k-16b-1ch.wav

# -c:a pcm_u8: PCM unsigned 8-bit (standard 8-bit WAV)
44k-8b-2ch.wav:
	nice ffmpeg -i source.wav -c:a pcm_u8 44k-8b-2ch.wav

44k-8b-1ch.wav:
	nice ffmpeg -i source.wav -c:a pcm_u8 -ac 1 44k-8b-1ch.wav

# -ar 22050: 22kHz sample rate
22k-16b-2ch.wav:
	nice ffmpeg -i source.wav -ar 22050 -c:a pcm_s16le 22k-16b-2ch.wav

22k-16b-1ch.wav:
	nice ffmpeg -i source.wav -ar 22050 -c:a pcm_s16le -ac 1 22k-16b-1ch.wav

22k-8b-2ch.wav:
	nice ffmpeg -i source.wav -ar 22050 -c:a pcm_u8 22k-8b-2ch.wav

22k-8b-1ch.wav:
	nice ffmpeg -i source.wav -ar 22050 -c:a pcm_u8 -ac 1 22k-8b-1ch.wav

11k-16b-2ch.wav:
	nice ffmpeg -i source.wav -ar 11025 -c:a pcm_s16le 11k-16b-2ch.wav

11k-16b-1ch.wav:
	nice ffmpeg -i source.wav -ar 11025 -c:a pcm_s16le -ac 1 11k-16b-1ch.wav

11k-8b-2ch.wav:
	nice ffmpeg -i source.wav -ar 11025 -c:a pcm_u8 11k-8b-2ch.wav

11k-8b-1ch.wav:
	nice ffmpeg -i source.wav -ar 11025 -c:a pcm_u8 -ac 1 11k-8b-1ch.wav

44k-16b-2ch.flac:
	ffmpeg -i source.wav 44k-16b-2ch.flac

# -m s: true stereo
# -b 320: fixed bitrate
44k-320k-2ch.mp3:
	nice lame -b 320 -m s source.wav 44k-320k-2ch.mp3

44k-192k-2ch.mp3:
	nice lame -b 192 -m s source.wav 44k-192k-2ch.mp3

# -m j: joint stereo
44k-128k-2chjs.mp3:
	nice lame -b 128 -m j source.wav 44k-128k-2chjs.mp3

44k-96k-2chjs.mp3:
	nice lame -b 96 -m j source.wav 44k-96k-2chjs.mp3

# -V 0: variable bitrate
44k-vbr0-2ch.mp3:
	nice lame -V 0 -m s source.wav 44k-vbr0-2ch.mp3

44k-vbr2-2ch.mp3:
	nice lame -V 2 -m s source.wav 44k-vbr2-2ch.mp3

44k-vbr4-2ch.mp3:
	nice lame -V 4 -m s source.wav 44k-vbr4-2ch.mp3

44k-vbr6-2chjs.mp3:
	nice lame -V 6 -m j source.wav 44k-vbr6-2chjs.mp3

# -c:a libfdk_aac: AAC, LC profile
# -b:a 192k: audio bitrate
44k-aac-lc-192k-2ch.m4a:
	ffmpeg -i source.wav -c:a libfdk_aac -b:a 192k 44k-aac-lc-192k-2ch.m4a

44k-aac-lc-128k-2ch.m4a:
	ffmpeg -i source.wav -c:a libfdk_aac -b:a 128k 44k-aac-lc-128k-2ch.m4a

# -profile:a aac_he: AAC, HE profile
44k-aac-he-64k-2ch.m4a:
	ffmpeg -i source.wav -c:a libfdk_aac -profile:a aac_he -b:a 64k 44k-aac-he-64k-2ch.m4a

# -profile:a aac_he_v2: AAC, HE v2 profile
44k-aac-he2-48k-2ch.m4a:
	ffmpeg -i source.wav -c:a libfdk_aac -profile:a aac_he_v2 -b:a 48k 44k-aac-he2-48k-2ch.m4a
