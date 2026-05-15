// Dithering technique constants — pass as dither_mode uniform.
const int DITHER_BAYER4    = 0;  // 4x4 ordered (Obra Dinn style)
const int DITHER_BAYER8    = 1;  // 8x8 ordered (smoother gradients)
const int DITHER_NOISE     = 2;  // animated white noise (film grain)
const int DITHER_SCANLINE  = 3;  // horizontal scanlines (retro CRT)

// --- Bayer 4x4 ---
float _bayer4(ivec2 p) {
	int x = p.x & 3, y = p.y & 3;
	if (y == 0) return float[](0.0,  8.0,  2.0, 10.0)[x] / 16.0;
	if (y == 1) return float[](12.0,  4.0, 14.0,  6.0)[x] / 16.0;
	if (y == 2) return float[](3.0, 11.0,  1.0,  9.0)[x] / 16.0;
	             return float[](15.0,  7.0, 13.0,  5.0)[x] / 16.0;
}

// --- Bayer 8x8 ---
float _bayer8_row(int row, int col) {
	col = col & 7;
	if (row == 0) return float[]( 0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0)[col];
	if (row == 1) return float[](48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0)[col];
	if (row == 2) return float[](12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0)[col];
	if (row == 3) return float[](60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0)[col];
	if (row == 4) return float[]( 3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0)[col];
	if (row == 5) return float[](51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0)[col];
	if (row == 6) return float[](15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0)[col];
	              return float[](63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0)[col];
}
float _bayer8(ivec2 p) {
	return _bayer8_row(p.y & 7, p.x & 7) / 64.0;
}

// --- Animated white noise ---
float _noise_hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 74.27);
	return fract(p.x * p.y);
}
float _white_noise(ivec2 p) {
	// Advances each frame so the grain animates like film.
	return _noise_hash(vec2(p) + floor(TIME * 24.0) * 0.317);
}

// --- Scanline ---
float _scanline(ivec2 p) {
	// Even rows have a low threshold (likely white), odd rows high (likely black)
	return (p.y & 1) == 0 ? 0.25 : 0.75;
}

// --- Public dispatch ---
// Returns a threshold in [0, 1). Compare with brightness: pixel is white if brightness > threshold.
float dither_threshold(ivec2 screen_px, int mode) {
	if (mode == DITHER_BAYER8)   return _bayer8(screen_px);
	if (mode == DITHER_NOISE)    return _white_noise(screen_px);
	if (mode == DITHER_SCANLINE) return _scanline(screen_px);
	return _bayer4(screen_px); // DITHER_BAYER4 and default
}
