import "scheduler" for Scheduler

class Timer {
  static sleep(milliseconds) {
    if (!(milliseconds is Num)) Fiber.abort("Milliseconds must be a number.")
    if (milliseconds < 0) Fiber.abort("Milliseconds cannot be negative.")

    return Scheduler.await_ { startTimer_(milliseconds, Fiber.current) }
  }

  foreign static startTimer_(milliseconds, fiber)
}
