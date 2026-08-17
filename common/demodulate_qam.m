function bits = demodulate_qam(syms, M)
% DEMODULATE_QAM Self-contained ML hard-decision QAM demodulator (Zero Toolbox Dependency).
%
% Inputs:
%   syms - Complex symbol vector
%   M    - Modulation order (2, 4, 16, 64)
%
% Outputs:
%   bits - Demodulated bit vector of length length(syms)*log2(M)

syms = syms(:);
k = log2(M);
N = length(syms);

switch M
    case 2 % BPSK
        bits = double(real(syms) >= 0);
        
    case 4 % QPSK
        % Gray decoding matching modulate_qam:
        % Real part >= 0 -> b0 = 1, else 0
        % Imag part >= 0 -> b1 = 1, else 0
        b0 = double(real(syms) >= 0);
        b1 = double(imag(syms) >= 0);
        bit_matrix = [b0, b1];
        bits = reshape(bit_matrix.', [], 1);
        
    case 16 % 16-QAM
        % Unnormalize
        s_unnorm = syms * sqrt(10);
        I = real(s_unnorm);
        Q = imag(s_unnorm);
        
        % ML bit decisions for standard Gray 16-QAM
        b0 = double(I >= 0);
        b1 = double(abs(I) < 2);
        b2 = double(Q >= 0);
        b3 = double(abs(Q) < 2);
        
        bit_matrix = [b0, b1, b2, b3];
        bits = reshape(bit_matrix.', [], 1);
        
    case 64 % 64-QAM
        % General Minimum Euclidean Distance slicer
        all_bits = de2bi_custom(0:(M-1), k);
        constellation = modulate_qam(reshape(all_bits.', [], 1), M);
        
        % Compute distance to all constellation points
        dist_matrix = abs(repmat(syms, 1, M) - repmat(constellation.', N, 1)).^2;
        [~, min_idx] = min(dist_matrix, [], 2);
        
        dec_bits = all_bits(min_idx, :);
        bits = reshape(dec_bits.', [], 1);
        
    otherwise
        error('Unsupported modulation order %d', M);
end

end

function b = de2bi_custom(d, n)
    d = d(:);
    b = zeros(length(d), n);
    for i = 1:n
        b(:, i) = bitget(d, n - i + 1);
    end
end
