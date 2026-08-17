function syms = modulate_qam(bits, M)
% MODULATE_QAM Self-contained QAM modulator with unit average power (Zero Toolbox Dependency).
%
% Inputs:
%   bits - Binary vector/matrix (values 0 or 1) of length N*k where k = log2(M)
%   M    - Modulation order (4 for QPSK, 16 for 16-QAM, 64 for 64-QAM, 2 for BPSK)
%
% Outputs:
%   syms - Complex symbols with E[|s|^2] = 1

k = log2(M);
bits = bits(:);
N = length(bits) / k;
if rem(length(bits), k) ~= 0
    error('Number of bits must be an integer multiple of log2(M)');
end

% Group bits into integers
bit_matrix = reshape(bits, k, N).';
% Binary to integer conversion: MSB first
powers_of_two = 2.^( (k-1):-1:0 );
symbols_int = bit_matrix * powers_of_two';

switch M
    case 2 % BPSK
        syms = 2 * bits - 1;
        
    case 4 % QPSK / 4-QAM (Gray coded)
        % Map 0: -1-j, 1: -1+j, 2: 1-j, 3: 1+j
        b0 = bit_matrix(:, 1);
        b1 = bit_matrix(:, 2);
        I = 2*b0 - 1;
        Q = 2*b1 - 1;
        syms = (I + 1j*Q) / sqrt(2);
        
    case 16 % 16-QAM (Gray mapped standard constellation)
        b0 = bit_matrix(:, 1); b1 = bit_matrix(:, 2);
        b2 = bit_matrix(:, 3); b3 = bit_matrix(:, 4);
        I = (2*b0 - 1) .* (3 - 2*b1);
        Q = (2*b2 - 1) .* (3 - 2*b3);
        syms = (I + 1j*Q) / sqrt(10);
        
    case 64 % 64-QAM
        % Standard square Gray mapping
        I_bits = bit_matrix(:, 1:3);
        Q_bits = bit_matrix(:, 4:6);
        % Map 3 bits to [-7, -5, -3, -1, 1, 3, 5, 7]
        map8 = [-7, -5, -1, -3, 7, 5, 1, 3];
        idx_I = I_bits * [4; 2; 1] + 1;
        idx_Q = Q_bits * [4; 2; 1] + 1;
        syms = (map8(idx_I)' + 1j * map8(idx_Q)') / sqrt(42);
        
    otherwise
        error('Unsupported modulation order %d. Supported: 2, 4, 16, 64.', M);
end

end
