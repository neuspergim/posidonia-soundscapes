%% Generate Perch 2.0 Mel spectrogram review batches
% This script creates standardized Mel-scale spectrogram panels for expert
% validation of clustered Perch 2.0 audio embeddings.
%
% Public version for the Posidonia Soundscapes repository.
%
% Expected input structure:
%
% reviewRoot/
%   pca_3d_hdbscan/
%     cluster_001/
%       *.wav
%   tsne_20d_hdbscan/
%     cluster_001/
%       *.wav
%   umap_3d_kmeans/
%     cluster_001/
%       *.wav
%
% Generated output:
%
% outputBase/
%   model_name/
%     cluster_name/
%       01_pairs_four_views/
%       02_groups_by_band/
%
% Notes:
% - WAV files are read but never modified.
% - Edit only the USER SETTINGS section before running.
% - Do not commit local absolute paths, raw recordings, or sensitive
%   deployment information to the public repository.

clear; clc;

%% USER SETTINGS
% Set this to the folder containing the model folders listed in modelNames.
% Example:
% reviewRoot = fullfile(pwd, "review_clusters");
reviewRoot = fullfile(pwd, "path_to_review_root");

% Model folders to process. Each folder should contain cluster_* subfolders.
modelNames = { ...
    "pca_3d_hdbscan", ...
    "tsne_20d_hdbscan", ...
    "umap_3d_kmeans"};

% Output folder. By default, output is written inside reviewRoot.
outputBase = fullfile(reviewRoot, "_review_protocol_mel_v1");

% Spectrogram bands used in the review protocol.
bands = [ ...
    makeBand("Full", 10, 48000, 128000, 0.032, 0.75); ...
    makeBand("Low", 10, 400, 2000, 0.500, 0.95); ...
    makeBand("Mid", 400, 2000, 8000, 0.064, 0.875); ...
    makeBand("High", 2000, 15000, 40000, 0.016, 0.75)];

% Display limits in dBFS for each band above.
colorLimits = {[-115 -45], [-125 -75], [-115 -45], [-115 -45]};

%% PROCESSING
assert(isfolder(reviewRoot), ...
    "Review root not found. Edit reviewRoot in USER SETTINGS: %s", ...
    reviewRoot);

if ~isfolder(outputBase)
    mkdir(outputBase);
end

grandTotalWavs = 0;
grandTotalPairPanels = 0;
grandTotalBandPanels = 0;

for m = 1:numel(modelNames)
    modelName = modelNames{m};
    modelDir = fullfile(reviewRoot, modelName);
    outputRoot = fullfile(outputBase, modelName);
    assert(isfolder(modelDir), "Model folder not found: %s", modelDir);
    if ~isfolder(outputRoot)
        mkdir(outputRoot);
    end

    clusterDirs = dir(fullfile(modelDir, "cluster_*"));
    clusterDirs = clusterDirs([clusterDirs.isdir]);
    [~, order] = sort(lower(string({clusterDirs.name})));
    clusterDirs = clusterDirs(order);

    totalWavs = 0;
    totalPairPanels = 0;
    totalBandPanels = 0;

    fprintf("\nProcessing %s (%d clusters)\n", modelName, numel(clusterDirs));

    for c = 1:numel(clusterDirs)
        clusterName = clusterDirs(c).name;
        clusterDir = fullfile(clusterDirs(c).folder, clusterName);
        pairDir = fullfile(outputRoot, clusterName, "01_pairs_four_views");
        bandDir = fullfile(outputRoot, clusterName, "02_groups_by_band");
        if ~isfolder(pairDir), mkdir(pairDir); end
        if ~isfolder(bandDir), mkdir(bandDir); end

        wavFiles = dir(fullfile(clusterDir, "*.wav"));
        [~, order] = sort(lower(string({wavFiles.name})));
        wavFiles = wavFiles(order);
        nWavs = numel(wavFiles);
        totalWavs = totalWavs + nWavs;

        spectra = cell(nWavs, numel(bands));
        for w = 1:nWavs
            wavPath = fullfile(wavFiles(w).folder, wavFiles(w).name);
            [x, fs] = audioread(wavPath);
            if size(x, 2) > 1
                x = mean(x, 2);
            end
            for b = 1:numel(bands)
                spectra{w, b} = calculateBandSpectrogram(x, fs, bands(b));
            end
        end

        pairNumber = 0;
        for firstWav = 1:2:nWavs
            pairNumber = pairNumber + 1;
            idx = firstWav:min(firstWav + 1, nWavs);
            outputPng = fullfile(pairDir, sprintf( ...
                "%s_pair_%02d_wavs_%02d_%02d.png", clusterName, ...
                pairNumber, idx(1), idx(end)));
            createPairPanel(wavFiles(idx), spectra(idx, :), bands, ...
                colorLimits, modelName, clusterName, outputPng);
        end
        totalPairPanels = totalPairPanels + pairNumber;

        bandPanelCount = 0;
        for b = 2:numel(bands)
            groupNumber = 0;
            for firstWav = 1:4:nWavs
                groupNumber = groupNumber + 1;
                idx = firstWav:min(firstWav + 3, nWavs);
                outputPng = fullfile(bandDir, sprintf( ...
                    "%s_%s_%g_%g_Hz_group_%02d_wavs_%02d_%02d.png", ...
                    clusterName, lower(bands(b).name), bands(b).fmin, ...
                    bands(b).fmax, groupNumber, idx(1), idx(end)));
                createBandPanel(wavFiles(idx), spectra(idx, b), bands(b), ...
                    colorLimits{b}, modelName, clusterName, outputPng);
                bandPanelCount = bandPanelCount + 1;
            end
        end
        totalBandPanels = totalBandPanels + bandPanelCount;

        fprintf("%s: %d WAV | %d pair panels | %d band panels\n", ...
            clusterName, nWavs, pairNumber, bandPanelCount);
    end

    grandTotalWavs = grandTotalWavs + totalWavs;
    grandTotalPairPanels = grandTotalPairPanels + totalPairPanels;
    grandTotalBandPanels = grandTotalBandPanels + totalBandPanels;

    fprintf(["\nModel batch complete\nModel: %s\nWAV: %d\n" ...
        "Pair panels: %d\nBand panels: %d\nTotal panels: %d\nOutput: %s\n"], ...
        modelName, totalWavs, totalPairPanels, totalBandPanels, ...
        totalPairPanels + totalBandPanels, outputRoot);
end

fprintf(["\nAll batches complete\nModels: %d\nWAV: %d\n" ...
    "Pair panels: %d\nBand panels: %d\nTotal panels: %d\nOutput base: %s\n"], ...
    numel(modelNames), grandTotalWavs, grandTotalPairPanels, ...
    grandTotalBandPanels, grandTotalPairPanels + grandTotalBandPanels, ...
    outputBase);

function band = makeBand(name, fmin, fmax, targetFs, windowSeconds, overlap)
    band = struct("name", name, "fmin", fmin, "fmax", fmax, ...
        "targetFs", targetFs, "windowSeconds", windowSeconds, ...
        "overlap", overlap);
end

function result = calculateBandSpectrogram(x, fs, band)
    targetFs = min(fs, band.targetFs);
    if targetFs < fs
        x = resample(x, targetFs, fs);
    end
    windowLength = round(band.windowSeconds * targetFs);
    window = hann(windowLength, "periodic");
    overlapLength = round(band.overlap * windowLength);
    nfft = 2 ^ nextpow2(windowLength);
    [s, f, t] = spectrogram(x, window, overlapLength, nfft, targetFs);
    amplitude = 2 * abs(s) / sum(window);
    dbfs = 20 * log10(amplitude + eps);
    keep = f >= band.fmin & f <= band.fmax;
    result = struct("t", t, "f", f(keep), "dbfs", dbfs(keep, :));
end

function createPairPanel(wavFiles, spectra, bands, colorLimits, ...
        modelName, clusterName, outputPng)
    nRows = numel(wavFiles);
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [40 40 2300 570 * nRows]);
    cleanup = onCleanup(@() close(fig));
    layout = tiledlayout(fig, nRows, 4, ...
        "TileSpacing", "compact", "Padding", "compact");
    title(layout, {sprintf("%s | %s | pair review", modelName, clusterName); ...
        "Mel scale | Full/Mid/High: -115 to -45 dBFS | Low: -125 to -75 dBFS"}, ...
        "Interpreter", "none", "FontWeight", "bold");

    for w = 1:nRows
        for b = 1:numel(bands)
            ax = nexttile(layout);
            plotMelSpectrogram(ax, spectra{w, b}, bands(b), colorLimits{b});
            title(ax, sprintf("%s\n%s: %g-%g Hz", wavFiles(w).name, ...
                bands(b).name, bands(b).fmin, bands(b).fmax), ...
                "Interpreter", "none", "FontSize", 8);
        end
    end
    exportgraphics(fig, outputPng, "Resolution", 180);
end

function createBandPanel(wavFiles, spectra, band, climDb, ...
        modelName, clusterName, outputPng)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [40 40 1800 1100]);
    cleanup = onCleanup(@() close(fig));
    layout = tiledlayout(fig, 2, 2, ...
        "TileSpacing", "compact", "Padding", "compact");
    title(layout, sprintf("%s | %s | %s %g-%g Hz | Mel | %g to %g dBFS", ...
        modelName, clusterName, band.name, band.fmin, band.fmax, ...
        climDb(1), climDb(2)), "Interpreter", "none", ...
        "FontWeight", "bold");

    for w = 1:numel(wavFiles)
        ax = nexttile(layout);
        plotMelSpectrogram(ax, spectra{w}, band, climDb);
        title(ax, wavFiles(w).name, "Interpreter", "none", "FontSize", 9);
    end
    cb = colorbar;
    cb.Label.String = "Amplitude (dBFS)";
    exportgraphics(fig, outputPng, "Resolution", 180);
end

function plotMelSpectrogram(ax, spectrum, band, climDb)
    melFrequency = hzToMel(spectrum.f);
    surface(ax, spectrum.t, melFrequency, zeros(size(spectrum.dbfs)), ...
        spectrum.dbfs, "EdgeColor", "none");
    view(ax, 2);
    xlim(ax, [0 5]);
    ylim(ax, hzToMel([band.fmin band.fmax]));
    clim(ax, climDb);
    colormap(ax, audacityLikeMap(256));
    xlabel(ax, "Time (s)");
    ylabel(ax, "Frequency (Hz, Mel)");
    ticksHz = chooseFrequencyTicks(band.fmin, band.fmax);
    yticks(ax, hzToMel(ticksHz));
    yticklabels(ax, compose("%g", ticksHz));
end

function mel = hzToMel(hz)
    mel = 2595 * log10(1 + hz / 700);
end

function ticks = chooseFrequencyTicks(fmin, fmax)
    if fmax >= 40000
        candidates = [10 50 100 200 500 1000 2000 5000 10000 ...
            20000 40000 48000];
    elseif fmax <= 400
        candidates = [10 20 50 100 200 300 400];
    elseif fmax <= 2000
        candidates = [400 500 700 1000 1500 2000];
    else
        candidates = [2000 3000 5000 7000 10000 15000];
    end
    ticks = candidates(candidates >= fmin & candidates <= fmax);
    if ticks(1) ~= fmin, ticks = [fmin ticks]; end
    if ticks(end) ~= fmax, ticks = [ticks fmax]; end
end

function map = audacityLikeMap(n)
    anchors = [0.00 0.00 0.02; 0.02 0.05 0.20; 0.16 0.04 0.35; ...
        0.48 0.03 0.52; 0.88 0.02 0.55; 1.00 0.32 0.18; ...
        1.00 0.92 0.40];
    anchorX = linspace(0, 1, size(anchors, 1));
    map = interp1(anchorX, anchors, linspace(0, 1, n), "pchip");
    map = min(max(map, 0), 1);
end
