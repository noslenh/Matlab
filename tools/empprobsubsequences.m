function [est_P, est_transP, iT, empHH] = empprobsubsequences(contexts, P, A, seq_length)
%EMPPROBSUBSEQUENCES Estimate the probability of occurrences of all the
%                    sequences of length lower than height that can be
%                    generated by the context tree model. The transition
%                    probabilities associated to those sequences are also
%                    estimated. This empirical estimates are done using a
%                    realization of the context tree model of length
%                    seq_length
%
% Inputs
%
%  contexts      : contexts of the context tree model
%  P             : transition probabilities associated to the contexts
%  A             : alphabet
%  seq_length    : length of the sequence used to estimate the empirical
%                  probabilities est_P and est_transP (this should be a
%                  large enough number, by default it is equal to 10^6)
% 
% Outputs
%
%  est_P         : cell array with estimates of probabilities of
%                  occurrence of all possible sequences of length 1,2,...,height. 
%  est_transP    : matrix with estimates of transition probabilities
%                  associated to sequences of length 'height'
%  iT            : cell array of matrices with the index of the past that is formed given a
%                  past and a symbol
%  empHH         : empirical entropy (entropy rate computed using the
%                  estimates obtained form a realization of size 1,...,N)

%Author : Noslen Hernandez (noslenh@gmail.com), Aline Duarte (alineduarte@usp.br)
%Date   : 08/2020

if ~exist('seq_length', 'var')
        seq_length = 10^6;  % sample size
end

% height of the context tree
height = max(cellfun(@(x) length(x), contexts, 'uniformoutput', 1));

% from context tree to Markov process of order 'height' 
[past{height}, ~, Mc, iT{height}] = contextTree_to_FiniteMarkov(contexts, P, A);

% Get the auxiliary matrices for subsequences lower than 'height'
for k = 2 : height - 1
    [past{k}, I] = permn(A, k);  % all possible past of length k
    for p = 1 : size(I,1)
        [~, idx] = past_with_transitions(I(p,:), I, 3);
        iT{k}(p, :) = idx;
    end
end

% simulates a sequence according to the context tree model 
seq = generatesampleCTM(contexts, P, A, seq_length);

% iterate the sequence to estimate the prob. of subsequences of length < k
% and the transition prob.
% initialize the matrices est_P and est_transP
est_P = cell(height, 1);
est_P{1} = zeros(length(A), 1);
for k = 2 : height
    est_P{k} = zeros(size(past{k},1), 1);
end
est_transP = zeros(size(Mc));

% Find the index of the first occurrence of subsequence of length <= k (update
% frequency of occurrence)
idx_lastpast = zeros(height,1);
idx_symbol = seq(1) + 1;
est_P{1}(idx_symbol) = est_P{1}(idx_symbol) + 1;
for p = 2 : height
    idx_symbol = seq(p) + 1;
    est_P{1}(idx_symbol) = est_P{1}(idx_symbol) + 1;  % always update frequency of symbols
    for j = 2 : p-1
        idx_currpast = iT{j}(idx_lastpast(j), idx_symbol);
        est_P{j}(idx_currpast) = est_P{j}(idx_currpast) + 1;
        idx_lastpast(j) = idx_currpast;
    end
    
    % find the index of the first occurrence 
    found = false;
    i = 1;
    fpast = seq(1 : p);
    while ~found 
        if (sum(fpast ~= past{p}(i,:)) == 0) 
            found = true;
            idx_lastpast(p) = i;
        end    
    i = i + 1;
    end
    est_P{p}(idx_lastpast(p)) = est_P{p}(idx_lastpast(p)) + 1;
end

% iterate 
empHH = zeros(seq_length, 1);
for i = height + 1 : seq_length
    idx_symbol = seq(i) + 1;
    
    % compute frequency of sequences (pasts) of length k and its transitions
    idx_currpast = iT{height}(idx_lastpast(height), idx_symbol);
    est_P{height}(idx_currpast) = est_P{height}(idx_currpast) + 1;
    est_transP(idx_lastpast(height), idx_symbol) = est_transP(idx_lastpast(height), idx_symbol) + 1;
    idx_lastpast(height) = idx_currpast;
    
    % compute frequency of sequences of length <= k
    % sequences of length 1
    est_P{1}(idx_symbol) = est_P{1}(idx_symbol) + 1;
    % sequences of length 2 : k - 1
    for j = 2 : height - 1
        idx_currpast = iT{j}(idx_lastpast(j), idx_symbol);
        est_P{j}(idx_currpast) = est_P{j}(idx_currpast) + 1;
        idx_lastpast(j) = idx_currpast;
    end
    
    % update empirical_entropy
    % normalize the probabilities
    ss = sum(est_transP, 2);
    ss(ss == 0) = 1;
    empP = bsxfun(@rdivide, est_transP, ss);
    empMu = est_P{height}/(i - k + 1);
    empH = 0;
    for s = 1 : size(past{height},1)
        T = 0;
        for a = 1 : length(A)
            if empP(s,a) ~= 0, T = T + empP(s,a)*log2(empP(s,a)); end
        end
        empH = empH + empMu(s)*(-T);
    end
    empHH(i) = empH;
end

% normalize probabilities
for k = 1 : height
    no_past_in_seq = seq_length - k + 1;
    est_P{k} = est_P{k}/no_past_in_seq;
end
est_transP = bsxfun(@rdivide, est_transP, sum(est_transP,2));

end


