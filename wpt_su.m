function [waveform] = wpt_su(beta2, beta4, powerBudget, nSubbands, nTxs, subchannel, tolerance)
% Function:
%   - optimize the amplitude and phase of transmit multisine waveform
%
% InputArg(s):
%   - beta2 [\beta_2]: diode second-order parameter
%   - beta4 [\beta_4]: diode fourth-order parameter
%   - powerBudget [P]: transmit power constraint
%   - nSubbands [N]: number of subbands/subcarriers
%   - nTxs [M]: number of transmit antennas
%   - subchannel [h_{q, n}] (nTxs * nSubbands): channel frequency response matrix
%   - tolerance [\epsilon]: convergence ratio
%
% OutputArg(s):
%   - waveform: complex waveform weights for each transmit antenna and subband
%
% Comment(s):
%   - the optimal spatial beamforming for SU WPT is MRT
%   - obtain the rank-1 frequency weight matrix in closed form for a complexity of \mathcal{O}(N ^ 3)
%   - as all eigenvalues of \boldsymbol{A}''_1 are negative, we choose the eigenvector corresponding to the minimum eigenvalue (maximum in magnitude)
%
% Reference(s):
%   - Y. Huang and B. Clerckx, "Large-Scale Multiantenna Multisine Wireless Power Transfer," IEEE Transactions on Signal Processing, vol. 65, no. 21, pp. 5812–5827, Jan. 2017.
%
% Author & Date: Yang (i@snowztail.com) - 06 Mar 20


    % ? initialize p by uniform power allocation
    frequencyWeight = sqrt(powerBudget / nSubbands) * ones(nSubbands, 1);
    % \boldsymbol{X}
    frequencyWeightMatrix = frequencyWeight * frequencyWeight';
    % \boldsymbol{M}''_k
    channelNormMatrix = cell(nSubbands, 1);
    % \boldsymbol{t}
    auxiliary = zeros(nSubbands, 1);
    for iSubband = 1 : nSubbands
        channelNormMatrix{iSubband} = diag(diag(vecnorm(subchannel).' * vecnorm(subchannel), iSubband - 1), iSubband - 1);
        auxiliary(iSubband) = trace(channelNormMatrix{iSubband} * frequencyWeightMatrix);
    end

    isConverged = false;
    while ~isConverged
        % \boldsymbol{C}''_1
        termC1 = - (beta2 + 3 * beta4 * auxiliary(1)) / 2 * channelNormMatrix{1} - 3 * beta4 * sum(cat(3, channelNormMatrix{2 : end}) .* reshape(conj(auxiliary(2 : end)), [1, 1, nSubbands - 1]), 3);
        % \boldsymbol{A}''_1
        termA1 = termC1 + termC1';

        % * Solve rank-1 \boldsymbol{X}^{\star} in closed form (low complexity)
        % \boldsymbol{x}^{\star}
        [v, d] = eig(termA1);
        frequencyWeight = sqrt(powerBudget) * v(:, diag(d) == min(diag(d)));
        clearvars v d;
        % \boldsymbol{X}^{\star}
        frequencyWeightMatrix_ = frequencyWeight * frequencyWeight';

        % % * Solve high rank \boldsymbol{X} in SDP problem by cvx (high complexity)
        % cvx_begin
        %     cvx_solver mosek
        %     variable frequencyWeightMatrix_
        %     minimize trace(termA1 * frequencyWeightMatrix_)
        %     subject to
        %         trace(frequencyWeightMatrix_) <= powerBudget;
        % cvx_end

        % Update \boldsymbol{t}
        for iSubband = 1 : nSubbands
            auxiliary(iSubband) = trace(channelNormMatrix{iSubband} * frequencyWeightMatrix_);
        end
        % test convergence
        if (norm(frequencyWeightMatrix_ - frequencyWeightMatrix, 'fro')) / norm(frequencyWeightMatrix_, 'fro') <= tolerance
            isConverged = true;
        end
        frequencyWeightMatrix = frequencyWeightMatrix_;
    end
    spatialPrecoder = conj(subchannel) ./ vecnorm(subchannel);
    % s_n
    waveform = zeros(nTxs, nSubbands);
    for iSubband = 1 : nSubbands
        waveform(:, iSubband) = frequencyWeight(iSubband) * spatialPrecoder(:, iSubband);
    end

end
