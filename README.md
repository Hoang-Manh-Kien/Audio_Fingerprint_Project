# 🎧 Audio Fingerprinting Project
## ALGORITHM THEORY
This project implements two fundamentally different approaches to audio fingerprinting: the Constellation Map method and a custom Chroma-Based Trend Fingerprinting method. Each approach extracts features, hashes them, and performs offset-based matching to identify songs from short clips.

### Constellation Map (Shazam-style Fingerprinting)
This method is based on identifying local peaks in a spectrogram. First, a spectrogram is computed using a short-time Fourier transform (STFT). A 2D sliding window (e.g. 9×9) is applied to find local maxima—these are considered landmark peaks in the time-frequency plane.

Each peak is treated as an anchor point (f1, t1) and is paired with nearby target peaks (f2, t2) within a defined target zone. The difference in frequency and time between the two peaks forms a "constellation pair." These are hashed using the formula:
```math
hash = Δt * 2^16 + (f1 - 1) * 2^8 + (f2 - 1)
```
The hash table stores entries as [hash, time_index, songID]. During identification, a query clip is processed the same way. When matching hashes are found in the database, the difference in time indices (Δt) is computed. For each song, a histogram of time offsets is built. The song with the most consistent offset (i.e., the mode) is considered the best match.

This method works very well for audio with strong transients, beats, and wide spectral content. However, it is sensitive to pitch changes and doesn't perform as well on melodic or harmonically shifted inputs.

### Chroma-Based Trend Fingerprinting
The chroma-based method focuses on pitch class energy rather than full-spectrum information. Audio is first converted to a mono signal and resampled to 22,050 Hz. Chroma vectors are then extracted from overlapping frames. Each chroma vector contains 12 values representing the energy of each pitch class (C, C#, D, ..., B), regardless of octave.

To simplify the data, chroma values are quantized to discrete levels (e.g., 0, 1, 2). The system then computes the first-order difference across time frames and encodes rising energy as binary ```1``` (i.e., when chroma(t) > chroma(t-1)), and ```0``` otherwise.

A sliding window is used over the fingerprint matrix to detect short-term patterns. For each pitch class, three behaviors are encoded: whether the values are rising, falling, or if a local peak occurs. This results in a binary matrix of shape 48×T, where T is the number of frames.

Each column (i.e., time slice) of the binary fingerprint is hashed into an integer (e.g., using binary-to-decimal or CRC). The database stores ```[hash, time_index, songID]``` similarly to the constellation method.

During matching, the same fingerprinting and hashing process is applied to the input clip. Matching hashes are retrieved from the database, and each hit contributes a vote to a song and time offset. The system uses adaptive confidence rules to accept matches based on clip length:

- For clips shorter than 3 seconds, at least 15% of hashes must agree on a song/offset.
- For 3–6s clips: 10% threshold.
- For longer clips: 8% is sufficient.
- A minimum of 3 matching hashes is always required.

This method performs especially well for music with clear harmonic content such as classical, acoustic, or melodic pop music. It is naturally invariant to key changes, making it robust against covers, remixes, and pitch shifts. However, it may struggle with highly percussive or noise-dominated tracks.

---

## 📁 PROJECT STRUCTURE

```bash
.
├── constellation-map/      # Instructor-style peak-pair hashing
├── chroma-based/           # Our custom chroma fingerprinting
├── songDatabase/           # MATLAB .mat files (50 songs)
└── README.md
```
## Version 1: Constellation Map
Implements landmark hashing via spectrogram peak pairs (Based on the original Shazam approach). Optimized to adapt peak count to clip length.

Key files:
- Kien2300984.m – recognition pipeline
- build_database.m – builds hash table (song.mat)
- enhanced_test.m – tests accuracy and speed
- hash.m

## Version 2: Chroma-Based Fingerprinting
Uses chroma energy, temporal differences, and rising/falling/peak pattern encoding. Binary fingerprints are hashed for offset-based matching. Robust to pitch shifts, harmonic changes, and melodic similarity.

Key files:
- chromaFingerprinting.m
- identifyChromaSong.m
- buildChromaDatabase.m
- testChromaSystem.m

## Result Summary
| Version           | Accuracy (avg) | Speed                            | Strength                          |
| ----------------- | -------------- | -------------------------------- | --------------------------------- |
| Constellation Map | \~82–90%       | Fast overall                     | Percussive-rich & full-spectrum   |
| Chroma-Based      | \~76–88%       | Fast on clean, slower on complex | Pitch-invariant, tonal robustness |

## How to Run
1. Clone repo and open in MATLAB in your device.
2. Add songDatabase folder with 50 files to the corresponding folder you are running in MATLAB
3. Run the following in command depending on which folder you are opening:

Constellation:
- build_database()
- enhanced_test()

Chroma-based:
- buildChromaDatabase()
- testChromaSystem()
