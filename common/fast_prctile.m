function y = fast_prctile(x, p)
% FAST_PRCTILE Computes percentiles using base MATLAB (Zero Toolbox Dependency).

x = sort(x(~isnan(x)));
n = length(x);
if n == 0
    y = NaN;
    return;
end

q = (p / 100) * (n - 1) + 1;
q = max(1, min(n, q));

floor_q = floor(q);
ceil_q = ceil(q);

if floor_q == ceil_q
    y = x(floor_q);
else
    frac = q - floor_q;
    y = x(floor_q) * (1 - frac) + x(ceil_q) * frac;
end

end
