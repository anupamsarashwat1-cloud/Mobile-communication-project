# Complete Step-by-Step Tutorial: Running the 5G MIMO Optimization Project in MATLAB

This tutorial provides complete instructions to open, execute, and view results for every stage of the project on **MATLAB Desktop (Windows)** and **MATLAB Online (Web Browser)**.

---

## 📑 Table of Contents
1. [Where are my project files located?](#1-where-are-my-project-files-located)
2. [Option A: Running on MATLAB Desktop (Local PC)](#2-option-a-running-on-matlab-desktop-local-pc)
3. [Option B: Running on MATLAB Online (Web Browser)](#3-option-b-running-on-matlab-online-web-browser)
4. [Using the Interactive MATLAB GUI Dashboard](#4-using-the-interactive-matlab-gui-dashboard)
5. [Step-by-Step Manual Stage Execution Guide](#5-step-by-step-manual-stage-execution-guide)
6. [Troubleshooting & FAQs](#6-troubleshooting--faqs)

---

## 1. Where are my project files located?

* **Local Machine Path**:  
  `C:\Users\anupa\OneDrive\Documents\Mobile Communication Project`
* **GitHub Repository**:  
  `https://github.com/anupamsarashwat1-cloud/Mobile-communication-project.git`

> [!NOTE]
> If you open MATLAB Online, you are looking at MathWorks Cloud Storage (**MATLAB Drive**). Your local OneDrive files are on your PC. To view and run the project in MATLAB Online, you simply clone the repository into MATLAB Online in one command as shown in [Option B](#3-option-b-running-on-matlab-online-web-browser).

---

## 2. Option A: Running on MATLAB Desktop (Local PC)

### Method 1: The 1-Click Batch Launcher (Easiest)
1. Open Windows File Explorer and navigate to:
   `C:\Users\anupa\OneDrive\Documents\Mobile Communication Project`
2. Double-click **`launch_gui.bat`**.
3. MATLAB will open directly inside the project root, automatically run `startup.m`, and configure all paths.

### Method 2: From within MATLAB Desktop
1. Open **MATLAB R2026a** (or your installed MATLAB version).
2. In the MATLAB **Command Window**, copy and paste this command and hit **Enter**:
   ```matlab
   cd 'C:\Users\anupa\OneDrive\Documents\Mobile Communication Project'
   ```
3. Alternatively, click the **Browse for folder** icon (📁) at the top of the MATLAB toolbar and select `Documents > Mobile Communication Project`.
4. As soon as you navigate into the folder, `startup.m` automatically runs and displays the interactive command menu.

---

## 3. Option B: Running on MATLAB Online (Web Browser)

To run the project in **MATLAB Online** ([matlab.mathworks.com](https://matlab.mathworks.com)):

### Step 1: Open MATLAB Online
Log in to [matlab.mathworks.com](https://matlab.mathworks.com) and click **Open MATLAB Online**.

### Step 2: Clone the Project Repository
In the MATLAB Online **Command Window**, type:
```matlab
!git clone https://github.com/anupamsarashwat1-cloud/Mobile-communication-project.git
```
*(Or in the top toolbar: **Git > Clone Repository** > Paste `https://github.com/anupamsarashwat1-cloud/Mobile-communication-project.git`)*

### Step 3: Enter the Project Directory
In the Command Window, type:
```matlab
cd Mobile-communication-project
startup
```
You are now ready to run everything in the cloud!

---

## 4. Using the Interactive MATLAB GUI Dashboard

We have created an interactive Graphical User Interface (GUI) app that allows you to run each stage and inspect plots with a single click.

1. In the MATLAB Command Window, type:
   ```matlab
   gui_dashboard
   ```
2. A window titled **"5G MIMO Diversity vs. Spatial Multiplexing Optimization Dashboard"** will open.
3. Click any of the stage buttons on the left panel:
   - **Stage 1**: Computes 10,000 Kronecker channel realizations and plots condition number growth.
   - **Stage 2**: Evaluates Alamouti STBC vs Linear ZF/MMSE BER curves.
   - **Stage 3**: Runs SVD and iterative Water-Filling ergodic capacity sweeps.
   - **Stage 4**: Evaluates Adaptive Mode Switching and plots the Goodput envelope.
   - **Stage 5**: Simulates non-linear Ordered MMSE-SIC (V-BLAST) detection.
   - **Stage 6**: Computes the Zheng-Tse DMT theoretical bound.
   - **Run Full Master Benchmark Suite**: Runs the complete end-to-end simulation.

---

## 5. Step-by-Step Manual Stage Execution Guide

If you prefer to run scripts one-by-one from the Command Window or MATLAB Editor, follow these steps:

### Stage 1: Channel Modeling & Condition Number Analysis
* **What it does**: Generates correlated Rayleigh MIMO matrices and assesses ill-conditioning.
* **Command**:
  ```matlab
  run('01_channel_modeling/test_channel_statistics.m')
  ```
* **Output Generated**:
  - `01_channel_modeling/figures/singular_value_pdf.png`
  - `01_channel_modeling/figures/condition_number_vs_correlation.png`

---

### Stage 2: Baseline Transceivers (Alamouti STBC vs ZF/MMSE)
* **What it does**: Quantifies BER performance and reveals ZF noise amplification.
* **Command**:
  ```matlab
  run('02_baseline_transceivers/run_baseline_comparison.m')
  ```
* **Output Generated**:
  - `02_baseline_transceivers/figures/alamouti_vs_sm_ber.png`
  - `02_baseline_transceivers/figures/zf_noise_amplification_analysis.png`

---

### Stage 3: SVD & Water-Filling Capacity Optimization
* **What it does**: Implements iterative water-filling power allocation across spatial eigenmodes.
* **Command**:
  ```matlab
  run('03_optimization_svd_waterfilling/run_capacity_optimization.m')
  ```
* **Output Generated**:
  - `03_optimization_svd_waterfilling/figures/capacity_wf_vs_equal_power.png`
  - `03_optimization_svd_waterfilling/figures/capacity_gain_vs_correlation.png`

---

### Stage 4: Dynamic Adaptive Mode Switching (Goodput Optimization)
* **What it does**: Dynamically adapts rank (Alamouti Diversity vs Spatial Mux) based on SNR and $\kappa(\mathbf{H})$.
* **Command**:
  ```matlab
  run('04_adaptive_mode_switching/run_adaptive_switching_simulation.m')
  ```
* **Output Generated**:
  - `04_adaptive_mode_switching/figures/effective_goodput_envelope.png`
  - `04_adaptive_mode_switching/figures/mode_switching_decision_boundary.png`

---

### Stage 5: Advanced Non-Linear Receivers (MMSE-SIC / V-BLAST)
* **What it does**: Evaluates successive interference cancellation and provides the Simulink block diagram.
* **Command**:
  ```matlab
  run('05_simulink_and_advanced_receivers/run_sic_simulation.m')
  ```
* **Output Generated**:
  - `05_simulink_and_advanced_receivers/figures/sic_vs_linear_receivers_ber.png`
  - `05_simulink_and_advanced_receivers/figures/simulink_model_overview.png`

---

### Stage 6: Master Benchmark Suite & Zheng-Tse DMT Bound
* **What it does**: Executes end-to-end evaluation and plots the 4-panel consolidated summary.
* **Command**:
  ```matlab
  run('06_master_runner_and_benchmarks/main_benchmark_suite.m')
  ```
* **Output Generated**:
  - `06_master_runner_and_benchmarks/figures/master_comprehensive_summary.png`
  - `06_master_runner_and_benchmarks/figures/dmt_diversity_multiplexing_curve.png`

---

## 6. Troubleshooting & FAQs

### Q: Why do I see no Communications Toolbox error?
**A**: All mathematical functions (`modulate_qam`, `demodulate_qam`, `smooth_density`, `fast_prctile`) were built natively in `common/`. You do not need any optional toolbox installed.

### Q: How do I export new high-resolution figures?
**A**: Every script automatically saves high-resolution `.png` files into its respective `figures/` folder when executed.

### Q: How do I update my local code if changes are pushed to GitHub?
**A**: In your Command Window, simply run:
```matlab
!git pull origin main
```
