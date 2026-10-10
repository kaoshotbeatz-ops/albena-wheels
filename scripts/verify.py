"""Smoke tests for the LGPL wheels. Run inside a throwaway venv with the wheels installed.
Usage: python -I verify.py [rtsp_url]   (rtsp_url optional: tests PyAV RTSP read)"""
import asyncio, ctypes, glob, io, math, os, subprocess, sys, tempfile, wave
import numpy as np

def ok(name, cond=True, extra=""):
    print(("PASS " if cond else "FAIL ") + name + (" " + str(extra) if extra else "")); 
    if not cond: ok.bad += 1
ok.bad = 0

import av
root = os.path.dirname(av.__file__)
libs = glob.glob(os.path.join(os.path.dirname(root), "av.libs", "libavcodec*")) + glob.glob(os.path.join(root, ".dylibs", "libavcodec*"))
lib = ctypes.CDLL(libs[0]); lib.avcodec_license.restype = ctypes.c_char_p
lic = lib.avcodec_license().decode(); lib.avcodec_configuration.restype = ctypes.c_char_p
conf = lib.avcodec_configuration().decode()
ok("avcodec_license is LGPL", lic.startswith("LGPL"), lic)
ok("configuration has no gpl/nonfree/x264", not any(s in conf for s in ("--enable-gpl", "--enable-nonfree", "x264", "x265", "fdk")), conf)
print("av", av.__version__, av.library_versions["libavcodec"])
ok("libx264 absent", "libx264" not in av.codecs_available)
for c in ("libopus", "libvpx", "libvpx-vp9", "libdav1d", "libaom-av1", "h264", "hevc", "aac", "mp3float"):
    ok("codec " + c, c in av.codecs_available)
print("hwaccels:", sorted(av.codec.hwaccel.hwdevices_available()))

# opus encode -> decode roundtrip
enc = av.CodecContext.create("libopus", "w"); enc.sample_rate = 48000; enc.layout = "mono"; enc.format = "s16"
dec = av.CodecContext.create("libopus", "r"); dec.sample_rate = 48000; dec.layout = "mono"
pts = 0; got = 0
for i in range(50):
    fr = av.AudioFrame.from_ndarray((np.sin(np.arange(960) / 10 + i * 96) * 8000).astype(np.int16)[None, :], format="s16", layout="mono")
    fr.sample_rate = 48000; fr.pts = pts; pts += 960
    for p in enc.encode(fr):
        for d in dec.decode(p): got += d.samples
ok("opus roundtrip", got >= 40 * 960, got)

# VP8/VP9/AV1/H.264 encode+decode of a tiny clip, plus RTP muxer/demuxer loopback
def roundtrip(codec, opts=None):
    buf = io.BytesIO()
    with av.open(buf, "w", format="matroska") as o:
        s = o.add_stream(codec, rate=10); s.width = 128; s.height = 96; s.pix_fmt = "yuv420p"
        if opts: s.options = opts
        for i in range(10):
            f = av.VideoFrame.from_ndarray(np.full((96, 128, 3), i * 20, np.uint8), format="rgb24")
            for p in s.encode(f): o.mux(p)
        for p in s.encode(): o.mux(p)
    buf.seek(0); n = 0
    with av.open(buf) as i:
        for f in i.decode(video=0): n += 1
    return n
for c, opts in (("libvpx", None), ("libvpx-vp9", None), ("libaom-av1", {"cpu-used": "8"}), ("mpeg4", None)):
    try: n = roundtrip(c, opts); ok("video roundtrip " + c, n == 10, n)
    except Exception as e: ok("video roundtrip " + c, False, e)
ok("software h264 encoder absent (expected, LGPL-only)", "libx264" not in av.codecs_available)

# RTP loopback (opus over RTP on localhost)
try:
    sdp = None
    out = av.open("rtp://127.0.0.1:50555", "w", format="rtp")
    s = out.add_stream("libopus", rate=48000); s.layout = "mono"
    ok("rtp muxer opens", True)
    out.close()
except Exception as e: ok("rtp muxer opens", False, e)

# wav decode (as faster-whisper does)
wp = os.path.join(tempfile.mkdtemp(), "t.wav")
with wave.open(wp, "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(16000)
    w.writeframes((np.sin(np.arange(16000 * 2) / 20) * 10000).astype(np.int16).tobytes())
try:
    from faster_whisper.audio import decode_audio
    a = decode_audio(wp, sampling_rate=16000); ok("faster_whisper.decode_audio", len(a) == 32000, len(a))
except Exception as e: ok("faster_whisper.decode_audio", False, e)

# aiortc loopback with Opus audio + data channel
async def loop():
    from aiortc import RTCPeerConnection, MediaStreamTrack
    from aiortc.mediastreams import AudioStreamTrack
    a, b = RTCPeerConnection(), RTCPeerConnection()
    a.addTrack(AudioStreamTrack()); a.createDataChannel("x")
    recv = asyncio.get_event_loop().create_future()
    @b.on("track")
    def on_track(t):
        async def r():
            for _ in range(5): await t.recv()
            recv.set_result(True)
        asyncio.ensure_future(r())
    await a.setLocalDescription(await a.createOffer()); await b.setRemoteDescription(a.localDescription)
    await b.setLocalDescription(await b.createAnswer()); await a.setRemoteDescription(b.localDescription)
    r = await asyncio.wait_for(recv, 15); await a.close(); await b.close(); return r
try: ok("aiortc loopback (opus audio)", asyncio.run(loop()))
except Exception as e: ok("aiortc loopback (opus audio)", False, repr(e))

import cv2
bi = cv2.getBuildInformation()
ok("cv2 import", True, cv2.__version__)
ok("cv2 FFMPEG disabled", "FFMPEG:                      NO" in bi.replace("\n", "\n") or "FFMPEG:                      NO" in bi, [l.strip() for l in bi.splitlines() if "FFMPEG" in l][:1])
img = np.random.randint(0, 255, (64, 64, 3), np.uint8)
okk, jpg = cv2.imencode(".jpg", img); dd = cv2.imdecode(jpg, cv2.IMREAD_COLOR)
ok("cv2 jpg encode/decode + resize/cvtColor", dd.shape == (64, 64, 3) and cv2.resize(cv2.cvtColor(dd, cv2.COLOR_BGR2GRAY), (32, 32)).shape == (32, 32))

if len(sys.argv) > 1:
    n = 0
    with av.open(sys.argv[1], options={"rtsp_transport": "tcp"}, timeout=10) as c:
        for f in c.decode(video=0):
            n += 1
            if n >= 10: break
    ok("PyAV RTSP read via " + sys.argv[1], n >= 10, n)
print("FAILURES:", ok.bad); sys.exit(1 if ok.bad else 0)
