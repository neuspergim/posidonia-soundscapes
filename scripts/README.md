# Scripts and analysis tools

This directory contains reviewed MATLAB, Python, and notebook-based tools
used in Posidonia Soundscapes.

## Available scripts

### `Generate_spectrograms_mel_LowMidHigh.m`

MATLAB script for generating standardized Mel-scale spectrogram panels from
audio recordings. The script creates organized collections of spectrograms
covering multiple frequency ranges, facilitating the visual inspection,
comparison, annotation, and validation of underwater acoustic signals.

Rather than displaying the full frequency spectrum in a single image, the
script generates three complementary spectrogram sets focused on different
frequency bands:

| Spectrogram set | Frequency range | Typical applications |
| --- | --- | --- |
| Low | 10-400 Hz | Vessel noise, low-frequency fish pulses, whale sounds, and tonal components |
| Mid | 400-2,000 Hz | Fish calls, pulse series, knocks, modulated calls (e.g., Scorpaenidae sp. signals) |
| High | 2,000-15,000 Hz | Snaps, whistles, broadband transients, modulated signals, and high-frequency background noise |

This frequency-band approach improves the visualization of signals with
different spectral characteristics and simplifies expert interpretation
compared with inspecting a single full-band spectrogram.

#### Example application: Posidonia Soundscapes

Within the Posidonia Soundscapes project, this script is currently used to
generate the spectrogram material employed during the expert validation of
clusters produced by the Perch 2.0 audio embedding model.

A preliminary inspection of recordings from the study area identified the
dominant acoustic characteristics. Based on these observations, the recordings
were systematically visualized using the three complementary frequency-band
spectrograms described above, allowing each type of signal to be examined
under the most informative spectral scale.

The public version uses editable placeholder paths and does not include local
storage locations, raw recordings, or project-specific data.

Every published script should document:

- scientific purpose and scope;
- software and toolbox requirements;
- editable user settings;
- expected inputs and generated outputs;
- acoustic units, calibration assumptions, and limitations;
- a minimal example or validation procedure;
- authorship and licence.

Do not publish local absolute paths, credentials, raw recordings, sensitive
coordinates, or code whose third-party licence does not permit redistribution.
