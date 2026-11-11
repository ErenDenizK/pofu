# Plate image format (HEIC vs PNG)

Question: how do we ship ~280 cells of full-size alpha plates without a 1.6 GB repo? Decision: ADR-0024.
Test: home day L10, night L10, day L2 plates (2048 x 3072 RGBA), vs the PNG source.

| Format | Size per plate | SSIM | ΔE2000 p95 | Note |
|---|---|---|---|---|
| PNG (now) | 3.6-5.7 MB | 1 | 0 | 64 MB for home's 11 states |
| HEIC q60 | 243-452 KB | .986-.992 | 1.1-2.2 | invisible at 200% |
| HEIC q70 (shipped) | ~0.7-0.8 MB | - | 1.4-2.0 (20 plates) | measured on all home and Çağlayan plates |
| AVIF | ~35% under HEIC | - | - | iOS 16+, not a catalog format |
| pngquant | - | - | - | visibly worse |

Small layers: islands (p95 3-8) and occluders (p95 1-4.6) suffer from 4:2:0 chroma on saturated edges; 4:4:4 halves the
error at +10-20% size but Apple decode of HEVC RExt is unverified, so q70 4:2:0 ships. Repo: 92 layers, 120.9 -> 18.4 MB.
