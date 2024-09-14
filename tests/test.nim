# Copyright 2019, NimGL contributors.

import imgui, imgui/[impl_opengl, impl_glfw]
import opengl
import nglfw as glfw

proc main() =
  assert glfw.init()

  glfw.windowHint(glfw.ContextVersionMajor, 4)
  glfw.windowHint(glfw.ContextVersionMinor, 1)
  glfw.windowHint(glfw.OpenglForwardCompat, glfw.TRUE)
  glfw.windowHint(glfw.OpenglProfile, glfw.OPENGL_CORE_PROFILE)
  glfw.windowHint(glfw.Resizable, glfw.FALSE)

  var w: glfw.Window = glfw.createWindow(1280, 720, "GLFW", nil, nil)
  if w == nil:
    quit(-1)

  w.makeContextCurrent()

  if not gladLoadGL(glfw.getProcAddress):
    echo "Could not initialize OpenGL"
    quit -1

  let context = igCreateContext()
  #let io = igGetIO()

  assert igGlfwInitForOpenGL(w, true)
  assert igOpenGL3Init()

  igStyleColorsCherry()

  var show_demo: bool = true
  var somefloat: float32 = 0.0f
  var counter: int32 = 0

  while not w.windowShouldClose:
    glfw.pollEvents()

    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()

    if show_demo:
      igShowDemoWindow(show_demo.addr)

    # Simple window
    igBegin("Hello, world!")

    igText("This is some useful text.")
    igCheckbox("Demo Window", show_demo.addr)

    igSliderFloat("float", somefloat.addr, 0.0f, 1.0f)

    if igButton("Button", ImVec2(x: 0, y: 0)):
      counter.inc
    igSameLine()
    igText("counter = %d", counter)

    igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / igGetIO().framerate, igGetIO().framerate)
    igEnd()
    # End simple window

    igRender()

    glClearColor(0.45f, 0.55f, 0.60f, 1.00f)
    glClear(GL_COLOR_BUFFER_BIT)

    igOpenGL3RenderDrawData(igGetDrawData())

    w.swapBuffers()

  igOpenGL3Shutdown()
  igGlfwShutdown()
  context.igDestroyContext()

  w.destroyWindow()
  glfw.terminate()

main()
