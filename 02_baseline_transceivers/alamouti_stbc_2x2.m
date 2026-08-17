function [ber, detected_syms] = alamouti_stbc_2x2(mod_order, snr_db_vec, num_packets, packet_len, rho)
% ALAMOUTI_STBC_2X2 Simulates 2x2 Alamouti Space-Time Block Coding (Diversity Mode).
%
% Inputs:
%   mod_order   - Modulation order (e.g., 4 for QPSK, 16 for 16-QAM)
%   snr_db_vec  - Vector of SNR values in dB (Es/N0)
%   num_packets - Number of packets to simulate per SNR point
%   packet_len  - Number of symbols per packet (must be even)
%   rho         - Spatial correlation coefficient (default: 0)
%
% Outputs:
%   ber           - Bit Error Rate vector corresponding to snr_db_vec
%   detected_syms - Detected symbol sequence for the last realization

if nargin < 5, rho = 0; end
if nargin < 4, packet_len = 1000; end
if nargin < 3, num_packets = 100; end

k = log2(mod_order);
ber = zeros(length(snr_db_vec), 1);

for s_idx = 1:length(snr_db_vec)
    snr_db = snr_db_vec(s_idx);
    snr_linear = 10^(snr_db / 10);
    noise_var = 1 / snr_linear; % Normalized symbol energy Es = 1
    
    total_bit_errors = 0;
    total_bits = 0;
    
    for p = 1:num_packets
        % 1. Generate random bits & QAM symbols
        tx_bits = randi([0, 1], packet_len * k, 1);
        tx_syms = qammod(tx_bits, mod_order, 'InputType', 'bit', 'UnitAveragePower', true);
        
        % 2. Reshape into 2 streams for Alamouti encoding
        s1 = tx_syms(1:2:end);
        s2 = tx_syms(2:2:end);
        L = length(s1);
        
        % 3. Generate 2x2 correlated channel matrix H (constant over 2 time slots)
        [H, ~, ~] = generate_correlated_channel(2, 2, rho, rho, 1);
        h11 = H(1, 1); h12 = H(1, 2);
        h21 = H(2, 1); h22 = H(2, 2);
        
        % 4. Alamouti Space-Time Block Encoding across 2 time slots
        % Time slot 1: Tx1 = s1, Tx2 = s2
        % Time slot 2: Tx1 = -conj(s2), Tx2 = conj(s1)
        % Total transmit power per symbol normalized
        x1_t1 = s1 / sqrt(2);
        x2_t1 = s2 / sqrt(2);
        x1_t2 = -conj(s2) / sqrt(2);
        x2_t2 = conj(s1) / sqrt(2);
        
        % AWGN noise for 2 Rx antennas across 2 time slots
        n1_t1 = sqrt(noise_var/2) * (randn(L, 1) + 1j * randn(L, 1));
        n2_t1 = sqrt(noise_var/2) * (randn(L, 1) + 1j * randn(L, 1));
        n1_t2 = sqrt(noise_var/2) * (randn(L, 1) + 1j * randn(L, 1));
        n2_t2 = sqrt(noise_var/2) * (randn(L, 1) + 1j * randn(L, 1));
        
        % Received signals at Rx1 and Rx2
        r1_t1 = h11 * x1_t1 + h12 * x2_t1 + n1_t1;
        r2_t1 = h21 * x1_t1 + h22 * x2_t1 + n2_t1;
        r1_t2 = h11 * x1_t2 + h12 * x2_t2 + n1_t2;
        r2_t2 = h21 * x1_t2 + h22 * x2_t2 + n2_t2;
        
        % 5. Alamouti MRC Combining (Decoupling cross-talk orthogonal channels)
        % Channel Frobenius norm squared: ||H||_F^2 = |h11|^2 + |h12|^2 + |h21|^2 + |h22|^2
        H_norm_sq = abs(h11)^2 + abs(h12)^2 + abs(h21)^2 + abs(h22)^2;
        
        s1_hat = (conj(h11)*r1_t1 + conj(h21)*r2_t1 + h12*conj(r1_t2) + h22*conj(r2_t2)) / (H_norm_sq / sqrt(2));
        s2_hat = (conj(h12)*r1_t1 + conj(h22)*r2_t1 - h11*conj(r1_t2) - h21*conj(r2_t2)) / (H_norm_sq / sqrt(2));
        
        % Interleave detected symbols
        detected_syms = zeros(packet_len, 1);
        detected_syms(1:2:end) = s1_hat;
        detected_syms(2:2:end) = s2_hat;
        
        % 6. Demodulate bits
        rx_bits = qamdemod(detected_syms, mod_order, 'OutputType', 'bit', 'UnitAveragePower', true);
        
        total_bit_errors = total_bit_errors + sum(tx_bits ~= rx_bits);
        total_bits = total_bits + length(tx_bits);
    end
    
    ber(s_idx) = total_bit_errors / total_bits;
end

end
