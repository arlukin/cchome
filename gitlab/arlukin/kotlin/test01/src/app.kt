import java.util.concurrent.atomic.AtomicLong

data class Greeting(val id: Long, val content: String)

class GreetingController {

    private val counter = AtomicLong()

    fun greeting(value: String = "name", defaultValue: String = "World") : Greeting {
        return Greeting(id = counter.incrementAndGet(), content="Hello, $value")
    }
}

fun main() {
    val x = GreetingController()
    println(x.greeting("cow 1"))
    println(x.greeting("cow 2"))
    println(x.greeting("cow 3"))
    println(x.greeting("cow 46"))
    println(x.greeting("cow 5"6))

    println("Hello world")
}
