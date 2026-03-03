# J.A.R.V.I.S. Command Center 🌐🛰️

This is the main control center for the **J.A.R.V.I.S. Project**.

## Architecture
- **iOS**: Native SwiftUI Core.
- **Android**: Flutter-based system in `JarvisAndroid01`.
- **Command Center**: Managed via the `agent/` directory with specific roles ([ARCH], [CORE], [UI], [BUILD]).

## Key Commands
- `/status`: Get project state report.
- `/save`: Save session progress.
- `/audit`: Perform a full system audit.

## Recent Updates
- **2026-03-03**: Successfully migrated Android build to GitHub Actions in a clean ASCII path.
- **2026-03-03**: Implemented Stream-based Mentor logic and Glassmorphism for Android.
