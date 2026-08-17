function [ber_zf, ber_mmse] = spatial_multiplexing_linear(mod_order, snr_db_vec, num_packets, packet_len, rho)
% SPATIAL_MULTIPLEXING_LINEAR Simulates 2x2 Spatial Multiplexing with ZF and MMSE detectors.

if nargin < 5, rho = 0; end
if nargin < 4, packet_len = 1000; end
if nargin < 3, num_packets = 100; end

Nt = 2;
Nr = 2;
k = log2(mod_order);

ber_zf = zeros(length(snr_db_vec), 1);
ber_mmse = zeros(length(snr_db_vec), 1);

for s_idx = 1:length(snr_db_vec)
    snr_db = snr_db_vec(s_idx);
    snr_linear = 10^(snr_db / 10);
    noise_var = 1 / snr_linear;
    
    err_zf = 0;
    err_mmse = 0;
    total_bits = 0;
    
    for p = 1:num_packets
        tx_bits = randi([0, 1], Nt, packet_len * k);
        tx_syms = zeros(Nt, packet_len);
        for tx = 1:Nt
            tx_syms(tx, :) = modulate_qam(tx_bits(tx, :)', mod_order).';
        end
        
        X = tx_syms / sqrt(Nt);
        [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 1);
        N = sqrt(noise_var / 2) * (randn(Nr, packet_len) + 1j * randn(Nr, packet_len));
        Y = H * X + N;
        
        % 1. Zero-Forcing (ZF) Receiver
        W_zf = pinv(H);
        S_hat_zf = sqrt(Nt) * (W_zf * Y);
        
        % 2. MMSE Receiver
        W_mmse = (H' * H + (noise_var * Nt) * eye(Nt)) \ H';
        S_hat_mmse = sqrt(Nt) * (W_mmse * Y);
        
        % Demodulate bits
        rx_bits_zf = zeros(Nt, packet_len * k);
        rx_bits_mmse = zeros(Nt, packet_len * k);
        for tx = 1:Nt
            rx_bits_zf(tx, :) = demodulate_qam(S_hat_zf(tx, :)', mod_order).';
            rx_bits_mmse(tx, :) = demodulate_qam(S_hat_mmse(tx, :)', mod_order).';
        end
        
        err_zf = err_zf + sum(sum(tx_bits ~= rx_bits_zf));
        err_mmse = err_mmse + sum(sum(tx_bits ~= rx_bits_mmse));
        total_bits = total_bits + numel(tx_bits);
    end
    
    ber_zf(s_idx) = err_zf / total_bits;
    ber_mmse(s_idx) = err_mmse / total_bits;
end

end
