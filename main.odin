package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:time"
import r "renderer"
import "vendor:sdl3"
import "vendor:wgpu"
import "vendor:wgpu/sdl3glue"


main :: proc() {
	flags := sdl3.InitFlags{.VIDEO, .EVENTS}
	sdlRes := sdl3.Init(flags)

	if sdlRes == false {
		fmt.println("SDL initialization failed")
		os.exit(1)
	} else {
		fmt.println("SDL initialized successfully")
	}

	ren, succ := r.init_renderer()

	if !succ {
		panic("Couldnt init Renderer")
	}

	test_res := r.renderer_test_command_queue(&ren)

	fmt.printfln("Tesing Result: %v", test_res)


	event: sdl3.Event
	running := true

	now := sdl3.GetPerformanceCounter()
	last: u64
	dt: f32

	shader := r.init_shader(ren)
	pipeline := r.init_pipeline(ren, shader)
	obj := r.create_tri_object(ren)
	vsync := true


	print_perf := false
	for running {

		last = now
		now = sdl3.GetPerformanceCounter()
		dt = f32((now - last) * 1000) / f32(sdl3.GetPerformanceFrequency())

		if print_perf {
			fmt.printfln("Frametime: %v", dt)
		}
		for sdl3.PollEvent(&event) {
			if event.type == .QUIT {
				running = false
			} else if event.type == .KEY_UP {
				if event.key.scancode == .B {
					fmt.println("Testing buffers...")
					r.test_buffers(ren)
				} else if event.key.scancode == .P {
					print_perf = !print_perf
				} else if event.key.scancode == .V {
					r.renderer_toggle_vsync(&ren, !vsync)
					vsync = !vsync
					fmt.printfln("Set VSync: %v", vsync)
				} else {
					fmt.printfln("Key: %v", event.key)
				}
			}
		}

		r.start_frame(&ren)
		r.clear_screen(ren)
		r.render_pipeline(ren, pipeline, obj)
		r.end_frame(&ren)
	}

	r.deinit_object(obj)
	r.deinit_pipeline(pipeline)
	r.deinit_shader(shader)
	r.deinit_renderer(ren)
	sdl3.Quit()


	os.exit(0)
}
