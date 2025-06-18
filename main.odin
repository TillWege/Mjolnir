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

	for running {

		last = now
		now = sdl3.GetPerformanceCounter()
		dt = f32((now - last) * 1000) / f32(sdl3.GetPerformanceFrequency())

		for sdl3.PollEvent(&event) {
			if event.type == .QUIT {
				running = false
			}
		}

		r.start_frame(&ren)
		r.clear_screen(ren)
		r.end_frame(&ren)
	}
	r.deinit_renderer(ren)
	sdl3.Quit()


	os.exit(0)
}
