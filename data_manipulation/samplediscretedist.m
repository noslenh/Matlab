function [xsampled, indices] = samplediscretedist(x, prob, nsamples)
%SAMPLEDISCRETEDIST Sample from a discrete distribution with domain in x
%					defined by prob
%
% x         : domain of the distribution 
% prob      : probability associated to each value on x
% nsamples  : number of sampled values
%
% xsampled  : sampled values
% idx       : indices of sampled values

%Author : Noslen Hernandez, Aline Duarte
%Date   : 04/2020

xsampled = zeros(nsamples,1);
indices = zeros(nsamples,1);

% cells in the interval [0,1]
u = cumsum(prob);

% generate samples from a uniform distribution in [0,1]
s = rand(1, nsamples);

% find in which cell of the interval the sample is
for n = 1 : nsamples
    idx = 1;
    while s(n) > u(idx)
        idx = idx + 1;
    end
    xsampled(n) = x(idx);
    indices(n) = idx;
end
end

