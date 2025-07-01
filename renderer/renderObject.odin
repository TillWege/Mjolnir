package renderer

import "vendor:wgpu"

Render_Object :: struct {
	buffer:    wgpu.Buffer,
	vertCount: u32,
}

create_tri_object :: proc(ren: Renderer) -> Render_Object {
	vert_data: []f32 = {-0.5, -0.5, 0.5, -0.5, 0.0, 0.5, -0.55, -0.5, -0.05, 0.5, -0.55, 0.5}
	vertex_count := len(vert_data) / 2

	buffer_desc := wgpu.BufferDescriptor {
		label            = "tri obj vertex buffer",
		mappedAtCreation = false,
		usage            = {.CopyDst, .Vertex},
		size             = u64(vertex_count * 2 * size_of(f32)),
	}

	buffer := wgpu.DeviceCreateBuffer(ren.device, &buffer_desc)

	if buffer == nil {
		panic("Couldnt create tri object")
	}

	wgpu.QueueWriteBuffer(ren.queue, buffer, 0, &vert_data[0], uint(buffer_desc.size))

	return {buffer = buffer, vertCount = u32(vertex_count)}
}

deinit_object :: proc(obj: Render_Object) {
	wgpu.BufferDestroy(obj.buffer)
}
