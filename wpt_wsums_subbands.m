%% * Initialize script for Figure 7
clear; close all; clc; setup; config_wsums_subbands;

%% * Waveform design by WSum and WSum-S algorithms
voltageWsum = zeros(length(Variable.nUsers), length(Variable.nSubbands), nRealizations);
voltageWSums = zeros(length(Variable.nUsers), length(Variable.nSubbands), nRealizations);
for iUser = 1 : length(Variable.nUsers)
    nUsers = Variable.nUsers(iUser);
    weight = ones(1, nUsers);
    [pathloss] = large_scale_fading(distance) * ones(1, nUsers);
    for iSubband = 1 : length(Variable.nSubbands)
        nSubbands = Variable.nSubbands(iSubband);
        [carrierFrequency] = carrier_frequency(centerFrequency, bandwidth, nSubbands);
        for iRealization = 1 : nRealizations
            channel = channel_tgn_e(pathloss, nTxs, nSubbands, nUsers, carrierFrequency, fadingType);
            [~, voltageWsum(iUser, iSubband, iRealization)] = waveform_wsum(beta2, beta4, txPower, channel, tolerance, weight);
            [~, voltageWSums(iUser, iSubband, iRealization)] = waveform_wsums(beta2, beta4, txPower, channel, tolerance, weight);
        end
    end
end
voltageWsum = mean(voltageWsum, 3);
voltageWSums = mean(voltageWSums, 3);
save('data/wpt_wsums_subbands.mat');

%% * Result
figure('name', sprintf('Average output voltage as a function of N with M = %d', nTxs));
legendString = cell(2, length(Variable.nUsers));
legendColor = num2cell(get(gca, 'colororder'), 2);
for iUser = 1 : length(Variable.nUsers)
    plot(Variable.nSubbands, voltageWsum(iUser, :) * 1e3, 'color', legendColor{iUser}, 'marker', 'o');
    legendString{1, iUser} = sprintf('WSum: K = %d', Variable.nUsers(iUser));
    hold on;
    plot(Variable.nSubbands, voltageWSums(iUser, :) * 1e3, 'color', legendColor{iUser}, 'marker', 'x');
    legendString{2, iUser} = sprintf('WSum-S: K = %d', Variable.nUsers(iUser));
end
hold off;
grid minor;
xlim([min(Variable.nSubbands), max(Variable.nSubbands)]);
xticks(Variable.nSubbands);
legend(vec(legendString), 'location', 'nw');
xlabel('Number of tones');
ylabel('Average v_{out} [mV]');
savefig('results/wpt_wsums_subbands.fig');
