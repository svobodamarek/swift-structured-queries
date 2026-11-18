import SwiftSyntax
import SwiftSyntaxBuilder

struct SelfRewriter {
  let selfEquivalent: TokenSyntax

  func rewrite(_ text: String) -> String {
    var rewritten = ""
    var index = text.startIndex
    while index < text.endIndex {
      guard text[index...].hasPrefix("Self") else {
        rewritten.append(text[index])
        index = text.index(after: index)
        continue
      }

      let before = index == text.startIndex ? nil : text[text.index(before: index)]
      let afterIndex = text.index(index, offsetBy: 4)
      let after = afterIndex == text.endIndex ? nil : text[afterIndex]
      if before?.isIdentifierCharacter != true && after?.isIdentifierCharacter != true {
        rewritten += selfEquivalent.trimmedDescription
        index = afterIndex
      } else {
        rewritten.append(text[index])
        index = text.index(after: index)
      }
    }
    return rewritten
  }
}

extension Character {
  fileprivate var isIdentifierCharacter: Bool {
    isLetter || isNumber || self == "_"
  }
}

extension DeclSyntax {
  func rewritten(_ rewriter: SelfRewriter) -> DeclSyntax {
    DeclSyntax("\(raw: rewriter.rewrite(description))")
  }
}

extension ExprSyntax {
  func rewritten(_ rewriter: SelfRewriter) -> ExprSyntax {
    ExprSyntax("\(raw: rewriter.rewrite(description))")
  }
}

extension PatternBindingSyntax {
  func rewritten(_ rewriter: SelfRewriter) -> PatternBindingSyntax {
    var binding = self
    binding.typeAnnotation = binding.typeAnnotation.map {
      $0.with(\.type, $0.type.rewritten(rewriter))
    }
    binding.initializer = binding.initializer.map {
      $0.with(\.value, $0.value.rewritten(rewriter))
    }
    return binding
  }
}

extension TypeSyntax {
  func rewritten(_ rewriter: SelfRewriter) -> TypeSyntax {
    TypeSyntax("\(raw: rewriter.rewrite(description))")
  }
}

extension VariableDeclSyntax {
  func rewritten(_ rewriter: SelfRewriter) -> VariableDeclSyntax {
    with(
      \.bindings,
      PatternBindingListSyntax(bindings.map { $0.rewritten(rewriter) })
    )
  }
}
