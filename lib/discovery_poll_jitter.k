let hexVal = c -> match c {
    case "0" -> 0
    case "1" -> 1
    case "2" -> 2
    case "3" -> 3
    case "4" -> 4
    case "5" -> 5
    case "6" -> 6
    case "7" -> 7
    case "8" -> 8
    case "9" -> 9
    case "a" -> 10
    case "b" -> 11
    case "c" -> 12
    case "d" -> 13
    case "e" -> 14
    case "f" -> 15
    case "A" -> 10
    case "B" -> 11
    case "C" -> 12
    case "D" -> 13
    case "E" -> 14
    case "F" -> 15
    case _ -> 0
}

let hash = user_id ->
    for i < chars.length with i = 0, h = 0, chars = user_id.split("") {
        h = (h * 33 + hexVal(chars[i])) % 2147483647
        i++
    } then h

let delayMs = (user_id, max_ms) -> {
    let max = if max_ms < 0 { 0 } else { max_ms }
    if max == 0 { 0 } else { hash(user_id) % max }
}
