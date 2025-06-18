package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:time"
import r "renderer"
import "vendor:sdl3"
import "vendor:wgpu"
import "vendor:wgpu/sdl3glue"

clearScreen :: proc(device: wgpu.Device, texView: wgpu.TextureView) {
	queue := wgpu.DeviceGetQueue(device)

	{
		UserData :: struct {
			done: bool,
		}

		onDone := proc "c" (
			status: wgpu.QueueWorkDoneStatus,
			userData: rawptr,
			userData2: rawptr,
		) {
			context = runtime.default_context()
			//fmt.printf("Finished Clearing with status: %v", status)
			data := transmute(^UserData)userData
			data.done = true
		}

		data := UserData{false}

		wgpu.QueueOnSubmittedWorkDone(
			queue,
			wgpu.QueueWorkDoneCallbackInfo{callback = onDone, userdata1 = &data},
		)


		encoderDesc := wgpu.CommandEncoderDescriptor {
			label = "my command encoder",
		}

		encoder := wgpu.DeviceCreateCommandEncoder(device, &encoderDesc)


		renderPassColorAttachment := wgpu.RenderPassColorAttachment {
			view       = texView,
			loadOp     = .Clear,
			storeOp    = .Store,
			clearValue = wgpu.Color{0.9, 0.1, 0.2, 1.0},
			depthSlice = wgpu.DEPTH_SLICE_UNDEFINED,
		}


		renderPassDescriptor := wgpu.RenderPassDescriptor {
			colorAttachmentCount = 1,
			colorAttachments     = &renderPassColorAttachment,
		}
		renderPass := wgpu.CommandEncoderBeginRenderPass(encoder, &renderPassDescriptor)


		wgpu.RenderPassEncoderEnd(renderPass)

		cmdBufferDesc := wgpu.CommandBufferDescriptor {
			label = "my command buffer",
		}

		cmdBuffer := wgpu.CommandEncoderFinish(encoder, &cmdBufferDesc)


		bufferArr := []wgpu.CommandBuffer{cmdBuffer}
		wgpu.QueueSubmit(queue, bufferArr)

		wgpu.CommandBufferRelease(cmdBuffer)
		wgpu.CommandEncoderRelease(encoder)

		wgpu.DevicePoll(device, false, nil)
	}

	wgpu.QueueRelease(queue)
}

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

		// // Render Frame
		// {
		// 	tex := wgpu.SurfaceGetCurrentTexture(surface)

		// 	if tex.status == .SuccessOptimal {
		// 		textureViewDesc := wgpu.TextureViewDescriptor {
		// 			label           = "Surface Texture View",
		// 			format          = wgpu.TextureGetFormat(tex.texture),
		// 			dimension       = ._2D,
		// 			baseMipLevel    = 0,
		// 			mipLevelCount   = 1,
		// 			baseArrayLayer  = 0,
		// 			arrayLayerCount = 1,
		// 			aspect          = .All,
		// 		}
		// 		textureView := wgpu.TextureCreateView(tex.texture, &textureViewDesc)


		// 		clearScreen(device, textureView)

		// 		wgpu.SurfacePresent(surface)
		// 		wgpu.TextureViewRelease(textureView)
		// 	}
		// 	wgpu.TextureRelease(tex.texture)
		// }
	}
	r.deinit_renderer(ren)
	sdl3.Quit()


	os.exit(0)
}
