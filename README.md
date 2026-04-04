# civic_connect
Smart Civic Issue Reporting and Resolution Platform - Bridging the gap between citizens and municipalities for faster civic issue resolution.

## Mapbox Setup

This project uses `mapbox_maps_flutter` on the citizen map page with local environment-based token management.

### Quick Start

1. **Get a Mapbox token**
   - Sign up at [mapbox.com](https://account.mapbox.com/)
   - Create a public token in your account settings

2. **Set up local environment**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your Mapbox public token:
   ```env
   MAPBOX_PUBLIC_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
   ```

3. **Run the app**
   ```bash
   flutter pub get
   flutter run
   ```

> **Note:** The `.env` file is in `.gitignore` and won't be committed to the repository. Each developer must have their own local `.env` file.

### Environment Variables

- `MAPBOX_PUBLIC_TOKEN` - **Required** - Your Mapbox public token for map rendering
  - Get it from: https://account.mapbox.com/tokens/

### Map Types Available in App

The map page includes style switching:

- Default
- Streets
- Satellite
- Satellite Streets
- Outdoors
