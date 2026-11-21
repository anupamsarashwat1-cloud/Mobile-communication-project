function [x1_t1, x2_t1, x1_t2, x2_t2] = alamouti_encoder_hw(s1, s2)
%#codegen
% ALAMOUTI_ENCODER_HW Hardware-synthesizable 2x2 Alamouti STBC Encoder
% Implements space-time block mapping across 2 transmit antennas and 2 time slots:
% Time slot 1: Antenna 1 = s1 / sqrt(2),          Antenna 2 = s2 / sqrt(2)
% Time slot 2: Antenna 1 = -conj(s2) / sqrt(2),  Antenna 2 = conj(s1) / sqrt(2)
%
% Inputs:
%   s1, s2 - Complex fixed-point / single symbols (Q1.15 or single)
% Outputs:
%   x1_t1, x2_t1 - Transmit antenna 1 & 2 outputs at time slot 1
%   x1_t2, x2_t2 - Transmit antenna 1 & 2 outputs at time slot 2

% 1/sqrt(2) scaling factor in fixed-point representation (0.70710678)
INV_SQRT2 = single(0.7071067811865475);

% Time slot 1
x1_t1 = s1 * INV_SQRT2;
x2_t1 = s2 * INV_SQRT2;

% Time slot 2
x1_t2 = (-conj(s2)) * INV_SQRT2;
x2_t2 = conj(s1) * INV_SQRT2;

end
