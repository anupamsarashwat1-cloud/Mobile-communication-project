function [s_hat_i, s_hat_q] = qam_slicer_hw(r_i, r_q, mod_order)
%#codegen
% QAM_SLICER_HW Hardware-synthesizable Hard-Decision Constellation Slicer
% Performs Euclidean nearest-neighbor slicing for QPSK (4) and 16-QAM (16)
%
% Inputs:
%   r_i, r_q  - Received complex in-phase and quadrature scalar samples
%   mod_order - 4 for QPSK, 16 for 16-QAM
%
% Outputs:
%   s_hat_i, s_hat_q - Sliced constellation symbol coordinates

INV_SQRT2 = single(0.7071067811865475);
INV_SQRT10 = single(0.31622776601683794);

if mod_order <= 4
    % QPSK slicing (+/- 1 / sqrt(2))
    if r_i >= single(0.0)
        s_hat_i = INV_SQRT2;
    else
        s_hat_i = -INV_SQRT2;
    end
    
    if r_q >= single(0.0)
        s_hat_q = INV_SQRT2;
    else
        s_hat_q = -INV_SQRT2;
    end
else
    % 16-QAM slicing (+/- 1, +/- 3 normalized by sqrt(10))
    % Thresholds at -2/sqrt(10), 0, +2/sqrt(10)
    thresh_pos = single(2.0) * INV_SQRT10;
    thresh_neg = -thresh_pos;
    
    % In-phase slicer
    if r_i > thresh_pos
        s_hat_i = single(3.0) * INV_SQRT10;
    elseif r_i > single(0.0)
        s_hat_i = single(1.0) * INV_SQRT10;
    elseif r_i > thresh_neg
        s_hat_i = -single(1.0) * INV_SQRT10;
    else
        s_hat_i = -single(3.0) * INV_SQRT10;
    end
    
    % Quadrature slicer
    if r_q > thresh_pos
        s_hat_q = single(3.0) * INV_SQRT10;
    elseif r_q > single(0.0)
        s_hat_q = single(1.0) * INV_SQRT10;
    elseif r_q > thresh_neg
        s_hat_q = -single(1.0) * INV_SQRT10;
    else
        s_hat_q = -single(3.0) * INV_SQRT10;
    end
end

end
