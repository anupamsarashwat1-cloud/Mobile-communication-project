function [f, x] = smooth_density(data, num_bins, min_val, max_val)
% SMOOTH_DENSITY Computes a smoothed probability density estimate using base MATLAB.
%
% Inputs:
%   data     - Vector of numeric observations
%   num_bins - Number of histogram bins (default: 60)
%   min_val  - Optional minimum x range
%   max_val  - Optional maximum x range
%
% Outputs:
%   f - Estimated probability density values
%   x - Grid evaluation centers

if nargin < 2 || isempty(num_bins), num_bins = 60; end

data = data(:);
if nargin >= 4 && ~isempty(min_val) && ~isempty(max_val)
    bin_edges = linspace(min_val, max_val, num_bins + 1);
else
    bin_edges = linspace(min(data), max(data), num_bins + 1);
end

% Compute histogram counts
[counts, ~] = histcounts(data, bin_edges, 'Normalization', 'pdf');
x = 0.5 * (bin_edges(1:end-1) + bin_edges(2:end));

% Gaussian smoothing window
span = 5;
kernel = exp(-(-span:span).^2 / (2 * (span/2)^2));
kernel = kernel / sum(kernel);

f = conv(counts, kernel, 'same');

end
