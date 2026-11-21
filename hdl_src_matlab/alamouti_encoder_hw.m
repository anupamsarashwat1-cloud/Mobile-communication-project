function [x1_t1_re, x1_t1_im, x2_t1_re, x2_t1_im, x1_t2_re, x1_t2_im, x2_t2_re, x2_t2_im] = alamouti_encoder_hw(s1_re, s1_im, s2_re, s2_im)
%#codegen
% ALAMOUTI_ENCODER_HW Hardware-synthesizable 2x2 Alamouti STBC Encoder
% Separates real and imaginary components into scalar channels for HDL Coder compatibility.
%
% Time slot 1: Antenna 1 = s1 / sqrt(2),          Antenna 2 = s2 / sqrt(2)
% Time slot 2: Antenna 1 = -conj(s2) / sqrt(2),  Antenna 2 = conj(s1) / sqrt(2)

INV_SQRT2 = single(0.7071067811865475);

% Time slot 1
x1_t1_re = s1_re * INV_SQRT2;
x1_t1_im = s1_im * INV_SQRT2;
x2_t1_re = s2_re * INV_SQRT2;
x2_t1_im = s2_im * INV_SQRT2;

% Time slot 2: -conj(s2) = -s2_re + 1j*s2_im
x1_t2_re = -s2_re * INV_SQRT2;
x1_t2_im =  s2_im * INV_SQRT2;

% Time slot 2: conj(s1) = s1_re - 1j*s1_im
x2_t2_re =  s1_re * INV_SQRT2;
x2_t2_im = -s1_im * INV_SQRT2;

end
