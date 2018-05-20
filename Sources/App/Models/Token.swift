import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class Token: Codable {
  var id: UUID?
  var token: String
  var userID: User.ID
  
  init(token: String, userID: User.ID) {
    self.token = token
    self.userID = userID
  }
}

extension Token: PostgreSQLUUIDModel {}
extension Token: Migration {}
extension Token: Content {}

extension Token {
  // 1
  static func generate(for user: User) throws -> Token {
    // 2
    let random = try CryptoRandom().generateData(count: 16)
    // 3
    return try Token(token: random.base64EncodedString(),
                     userID: user.requireID())
  }
}

extension Token: Authentication.Token {
  // 2
  static let userIDKey: UserIDKey = \Token.userID
  // 3
  typealias UserType = User
  // 4
//  typealias UserIDType = User.ID
}

// 5
extension Token: BearerAuthenticatable {
  // 6
  static let tokenKey: TokenKey = \Token.token
}
