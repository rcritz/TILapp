import Vapor
import App
import FluentPostgreSQL

extension Application {
  static func testable(envArgs: [String]? = nil) throws
    -> Application {
      var config = Config.default()
      var services = Services.default()
      var env = Environment.testing
      
      if let environmentArgs = envArgs {
        env.arguments = environmentArgs
      }
      
      try App.configure(&config, &env, &services)
      let app = try Application(config: config,
                                environment: env,
                                services: services)
      
      try App.boot(app)
      return app
  }

  static func reset() throws {
    let revertEnvironment = ["vapor", "revert", "--all", "-y"]
    try Application.testable(envArgs: revertEnvironment)
      .asyncRun()
      .wait()
  }

  // 1
  func sendRequest(to path: String,
                   method: HTTPMethod,
                   headers: HTTPHeaders = .init(),
                   body: HTTPBody = .init()) throws -> Response {
    // 2
    let responder = try self.make(Responder.self)
    let request = HTTPRequest(method: method,
                              url: URL(string: path)!,
                              headers:headers, body: body)
    let wrappedRequest = Request(http: request, using: self)
    // 3
    return try responder.respond(to: wrappedRequest).wait()
  }
  
  // 4
  func getResponse<T>(to path: String,
                      method: HTTPMethod = .GET,
                      headers: HTTPHeaders = .init(),
                      body: HTTPBody = .init(),
                      decodeTo type: T.Type) throws
    -> T where T: Decodable {
      // 5
      let response = try self.sendRequest(to: path,
                                          method: method,
                                          headers: headers,
                                          body: body)
      
      // 6
      return try
        JSONDecoder().decode(type,
                             from: response.http.body.data!)
  }

  func getResponse<T, U>(to path: String,
                         method: HTTPMethod = .GET,
                         headers: HTTPHeaders = .init(),
                         data: U,
                         decodeTo type: T.Type) throws
    -> T where T: Decodable, U: Encodable {
      let body = try HTTPBody(data: JSONEncoder().encode(data))
      return try self.getResponse(to: path,
                                  method: method,
                                  headers: headers,
                                  body: body,
                                  decodeTo: type)
  }

  func sendRequest<T>(to path: String,
                      method: HTTPMethod,
                      headers: HTTPHeaders,
                      data: T) throws where T: Encodable {
    let body = try HTTPBody(data: JSONEncoder().encode(data))
    _ = try self.sendRequest(to: path,
                             method: method,
                             headers: headers,
                             body: body)
  }
}
