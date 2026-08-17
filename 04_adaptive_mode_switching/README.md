# Stage 4: Dynamic Link Adaptation & Adaptive Mode Switching

## 1. Overview & Problem Formulation
In real-world mobile communications (5G NR), transmitting a fixed modulation or fixed MIMO rank fails to maximize throughput:
* At **low SNR** or during deep spatial fading ($\kappa(\mathbf{H}) \gg 1$), Spatial Multiplexing experiences near $100\%$ Frame Error Rate (FER), collapsing effective throughput to $0$.
* At **high SNR** and under orthogonal channels ($\kappa(\mathbf{H}) \approx 1$), Alamouti STBC wastefully caps the data rate to $1\times$ SISO capacity despite the availability of 2 parallel spatial pipes.

This stage designs an **Adaptive MIMO Controller** that dynamically monitors instantaneous channel metrics and switches transmission modes to track the optimal upper-envelope throughput.

---

## 2. Mathematical Formulation

### 2.1 Effective Goodput Metric
Effective throughput (Goodput $T_{eff}$) accounts for the retransmission / frame discard penalty when packets are corrupted:

$$T_{eff} = R_{mode} \times (1 - \text{FER}) \quad \text{[bps/Hz]}$$

Where:
* $R_{mode} = \begin{cases} 1 \cdot \log_2(M), & \text{Mode 0 (Alamouti STBC Diversity)} \\ 2 \cdot \log_2(M), & \text{Mode 1 (Spatial Multiplexing Rank-2)} \end{cases}$
* $\text{FER} = 1 - (1 - \text{BER})^{L_{packet}}$

### 2.2 Adaptive Switching Decision Rules
The controller computes the condition number $\kappa(\mathbf{H}) = \frac{\sigma_1}{\sigma_2}$ and instantaneous SNR $\gamma$ and maps the channel state:

$$\text{Mode} = \begin{cases} \text{Alamouti STBC (Diversity)}, & \text{if } \gamma < \gamma_{th} \text{ or } \kappa(\mathbf{H}) > \kappa_{th} \\ \text{Spatial Multiplexing (Rank-2)}, & \text{if } \gamma \ge \gamma_{th} \text{ and } \kappa(\mathbf{H}) \le \kappa_{th} \end{cases}$$

In our fixed $2 \times 2$ QPSK implementation, optimal threshold boundaries are empirically calibrated at $\gamma_{th} = 8.0\text{ dB}$ and $\kappa_{th} = 4.5$.

---

## 3. Files in this Folder

| File | Description |
|---|---|
| [`adaptive_mimo_controller.m`](adaptive_mimo_controller.m) | Decision function evaluating instantaneous channel $\mathbf{H}$ and SNR $\gamma$ to select transmission mode. |
| [`run_adaptive_switching_simulation.m`](run_adaptive_switching_simulation.m) | Monte Carlo simulation comparing Goodput of Fixed Diversity vs Fixed Multiplexing vs Adaptive Controller. |
| [`figures/`](figures/) | Contains exported decision region maps and goodput envelope comparison plots. |

---

## 4. Key Performance Insights

```mermaid
graph TD
    A["Evaluate Channel Matrix H and SNR gamma"] --> B{"SNR >= 8 dB and kappa <= 4.5?"}
    B -- "No" --> C["Mode 0: Transmit 1 Stream via Alamouti STBC"]
    B -- "Yes" --> D["Mode 1: Transmit 2 Streams via Spatial Multiplexing"]
    C --> E["Guarantees Low Packet Error Rate at Low SNR"]
    D --> F["Delivers 2x Peak Throughput at High SNR"]
    E --> G["Result: Perfect Goodput Upper Envelope"]
    F --> G
```

### 4.1 Effective Goodput Optimization Envelope
![Effective Goodput Envelope](figures/effective_goodput_envelope.png)

### 4.2 Dynamic Mode Decision Boundaries
![Adaptive Mode Decision Regions](figures/mode_switching_decision_boundary.png)

1. **Eliminating the Low-SNR Collapse:** While fixed Spatial Multiplexing delivers zero goodput below $6\text{ dB}$ due to packet drops, the adaptive controller gracefully retains the full diversity goodput of Alamouti STBC.
2. **200% Peak Rate Extraction:** As soon as channel conditions permit ($\text{SNR} > 12\text{ dB}$), the adaptive controller shifts $100\%$ of frames to Spatial Multiplexing, unlocking $4.0\text{ bps/Hz}$ (for QPSK).

