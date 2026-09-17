# health_tracker

A helath tracker app

## Getting Started
* 🎬 **Screen Recording**: [Watch Demo Video](https://drive.google.com/file/d/1zEOlR3uSxNzbXI8WnPCiy41hL9zQWD7D/view?usp=drive_link)

  ## 🏗️ Architecture Overview

The app follows a clean, layer-separated architecture using **Riverpod** (`StateNotifierProvider`) for state management:

* **Data Layer (`lib/data`)**: Defines data models (`StepsTakenModel`, `HeartBeatModel`) and streaming sources (`HealthConnectService`, `Data Source`).
* **Presentation Layer (`lib/presentation`)**: Pure Flutter UI.

  ## 🧪 Tests Implemented

* **Unit Testing (`test/unit/`)**:

## ⚙️ CI Pipeline (GitHub Actions)
