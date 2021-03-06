%% * Initialize script for Figure 9
clear; close all; clc; setup; config_mu_comparison;

%% * Waveform design by Max-Min-Rand, CHE Max-Min-RR and CHE Max-Min-Rand algorithms
minVoltageRand = zeros(length(Variable.nTxs), length(Variable.nSubbands), length(Variable.nUsers), nRealizations);
minVoltageCheRr = zeros(length(Variable.nTxs), length(Variable.nSubbands), length(Variable.nUsers), nRealizations);
minVoltageCheRand = zeros(length(Variable.nTxs), length(Variable.nSubbands), length(Variable.nUsers), nRealizations);
for iTx = 1 : length(Variable.nTxs)
    nTxs = Variable.nTxs(iTx);
    txPower = eirp / nTxs;
    for iSubband = 1 : length(Variable.nSubbands)
        nSubbands = Variable.nSubbands(iSubband);
        [carrierFrequency] = carrier_frequency(centerFrequency, bandwidth, nSubbands);
        for iUser = 1 : length(Variable.nUsers)
            nUsers = Variable.nUsers(iUser);
            weight = ones(1, nUsers);
            [pathloss] = large_scale_fading(distance) * ones(1, nUsers);
            for iRealization = 1 : nRealizations
                channel = channel_tgn_e(pathloss, nTxs, nSubbands, nUsers, carrierFrequency, fadingType);
                [~, ~, ~, minVoltageRand(iTx, iSubband, iUser, iRealization)] = waveform_max_min_rand(beta2, beta4, txPower, channel, tolerance, nCandidates);
                [~, ~, ~, minVoltageCheRr(iTx, iSubband, iUser, iRealization)] = waveform_max_min_che_rr(beta2, beta4, txPower, channel, tolerance, pathloss);
                [~, ~, ~, minVoltageCheRand(iTx, iSubband, iUser, iRealization)] = waveform_max_min_che_rand(beta2, beta4, txPower, channel, tolerance, pathloss);
            end
        end
    end
end
minVoltageRand = mean(minVoltageRand, 4);
minVoltageCheRr = mean(minVoltageCheRr, 4);
minVoltageCheRand = mean(minVoltageCheRand, 4);
save('data/wpt_mu_comparison.mat');

%% * Result
figure('name', sprintf('Average minimum output voltage as a function of (M, N, K)'));
bar(1e3 * [vec(minVoltageRand), vec(minVoltageCheRr), vec(minVoltageCheRand)]);
grid minor;
label = [repelem(Variable.nTxs, length(Variable.nSubbands) * length(Variable.nUsers)); repmat(repelem(Variable.nSubbands, length(Variable.nUsers)), [1, length(Variable.nTxs)]); repmat(repmat(Variable.nUsers, [1, length(Variable.nSubbands)]), [1, length(Variable.nTxs)])];
set(gca, 'xtick', 1 : length(Variable.nTxs) * length(Variable.nSubbands) * length(Variable.nUsers), 'xticklabel', display_coordinate(label));
legend('Max-Min-Rand', 'CHE Max-Min-RR', 'CHE Max-Min-Rand', 'location', 'nw');
ylabel('Average minimum v_{out} [mV]');
savefig('results/wpt_mu_comparison.fig');
