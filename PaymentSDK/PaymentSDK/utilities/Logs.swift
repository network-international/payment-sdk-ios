import Foundation

func log(_ logMessage: String, functionName: String = #function, line: Int = #line, file: String = #file)
{
    let thread = Thread.isMainThread ? "🌕" : "🌘"
    let className = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    print("\(thread) 📚\(className) ✳️ \(functionName) #️⃣[\(line)]: \(logMessage)")
}
