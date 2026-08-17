function [ber_sic, ber_mmse, ber_zf] = mmse_sic_detector(mod_order, snr_db_vec, num_packets, packet_len, rho)
% MMSE_SIC_DETECTOR Implements Non-Linear Successive Interference Cancellation (V-BLAST) for 2x2 MIMO.

if nargin < 5, rho = 0; end
if nargin < 4, packet_len = 1000; end
if nargin < 3, num_packets = 100; end

Nt = 2;
Nr = 2;
k = log2(mod_order);

ber_sic  = zeros(length(snr_db_vec), 1);
ber_mmse = zeros(length(snr_db_vec), 1);
ber_zf   = zeros(length(snr_db_vec), 1);

for s_idx = 1:length(snr_db_vec)
    snr_db = snr_db_vec(s_idx);
    snr_lin = 10^(snr_db / 10);
    noise_var = 1 / snr_lin;
    
    err_sic = 0; err_mmse = 0; err_zf = 0;
    total_bits = 0;
    
    for p = 1:num_packets
        tx_bits = randi([0, 1], Nt, packet_len * k);
        tx_syms = zeros(Nt, packet_len);
        for tx = 1:Nt
            tx_syms(tx, :) = modulate_qam(tx_bits(tx, :)', mod_order).';
        end
        
        X = tx_syms / sqrt(Nt);
        [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 1);
        N = sqrt(noise_var/2) * (randn(Nr, packet_len) + 1j * randn(Nr, packet_len));
        Y = H * X + N;
        
        % 1. Linear ZF & MMSE Baseline
        W_zf = pinv(H);
        S_hat_zf = sqrt(Nt) * (W_zf * Y);
        
        W_mmse = (H'*H + (noise_var*Nt)*eye(Nt)) \ H';
        S_hat_mmse = sqrt(Nt) * (W_mmse * Y);
        
        % 2. Non-Linear Ordered MMSE-SIC (V-BLAST)
        inv_matrix = inv(H'*H + (noise_var*Nt)*eye(Nt));
        sinr_1 = 1 / real(inv_matrix(1, 1)) - 1;
        sinr_2 = 1 / real(inv_matrix(2, 2)) - 1;
        
        if sinr_1 >= sinr_2
            order = [1, 2];
        else
            order = [2, 1];
        end
        
        S_hat_sic = zeros(Nt, packet_len);
        
        % Stage 1: Detect first stream
        first_idx = order(1);
        w1 = W_mmse(first_idx, :);
        s_first_raw = sqrt(Nt) * (w1 * Y);
        
        % Slicing
        bits_first = demodulate_qam(s_first_raw.', mod_order).';
        s_first_sliced = modulate_qam(bits_first.', mod_order).';
        S_hat_sic(first_idx, :) = s_first_raw;
        
        % Cancel first stream
        h_first = H(:, first_idx);
        Y_cancelled = Y - h_first * (s_first_sliced / sqrt(Nt));
        
        % Stage 2: Detect second stream with MRC
        second_idx = order(2);
        h_second = H(:, second_idx);
        w2 = (h_second') / (norm(h_second)^2 + noise_var*Nt);
        s_second_raw = sqrt(Nt) * (w2 * Y_cancelled);
        S_hat_sic(second_idx, :) = s_second_raw;
        
        % Demodulation
        rx_bits_sic = zeros(Nt, packet_len * k);
        rx_bits_mmse = zeros(Nt, packet_len * k);
        rx_bits_zf = zeros(Nt, packet_len * k);
        
        for tx = 1:Nt
            rx_bits_sic(tx, :)  = demodulate_qam(S_hat_sic(tx, :)', mod_order).';
            rx_bits_mmse(tx, :) = demodulate_qam(S_hat_mmse(tx, :)', mod_order).';
            rx_bits_zf(tx, :)   = demodulate_qam(S_hat_zf(tx, :)', mod_order).';
        end
        
        err_sic  = err_sic  + sum(sum(tx_bits ~= rx_bits_sic));
        err_mmse = err_mmse + sum(sum(tx_bits ~= rx_bits_mmse));
        err_zf   = err_zf   + sum(sum(tx_bits ~= rx_bits_zf));
        total_bits = total_bits + numel(tx_bits);
    end
    
    ber_sic(s_idx)  = err_sic / total_bits;
    ber_mmse(s_idx) = err_mmse / total_bits;
    ber_zf(s_idx)   = err_zf / total_bits;
end

end
