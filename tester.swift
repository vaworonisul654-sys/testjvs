import Foundation

let rawJson = """
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "```json\\n{\\n  \\\"source_lang\\\": \\\"English\\\",\\n  \\\"translated_text\\\": \\\"Hello World\\\"\\n}\\n```"
      }
    }
  ]
}
"""
let data = rawJson.data(using: .utf8)!

guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let choices = json["choices"] as? [[String: Any]],
      let firstChoice = choices.first,
      let message = firstChoice["message"] as? [String: Any],
      let content = message["content"] as? String else {
    print("Failed")
    exit(1)
}

print("Extracted content:", content)

var cleanedContent = content
if let firstBrace = content.firstIndex(of: "{"),
   let lastBrace = content.lastIndex(of: "}") {
    cleanedContent = String(content[firstBrace...lastBrace])
}
print("Cleaned:", cleanedContent)
