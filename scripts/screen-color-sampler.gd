extends Node

## Samples screen colors and provides median color for transitions/backgrounds
## Attached as autoload singleton

const SAMPLE_GRID_SIZE: int = 8  # 8x8 = 64 samples (good balance)

## Get median color of current screen
## Uses a grid sampling approach for performance
func get_median_color() -> Color:
	var viewport := get_viewport()
	if not viewport:
		return Color(0.996, 0.616, 0.388)  # Fallback to default orange

	# Wait for frame to render
	await RenderingServer.frame_post_draw

	var viewport_texture := viewport.get_texture()
	var image := viewport_texture.get_image()

	if not image:
		return Color(0.996, 0.616, 0.388)

	var width := image.get_width()
	var height := image.get_height()

	# Collect color samples in a grid pattern
	var reds: Array[float] = []
	var greens: Array[float] = []
	var blues: Array[float] = []

	var step_x := width / SAMPLE_GRID_SIZE
	var step_y := height / SAMPLE_GRID_SIZE

	for y in range(SAMPLE_GRID_SIZE):
		for x in range(SAMPLE_GRID_SIZE):
			var px := int(x * step_x + step_x / 2)
			var py := int(y * step_y + step_y / 2)

			# Clamp to valid range
			px = clamp(px, 0, width - 1)
			py = clamp(py, 0, height - 1)

			var pixel := image.get_pixel(px, py)
			reds.append(pixel.r)
			greens.append(pixel.g)
			blues.append(pixel.b)

	# Calculate median for each channel
	reds.sort()
	greens.sort()
	blues.sort()

	var mid := SAMPLE_GRID_SIZE * SAMPLE_GRID_SIZE / 2

	return Color(reds[mid], greens[mid], blues[mid])

## Get average color (alternative method, usually less visually pleasing)
func get_average_color() -> Color:
	var viewport := get_viewport()
	if not viewport:
		return Color(0.996, 0.616, 0.388)

	await RenderingServer.frame_post_draw

	var viewport_texture := viewport.get_texture()
	var image := viewport_texture.get_image()

	if not image:
		return Color(0.996, 0.616, 0.388)

	var width := image.get_width()
	var height := image.get_height()

	var total_r := 0.0
	var total_g := 0.0
	var total_b := 0.0

	var step_x := width / SAMPLE_GRID_SIZE
	var step_y := height / SAMPLE_GRID_SIZE
	var sample_count := 0

	for y in range(SAMPLE_GRID_SIZE):
		for x in range(SAMPLE_GRID_SIZE):
			var px := int(x * step_x + step_x / 2)
			var py := int(y * step_y + step_y / 2)

			px = clamp(px, 0, width - 1)
			py = clamp(py, 0, height - 1)

			var pixel := image.get_pixel(px, py)
			total_r += pixel.r
			total_g += pixel.g
			total_b += pixel.b
			sample_count += 1

	return Color(
		total_r / sample_count,
		total_g / sample_count,
		total_b / sample_count
	)
