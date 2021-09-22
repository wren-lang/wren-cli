import "scheduler" for Scheduler
import "ensure" for Ensure

class Timer {
  static sleep(milliseconds) {
    Ensure.positiveNum(milliseconds, "milliseconds")
    return Scheduler.await_ { startTimer_(milliseconds, Fiber.current) }
  }

  foreign static startTimer_(milliseconds, fiber)
}
